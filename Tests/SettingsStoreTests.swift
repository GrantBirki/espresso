@testable import Espresso
import Foundation
import ServiceManagement
import XCTest

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testDefaultSettings() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: FakeLaunchAtLoginService(status: .notRegistered))
        )

        XCTAssertFalse(settings.autoLaunchEnabled)
    }

    func testPersistsLaunchAtLoginSetting() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeLaunchAtLoginService(status: .notRegistered)

        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )
        settings.setAutoLaunchEnabled(true)

        let reloaded = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )
        XCTAssertTrue(reloaded.autoLaunchEnabled)
    }

    func testFailedEnableKeepsConfirmedDisabledState() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        service.shouldFail = true
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )

        settings.setAutoLaunchEnabled(true)

        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertFalse(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertEqual(service.registerCalls, 1)
        XCTAssertNotNil(settings.launchAtLoginMessage)

        service.shouldFail = false
        settings.setAutoLaunchEnabled(true)

        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertTrue(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertEqual(service.registerCalls, 2)
        XCTAssertNil(settings.launchAtLoginMessage)
    }

    func testFailedDisableKeepsConfirmedEnabledState() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: SettingsStoreKeys.autoLaunchEnabled)
        let service = FakeLaunchAtLoginService(status: .enabled)
        service.shouldFail = true
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )

        settings.setAutoLaunchEnabled(false)

        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertTrue(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertEqual(service.unregisterCalls, 1)
        XCTAssertNotNil(settings.launchAtLoginMessage)

        service.shouldFail = false
        settings.setAutoLaunchEnabled(false)

        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertFalse(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertEqual(service.unregisterCalls, 2)
        XCTAssertNil(settings.launchAtLoginMessage)
    }

    func testPendingApprovalIsVisibleAndRepeatedEnableDoesNotRegisterAgain() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        service.statusAfterRegister = .requiresApproval
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )

        settings.setAutoLaunchEnabled(true)
        settings.setAutoLaunchEnabled(true)

        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertTrue(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertNotNil(settings.launchAtLoginMessage)
        XCTAssertEqual(service.registerCalls, 1)

        service.status = .enabled
        settings.refreshLaunchAtLoginStatus()

        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertNil(settings.launchAtLoginMessage)

        settings.setAutoLaunchEnabled(false)
        settings.setAutoLaunchEnabled(false)

        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertEqual(service.unregisterCalls, 1)
    }

    func testRefreshRecordsExternalRegistrationChangeWithoutMutation() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: SettingsStoreKeys.autoLaunchEnabled)
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )

        settings.refreshLaunchAtLoginStatus()

        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertFalse(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertEqual(service.registerCalls, 0)
        XCTAssertEqual(service.unregisterCalls, 0)
    }

    func testFailedStartupReconciliationStaysVisibleUntilRetrySucceeds() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: SettingsStoreKeys.autoLaunchEnabled)
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        service.shouldFail = true
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )

        settings.synchronizeLaunchAtLogin()

        XCTAssertFalse(settings.autoLaunchEnabled)
        XCTAssertFalse(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertEqual(service.registerCalls, 1)
        XCTAssertNotNil(settings.launchAtLoginMessage)

        let failureMessage = settings.launchAtLoginMessage
        settings.refreshLaunchAtLoginStatus()

        XCTAssertEqual(settings.launchAtLoginMessage, failureMessage)

        service.shouldFail = false
        settings.setAutoLaunchEnabled(true)

        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertNil(settings.launchAtLoginMessage)
        XCTAssertEqual(service.registerCalls, 2)
    }

    func testErrorAfterRegistrationChangeRecordsTheChangedStatus() throws {
        let suite = "EspressoSettingsStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeLaunchAtLoginService(status: .notRegistered)
        service.shouldFail = true
        service.statusAfterFailure = .enabled
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: LaunchAtLoginManager(service: service)
        )

        settings.setAutoLaunchEnabled(true)

        XCTAssertTrue(settings.autoLaunchEnabled)
        XCTAssertTrue(defaults.bool(forKey: SettingsStoreKeys.autoLaunchEnabled))
        XCTAssertNotNil(settings.launchAtLoginMessage)
    }
}

private final class FakeLaunchAtLoginService: LaunchAtLoginService {
    var status: SMAppService.Status
    var shouldFail = false
    var statusAfterRegister: SMAppService.Status = .enabled
    var statusAfterFailure: SMAppService.Status?
    private(set) var registerCalls = 0
    private(set) var unregisterCalls = 0

    init(status: SMAppService.Status) {
        self.status = status
    }

    func register() throws {
        registerCalls += 1
        if shouldFail {
            if let statusAfterFailure {
                status = statusAfterFailure
            }
            throw TestError.failed
        }
        status = statusAfterRegister
    }

    func unregister() throws {
        unregisterCalls += 1
        if shouldFail {
            if let statusAfterFailure {
                status = statusAfterFailure
            }
            throw TestError.failed
        }
        status = .notRegistered
    }

    private enum TestError: Error {
        case failed
    }
}
