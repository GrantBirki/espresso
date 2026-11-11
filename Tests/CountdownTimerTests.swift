@testable import Espresso
import XCTest

@MainActor
final class CountdownTimerTests: XCTestCase {
    func testFiniteCountdownRunsWhileEitherSurfaceIsVisible() throws {
        let countdown = CountdownTimer()
        let session = AwakeSession(duration: .oneHour, startUptime: 0)
        var refreshes = 0

        func update(menu: Bool, settings: Bool) {
            countdown.update(session: session, menuOpen: menu, settingsVisible: settings) { refreshes += 1 }
        }

        update(menu: false, settings: false)
        XCTAssertNil(countdown.timer)
        XCTAssertEqual(refreshes, 0)

        update(menu: true, settings: false)
        let timer = try XCTUnwrap(countdown.timer)
        XCTAssertEqual(refreshes, 1)
        timer.fire()
        XCTAssertEqual(refreshes, 2)

        update(menu: true, settings: true)
        update(menu: false, settings: true)
        XCTAssertTrue(countdown.timer === timer)
        XCTAssertTrue(timer.isValid)

        update(menu: false, settings: false)
        XCTAssertNil(countdown.timer)
        XCTAssertFalse(timer.isValid)
    }

    func testReplacingOrStoppingSessionRemovesVisibleCountdown() throws {
        let countdown = CountdownTimer()
        for nextSession in [AwakeSession(duration: .indefinitely, startUptime: 0), nil] {
            let session = AwakeSession(duration: .oneHour, startUptime: 0)
            countdown.update(session: session, menuOpen: false, settingsVisible: true) {}
            let timer = try XCTUnwrap(countdown.timer)
            countdown.update(session: nextSession, menuOpen: true, settingsVisible: true) {
                XCTFail("Only finite sessions display a countdown")
            }
            XCTAssertNil(countdown.timer)
            XCTAssertFalse(timer.isValid)
        }
    }
}
