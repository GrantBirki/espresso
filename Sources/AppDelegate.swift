import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appController: AppController?

    func applicationDidFinishLaunching(_: Notification) {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return
        }

        AppLog.app.info("Espresso did finish launching")
        appController = AppController()
        appController?.start()
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        appController?.showSettings()
        return false
    }

    func applicationWillTerminate(_: Notification) {
        appController?.stop()
    }
}
