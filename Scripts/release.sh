#!/bin/bash
set -euo pipefail

# MacPulse Release Script
# Usage: ./Scripts/release.sh [version]
# Requires: Apple Developer ID certificate, notarytool credentials stored in keychain

VERSION="${1:-1.0.0}"
APP_NAME="MacPulse"
BUILD_DIR=".build"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"
DMG_FILE="${BUILD_DIR}/${APP_NAME}-${VERSION}.dmg"
TEAM_ID="${TEAM_ID:-}"
IDENTITY="${IDENTITY:-Developer ID Application}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-macpulse-notary}"

echo "=== MacPulse Release v${VERSION} ==="

# Step 1: Clean build
echo "[1/6] Building release binary..."
make clean
make build

# Step 2: Bundle app
echo "[2/6] Creating app bundle..."
make bundle

# Update version in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${BUNDLE_DIR}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${BUNDLE_DIR}/Contents/Info.plist"

# Step 3: Code sign with Developer ID
echo "[3/6] Code signing..."
if [ -n "${TEAM_ID}" ]; then
    codesign --force --options runtime --sign "${IDENTITY}" --timestamp "${BUNDLE_DIR}"
    echo "  Signed with: ${IDENTITY}"
else
    echo "  TEAM_ID not set — using ad-hoc signature (skip notarization)"
    codesign --force --sign - "${BUNDLE_DIR}"
fi

# Step 4: Create DMG
echo "[4/6] Creating DMG..."
DMG_DIR="${BUILD_DIR}/dmg"
mkdir -p "${DMG_DIR}"
cp -R "${BUNDLE_DIR}" "${DMG_DIR}/"
ln -sf /Applications "${DMG_DIR}/Applications"
hdiutil create -volname "${APP_NAME} ${VERSION}" -srcfolder "${DMG_DIR}" -ov -format UDZO "${DMG_FILE}"
rm -rf "${DMG_DIR}"

# Step 5: Notarize (if signed with Developer ID)
if [ -n "${TEAM_ID}" ]; then
    echo "[5/6] Submitting for notarization..."
    xcrun notarytool submit "${DMG_FILE}" --keychain-profile "${KEYCHAIN_PROFILE}" --wait

    echo "[6/6] Stapling notarization ticket..."
    xcrun stapler staple "${DMG_FILE}"
else
    echo "[5/6] Skipping notarization (no TEAM_ID)"
    echo "[6/6] Skipping stapling"
fi

# Summary
echo ""
echo "=== Release complete ==="
echo "  DMG: ${DMG_FILE}"
echo "  Size: $(du -h "${DMG_FILE}" | cut -f1)"

if [ -n "${TEAM_ID}" ]; then
    echo "  Status: Signed + Notarized"
    echo ""
    echo "To verify: spctl --assess --type open --context context:primary-signature -v ${DMG_FILE}"
else
    echo "  Status: Ad-hoc signed (not notarized)"
    echo ""
    echo "To notarize, set environment variables and re-run:"
    echo "  TEAM_ID=XXXXXXXXXX IDENTITY='Developer ID Application: Your Name (XXXXXXXXXX)' ./Scripts/release.sh ${VERSION}"
    echo ""
    echo "First-time setup for notarytool:"
    echo "  xcrun notarytool store-credentials macpulse-notary --apple-id you@example.com --team-id XXXXXXXXXX"
fi
