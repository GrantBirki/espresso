import Foundation

enum AwakeDuration: String, CaseIterable, Identifiable {
    #if DEBUG
        case oneMinute
    #endif
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case fiveHours
    case eightHours
    case indefinitely

    var id: String {
        rawValue
    }

    static var allCases: [AwakeDuration] {
        var values: [AwakeDuration] = []
        #if DEBUG
            values.append(.oneMinute)
        #endif
        values.append(contentsOf: [
            .fifteenMinutes,
            .thirtyMinutes,
            .oneHour,
            .fiveHours,
            .eightHours,
            .indefinitely,
        ])
        return values
    }

    var seconds: TimeInterval? {
        switch self {
        #if DEBUG
            case .oneMinute:
                60
        #endif
        case .fifteenMinutes:
            15 * 60
        case .thirtyMinutes:
            30 * 60
        case .oneHour:
            60 * 60
        case .fiveHours:
            5 * 60 * 60
        case .eightHours:
            8 * 60 * 60
        case .indefinitely:
            nil
        }
    }

    var menuTitle: String {
        switch self {
        #if DEBUG
            case .oneMinute:
                "1 Minute"
        #endif
        case .fifteenMinutes:
            "15 Minutes"
        case .thirtyMinutes:
            "30 Minutes"
        case .oneHour:
            "1 Hour"
        case .fiveHours:
            "5 Hours"
        case .eightHours:
            "8 Hours"
        case .indefinitely:
            "Indefinitely"
        }
    }

    var accessibilityLabel: String {
        switch self {
        #if DEBUG
            case .oneMinute:
                "Keep your Mac awake for 1 minute"
        #endif
        case .fifteenMinutes:
            "Keep your Mac awake for 15 minutes"
        case .thirtyMinutes:
            "Keep your Mac awake for 30 minutes"
        case .oneHour:
            "Keep your Mac awake for 1 hour"
        case .fiveHours:
            "Keep your Mac awake for 5 hours"
        case .eightHours:
            "Keep your Mac awake for 8 hours"
        case .indefinitely:
            "Keep your Mac awake indefinitely"
        }
    }

    var isIndefinite: Bool {
        seconds == nil
    }
}
