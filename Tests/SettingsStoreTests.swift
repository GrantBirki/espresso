@testable import Espresso
import Foundation
import XCTest

final class SettingsStoreTests: XCTestCase {
    func testDefaultSettings() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let settings = SettingsStore(defaults: defaults)

        XCTAssertFalse(settings.autoLaunchEnabled)
    }

    func testPersistsLaunchAtLoginSetting() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        var settings: SettingsStore? = SettingsStore(defaults: defaults)
        settings?.autoLaunchEnabled = true
        settings = nil

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertTrue(reloaded.autoLaunchEnabled)
    }
}
