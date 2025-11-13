echo "🔄 Generating project with Tuist..."
tuist generate --no-open

# === Configuration ===
APP_NAME="IntegrationTests"
SCHEME="IntegrationTests"
BUNDLE_ID="com.mparticle.IntegrationTests"
CONFIGURATION="Debug"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

HTTP_PORT=${1:-8080}
HTTPS_PORT=${2:-443}
MAPPINGS_DIR=${3:-"./wiremock-recordings"}
TARGET_URL=${4:-"https://config2.mparticle.com"}
CONTAINER_NAME="wiremock-recorder"

# Global variables
DEVICE_NAME=""
DEVICE_ID=""
APP_PATH=""
APP_PID=""

# === Prepare local directory for mappings ===
mkdir -p "${MAPPINGS_DIR}/mappings"
mkdir -p "${MAPPINGS_DIR}/__files"

build_application() {
  echo "📦 Building application '$APP_NAME'..."
  xcodebuild \
    -project IntegrationTests.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED_DATA" \
    -quiet \
    build || { echo "❌ Build error"; exit 1; }
  echo "✅ Build completed."
}

reset_simulators() {
  echo "🧹 Resetting simulators..."
  xcrun simctl shutdown all || true
  xcrun simctl erase all || true
  killall Simulator || true
  echo "✅ Simulators cleaned."
}

find_available_device() {
  echo "🔍 Searching for available iPhone simulator..."
  
  # Get list of available iPhone devices (excluding unavailable ones)
  AVAILABLE_DEVICES=$(xcrun simctl list devices iPhone | grep -v "unavailable" | grep "iPhone" | grep -v "==" | head -5)
  
  if [ -z "$AVAILABLE_DEVICES" ]; then
    echo "❌ No iPhone simulators found. Please install iPhone simulators in Xcode."
    exit 1
  fi
  
  # Try to find iPhone 17, 16, 15, or any available iPhone
  for device_pattern in "iPhone 17" "iPhone 16" "iPhone 15" "iPhone"; do
    DEVICE_NAME=$(echo "$AVAILABLE_DEVICES" | grep "$device_pattern" | head -1 | sed 's/^[[:space:]]*//' | sed 's/ (.*//')
    if [ -n "$DEVICE_NAME" ]; then
      echo "✅ Selected device: $DEVICE_NAME"
      break
    fi
  done
  
  if [ -z "$DEVICE_NAME" ]; then
    echo "❌ No suitable iPhone simulator found"
    exit 1
  fi
}

find_device() {
  echo "🔍 Finding simulator device '$DEVICE_NAME'..."
  DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | awk -F '[()]' '{print $2}' | head -1)
  
  if [ -z "$DEVICE_ID" ]; then
    echo "❌ Simulator '$DEVICE_NAME' not found. Check Xcode > Devices & Simulators."
    exit 1
  fi
  echo "✅ Found device: $DEVICE_ID"
}

start_simulator() {
  echo "📱 Starting simulator $DEVICE_NAME..."
  xcrun simctl boot "$DEVICE_ID" || true
  open -a Simulator

  echo "⏳ Waiting for simulator to start..."
  xcrun simctl bootstatus "$DEVICE_ID" -b
  echo "✅ Simulator started."
}

install_application() {
  echo "📲 Installing '$APP_NAME'..."
  xcrun simctl install "$DEVICE_ID" "$APP_PATH"

  echo "⏳ Waiting for app installation to complete..."
  local MAX_WAIT=30
  local WAIT_COUNT=0
  while ! xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" &>/dev/null; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
      echo "❌ App installation timed out after ${MAX_WAIT} seconds"
      exit 1
    fi
  done
  echo "✅ App installed successfully"
}

launch_application() {
  echo "▶️ Launching application..."
  LAUNCH_OUTPUT=$(xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID")
  APP_PID=$(echo "$LAUNCH_OUTPUT" | awk -F': ' '{print $2}')

  if [ -z "$APP_PID" ]; then
    echo "❌ Failed to get app PID"
    exit 1
  fi

  echo "✅ Application '$APP_NAME' started with PID: $APP_PID"
}

wait_for_app_completion() {
  echo "⏳ Waiting for app to complete execution..."
  MAX_WAIT=60
  WAIT_COUNT=0
  while kill -0 "$APP_PID" 2>/dev/null; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
      echo "⚠️  App still running after ${MAX_WAIT} seconds, proceeding anyway..."
      break
    fi
  done
  if [ $WAIT_COUNT -lt $MAX_WAIT ]; then
    echo "✅ App execution completed"
  fi
}

find_app_path() {
  echo "🔍 Finding application path..."
  APP_PATH=$(find "$DERIVED_DATA" -type d -name "${APP_NAME}.app" | head -1)
  
  if [ -z "$APP_PATH" ]; then
    echo "❌ Application not found in DerivedData"
    exit 1
  fi
  echo "✅ Found app at: $APP_PATH"
}

start_wiremock() {  
  stop_wiremock
  
  docker run -d --name ${CONTAINER_NAME} \
    -p ${HTTP_PORT}:8080 \
    -p ${HTTPS_PORT}:8443 \
    -v "$(pwd)/${MAPPINGS_DIR}":/home/wiremock \
    wiremock/wiremock:3.9.1 \
    --enable-browser-proxying \
    --preserve-host-header \
    --record-mappings \
    --proxy-all="${TARGET_URL}" \
    --https-port 8443
}

wait_for_wiremock() {
  echo "⏳ Waiting for WireMock to start..."
  MAX_RETRIES=30
  RETRY_COUNT=0
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:${HTTPS_PORT}/__admin/mappings | grep -q "200"; then
      echo "✅ WireMock is ready!"
      break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 1
  done

  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ WireMock failed to start within ${MAX_RETRIES} seconds"
    exit 1
  fi

  echo ""
  echo "📝 WireMock is running and recording traffic to: ${MAPPINGS_DIR}"
  echo "🔗 Admin UI: http://localhost:${HTTP_PORT}/__admin"
  echo "🔗 HTTPS Proxy: https://localhost:${HTTPS_PORT}"
  echo ""
  echo "Press Ctrl+C to stop WireMock and exit..."
  echo ""
}

stop_wiremock() {
  echo ""
  echo "🛑 Stopping WireMock container..."
  docker stop ${CONTAINER_NAME} 2>/dev/null || true
  docker rm ${CONTAINER_NAME} 2>/dev/null || true
  echo "✅ WireMock stopped"
}

trap stop_wiremock EXIT INT TERM

build_application
find_app_path
reset_simulators
find_available_device
find_device
start_wiremock
wait_for_wiremock
start_simulator
install_application
launch_application
wait_for_app_completion
