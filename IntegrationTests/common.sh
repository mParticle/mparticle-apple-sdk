#!/bin/bash
# Common functions for WireMock integration testing scripts

# === Common Configuration ===
APP_NAME="IntegrationTests"
SCHEME="IntegrationTests"
BUNDLE_ID="com.mparticle.IntegrationTests"
CONFIGURATION="Debug"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

# WireMock configuration (can be overridden by scripts)
HTTP_PORT=${HTTP_PORT:-8080}
HTTPS_PORT=${HTTPS_PORT:-443}
MAPPINGS_DIR=${MAPPINGS_DIR:-"./wiremock-recordings"}

# Global variables
DEVICE_NAME=""
DEVICE_ID=""
APP_PATH=""
APP_PID=""
TEMP_ARTIFACTS_DIR="$(pwd)/temp_artifacts"

build_framework() {
	echo "🏗️  Building mParticle SDK xcframework for iOS Simulator..."

	local SDK_DIR="$(cd .. && pwd)"

	# Clean previous builds
	echo "🧹 Cleaning previous builds..."
	rm -rf "$SDK_DIR/archives" "$TEMP_ARTIFACTS_DIR/mParticle_Apple_SDK.xcframework" "${TEMP_ARTIFACTS_DIR}/mParticle_Apple_SDK_Swift.xcframework"

	# # Build dependency target first (mParticle-Apple-SDK-Swift)
	echo "📱 Building dependency target mParticle-Apple-SDK-Swift for iOS Simulator..."
	xcodebuild archive \
		-project "${SDK_DIR}/mParticle-Apple-SDK.xcodeproj" \
		-scheme mParticle-Apple-SDK-Swift \
		-destination "generic/platform=iOS Simulator" \
		-archivePath "${SDK_DIR}/archives/mParticle-Apple-SDK-Swift-iOS_Simulator" \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		-quiet || {
		echo "❌ Dependency framework build error"
		exit 1
	}

	echo "📦 --------------------------------------------------------------"
	ls -la "${SDK_DIR}/archives/mParticle-Apple-SDK-Swift-iOS_Simulator.xcarchive/Products/Library/Frameworks/mParticle_Apple_SDK_Swift.framework/"
	echo "📦 --------------------------------------------------------------"

	# Create xcframework from simulator archive only
	echo "📦 Creating xcframework..."
	xcodebuild -create-xcframework \
		-archive "${SDK_DIR}/archives/mParticle-Apple-SDK-Swift-iOS_Simulator.xcarchive" -framework mParticle_Apple_SDK_Swift.framework \
		-output "${SDK_DIR}/mParticle_Apple_SDK_Swift.xcframework" \
		2>&1 | grep -v "note:" || true

	# Build main target (mParticle-Apple-SDK-NoLocation) which depends on Swift target
	echo "📱 Building archive for iOS Simulator..."
	xcodebuild archive \
		-project "$SDK_DIR/mParticle-Apple-SDK.xcodeproj" \
		-scheme mParticle-Apple-SDK-NoLocation \
		-destination "generic/platform=iOS Simulator" \
		-archivePath "$SDK_DIR/archives/mParticle-Apple-SDK-iOS_Simulator" \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		-quiet || {
		echo "❌ Framework build error"
		exit 1
	}

	echo "📦 --------------------------------------------------------------"
	ls -la "${SDK_DIR}/archives/mParticle-Apple-SDK-iOS_Simulator.xcarchive/Products/Library/Frameworks/mParticle_Apple_SDK_NoLocation.framework/Frameworks/mParticle_Apple_SDK_Swift.framework/mParticle_Apple_SDK_Swift"
	echo "📦 --------------------------------------------------------------"

	# Create xcframework from simulator archive only
	echo "📦 Creating xcframework..."
	xcodebuild -create-xcframework \
		-archive "$SDK_DIR/archives/mParticle-Apple-SDK-iOS_Simulator.xcarchive" -framework mParticle_Apple_SDK_NoLocation.framework \
		-output "$SDK_DIR/mParticle_Apple_SDK.xcframework" \
		2>&1 | grep -v "note:" || true

	# Move xcframeworks to temp artifacts directory
	echo "📁 Moving xcframeworks to temp directory..."
	mkdir -p "$TEMP_ARTIFACTS_DIR"
	rm -rf "$TEMP_ARTIFACTS_DIR/mParticle_Apple_SDK.xcframework" "${TEMP_ARTIFACTS_DIR}/mParticle_Apple_SDK_Swift.xcframework"
	mv "$SDK_DIR/mParticle_Apple_SDK.xcframework" "$TEMP_ARTIFACTS_DIR/"
	mv "${SDK_DIR}/mParticle_Apple_SDK_Swift.xcframework" "${TEMP_ARTIFACTS_DIR}/"

	# Clean up archives
	rm -rf "$SDK_DIR/archives"

	echo "✅ SDK built successfully at: $TEMP_ARTIFACTS_DIR/mParticle_Apple_SDK.xcframework"
	echo "✅ Swift SDK built successfully at${ $TEMP_ARTIFACTS_D}IR/mParticle_Apple_SDK_Swift.xcframework"
}

