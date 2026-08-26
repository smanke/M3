# M3 Tracker: Mac Mouse Mileage Tracker

A macOS menu bar app that tracks cumulative mouse/trackpad movement distance,
keystrokes, and left/right click counts. Counters persist across restarts and
reboots (stored via `UserDefaults`, which is backed by disk).

## Install

[**Download M3 Tracker 1.13**](dist/M3%20Tracker%201.13.zip) — signed with a
Developer ID certificate and notarized by Apple, so it opens cleanly with no
Gatekeeper warning. Unzip, drag `M3 Tracker.app` to `/Applications`, and
launch it. On first launch, grant Accessibility (Input Monitoring) access
when macOS prompts — see [Required permission](#required-permission) below.

## How it works

- `EventMonitor` uses `NSEvent.addGlobalMonitorForEvents` to observe pointer
  movement, clicks, and key-down events system-wide. Trackpad-driven cursor
  movement generates the same `mouseMoved`/`*Dragged` events as a physical
  mouse, so both are counted identically — there's no way (or need) to tell
  them apart.
- Distance is accumulated in Cocoa points and converted to real-world units
  using the standard 72-points-per-inch definition (there's no API to query a
  pointing device's physical DPI, so this is the same convention AppKit itself
  uses for point-based coordinates).
- `MetricsStore` persists counters to `UserDefaults` every 5 seconds and on
  quit. `MileageHistoryStore` separately buckets mileage by hour/day for the
  charts.
- The menu bar shows feet (to the tenths place) while under a mile, then
  switches to miles (to the hundredths place).
- Clicking the menu bar item shows mileage charts (Today by Hour, By Day,
  Year to Date) using Swift Charts, plus Preferences and Quit.
- The Preferences window shows current stats and has buttons to reset
  mileage, keystrokes, clicks, or everything — each asks for confirmation
  before clearing. It also has a "Launch at Login" checkbox, backed by
  `SMAppService` (`LaunchAtLoginController.swift`).

## Required permission

Global keystroke/mouse monitoring requires **Accessibility** (Input
Monitoring) permission. On first launch macOS will prompt you to grant it in
**System Settings → Privacy & Security → Accessibility** (and/or **Input
Monitoring**). Until granted, movement/click/keystroke events from other apps
won't be seen.

## Running during development

```bash
swift run
```

## Building the .app

```bash
./build_app.sh
```

This builds a **universal binary** (`--arch arm64 --arch x86_64` — works
natively on both Intel and Apple Silicon Macs), assembles it into
`.build/app/M3 Tracker.app` with the app icon and Info.plist, and ad-hoc
code-signs it with a stable identifier (`com.smanke.MouseMileage`) so
Accessibility/Launch-at-Login permissions survive rebuilds. Deployment target
is macOS 13 (Ventura), which both Intel and Apple Silicon Macs can run.

Install and launch it with:

```bash
cp -R ".build/app/M3 Tracker.app" /Applications/
open "/Applications/M3 Tracker.app"
```

To survive reboots automatically, use the in-app "Launch at Login" checkbox
in Preferences (backed by `SMAppService.mainApp`, macOS 13+) once the app is
installed in `/Applications`, or add it manually as a Login Item in
**System Settings → General → Login Items**. `SMAppService` registration only
works from a properly installed `.app` bundle — running via `swift run` will
show a "couldn't update" alert if you try it.

Because counters are stored in `UserDefaults` under the app's bundle
identifier, keep the bundle identifier stable once you start using it —
changing it will reset the persisted history. Note that transferring the
`.app` bundle itself (e.g. via AirDrop or a zip) does **not** carry over
`~/Library/Preferences` — a fresh machine/user account starts with empty
counters, which is expected.
