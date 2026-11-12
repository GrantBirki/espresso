import Foundation

enum ThermalPressure: String {
    case serious, critical, unknown

    init?(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal, .fair: return nil
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .unknown
        }
    }

    static func peak(_ previous: Self?, _ current: Self?) -> Self? {
        if previous == .critical || current == .critical {
            return .critical
        }
        if previous == .serious || current == .serious {
            return .serious
        }
        return current ?? previous
    }
}

enum ThermalStopEvent: Equatable {
    case stopped(ThermalPressure)
    case releasePending(ThermalPressure)

    func log() {
        switch self {
        case let .stopped(pressure):
            AppLog.thermal.notice(
                "Thermal stop (\(pressure.rawValue, privacy: .public)): keep-awake assertion no longer held."
            )
        case let .releasePending(pressure):
            AppLog.thermal.error(
                "Thermal stop (\(pressure.rawValue, privacy: .public)): release unconfirmed. Espresso will retry."
            )
        }
    }
}
