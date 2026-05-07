@testable import Espresso
import Foundation
import XCTest

@MainActor
final class SleepAssertionControllerTests: XCTestCase {
    func testStartCreatesAssertionAndSession() {
        let client = FakeSleepAssertionClient()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let controller = EspressoController(assertionClient: client, now: { date })

        controller.start(duration: .fifteenMinutes)

        XCTAssertEqual(client.createdDurations, [.fifteenMinutes])
        XCTAssertEqual(controller.session, AwakeSession(duration: .fifteenMinutes, startDate: date))
        XCTAssertNil(controller.lastError)
    }

    func testStartReleasesExistingAssertionBeforeReplacement() {
        let client = FakeSleepAssertionClient()
        let controller = EspressoController(assertionClient: client)

        controller.start(duration: .fifteenMinutes)
        controller.start(duration: .oneHour)

        XCTAssertEqual(client.createdDurations, [.fifteenMinutes, .oneHour])
        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertEqual(controller.session?.duration, .oneHour)
    }

    func testStopReleasesAssertionAndClearsSession() {
        let client = FakeSleepAssertionClient()
        let controller = EspressoController(assertionClient: client)

        controller.start(duration: .thirtyMinutes)
        controller.stop()

        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertNil(controller.session)
        XCTAssertNil(controller.lastError)
    }

    func testExpiryReleasesAssertion() {
        let client = FakeSleepAssertionClient()
        let startDate = Date(timeIntervalSince1970: 1_800_000_000)
        let controller = EspressoController(assertionClient: client, now: { startDate })

        controller.start(duration: .fifteenMinutes)
        controller.expireIfNeeded(at: startDate.addingTimeInterval(900))

        XCTAssertEqual(client.releasedAssertions, [1])
        XCTAssertNil(controller.session)
    }

    func testCreateFailureLeavesInactiveState() {
        let client = FakeSleepAssertionClient()
        client.nextResult = .failure(SleepAssertionError(code: -1))
        let controller = EspressoController(assertionClient: client)

        controller.start(duration: .fifteenMinutes)

        XCTAssertNil(controller.session)
        XCTAssertEqual(controller.lastError, SleepAssertionError(code: -1))
        XCTAssertEqual(controller.menuBarState().statusTitle, "Unable to start")
        XCTAssertTrue(client.releasedAssertions.isEmpty)
    }
}

private final class FakeSleepAssertionClient: SleepAssertionClient {
    var nextResult: Result<SleepAssertionIdentifier, SleepAssertionError>?
    private var nextAssertion: SleepAssertionIdentifier = 1
    private(set) var createdDurations: [AwakeDuration] = []
    private(set) var releasedAssertions: [SleepAssertionIdentifier] = []

    func createAssertion(duration: AwakeDuration) -> Result<SleepAssertionIdentifier, SleepAssertionError> {
        createdDurations.append(duration)
        if let nextResult {
            self.nextResult = nil
            return nextResult
        }

        defer { nextAssertion += 1 }
        return .success(nextAssertion)
    }

    func releaseAssertion(_ assertion: SleepAssertionIdentifier) {
        releasedAssertions.append(assertion)
    }
}
