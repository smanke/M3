#!/bin/bash
# Builds, Developer-ID-signs, notarizes, and staples "M3 Tracker.app" for
# distribution outside the Mac App Store, then zips it for upload/download.
#
# One-time setup before running this:
#   1. In Xcode: Settings -> Accounts -> your team -> Manage Certificates ->
#      "+" -> Developer ID Application. This installs a signing identity.
#   2. Store notarization credentials once:
#        xcrun notarytool store-credentials "M3TrackerNotary" \
#          --apple-id "you@example.com" \
#          --team-id "YOURTEAMID" \
#          --password "an-app-specific-password"
#      (generate the app-specific password at appleid.apple.com; team ID is
#      shown next to your Developer ID Application identity, or in
#      developer.apple.com/account -> Membership details)
#
# Then run:
#   ./release.sh "Developer ID Application: Your Name (TEAMID)"
set -euo pipefail

cd "$(dirname "$0")"

SIGNING_IDENTITY="${1:?Usage: ./release.sh \"Developer ID Application: Your Name (TEAMID)\"}"
NOTARY_PROFILE="${NOTARY_PROFILE:-M3TrackerNotary}"

APP_NAME="M3 Tracker"
BUNDLE_ID="com.smanke.MouseMileage"
APP_DIR=".build/app/${APP_NAME}.app"
ZIP_PATH=".build/app/${APP_NAME}.zip"

echo "Building universal release binary (arm64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64

UNIVERSAL_BIN=".build/apple/Products/Release/MouseMileage"
if [ ! -f "${UNIVERSAL_BIN}" ]; then
  UNIVERSAL_BIN=$(find .build -path "*release/MouseMileage" -not -path "*.dSYM*" | head -n 1)
fi

echo "Verifying architectures..."
lipo -info "${UNIVERSAL_BIN}"

echo "Assembling app bundle at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp "${UNIVERSAL_BIN}" "${APP_DIR}/Contents/MacOS/MouseMileage"
cp "Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

echo "Signing with Developer ID (identifier: ${BUNDLE_ID})..."
codesign --force --deep --options runtime --timestamp \
  --identifier "${BUNDLE_ID}" \
  --sign "${SIGNING_IDENTITY}" \
  "${APP_DIR}"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${APP_DIR}"

echo "Zipping for notarization..."
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_DIR}" "${ZIP_PATH}"

echo "Submitting to Apple notary service (profile: ${NOTARY_PROFILE})..."
xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "${APP_DIR}"

echo "Final Gatekeeper check..."
spctl -a -vvv --type execute "${APP_DIR}"

echo "Re-zipping stapled app for distribution..."
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_DIR}" "${ZIP_PATH}"

echo ""
echo "Done. Distributable app: ${APP_DIR}"
echo "Distributable zip:       ${ZIP_PATH}"
