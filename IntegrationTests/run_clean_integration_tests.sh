#!/bin/bash
set -e

# === 🔧 Settings ===
APP_NAME="IntegrationTests"
SCHEME="IntegrationTests"
BUNDLE_ID="com.mparticle.IntegrationTests"
DEVICE_NAME="iPhone 16"                # Simulator
CONFIGURATION="Debug"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
WIREMOCK_URL="https://localhost:443"   # Your local WireMock endpoint

# === 🧹 Complete simulator cleanup ===
echo "🧹 Resetting simulators..."
xcrun simctl shutdown all || true
xcrun simctl erase all || true
killall Simulator || true

echo "✅ Simulators cleaned."

# === 🧱 Building project ===
echo "📦 Building application '$APP_NAME'..."
xcodebuild \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -derivedDataPath "$DERIVED_DATA" \
  build || { echo "❌ Build error"; exit 1; }

# === 🔍 Finding device ===
DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | awk -F '[()]' '{print $2}' | head -1)
if [ -z "$DEVICE_ID" ]; then
  echo "❌ Simulator '$DEVICE_NAME' not found. Check Xcode > Devices & Simulators."
  exit 1
fi

# === 🔍 Finding .app file ===
APP_PATH=$(find "$DERIVED_DATA" -type d -path "*/Build/Products/${CONFIGURATION}-iphonesimulator/${APP_NAME}.app" | head -1)
if [ ! -d "$APP_PATH" ]; then
  echo "❌ .app not found. Check scheme and build path."
  exit 1
fi

# === 📱 Starting simulator ===
echo "📱 Starting simulator $DEVICE_NAME..."
xcrun simctl boot "$DEVICE_ID" || true
open -a Simulator

# Wait for simulator to boot
echo "⏳ Waiting for simulator to start..."
sleep 50

# === 📲 Installing application ===
echo "📲 Installing '$APP_NAME'..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

sleep 30

# === ⚙️ Configuring environment variable / API URL ===
# If application reads from UserDefaults
echo "⚙️ Configuring APIBaseURL -> $WIREMOCK_URL"
defaults write "$BUNDLE_ID" APIBaseURL "$WIREMOCK_URL"

# === ▶️ Launching application ===
echo "▶️ Launching application..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "✅ Application '$APP_NAME' launched on clean '$DEVICE_NAME'."

