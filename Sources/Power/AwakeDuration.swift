import Foundation

enum AwakeDuration: String, CaseIterable, Identifiable {
    #if DEBUG
        case oneMinute
    #endif
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case threeHours
    case fourHours
    case fiveHours
    case eightHours
    case twelveHours
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
            .twoHours,
            .threeHours,
            .fourHours,
            .fiveHours,
            .eightHours,
            .twelveHours,
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
        case .twoHours:
            2 * 60 * 60
        case .threeHours:
            3 * 60 * 60
        case .fourHours:
            4 * 60 * 60
        case .fiveHours:
            5 * 60 * 60
        case .eightHours:
            8 * 60 * 60
        case .twelveHours:
            12 * 60 * 60
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
        case .twoHours:
            "2 Hours"
        case .threeHours:
            "3 Hours"
        case .fourHours:
            "4 Hours"
        case .fiveHours:
            "5 Hours"
        case .eightHours:
            "8 Hours"
        case .twelveHours:
            "12 Hours"
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
        case .twoHours:
            "Keep your Mac awake for 2 hours"
        case .threeHours:
            "Keep your Mac awake for 3 hours"
        case .fourHours:
            "Keep your Mac awake for 4 hours"
        case .fiveHours:
            "Keep your Mac awake for 5 hours"
        case .eightHours:
            "Keep your Mac awake for 8 hours"
        case .twelveHours:
            "Keep your Mac awake for 12 hours"
        case .indefinitely:
            "Keep your Mac awake indefinitely"
        }
    }

    var isIndefinite: Bool {
        seconds == nil
    }
}
