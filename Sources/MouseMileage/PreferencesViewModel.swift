import ApplicationServices
import Combine
import Foundation

final class PreferencesViewModel: ObservableObject {
    @Published var mileageText: String = ""
    @Published var keystrokesText: String = ""
    @Published var clicksText: String = ""
    @Published var trackingSinceText: String = ""

    private static let startedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    @Published var launchAtLoginEnabled: Bool
    @Published var launchAtLoginError: String?
    @Published var checkForUpdatesAtLaunch: Bool {
        didSet { UpdateSettings.checkForUpdatesAtLaunch = checkForUpdatesAtLaunch }
    }
    /// Keystrokes are only delivered to a global monitor when the app is
    /// trusted for Accessibility; without it they silently never arrive.
    @Published var isAccessibilityTrusted: Bool = AXIsProcessTrusted()

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
        mileageText = "\(MetricsFormatter.hundredths(store.totalMiles)) mi (\(MetricsFormatter.tenths(store.totalFeet)) ft)"
        keystrokesText = MetricsFormatter.count(store.keystrokes)
        clicksText = "Left: \(MetricsFormatter.count(store.leftClicks))   Right: \(MetricsFormatter.count(store.rightClicks))"

        let started = store.trackingStartedAt
        let days = Calendar.current.dateComponents([.day], from: started, to: Date()).day ?? 0
        let span = days == 0 ? "today" : (days == 1 ? "1 day" : "\(MetricsFormatter.count(days)) days")
        trackingSinceText = "\(Self.startedFormatter.string(from: started)) (\(span))"
    }

    /// Picks up changes made elsewhere (the menu bar toggle, or System
    /// Settings for the login item) when the window is reopened.
    func refreshSettings() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
        isAccessibilityTrusted = AXIsProcessTrusted()
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

    func openAccessibilitySettings() {
        EventMonitor.openAccessibilitySettings()
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
