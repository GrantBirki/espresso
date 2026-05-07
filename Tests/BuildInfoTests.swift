@testable import Espresso
import Foundation
import XCTest

final class BuildInfoTests: XCTestCase {
    func testInfoValueReturnsFallbackForMissingOrEmptyValues() {
        XCTAssertEqual(BuildInfo.value(for: "missing", in: [:], fallback: "fallback"), "fallback")
        XCTAssertEqual(BuildInfo.value(for: "empty", in: ["empty": ""], fallback: "fallback"), "fallback")
    }

    func testInfoValueReturnsStringValue() {
        XCTAssertEqual(BuildInfo.value(for: "GIT_SHA", in: ["GIT_SHA": "abcdef12"], fallback: "unknown"), "abcdef12")
    }
}
