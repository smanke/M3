#!/bin/bash
# Builds a proper "M3 Tracker.app" bundle from the Swift package.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="M3 Tracker"
BUNDLE_ID="com.smanke.MouseMileage"
APP_DIR=".build/app/${APP_NAME}.app"

echo "Building universal release binary (arm64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64

UNIVERSAL_BIN=".build/apple/Products/Release/MouseMileage"
if [ ! -f "${UNIVERSAL_BIN}" ]; then
  # Fallback path used by some toolchain versions.
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

echo "Ad-hoc code signing (stable identifier: ${BUNDLE_ID})..."
codesign --force --deep --options runtime --identifier "${BUNDLE_ID}" --sign - "${APP_DIR}"

echo "Done: ${APP_DIR}"
echo "Move it to /Applications, then launch it, e.g.:"
echo "  cp -R \"${APP_DIR}\" /Applications/"
echo "  open \"/Applications/${APP_NAME}.app\""