build_application() {
	echo "📦 Building application '$APP_NAME'..."
	xcodebuild \
		-project IntegrationTests.xcodeproj \
		-scheme "$SCHEME" \
		-configuration "$CONFIGURATION" \
		-destination "generic/platform=iOS Simulator" \
		-derivedDataPath "$DERIVED_DATA" \
		-quiet \
		build || {
		echo "❌ Build error"
		exit 1
	}
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

	# Only open Simulator GUI if not running in CI (headless mode)
	if [[ -z ${CI} ]]; then
		open -a Simulator
	else
		echo "ℹ️  Running in CI mode - skipping Simulator GUI"
	fi

	echo "⏳ Waiting for simulator to start..."
	xcrun simctl bootstatus "$DEVICE_ID" -b
	echo "✅ Simulator started."
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

	if [[ -n ${MPARTICLE_API_KEY} ]]; then
		export SIMCTL_CHILD_MPARTICLE_API_KEY="${MPARTICLE_API_KEY}"
	fi
	if [[ -n ${MPARTICLE_API_SECRET} ]]; then
		export SIMCTL_CHILD_MPARTICLE_API_SECRET="${MPARTICLE_API_SECRET}"
	fi

	LAUNCH_OUTPUT=$(xcrun simctl launch "${DEVICE_ID}" "${BUNDLE_ID}")
	APP_PID=$(echo "${LAUNCH_OUTPUT}" | awk -F': ' '{print $2}')

	if [[ -z ${APP_PID} ]]; then
		echo "❌ Failed to get app PID"
		exit 1
	fi

	echo "✅ Application '$APP_NAME' started with PID: $APP_PID"
}

wait_for_app_completion() {
	echo "⏳ Waiting for app to complete execution..."
	local MAX_WAIT=120
	local WAIT_COUNT=0
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

wait_for_wiremock() {
	echo "⏳ Waiting for WireMock to start..."
	local MAX_RETRIES=30
	local RETRY_COUNT=0
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
}

start_wiremock() {
	local mode=${1:-"verify"} # "record" or "verify"

	if [ "$mode" = "record" ]; then
		echo "🚀 Starting WireMock container in recording mode..."
	else
		echo "🚀 Starting WireMock container in verification mode..."
	fi

	stop_wiremock

	# Base docker command
	local docker_cmd="docker run -d --name ${CONTAINER_NAME} \
    -p ${HTTP_PORT}:8080 \
    -p ${HTTPS_PORT}:8443 \
    -v \"$(pwd)/${MAPPINGS_DIR}\":/home/wiremock \
    wiremock/wiremock:3.9.1 \
    --https-port 8443"

	# Add mode-specific parameters
	if [ "$mode" = "record" ]; then
		docker_cmd="${docker_cmd} \
      --enable-browser-proxying \
      --preserve-host-header \
      --record-mappings \
      --proxy-all=\"${TARGET_URL}\""
	else
		docker_cmd="${docker_cmd} \
      --verbose"
	fi

	# Execute docker command
	eval $docker_cmd
}

show_wiremock_logs() {
	echo ""
	echo "📋 WireMock container logs:"
	echo "════════════════════════════════════════════════════════════════"
	docker logs ${CONTAINER_NAME} 2>&1 || echo "❌ Could not retrieve container logs"
	echo "════════════════════════════════════════════════════════════════"
	echo ""
}

stop_wiremock() {
	docker stop ${CONTAINER_NAME} 2>/dev/null || true
	docker rm ${CONTAINER_NAME} 2>/dev/null || true
}

stop_wiremock_with_logs() {
	show_wiremock_logs
	stop_wiremock
}

create_proxy_mappings() {
	echo "📝 Creating proxy mappings for recording mode..."

	local PROXY_DIR="${MAPPINGS_DIR}/mappings"
	mkdir -p "${PROXY_DIR}"

	# Create proxy-identify.json
	cat >"${PROXY_DIR}/proxy-identify.json" <<'EOF'
{
  "priority": 1,
  "request": {
    "urlPathPattern": "/v1/identify"
  },
  "response": {
    "proxyBaseUrl": "https://identity.mparticle.com"
  }
}
EOF

	# Create proxy-events.json
	cat >"${PROXY_DIR}/proxy-events.json" <<'EOF'
{
  "priority": 1,
  "request": {
    "urlPathPattern": "/v2/events"
  },
  "response": {
    "proxyBaseUrl": "https://nativesdks.mparticle.com"
  }
}
EOF

	echo "✅ Proxy mappings created"
}

remove_proxy_mappings() {
	echo "🗑️  Removing proxy mappings for verification mode..."

	rm -f "${MAPPINGS_DIR}/mappings/proxy-identify.json" 2>/dev/null || true
	rm -f "${MAPPINGS_DIR}/mappings/proxy-events.json" 2>/dev/null || true

	echo "✅ Proxy mappings removed"
}
