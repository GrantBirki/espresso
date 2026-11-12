import Foundation
import ServiceManagement

private typealias Keys = SettingsStoreKeys

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var autoLaunchEnabled: Bool
    @Published private(set) var launchAtLoginMessage: String?

    private let defaults: UserDefaults
    private let launchAtLoginManager: LaunchAtLoginManager
    private var launchAtLoginUpdateFailed = false

    init(
        defaults: UserDefaults = .standard,
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager()
    ) {
        self.defaults = defaults
        self.launchAtLoginManager = launchAtLoginManager
        autoLaunchEnabled = defaults.object(forKey: Keys.autoLaunchEnabled) as? Bool ?? false
    }

    func setAutoLaunchEnabled(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            launchAtLoginUpdateFailed = false
        } catch {
            AppLog.settings.error("Launch at login update failed: \(String(describing: error), privacy: .public)")
            launchAtLoginUpdateFailed = true
        }
        refreshLaunchAtLoginStatus()
    }

    func synchronizeLaunchAtLogin() {
        setAutoLaunchEnabled(autoLaunchEnabled)
    }

    func refreshLaunchAtLoginStatus() {
        switch launchAtLoginManager.status {
        case .enabled:
            autoLaunchEnabled = true
            launchAtLoginMessage = nil
        case .requiresApproval:
            autoLaunchEnabled = true
            launchAtLoginMessage = "Allow Espresso in System Settings to launch at login."
        case .notRegistered:
            autoLaunchEnabled = false
            launchAtLoginMessage = nil
        case .notFound:
            autoLaunchEnabled = false
            launchAtLoginMessage = "Launch at login is unavailable for this app."
        @unknown default:
            autoLaunchEnabled = false
            launchAtLoginMessage = "Launch at login is unavailable for this app."
        }
        if launchAtLoginUpdateFailed {
            launchAtLoginMessage = "Unable to update launch at login. Try again."
        }
        defaults.set(autoLaunchEnabled, forKey: Keys.autoLaunchEnabled)
    }
}
