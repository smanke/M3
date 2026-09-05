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

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    /// "v1.13.7", or "v1.13.7 (12)" when the build number has moved past the
    /// marketing version.
    static var displayVersion: String {
        version == build ? "v\(version)" : "v\(version) (\(build))"
    }
}
