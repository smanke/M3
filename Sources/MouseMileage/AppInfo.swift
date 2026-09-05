import Foundation

enum AppInfo {
    static let displayName = "M3 Tracker: Mac Mouse Mileage Tracker"
    static let shortName = "M3 Tracker"
    static let bundleIdentifier = "com.smanke.MouseMileage"

    /// Read from the bundle rather than hardcoded, so this always matches
    /// what was actually built instead of a copy that can drift from
    /// Resources/Info.plist.
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
