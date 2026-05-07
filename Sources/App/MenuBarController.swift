import AppKit
import Foundation

struct MenuBarState: Equatable {
    var session: AwakeSession?
    var errorMessage: String?
    var now: Date

    var isActive: Bool {
        session?.isActive(at: now) ?? false
    }

    var selectedDuration: AwakeDuration? {
        guard isActive else { return nil }
        return session?.duration
    }

    var statusTitle: String {
        if let errorMessage {
            return errorMessage
        }
        guard let session, session.isActive(at: now) else {
            return "Espresso is off"
        }
        if session.duration.isIndefinite {
            return "On indefinitely"
        }
        return "On: \(session.remainingLabel(at: now))"
    }

    var tooltip: String {
        guard let session, session.isActive(at: now) else {
            return "Espresso: Off"
        }
        if let endDate = session.endDate {
            return "Espresso: On until \(Self.timeFormatter.string(from: endDate))"
        }
        return "Espresso: On indefinitely"
    }

    var stopItemHidden: Bool {
        !isActive
    }

    var statusSymbolName: String {
        isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
    }

    static let inactive = MenuBarState(session: nil, errorMessage: nil, now: Date())

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let statusItemView = NSMenuItem(title: "Espresso is off", action: nil, keyEquivalent: "")
    private var durationItems: [AwakeDuration: NSMenuItem] = [:]
    private let stopItem = NSMenuItem(title: "Stop Espresso", action: #selector(stop), keyEquivalent: "")
    private let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
    private let aboutItem = NSMenuItem(title: "About Espresso", action: #selector(openAbout), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit Espresso", action: #selector(quit), keyEquivalent: "q")
    private var state = MenuBarState.inactive

    private var onStart: (AwakeDuration) -> Void
    private var onStop: () -> Void
    private var onSettings: () -> Void
    private var onAbout: () -> Void
    private var onQuit: () -> Void

    init(
        onStart: @escaping (AwakeDuration) -> Void,
        onStop: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onStart = onStart
        self.onStop = onStop
        self.onSettings = onSettings
        self.onAbout = onAbout
        self.onQuit = onQuit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        stopItem.target = self
        settingsItem.target = self
        aboutItem.target = self
        quitItem.target = self
    }

    func configureActions(
        onStart: @escaping (AwakeDuration) -> Void,
        onStop: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onStart = onStart
        self.onStop = onStop
        self.onSettings = onSettings
        self.onAbout = onAbout
        self.onQuit = onQuit
    }

    func start() {
        statusItemView.isEnabled = false
        menu.delegate = self
        menu.addItem(statusItemView)
        menu.addItem(.separator())

        for duration in AwakeDuration.allCases {
            let item = NSMenuItem(title: duration.menuTitle, action: #selector(startDuration(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = duration.rawValue
            item.setAccessibilityLabel(duration.accessibilityLabel)
            durationItems[duration] = item
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(stopItem)
        menu.addItem(settingsItem)
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem.menu = menu
        refresh()
        AppLog.app.info("Menu bar item started")
    }

    func update(state: MenuBarState) {
        self.state = state
        refresh()
    }

    func menuNeedsUpdate(_: NSMenu) {
        refresh()
    }

    private func refresh() {
        statusItemView.title = state.statusTitle
        stopItem.isHidden = state.stopItemHidden

        for (duration, item) in durationItems {
            item.state = state.selectedDuration == duration ? .on : .off
        }

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: state.statusSymbolName, accessibilityDescription: "Espresso") {
                button.image = image
                button.imagePosition = .imageOnly
                button.title = ""
            } else {
                button.image = nil
                button.title = "Espresso"
            }
            button.toolTip = state.tooltip
        }
    }

    @objc private func startDuration(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let duration = AwakeDuration(rawValue: rawValue)
        else {
            return
        }
        onStart(duration)
    }

    @objc private func stop() {
        onStop()
    }

    @objc private func openSettings() {
        onSettings()
    }

    @objc private func openAbout() {
        onAbout()
    }

    @objc private func quit() {
        onQuit()
    }
}
