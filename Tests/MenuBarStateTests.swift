@testable import Espresso
import Foundation
import XCTest

final class MenuBarStateTests: XCTestCase {
    private let startDate = Date(timeIntervalSince1970: 1_800_000_000)

    func testInactiveState() {
        let state = MenuBarState(session: nil, errorMessage: nil, now: startDate)

        XCTAssertFalse(state.isActive)
        XCTAssertEqual(state.statusTitle, "Espresso is off")
        XCTAssertEqual(state.tooltip, "Espresso: Off")
        XCTAssertTrue(state.stopItemHidden)
        XCTAssertEqual(state.statusSymbolName, "cup.and.saucer")
    }

    func testActiveFiniteState() {
        let session = AwakeSession(duration: .oneHour, startDate: startDate)
        let state = MenuBarState(session: session, errorMessage: nil, now: startDate.addingTimeInterval(60))

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.selectedDuration, .oneHour)
        XCTAssertEqual(state.statusTitle, "On: 59m remaining")
        XCTAssertTrue(state.tooltip.hasPrefix("Espresso: On until "))
        XCTAssertFalse(state.stopItemHidden)
        XCTAssertEqual(state.statusSymbolName, "cup.and.saucer.fill")
    }

    func testActiveIndefiniteState() {
        let session = AwakeSession(duration: .indefinitely, startDate: startDate)
        let state = MenuBarState(session: session, errorMessage: nil, now: startDate.addingTimeInterval(60))

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.statusTitle, "On indefinitely")
        XCTAssertEqual(state.tooltip, "Espresso: On indefinitely")
        XCTAssertFalse(state.stopItemHidden)
    }

    func testErrorState() {
        let state = MenuBarState(session: nil, errorMessage: "Unable to start", now: startDate)

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
