#!/bin/bash
set -euo pipefail

# ── schema-viewer build script ────────────────────────────────────────────
# Builds the Swift project and packages it as a macOS .app bundle.
#
# Prerequisites:
#   - macOS 14+
#   - Xcode Command Line Tools (xcode-select --install)
#
# Usage:
#   ./build.sh              Build and create SchemaViewer.app
#   ./build.sh --install    Build + copy to /Applications
#   ./build.sh --run        Build + launch immediately
# ────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="SchemaViewer"
APP_BUNDLE="$APP_NAME.app"
BUNDLE_ID="ai.fastbreak.schema-viewer"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"

INSTALL=false
RUN=false
for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=true ;;
        --run) RUN=true ;;
    esac
done

echo ""
echo "  ╔════════════════════════════════════╗"
echo "  ║       schema-viewer build          ║"
echo "  ╚════════════════════════════════════╝"
echo ""

if ! command -v swift &>/dev/null; then
    echo "  ✗ Swift compiler not found."
    echo "    Install Xcode from the App Store."
    exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
DEV_DIR=$(xcode-select -p 2>/dev/null)
echo "  ✓ $SWIFT_VERSION"
echo "  ✓ Developer tools: $DEV_DIR"

# ── Build ────────────────────────────────────────────────────────────────────
echo ""
echo "  Building release binary..."
echo "  (first build fetches dependencies — may take ~60s)"
echo ""

swift build -c release 2>&1 | while IFS= read -r line; do echo "    $line"; done

if [ ! -f ".build/release/$APP_NAME" ]; then
    echo "  ✗ Build failed"
    exit 1
fi
echo ""
echo "  ✓ Build complete"

# ── Package .app bundle ──────────────────────────────────────────────────────
echo "  Packaging $APP_BUNDLE..."

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

[ -f "AppIcon.icns" ] && cp AppIcon.icns "$APP_BUNDLE/Contents/Resources/"

RESOURCE_BUNDLE=".build/release/${APP_NAME}_${APP_NAME}.bundle"
[ -d "$RESOURCE_BUNDLE" ] && cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"

# Copy Sparkle framework
SPARKLE_FW=$(find .build/artifacts -name "Sparkle.framework" -type d 2>/dev/null | head -1)
if [ -n "$SPARKLE_FW" ] && [ -d "$SPARKLE_FW" ]; then
    mkdir -p "$APP_BUNDLE/Contents/Frameworks"
    ditto "$SPARKLE_FW" "$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
    install_name_tool -add_rpath @executable_path/../Frameworks \
        "$APP_BUNDLE/Contents/MacOS/$APP_NAME" 2>/dev/null || true
fi

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Schema Viewer</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>SUFeedURL</key>
    <string>https://github.com/devinegearing/schema-viewer/releases/latest/download/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>REPLACE_WITH_EDDSA_PUBLIC_KEY</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUAllowsAutomaticUpdates</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Schema Diagram</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>ai.fastbreak.schema</string>
            </array>
        </dict>
    </array>
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>ai.fastbreak.schema</string>
            <key>UTTypeDescription</key>
            <string>Schema Diagram</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.plain-text</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>schema</string>
                </array>
                <key>public.mime-type</key>
                <string>text/x-schema</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Ad-hoc codesign with entitlements
codesign --force --deep --sign - \
    --entitlements SchemaViewer.entitlements \
    "$APP_BUNDLE" 2>/dev/null

echo "  ✓ $APP_BUNDLE ready"

# ── Optional: install to /Applications ───────────────────────────────────────
if $INSTALL; then
    echo ""
    echo "  Installing to /Applications..."
    rm -rf "/Applications/$APP_BUNDLE"
    cp -R "$APP_BUNDLE" "/Applications/"
    echo "  ✓ Installed at /Applications/$APP_BUNDLE"
fi

echo ""
echo "  ┌──────────────────────────────────────────────────┐"
echo "  │  To launch:                                       │"
echo "  │    open $APP_BUNDLE                         │"
echo "  │                                                   │"
echo "  │  To open a schema file:                           │"
echo "  │    open $APP_BUNDLE file.schema             │"
echo "  │                                                   │"
echo "  │  Or double-click any .schema file in Finder       │"
echo "  └──────────────────────────────────────────────────┘"
echo ""

if $RUN; then
    echo "  Launching..."
    open "$APP_BUNDLE"
fi
