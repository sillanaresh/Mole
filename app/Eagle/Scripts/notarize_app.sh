#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PACKAGE_DIR/.build"
APP_BUNDLE="$BUILD_DIR/Eagle.app"
ZIP_PATH="$BUILD_DIR/Eagle.zip"

require_env() {
    local name="$1"
    if [[ -z "${!name:-}" ]]; then
        echo "Missing required environment variable: $name" >&2
        exit 1
    fi
}

require_env EAGLE_CODESIGN_IDENTITY
require_env APPLE_ID
require_env APPLE_TEAM_ID
require_env APPLE_APP_SPECIFIC_PASSWORD

"$SCRIPT_DIR/package_app.sh" --zip

echo "Submitting to Apple notarization..."
xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP_BUNDLE"

if [[ -f "$ZIP_PATH" ]]; then
    rm "$ZIP_PATH"
fi
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "Notarized archive ready: $ZIP_PATH"
