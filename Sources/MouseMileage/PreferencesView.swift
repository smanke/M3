import AppKit
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            statsSection
            Divider()
            settingsSection
            Divider()
            resetSection
            footer
        }
        .padding(20)
        .frame(width: 360)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mileage: \(viewModel.mileageText)")
            Text("Keystrokes: \(viewModel.keystrokesText)")
            Text("Clicks — \(viewModel.clicksText)")
        }
        .font(.system(size: 13))
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Launch at Login", isOn: Binding(
                get: { viewModel.launchAtLoginEnabled },
                set: { viewModel.toggleLaunchAtLogin($0) }
            ))
            .toggleStyle(.checkbox)

            if let error = viewModel.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Reset Mileage") { confirmAndRun("Reset mouse mileage to zero?", viewModel.resetMileage) }
            Button("Reset Keystrokes") { confirmAndRun("Reset keystroke count to zero?", viewModel.resetKeystrokes) }
            Button("Reset Clicks") { confirmAndRun("Reset left and right click counts to zero?", viewModel.resetClicks) }
            Button("Reset All") { confirmAndRun("Reset all counters (mileage, keystrokes, and clicks) to zero?", viewModel.resetAll) }
        }
    }

    private var footer: some View {
        Text("\(AppInfo.displayName) — Version \(AppInfo.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func confirmAndRun(_ message: String, _ action: @escaping () -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn {
            action()
        }
    }
}
