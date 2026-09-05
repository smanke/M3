import Foundation

/// Persists and formats the tracked metrics. All access is expected from the main thread,
/// since events arrive via AppKit's global event monitor on the main run loop.
final class MetricsStore {
    static let shared = MetricsStore()

    static let didUpdateNotification = Notification.Name("MetricsStore.didUpdate")

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let totalPoints = "totalPoints"
        static let keystrokes = "keystrokes"
        static let leftClicks = "leftClicks"
        static let rightClicks = "rightClicks"
        static let trackingStartedAt = "trackingStartedAt"
    }

    // A Cocoa "point" is nominally 1/72 inch; this is the standard conversion
    // used since there is no way to query the physical DPI of a pointing device.
    private let pointsPerInch: Double = 72.0
    private let inchesPerFoot: Double = 12.0
    private let feetPerMile: Double = 5280.0

    private(set) var totalPoints: Double
    private(set) var keystrokes: Int
    private(set) var leftClicks: Int
    private(set) var rightClicks: Int
    /// When these totals started accumulating, so the numbers have a span to
    /// be read against. Reset along with "Reset All".
    private(set) var trackingStartedAt: Date

    private var dirty = false
    private var saveTimer: Timer?

    private init() {
        totalPoints = defaults.double(forKey: Keys.totalPoints)
        keystrokes = defaults.integer(forKey: Keys.keystrokes)
        leftClicks = defaults.integer(forKey: Keys.leftClicks)
        rightClicks = defaults.integer(forKey: Keys.rightClicks)

        if let stored = defaults.object(forKey: Keys.trackingStartedAt) as? Date {
            trackingStartedAt = stored
        } else {
            // Installs that predate this being recorded still have daily history
            // to date from; only a genuinely fresh install starts from today.
            trackingStartedAt = MileageHistoryStore.shared.earliestRecordedDay ?? Date()
            defaults.set(trackingStartedAt, forKey: Keys.trackingStartedAt)
        }

        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveIfNeeded()
        }
    }

    // MARK: - Mutation

    func addMovement(points: Double) {
        guard points > 0, points.isFinite else { return }
        totalPoints += points
        dirty = true
        MileageHistoryStore.shared.recordMovement(points: points)
        notifyChanged()
    }

    func incrementKeystrokes() {
        keystrokes += 1
        dirty = true
        notifyChanged()
    }

    func incrementLeftClicks() {
        leftClicks += 1
        dirty = true
        notifyChanged()
    }

    func incrementRightClicks() {
        rightClicks += 1
        dirty = true
        notifyChanged()
    }

    func resetMileage() {
        totalPoints = 0
        dirty = true
        saveIfNeeded()
        MileageHistoryStore.shared.resetHistory()
        notifyChanged()
    }

    func resetKeystrokes() {
        keystrokes = 0
        dirty = true
        saveIfNeeded()
        notifyChanged()
    }

    func resetClicks() {
        leftClicks = 0
        rightClicks = 0
        dirty = true
        saveIfNeeded()
        notifyChanged()
    }

    func resetAll() {
        totalPoints = 0
        keystrokes = 0
        leftClicks = 0
        rightClicks = 0
        // Everything is starting over, so the span the totals cover does too.
        trackingStartedAt = Date()
        dirty = true
        saveIfNeeded()
        MileageHistoryStore.shared.resetHistory()
        notifyChanged()
    }

    // MARK: - Derived values

    var totalInches: Double { totalPoints / pointsPerInch }
    var totalFeet: Double { totalInches / inchesPerFoot }
    var totalMiles: Double { totalFeet / feetPerMile }

    /// Menu bar text: feet (to tenths) when under a mile, otherwise miles (to hundredths).
    var menuBarText: String {
        if totalMiles < 1.0 {
            return "\(MetricsFormatter.tenths(totalFeet)) ft"
        } else {
            return "\(MetricsFormatter.hundredths(totalMiles)) mi"
        }
    }

    // MARK: - Persistence

    private func notifyChanged() {
        NotificationCenter.default.post(name: MetricsStore.didUpdateNotification, object: self)
    }

    func saveIfNeeded() {
        guard dirty else { return }
        defaults.set(totalPoints, forKey: Keys.totalPoints)
        defaults.set(keystrokes, forKey: Keys.keystrokes)
        defaults.set(trackingStartedAt, forKey: Keys.trackingStartedAt)
        defaults.set(leftClicks, forKey: Keys.leftClicks)
        defaults.set(rightClicks, forKey: Keys.rightClicks)
        dirty = false
    }
}
