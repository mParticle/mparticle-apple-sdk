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
TEMP_ARTIFACTS_DIR="$(pwd)/temp_artifacts"

# === 🏗️ Building SDK xcframework ===
echo "🏗️  Building mParticle SDK xcframework for iOS Simulator..."
cd ..

# Clean previous builds
rm -rf archives mParticle_Apple_SDK.xcframework

# Build for iOS Simulator only (faster for integration tests)
echo "   📱 Building archive for iOS Simulator..."
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj \
  -scheme mParticle-Apple-SDK \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "archives/mParticle-Apple-SDK-iOS_Simulator" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create xcframework from simulator archive only
echo "   📦 Creating xcframework..."
xcodebuild -create-xcframework \
  -archive archives/mParticle-Apple-SDK-iOS_Simulator.xcarchive -framework mParticle_Apple_SDK.framework \
  -output mParticle_Apple_SDK.xcframework

# Move xcframework to temp artifacts directory
echo "   📁 Moving xcframework to temp directory..."
rm -rf "$TEMP_ARTIFACTS_DIR"
mkdir -p "$TEMP_ARTIFACTS_DIR"
mv mParticle_Apple_SDK.xcframework "$TEMP_ARTIFACTS_DIR/"
rm -rf archives

echo "✅ SDK built successfully."

cd IntegrationTests

# === 🔄 Regenerating Tuist project ===
echo "🔄 Regenerating Tuist project..."
tuist clean
tuist install
tuist generate --no-open

echo "✅ Project regenerated."

# === 🧹 Complete simulator cleanup ===
echo "🧹 Resetting simulators..."
xcrun simctl shutdown all || true
xcrun simctl erase all || true
killall Simulator || true

echo "✅ Simulators cleaned."

# === 🧱 Building project ===
echo "📦 Building application '$APP_NAME'..."
xcodebuild \
  -project IntegrationTests.xcodeproj \
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
sleep 20

# === 📲 Installing application ===
echo "📲 Installing '$APP_NAME'..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

sleep 10

# === ⚙️ Configuring environment variable / API URL ===
# If application reads from UserDefaults
echo "⚙️ Configuring APIBaseURL -> $WIREMOCK_URL"
defaults write "$BUNDLE_ID" APIBaseURL "$WIREMOCK_URL"

# === ▶️ Launching application ===
echo "▶️ Launching application..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "✅ Application '$APP_NAME' launched on clean '$DEVICE_NAME'."

