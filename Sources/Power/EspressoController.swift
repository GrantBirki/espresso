import Combine
import Foundation
import os

@MainActor
final class EspressoController {
    private let assertionClient: SleepAssertionClient
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    private let thermalState: @Sendable () -> ProcessInfo.ThermalState
    private let pendingHeat = OSAllocatedUnfairLock<ThermalPressure?>(initialState: nil)
    private let recordThermalStop: (ThermalStopEvent) -> Void
    private var thermalReleasePending: ThermalPressure?
    private var thermalObservation: AnyCancellable?
    private var needsToCoolDown = false
    private var assertionID: SleepAssertionIdentifier?
    private var assertionTimer: Timer?

    private(set) var session: AwakeSession?
    private(set) var lastError: SleepAssertionError?
    var onStateChange: (() -> Void)?

    init(
        assertionClient: SleepAssertionClient = IOKitSleepAssertionClient(),
        now: @escaping () -> Date = Date.init,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        thermalState: @escaping @Sendable () -> ProcessInfo.ThermalState = { ProcessInfo.processInfo.thermalState },
        notificationCenter: NotificationCenter = .default,
        recordThermalStop: @escaping (ThermalStopEvent) -> Void = { $0.log() }
    ) {
        self.assertionClient = assertionClient
        self.now = now
        self.uptime = uptime
        self.thermalState = thermalState
        self.recordThermalStop = recordThermalStop

        // Foundation requires a thermal-state read before notification registration.
        needsToCoolDown = ThermalPressure(thermalState()) != nil
        thermalObservation = notificationCenter.publisher(
            for: ProcessInfo.thermalStateDidChangeNotification, object: ProcessInfo.processInfo
        )
        .sink { @Sendable [weak self, pendingHeat] _ in
            // A hot interval can end before the main run loop handles this notification.
            pendingHeat.withLock { pending in
                pending = ThermalPressure.peak(pending, ThermalPressure(thermalState()))
            }
            RunLoop.main.perform(inModes: [.common]) { [weak self] in
                MainActor.assumeIsolated { self?.thermalStateDidChange() }
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }
        thermalStateDidChange()
    }

    func start(duration: AwakeDuration) {
        let heat = consumeThermalReading()
        needsToCoolDown = heat.current != nil
        guard !needsToCoolDown else {
            stop(for: heat.peak)
            return
        }
        guard releaseCurrentAssertion(for: heat.peak) else {
            onStateChange?()
            return
        }

        switch assertionClient.createAssertion(duration: duration) {
        case let .success(assertion):
            assertionID = assertion
            session = AwakeSession(duration: duration, startUptime: uptime())
            lastError = nil
            expireIfNeeded()
            AppLog.power.info("Espresso started for \(duration.menuTitle, privacy: .public)")
        case let .failure(error):
            assertionID = nil
            session = nil
            lastError = error
            AppLog.power.error("Espresso failed to start: \(error.code, privacy: .public)")
        }

        onStateChange?()
    }

    func stop(for pressure: ThermalPressure? = nil) {
        _ = releaseCurrentAssertion(for: pressure)
        lastError = nil
        onStateChange?()
    }

    func expireIfNeeded(at comparisonUptime: TimeInterval? = nil) {
        guard let remaining = session?.remainingTime(at: comparisonUptime ?? uptime()) else { return }
        cancelAssertionTimer()
        guard remaining > 0 else {
            stop()
            return
        }
        let timer = Timer(timeInterval: remaining, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.expireIfNeeded() }
        }
        assertionTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func menuBarState(at date: Date? = nil) -> MenuBarState {
        MenuBarState(
            session: session,
            errorMessage: lastError?.userMessage,
            needsToCoolDown: needsToCoolDown,
            now: date ?? now(),
            uptime: uptime(),
            isStopping: assertionID != nil && session == nil
        )
    }

    private func consumeThermalReading() -> (current: ThermalPressure?, peak: ThermalPressure?) {
        pendingHeat.withLock { pending in
            let current = ThermalPressure(thermalState())
            defer { pending = nil }
            return (current, ThermalPressure.peak(pending, current))
        }
    }

    private func thermalStateDidChange() {
        let heat = consumeThermalReading()
        let availabilityChanged = needsToCoolDown != (heat.current != nil)
        needsToCoolDown = heat.current != nil
        if session != nil, let pressure = heat.peak {
            stop(for: pressure)
        } else if availabilityChanged {
            onStateChange?()
        }
    }

    private func releaseCurrentAssertion(for pressure: ThermalPressure?) -> Bool {
        cancelAssertionTimer()
        let newThermalStop = session == nil ? nil : pressure
        session = nil
        guard let assertionID else { return true }
        if assertionClient.releaseAssertion(assertionID) {
            self.assertionID = nil
            if let reason = thermalReleasePending ?? newThermalStop {
                thermalReleasePending = nil
                recordThermalStop(.stopped(reason))
            }
            return true
        }

        if let reason = newThermalStop {
            thermalReleasePending = reason
            recordThermalStop(.releasePending(reason))
        }
        let retry = Timer(timeInterval: 5, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
        retry.tolerance = 0.5
        assertionTimer = retry
        RunLoop.main.add(retry, forMode: .common)
        return false
    }

    private func cancelAssertionTimer() {
        assertionTimer?.invalidate()
        assertionTimer = nil
    }
}
