import AppKit
import SwiftUI

final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let preferencesController = PreferencesWindowController()
    private let historyViewModel = HistoryViewModel()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        statusItem.button?.title = MetricsStore.shared.menuBarText
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        buildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metricsDidUpdate),
            name: MetricsStore.didUpdateNotification,
            object: nil
        )
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let chartsItem = NSMenuItem()
        let hostingView = NSHostingView(rootView: MenuChartsView(viewModel: historyViewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: 340, height: hostingView.fittingSize.height)
        chartsItem.view = hostingView
        menu.addItem(chartsItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
            .target = self
        menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit \(AppInfo.shortName)", action: #selector(quit), keyEquivalent: "q")
            .target = self
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        historyViewModel.refresh()
    }

    @objc private func metricsDidUpdate() {
        statusItem.button?.title = MetricsStore.shared.menuBarText
    }

    @objc private func openPreferences() {
        preferencesController.show()
    }

    @objc private func checkForUpdates() {
        UpdateController.checkForUpdates()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
