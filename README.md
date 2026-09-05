# M3 Tracker: Mac Mouse Mileage Tracker

A macOS menu bar app that tracks cumulative mouse/trackpad movement distance,
keystrokes, and left/right click counts. Counters persist across restarts and
reboots (stored via `UserDefaults`, which is backed by disk).

## Install

[**Download the latest release**](https://github.com/smanke/M3/releases/latest)
— a `.dmg` signed with a Developer ID certificate and notarized by Apple, so
it opens cleanly with no Gatekeeper warning. Open the disk image, drag
`M3 Tracker.app` to `/Applications`, and launch it. On first launch, grant
Accessibility (Input Monitoring) access when macOS prompts — see
[Required permission](#required-permission) below.

The app checks for updates on demand from the menu bar dropdown
("Check for Updates…") — see [Auto-update](#auto-update) below.

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

## Auto-update

`UpdateController.swift` checks `https://api.github.com/repos/smanke/M3/releases/latest`,
compares the tag against the running `CFBundleShortVersionString`
(`AppInfo.version`, read straight from the bundle so it can't drift out of
sync with `Info.plist`), and if newer, downloads the release's `.dmg` asset.
Before installing anything it verifies the downloaded app: a valid signature,
the **same Developer ID Team ID** as the running app, and a passing Gatekeeper
assessment (i.e. Apple notarized it) — any failure aborts the update and
leaves the installed app untouched. On success it hands off to a small
detached shell script that waits for the app to quit, replaces the bundle,
clears the quarantine flag (already verified above), and relaunches.

There's no background/automatic check — only the "Check for Updates…" menu
item triggers it, matching Desktop Bins Widget's update strategy.

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

## Cutting a release

1. Bump `CFBundleShortVersionString`/`CFBundleVersion` in `Resources/Info.plist`
   (third component for ordinary changes, e.g. `1.13.1` → `1.13.2`).
2. `./release.sh "Developer ID Application: Your Name (TEAMID)"` — builds,
   signs, notarizes, and staples the `.app`.
3. `./make_dmg.sh` — wraps the stapled app into a signed, notarized
   `M3Tracker-<version>.dmg` at `.build/app/`.
4. Create a GitHub release tagged `v<version>` (matching the plist version)
   at https://github.com/smanke/M3/releases/new and upload the `.dmg` as its
   asset. `UpdateController` fetches whatever asset ends in `.dmg` from the
   **latest** release, so this is the step that actually makes an update
   available to installed copies of the app.
