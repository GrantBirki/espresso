import Foundation

struct AwakeSession: Equatable {
    let duration: AwakeDuration
    let startUptime: TimeInterval

    var endUptime: TimeInterval? {
        guard let seconds = duration.seconds else { return nil }
        return startUptime + seconds
    }

    func isActive(at uptime: TimeInterval) -> Bool {
        !isExpired(at: uptime)
    }

    func isExpired(at uptime: TimeInterval) -> Bool {
        guard let endUptime else { return false }
        return uptime >= endUptime
    }

    func remainingTime(at uptime: TimeInterval) -> TimeInterval? {
        guard let endUptime else { return nil }
        return max(0, endUptime - uptime)
    }

    func remainingLabel(at uptime: TimeInterval) -> String {
        guard let remaining = remainingTime(at: uptime) else {
            return "Indefinitely"
        }

        if remaining <= 0 {
            return "Expired"
        }

        let totalSeconds = Int(ceil(remaining))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m remaining"
        }
        if hours > 0 {
            return "\(hours)h remaining"
        }
        if totalSeconds >= 60 {
            let roundedMinutes = Int(ceil(Double(totalSeconds) / 60.0))
            return "\(max(1, roundedMinutes))m remaining"
        }
        return "\(totalSeconds)s remaining"
    }
}
