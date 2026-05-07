import Foundation

@MainActor
final class EspressoController {
    private let assertionClient: SleepAssertionClient
    private let now: () -> Date
    private var assertionID: SleepAssertionIdentifier?
    private var expiryTimer: Timer?
    private var refreshTimer: Timer?

    private(set) var session: AwakeSession?
    private(set) var lastError: SleepAssertionError?
    var onStateChange: (() -> Void)?

    init(
        assertionClient: SleepAssertionClient = IOKitSleepAssertionClient(),
        now: @escaping () -> Date = Date.init
    ) {
        self.assertionClient = assertionClient
        self.now = now
    }

    func start(duration: AwakeDuration) {
        releaseCurrentAssertion()
        cancelTimers()

        switch assertionClient.createAssertion(duration: duration) {
        case let .success(assertion):
            assertionID = assertion
            session = AwakeSession(duration: duration, startDate: now())
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

    func expireIfNeeded(at date: Date? = nil) {
        let comparisonDate = date ?? now()
        guard let session, session.isExpired(at: comparisonDate) else {
            return
        }
        stop()
    }

    func menuBarState(at date: Date? = nil) -> MenuBarState {
        MenuBarState(
            session: session,
            errorMessage: lastError?.userMessage,
            now: date ?? now()
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

        if let endDate = session.endDate {
            let interval = max(0.1, endDate.timeIntervalSince(now()))
            expiryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.expireIfNeeded()
                }
            }
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.expireIfNeeded()
                self?.onStateChange?()
            }
        }
    }
}
