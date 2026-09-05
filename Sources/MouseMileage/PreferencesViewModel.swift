import Combine
import Foundation

final class PreferencesViewModel: ObservableObject {
    @Published var mileageText: String = ""
    @Published var keystrokesText: String = ""
    @Published var clicksText: String = ""
    @Published var launchAtLoginEnabled: Bool
    @Published var launchAtLoginError: String?
    @Published var checkForUpdatesAtLaunch: Bool {
        didSet { UpdateSettings.checkForUpdatesAtLaunch = checkForUpdatesAtLaunch }
    }

    private var metricsObserver: NSObjectProtocol?

    init() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
        checkForUpdatesAtLaunch = UpdateSettings.checkForUpdatesAtLaunch
        refreshText()

        metricsObserver = NotificationCenter.default.addObserver(
            forName: MetricsStore.didUpdateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshText()
        }
    }

    deinit {
        if let metricsObserver {
            NotificationCenter.default.removeObserver(metricsObserver)
        }
    }

    func refreshText() {
        let store = MetricsStore.shared
        mileageText = String(format: "%.2f mi (%.1f ft)", store.totalMiles, store.totalFeet)
        keystrokesText = "\(store.keystrokes)"
        clicksText = "Left: \(store.leftClicks)   Right: \(store.rightClicks)"
    }

    /// Picks up changes made elsewhere (the menu bar toggle, or System
    /// Settings for the login item) when the window is reopened.
    func refreshSettings() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
        if checkForUpdatesAtLaunch != UpdateSettings.checkForUpdatesAtLaunch {
            checkForUpdatesAtLaunch = UpdateSettings.checkForUpdatesAtLaunch
        }
    }

    func toggleLaunchAtLogin(_ enabled: Bool) {
        let succeeded = LaunchAtLoginController.setEnabled(enabled)
        if succeeded {
            launchAtLoginEnabled = enabled
            launchAtLoginError = nil
        } else {
            launchAtLoginEnabled = LaunchAtLoginController.isEnabled
            launchAtLoginError = "Couldn't update Launch at Login. This requires M3 to be running from an installed app in /Applications."
        }
    }

    func resetMileage() {
        MetricsStore.shared.resetMileage()
    }

    func resetKeystrokes() {
        MetricsStore.shared.resetKeystrokes()
    }

    func resetClicks() {
        MetricsStore.shared.resetClicks()
    }

    func resetAll() {
        MetricsStore.shared.resetAll()
    }
}
