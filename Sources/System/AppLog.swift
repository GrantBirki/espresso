import OSLog

enum AppLog {
    static let app = Logger(subsystem: BuildInfo.bundleIdentifier, category: "app")
    static let power = Logger(subsystem: BuildInfo.bundleIdentifier, category: "power")
    static let settings = Logger(subsystem: BuildInfo.bundleIdentifier, category: "settings")
}
