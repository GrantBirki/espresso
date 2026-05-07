import Foundation

struct AwakeSession: Equatable {
    let duration: AwakeDuration
    let startDate: Date

    var endDate: Date? {
        guard let seconds = duration.seconds else { return nil }
        return startDate.addingTimeInterval(seconds)
    }

    func isActive(at date: Date) -> Bool {
        !isExpired(at: date)
    }

    func isExpired(at date: Date) -> Bool {
        guard let endDate else { return false }
        return date >= endDate
    }

    func remainingTime(at date: Date) -> TimeInterval? {
        guard let endDate else { return nil }
        return max(0, endDate.timeIntervalSince(date))
    }

    func remainingLabel(at date: Date) -> String {
        guard let remaining = remainingTime(at: date) else {
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
