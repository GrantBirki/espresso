import Foundation

private typealias Keys = SettingsStoreKeys

final class SettingsStore: ObservableObject {
    @Published var autoLaunchEnabled: Bool {
        didSet { defaults.set(autoLaunchEnabled, forKey: Keys.autoLaunchEnabled) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        autoLaunchEnabled = defaults.object(forKey: Keys.autoLaunchEnabled) as? Bool ?? false
    }
}
