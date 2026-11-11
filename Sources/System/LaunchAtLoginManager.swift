import Foundation
import ServiceManagement

@MainActor
protocol LaunchAtLoginService {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LaunchAtLoginService {}

@MainActor
final class LaunchAtLoginManager {
    private let service: LaunchAtLoginService

    init(service: LaunchAtLoginService = SMAppService.mainApp) {
        self.service = service
    }

    var status: SMAppService.Status {
        service.status
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard status != .enabled, status != .requiresApproval else { return }
            try service.register()
        } else {
            guard status != .notRegistered else { return }
            try service.unregister()
        }
    }
}
