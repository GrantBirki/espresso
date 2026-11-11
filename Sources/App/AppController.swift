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
    private var isMenuOpen = false
    private var countdownTimer: Timer?
    private var clockObservation: AnyCancellable?

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
        menuBarController.onMenuVisibilityChange = { [weak self] isOpen in
            self?.isMenuOpen = isOpen
            self?.updateCountdownTimer()
        }
        settingsWindowController.onVisibilityChange = { [weak self] in
            self?.updateCountdownTimer()
        }
    }

    func start() {
        AppLog.app.info("Espresso AppController start")
        menuBarController.start()
        settings.synchronizeLaunchAtLogin()
        clockObservation = Publishers.Merge3(
            NotificationCenter.default.publisher(for: .NSSystemClockDidChange),
            NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange),
            NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.updateVisibleState() }
        updateVisibleState()
    }

    func stop() {
        clockObservation = nil
        espressoController.stop()
    }

    func showSettings() {
        settings.refreshLaunchAtLoginStatus()
        updateVisibleState()
        settingsWindowController.show()
    }

    private func updateVisibleState() {
        let state = espressoController.menuBarState()
        menuBarController.update(state: state)
        settingsWindowController.update(state: state)
        updateCountdownTimer()
    }

    private func updateCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        guard espressoController.session?.endUptime != nil, isMenuOpen || settingsWindowController.showsCountdown else {
            return
        }
        updateCountdown()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateCountdown() }
        }
        timer.tolerance = 0.1
        countdownTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func updateCountdown() {
        let state = espressoController.menuBarState()
        if isMenuOpen {
            menuBarController.updateCountdown(state.statusTitle)
        }
        if settingsWindowController.showsCountdown {
            settingsWindowController.update(state: state)
        }
    }
}
