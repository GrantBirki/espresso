@testable import Espresso
import Foundation
import XCTest

final class AwakeSessionTests: XCTestCase {
    private let startUptime: TimeInterval = 1000

    func testFiniteSessionComputesEndUptime() {
        let session = AwakeSession(duration: .thirtyMinutes, startUptime: startUptime)

        XCTAssertEqual(session.endUptime, startUptime + 30 * 60)
    }

    func testIndefiniteSessionHasNoEndUptime() {
        let session = AwakeSession(duration: .indefinitely, startUptime: startUptime)

        XCTAssertNil(session.endUptime)
        XCTAssertTrue(session.isActive(at: startUptime + 10000))
        XCTAssertEqual(session.remainingLabel(at: startUptime), "Indefinitely")
    }

    func testFiniteSessionExpiresAtEndUptime() {
        let session = AwakeSession(duration: .fifteenMinutes, startUptime: startUptime)

        XCTAssertTrue(session.isActive(at: startUptime + 899))
        XCTAssertTrue(session.isExpired(at: startUptime + 900))
        XCTAssertFalse(session.isActive(at: startUptime + 900))
    }

    func testRemainingLabelsAreCompact() {
        let session = AwakeSession(duration: .fiveHours, startUptime: startUptime)

        XCTAssertEqual(session.remainingLabel(at: startUptime + 60), "4h 59m remaining")
        XCTAssertEqual(session.remainingLabel(at: startUptime + 5 * 60 * 60 - 90), "2m remaining")
        XCTAssertEqual(session.remainingLabel(at: startUptime + 5 * 60 * 60 - 10), "10s remaining")
        XCTAssertEqual(session.remainingLabel(at: startUptime + 5 * 60 * 60), "Expired")
    }
}
