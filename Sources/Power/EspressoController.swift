import Foundation

@MainActor
final class EspressoController {
    private let assertionClient: SleepAssertionClient
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    private var assertionID: SleepAssertionIdentifier?
    private var expiryTimer: Timer?
    private var refreshTimer: Timer?

    private(set) var session: AwakeSession?
    private(set) var lastError: SleepAssertionError?
    var onStateChange: (() -> Void)?

    init(
        assertionClient: SleepAssertionClient = IOKitSleepAssertionClient(),
        now: @escaping () -> Date = Date.init,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.assertionClient = assertionClient
        self.now = now
        self.uptime = uptime
    }

    func start(duration: AwakeDuration) {
        releaseCurrentAssertion()
        cancelTimers()

        switch assertionClient.createAssertion(duration: duration) {
        case let .success(assertion):
            assertionID = assertion
            session = AwakeSession(duration: duration, startUptime: uptime())
            lastError = nil
            scheduleTimers()
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
        cancelTimers()
        session = nil
        lastError = nil
        onStateChange?()
    }

    func expireIfNeeded(at comparisonUptime: TimeInterval? = nil) {
        guard let session, session.isExpired(at: comparisonUptime ?? uptime()) else {
            return
        }
        stop()
    }

    func menuBarState(at date: Date? = nil) -> MenuBarState {
        MenuBarState(
            session: session,
            errorMessage: lastError?.userMessage,
            now: date ?? now(),
            uptime: uptime()
        )
    }

    private func releaseCurrentAssertion() {
        if let assertionID {
            assertionClient.releaseAssertion(assertionID)
        }
        assertionID = nil
    }

    private func cancelTimers() {
        expiryTimer?.invalidate()
        expiryTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func scheduleTimers() {
        guard let session else { return }

        if let remaining = session.remainingTime(at: uptime()) {
            let timer = Timer(timeInterval: max(0.1, remaining), repeats: false) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.expireIfNeeded()
                }
            }
            expiryTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.expireIfNeeded()
                self?.onStateChange?()
            }
        }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}
