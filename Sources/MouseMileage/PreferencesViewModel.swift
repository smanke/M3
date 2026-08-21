import Combine
import Foundation

final class PreferencesViewModel: ObservableObject {
    @Published var mileageText: String = ""
    @Published var keystrokesText: String = ""
    @Published var clicksText: String = ""
    @Published var launchAtLoginEnabled: Bool
    @Published var launchAtLoginError: String?

    private var metricsObserver: NSObjectProtocol?

    init() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
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
