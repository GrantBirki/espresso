@testable import Espresso
import Foundation
import XCTest

final class MenuBarStateTests: XCTestCase {
    private let startDate = Date(timeIntervalSince1970: 1_800_000_000)
    private let startUptime: TimeInterval = 1000

    func testInactiveState() {
        let state = MenuBarState(session: nil, errorMessage: nil, now: startDate, uptime: startUptime)

        XCTAssertFalse(state.isActive)
        XCTAssertEqual(state.statusTitle, "Espresso is off")
        XCTAssertEqual(state.tooltip, "Espresso: Off")
        XCTAssertTrue(state.stopItemHidden)
        XCTAssertEqual(state.statusSymbolName, "cup.and.saucer")
    }

    func testActiveFiniteState() {
        let session = AwakeSession(duration: .oneHour, startUptime: startUptime)
        let state = MenuBarState(
            session: session, errorMessage: nil, now: startDate.addingTimeInterval(60), uptime: startUptime + 60
        )

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.selectedDuration, .oneHour)
        XCTAssertEqual(state.statusTitle, "On: 59m remaining")
        XCTAssertTrue(state.tooltip.hasPrefix("Espresso: On until "))
        XCTAssertFalse(state.stopItemHidden)
        XCTAssertEqual(state.statusSymbolName, "cup.and.saucer.fill")
    }

    func testActiveIndefiniteState() {
        let session = AwakeSession(duration: .indefinitely, startUptime: startUptime)
        let state = MenuBarState(
            session: session, errorMessage: nil, now: startDate.addingTimeInterval(60), uptime: startUptime + 60
        )

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.statusTitle, "On indefinitely")
        XCTAssertEqual(state.tooltip, "Espresso: On indefinitely")
        XCTAssertFalse(state.stopItemHidden)
    }

    func testClockChangesOnlyAdjustProjectedEndTime() {
        let session = AwakeSession(duration: .oneHour, startUptime: startUptime)
        let state = MenuBarState(session: session, errorMessage: nil, now: startDate, uptime: startUptime + 60)
        let laterClock = MenuBarState(
            session: session, errorMessage: nil, now: startDate.addingTimeInterval(3600), uptime: startUptime + 60
        )

        XCTAssertEqual(state.statusTitle, laterClock.statusTitle)
        XCTAssertEqual(state.selectedDuration, laterClock.selectedDuration)
        XCTAssertNotEqual(state.tooltip, laterClock.tooltip)
    }

    func testErrorState() {
        let state = MenuBarState(session: nil, errorMessage: "Unable to start", now: startDate, uptime: startUptime)

        XCTAssertEqual(state.statusTitle, "Unable to start")
        XCTAssertEqual(state.tooltip, "Espresso: Off")
        XCTAssertTrue(state.stopItemHidden)
    }

    func testMenuLabelsStayShort() {
        for duration in AwakeDuration.allCases {
            XCTAssertLessThanOrEqual(duration.menuTitle.count, 30)
        }
    }
}
