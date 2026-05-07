import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private let settings: SettingsStore
    private let state: SettingsWindowState
    private var hasCenteredInitialWindow = false

    init(settings: SettingsStore, state: SettingsWindowState) {
        self.settings = settings
        self.state = state
        let window = NSWindow()
        super.init(window: window)
        configureWindow(window)
        installContent()
    }

    required init?(coder _: NSCoder) {
        nil
    }

    func show() {
        guard let window else { return }
        if !window.isVisible, !hasCenteredInitialWindow {
            if !window.setFrameUsingName("EspressoSettingsWindow") {
                window.center()
            }
            hasCenteredInitialWindow = true
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func update(state menuState: MenuBarState) {
        state.menuState = menuState
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "Espresso Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.minSize = NSSize(width: 520, height: 320)
        window.setContentSize(NSSize(width: 560, height: 360))
        window.setFrameAutosaveName("EspressoSettingsWindow")
    }

    private func installContent() {
        let view = SettingsView(settings: settings, state: state)
        window?.contentViewController = NSHostingController(rootView: view)
    }
}

@MainActor
final class SettingsWindowState: ObservableObject {
    @Published var menuState: MenuBarState

    init(menuState: MenuBarState) {
        self.menuState = menuState
    }
}
