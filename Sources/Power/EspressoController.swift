import Combine
import Foundation

@MainActor
final class EspressoController {
    private let assertionClient: SleepAssertionClient
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    private let thermalState: () -> ProcessInfo.ThermalState
    private var thermalObservation: AnyCancellable?
    private var needsToCoolDown = false
    private var assertionID: SleepAssertionIdentifier?
    private var expiryTimer: Timer?

    private(set) var session: AwakeSession?
    private(set) var lastError: SleepAssertionError?
    var onStateChange: (() -> Void)?

    init(
        assertionClient: SleepAssertionClient = IOKitSleepAssertionClient(),
        now: @escaping () -> Date = Date.init,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        thermalState: @escaping () -> ProcessInfo.ThermalState = { ProcessInfo.processInfo.thermalState },
        notificationCenter: NotificationCenter = .default
    ) {
        self.assertionClient = assertionClient
        self.now = now
        self.uptime = uptime
        self.thermalState = thermalState

        // Foundation requires a thermal-state read before notification registration.
        needsToCoolDown = thermalLimitReached
        thermalObservation = notificationCenter.publisher(
            for: ProcessInfo.thermalStateDidChangeNotification, object: ProcessInfo.processInfo
        )
        .sink { @Sendable [weak self] _ in
            RunLoop.main.perform(inModes: [.common]) { [weak self] in
                MainActor.assumeIsolated { self?.thermalStateDidChange() }
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }
        thermalStateDidChange()
    }

    func start(duration: AwakeDuration) {
        needsToCoolDown = thermalLimitReached
        guard !needsToCoolDown else {
            stop()
            return
        }
        releaseCurrentAssertion()
        cancelExpiryTimer()

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
        releaseCurrentAssertion()
        cancelExpiryTimer()
        session = nil
        lastError = nil
        onStateChange?()
    }

    func expireIfNeeded(at comparisonUptime: TimeInterval? = nil) {
        cancelExpiryTimer()
        guard let remaining = session?.remainingTime(at: comparisonUptime ?? uptime()) else { return }
        guard remaining > 0 else {
            stop()
            return
        }
        let timer = Timer(timeInterval: remaining, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.expireIfNeeded() }
        }
        expiryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func menuBarState(at date: Date? = nil) -> MenuBarState {
        MenuBarState(
            session: session,
            errorMessage: needsToCoolDown ? "Off until your Mac cools down" : lastError?.userMessage,
            now: date ?? now(),
            uptime: uptime()
        )
    }

    private var thermalLimitReached: Bool {
        switch thermalState() {
        case .nominal, .fair: false
        case .serious, .critical: true
        @unknown default: true
        }
    }

    private func thermalStateDidChange() {
        let needsCooling = thermalLimitReached
        guard needsCooling != needsToCoolDown else { return }
        needsToCoolDown = needsCooling
        if needsCooling {
            stop()
        } else {
            onStateChange?()
        }
    }

    private func releaseCurrentAssertion() {
        if let assertionID {
            assertionClient.releaseAssertion(assertionID)
        }
        assertionID = nil
    }

    private func cancelExpiryTimer() {
        expiryTimer?.invalidate()
        expiryTimer = nil
    }
}
