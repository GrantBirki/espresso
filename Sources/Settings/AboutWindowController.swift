import AppKit
import SwiftUI

@MainActor
final class AboutWindowController: NSWindowController {
    private var hasCenteredInitialWindow = false

    init() {
        let window = NSWindow()
        super.init(window: window)
        configureWindow(window)
        window.contentViewController = NSHostingController(rootView: AboutView())
    }

    required init?(coder _: NSCoder) {
        nil
    }

    func show() {
        guard let window else { return }
        if !window.isVisible, !hasCenteredInitialWindow {
            window.center()
            hasCenteredInitialWindow = true
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "About Espresso"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 420, height: 300))
    }
}
