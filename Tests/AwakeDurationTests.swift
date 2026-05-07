@testable import Espresso
import Foundation
import XCTest

final class AwakeDurationTests: XCTestCase {
    func testDurationsAreShownInMenuOrder() {
        let titles = AwakeDuration.allCases.map(\.menuTitle)

        #if DEBUG
            XCTAssertEqual(titles.first, "1 Minute")
            XCTAssertEqual(Array(titles.dropFirst()), [
                "15 Minutes",
                "30 Minutes",
                "1 Hour",
                "2 Hours",
                "3 Hours",
                "4 Hours",
                "5 Hours",
                "8 Hours",
                "12 Hours",
                "Indefinitely",
            ])
        #else
            XCTAssertEqual(titles, [
                "15 Minutes",
                "30 Minutes",
                "1 Hour",
                "2 Hours",
                "3 Hours",
                "4 Hours",
                "5 Hours",
                "8 Hours",
                "12 Hours",
                "Indefinitely",
            ])
        #endif
    }

    func testSecondsMatchDurationCases() {
        XCTAssertEqual(AwakeDuration.fifteenMinutes.seconds, 15 * 60)
        XCTAssertEqual(AwakeDuration.thirtyMinutes.seconds, 30 * 60)
        XCTAssertEqual(AwakeDuration.oneHour.seconds, 60 * 60)
        XCTAssertEqual(AwakeDuration.twoHours.seconds, 2 * 60 * 60)
        XCTAssertEqual(AwakeDuration.threeHours.seconds, 3 * 60 * 60)
        XCTAssertEqual(AwakeDuration.fourHours.seconds, 4 * 60 * 60)
        XCTAssertEqual(AwakeDuration.fiveHours.seconds, 5 * 60 * 60)
        XCTAssertEqual(AwakeDuration.eightHours.seconds, 8 * 60 * 60)
        XCTAssertEqual(AwakeDuration.twelveHours.seconds, 12 * 60 * 60)
        XCTAssertNil(AwakeDuration.indefinitely.seconds)
    }

    func testIndefiniteDurationHasNoSeconds() {
        XCTAssertTrue(AwakeDuration.indefinitely.isIndefinite)
        XCTAssertEqual(AwakeDuration.indefinitely.accessibilityLabel, "Keep your Mac awake indefinitely")
    }
}
