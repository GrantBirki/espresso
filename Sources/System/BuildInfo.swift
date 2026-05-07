import Foundation

enum BuildInfo {
    static var displayName: String {
        infoString("CFBundleDisplayName", fallback: "Espresso")
    }

    static var version: String {
        infoString("CFBundleShortVersionString", fallback: "0.0.0")
    }

    static var build: String {
        infoString("CFBundleVersion", fallback: version)
    }

    static var gitSHA: String {
        infoString("GIT_SHA", fallback: "unknown")
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "io.birki.espresso"
    }

    static func value(for key: String, in info: [String: Any], fallback: String) -> String {
        guard let value = info[key] as? String, !value.isEmpty else {
            return fallback
        }
        return value
    }

    private static func infoString(_ key: String, fallback: String) -> String {
        value(for: key, in: Bundle.main.infoDictionary ?? [:], fallback: fallback)
    }
}
