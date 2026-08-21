import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private let eventMonitor = EventMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only app, no Dock icon.
        NSApp.setActivationPolicy(.accessory)

        statusItemController = StatusItemController()

        eventMonitor.requestPermissionIfNeeded()
        eventMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        MetricsStore.shared.saveIfNeeded()
        MileageHistoryStore.shared.saveIfNeeded()
        eventMonitor.stop()
    }
}
