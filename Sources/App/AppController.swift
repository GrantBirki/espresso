import AppKit
import Combine
import Foundation

@MainActor
final class AppController {
    private let settings: SettingsStore
    private let espressoController: EspressoController
    private let menuBarController: MenuBarController
    private let settingsWindowController: SettingsWindowController
    private let aboutWindowController = AboutWindowController()
    private let launchAtLoginManager = LaunchAtLoginManager()
    private var cancellables = Set<AnyCancellable>()

    init(espressoController: EspressoController = EspressoController()) {
        settings = SettingsStore()
        self.espressoController = espressoController
        settingsWindowController = SettingsWindowController(
            settings: settings,
            state: SettingsWindowState(menuState: espressoController.menuBarState())
        )
        menuBarController = MenuBarController(
            onStart: { duration in espressoController.start(duration: duration) },
            onStop: { espressoController.stop() },
            onSettings: {},
            onAbout: {},
            onQuit: {}
        )

        menuBarController.configureActions(
            onStart: { [weak espressoController] duration in espressoController?.start(duration: duration) },
            onStop: { [weak espressoController] in espressoController?.stop() },
            onSettings: { [weak self] in self?.showSettings() },
            onAbout: { [weak self] in self?.aboutWindowController.show() },
            onQuit: { NSApp.terminate(nil) }
        )

        espressoController.onStateChange = { [weak self] in
            self?.updateVisibleState()
        }
    }

    func start() {
        AppLog.app.info("Espresso AppController start")
        menuBarController.start()
        observeSettings()
        launchAtLoginManager.setEnabled(settings.autoLaunchEnabled)
        updateVisibleState()
    }

    func stop() {
        espressoController.stop()
    }

    func showSettings() {
        updateVisibleState()
        settingsWindowController.show()
    }

    private func observeSettings() {
        settings.$autoLaunchEnabled
            .sink { [weak self] enabled in
                self?.launchAtLoginManager.setEnabled(enabled)
            }
            .store(in: &cancellables)
    }

    private func updateVisibleState() {
        let state = espressoController.menuBarState()
        menuBarController.update(state: state)
        settingsWindowController.update(state: state)
    }
}
