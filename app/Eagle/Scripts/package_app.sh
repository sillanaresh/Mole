#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PACKAGE_DIR/../.." && pwd)"
APP_NAME="Eagle"
DISPLAY_NAME="Eagle"
BUILD_DIR="$PACKAGE_DIR/.build"
ICON_FILE="$PACKAGE_DIR/Resources/AppIcon.icns"
APP_BUNDLE="$BUILD_DIR/$DISPLAY_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MOLE_RESOURCES_DIR="$RESOURCES_DIR/Mole"

echo "Building Mole Go helpers..."
(cd "$REPO_ROOT" && make build)

echo "Building $DISPLAY_NAME..."
(cd "$PACKAGE_DIR" && swift build -c release --product "$APP_NAME")

if [[ -d "$APP_BUNDLE" ]]; then
    case "$APP_BUNDLE" in
        "$BUILD_DIR"/*.app)
            rm -R "$APP_BUNDLE"
            ;;
        *)
            echo "Refusing to remove unexpected path: $APP_BUNDLE" >&2
            exit 1
            ;;
    esac
fi

mkdir -p "$MACOS_DIR" "$MOLE_RESOURCES_DIR"
cp "$BUILD_DIR/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
if [[ -f "$ICON_FILE" ]]; then
    cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.nareshsilla.eagle</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

rsync -a --delete \
    "$REPO_ROOT/mole" \
    "$REPO_ROOT/mo" \
    "$REPO_ROOT/bin" \
    "$REPO_ROOT/lib" \
    "$REPO_ROOT/LICENSE" \
    "$MOLE_RESOURCES_DIR/"

CODE_SIGN_IDENTITY="${EAGLE_CODESIGN_IDENTITY:-}"
AD_HOC_SIGN="${EAGLE_AD_HOC_SIGN:-0}"

if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
    echo "Signing with $CODE_SIGN_IDENTITY..."
    codesign --force --deep --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$APP_BUNDLE"
elif [[ "$AD_HOC_SIGN" == "1" ]]; then
    echo "Applying ad-hoc signature..."
    codesign --force --deep --sign - "$APP_BUNDLE"
fi

echo "Created $APP_BUNDLE"

if [[ "${1:-}" == "--zip" ]]; then
    ZIP_PATH="$BUILD_DIR/$DISPLAY_NAME.zip"
    if [[ -f "$ZIP_PATH" ]]; then
        rm "$ZIP_PATH"
    fi
    ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
    echo "Created $ZIP_PATH"
fi
