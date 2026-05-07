import Foundation
import ServiceManagement

final class LaunchAtLoginManager {
    func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        let status = service.status
        do {
            if enabled {
                guard status != .enabled, status != .requiresApproval else { return }
                try service.register()
            } else {
                guard status != .notRegistered else { return }
                try service.unregister()
            }
        } catch {
            AppLog.settings.error("Launch at login update failed: \(String(describing: error), privacy: .public)")
        }
    }
}
