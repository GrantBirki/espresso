import Combine
import Foundation
import os

@MainActor
final class EspressoController {
    private let assertionClient: SleepAssertionClient
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    private let thermalState: @Sendable () -> ProcessInfo.ThermalState
    private let pendingHotState = OSAllocatedUnfairLock(initialState: false)
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
        notificationCenter: NotificationCenter = .default
    ) {
        self.assertionClient = assertionClient
        self.now = now
        self.uptime = uptime
        self.thermalState = thermalState

        // Foundation requires a thermal-state read before notification registration.
        needsToCoolDown = Self.requiresCooling(thermalState())
        thermalObservation = notificationCenter.publisher(
            for: ProcessInfo.thermalStateDidChangeNotification, object: ProcessInfo.processInfo
        )
        .sink { @Sendable [weak self, pendingHotState] _ in
            // A hot interval can end before the main run loop handles this notification.
            pendingHotState.withLock { pending in
                if Self.requiresCooling(thermalState()) {
                    pending = true
                }
            }
            RunLoop.main.perform(inModes: [.common]) { [weak self] in
                MainActor.assumeIsolated { self?.thermalStateDidChange() }
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }
        thermalStateDidChange()
    }

    func start(duration: AwakeDuration) {
        // A new selection after cooling supersedes notifications from the previous session.
        needsToCoolDown = pendingHotState.withLock { pending in
            pending = false
            return Self.requiresCooling(thermalState())
        }
        guard !needsToCoolDown else {
            stop()
            return
        }
        guard releaseCurrentAssertion() else {
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

    func stop() {
        _ = releaseCurrentAssertion()
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

    private nonisolated static func requiresCooling(_ state: ProcessInfo.ThermalState) -> Bool {
        switch state {
        case .nominal, .fair: false
        case .serious, .critical: true
        @unknown default: true
        }
    }

    private func thermalStateDidChange() {
        let (wasHot, isHot) = pendingHotState.withLock { pending in
            defer { pending = false }
            return (pending, Self.requiresCooling(thermalState()))
        }
        let availabilityChanged = needsToCoolDown != isHot
        needsToCoolDown = isHot
        if session != nil, wasHot || isHot {
            stop()
        } else if availabilityChanged {
            onStateChange?()
        }
    }

    private func releaseCurrentAssertion() -> Bool {
        cancelAssertionTimer()
        session = nil
        guard let assertionID else { return true }
        if assertionClient.releaseAssertion(assertionID) {
            self.assertionID = nil
            return true
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
