@testable import Espresso
import Foundation
import XCTest

final class AwakeSessionTests: XCTestCase {
    private let startDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testFiniteSessionComputesEndDate() {
        let session = AwakeSession(duration: .thirtyMinutes, startDate: startDate)

        XCTAssertEqual(session.endDate, startDate.addingTimeInterval(30 * 60))
    }

    func testIndefiniteSessionHasNoEndDate() {
        let session = AwakeSession(duration: .indefinitely, startDate: startDate)

        XCTAssertNil(session.endDate)
        XCTAssertTrue(session.isActive(at: startDate.addingTimeInterval(10000)))
        XCTAssertEqual(session.remainingLabel(at: startDate), "Indefinitely")
    }

    func testFiniteSessionExpiresAtEndDate() {
        let session = AwakeSession(duration: .fifteenMinutes, startDate: startDate)

        XCTAssertTrue(session.isActive(at: startDate.addingTimeInterval(899)))
        XCTAssertTrue(session.isExpired(at: startDate.addingTimeInterval(900)))
        XCTAssertFalse(session.isActive(at: startDate.addingTimeInterval(900)))
    }

    func testRemainingLabelsAreCompact() {
        let session = AwakeSession(duration: .fiveHours, startDate: startDate)

        XCTAssertEqual(session.remainingLabel(at: startDate.addingTimeInterval(60)), "4h 59m remaining")
        XCTAssertEqual(session.remainingLabel(at: startDate.addingTimeInterval((5 * 60 * 60) - 90)), "2m remaining")
        XCTAssertEqual(session.remainingLabel(at: startDate.addingTimeInterval((5 * 60 * 60) - 10)), "10s remaining")
        XCTAssertEqual(session.remainingLabel(at: startDate.addingTimeInterval(5 * 60 * 60)), "Expired")
    }
}
