import AppKit
import ApplicationServices

/// Watches system-wide mouse movement, clicks, and keystrokes via AppKit's global
/// event monitor. Requires Accessibility (Input Monitoring) permission to see events
/// that originate outside this app.
final class EventMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func requestPermissionIfNeeded() {
        let options: [String: Bool] = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func start() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .leftMouseDown, .rightMouseDown, .keyDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }

        // Local monitor covers events targeted at our own app's windows (e.g. the
        // preferences panel), so mileage/clicks/keystrokes are counted consistently
        // even while this app is frontmost. Return the event unmodified.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        let store = MetricsStore.shared
        switch event.type {
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
            // deltaX/deltaY reflect raw pointer movement regardless of whether it
            // came from a mouse or a trackpad, so both are counted identically.
            let dx = Double(event.deltaX)
            let dy = Double(event.deltaY)
            let distance = (dx * dx + dy * dy).squareRoot()
            store.addMovement(points: distance)
        case .leftMouseDown:
            store.incrementLeftClicks()
        case .rightMouseDown:
            store.incrementRightClicks()
        case .keyDown:
            store.incrementKeystrokes()
        default:
            break
        }
    }
}
