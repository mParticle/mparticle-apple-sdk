#!/bin/bash
#
# SDK Size Measurement Script
#
# This script builds both the baseline and with-SDK test apps,
# and measures their sizes to determine the SDK's size impact.
#
# Usage: ./measure_size.sh [--json] [--with-sdk-only]
#
# Options:
#   --json           Output results as JSON
#   --with-sdk-only  Only build and measure the with-SDK app
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
EXPORT_OPTIONS="${SCRIPT_DIR}/ExportOptions.plist"

# Parse arguments
OUTPUT_JSON=false
WITH_SDK_ONLY=false
for arg in "$@"; do
	case $arg in
	--json)
		OUTPUT_JSON=true
		;;
	--with-sdk-only)
		WITH_SDK_ONLY=true
		;;
	esac
done

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Function to get app size from the built .app bundle
get_app_size() {
	local app_path="$1"
	if [[ -d $app_path ]]; then
		# Get size in bytes
		du -sk "$app_path" | cut -f1
	else
		echo "0"
	fi
}

# Function to get binary size from the executable
get_binary_size() {
	local app_path="$1"
	local app_name=$(basename "$app_path" .app)
	local binary_path="${app_path}/${app_name}"
	if [[ -f $binary_path ]]; then
		stat -f%z "$binary_path" 2>/dev/null || stat -c%s "$binary_path" 2>/dev/null || echo "0"
	else
		echo "0"
	fi
}

# Function to build an app
build_app() {
	local project_path="$1"
	local scheme="$2"
	local archive_path="$3"

	echo "Building ${scheme}..." >&2

	xcodebuild archive \
		-project "${project_path}" \
		-scheme "${scheme}" \
		-configuration Release \
		-destination "generic/platform=iOS" \
		-archivePath "${archive_path}" \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ONLY_ACTIVE_ARCH=NO \
		-quiet 2>/dev/null || {
		echo "Warning: Archive failed, trying build instead..." >&2
		# Fallback to regular build if archive fails
		xcodebuild build \
			-project "${project_path}" \
			-scheme "${scheme}" \
			-configuration Release \
			-destination "generic/platform=iOS" \
			-derivedDataPath "${BUILD_DIR}/DerivedData/${scheme}" \
			CODE_SIGN_IDENTITY="-" \
			CODE_SIGNING_REQUIRED=NO \
			CODE_SIGNING_ALLOWED=NO \
			ONLY_ACTIVE_ARCH=NO \
			-quiet 2>/dev/null
	}
}

# Build baseline app (if not with-sdk-only)
BASELINE_SIZE_KB=0
BASELINE_BINARY_SIZE=0
if [[ $WITH_SDK_ONLY == "false" ]]; then
	build_app \
		"${SCRIPT_DIR}/SizeTestApp/SizeTestApp.xcodeproj" \
		"SizeTestApp" \
		"${BUILD_DIR}/SizeTestApp.xcarchive"

	# Find the .app in archive or DerivedData
	if [[ -d "${BUILD_DIR}/SizeTestApp.xcarchive" ]]; then
		BASELINE_APP="${BUILD_DIR}/SizeTestApp.xcarchive/Products/Applications/SizeTestApp.app"
	else
		BASELINE_APP=$(find "${BUILD_DIR}/DerivedData/SizeTestApp" -name "SizeTestApp.app" -type d | head -1)
	fi

	if [[ -d $BASELINE_APP ]]; then
		BASELINE_SIZE_KB=$(get_app_size "$BASELINE_APP")
		BASELINE_BINARY_SIZE=$(get_binary_size "$BASELINE_APP")
	fi
fi

# Build with-SDK app
build_app \
	"${SCRIPT_DIR}/SizeTestAppWithSDK/SizeTestAppWithSDK.xcodeproj" \
	"SizeTestAppWithSDK" \
	"${BUILD_DIR}/SizeTestAppWithSDK.xcarchive"

# Find the .app in archive or DerivedData
if [[ -d "${BUILD_DIR}/SizeTestAppWithSDK.xcarchive" ]]; then
	WITHSDK_APP="${BUILD_DIR}/SizeTestAppWithSDK.xcarchive/Products/Applications/SizeTestAppWithSDK.app"
else
	WITHSDK_APP=$(find "${BUILD_DIR}/DerivedData/SizeTestAppWithSDK" -name "SizeTestAppWithSDK.app" -type d | head -1)
fi

WITHSDK_SIZE_KB=0
WITHSDK_BINARY_SIZE=0
if [[ -d $WITHSDK_APP ]]; then
	WITHSDK_SIZE_KB=$(get_app_size "$WITHSDK_APP")
	WITHSDK_BINARY_SIZE=$(get_binary_size "$WITHSDK_APP")
fi

# Calculate SDK impact
SDK_SIZE_KB=$((WITHSDK_SIZE_KB - BASELINE_SIZE_KB))
SDK_BINARY_SIZE=$((WITHSDK_BINARY_SIZE - BASELINE_BINARY_SIZE))

# Output results
if [[ $OUTPUT_JSON == "true" ]]; then
	cat <<EOF
{
    "baseline_app_size_kb": ${BASELINE_SIZE_KB},
    "baseline_binary_size_bytes": ${BASELINE_BINARY_SIZE},
    "with_sdk_app_size_kb": ${WITHSDK_SIZE_KB},
    "with_sdk_binary_size_bytes": ${WITHSDK_BINARY_SIZE},
    "sdk_impact_kb": ${SDK_SIZE_KB},
    "sdk_binary_impact_bytes": ${SDK_BINARY_SIZE}
}
EOF
else
	echo ""
	echo "=== SDK Size Measurement Results ==="
	echo ""
	if [[ $WITH_SDK_ONLY == "false" ]]; then
		echo "Baseline App (no SDK):"
		echo "  App bundle size: ${BASELINE_SIZE_KB} KB"
		echo "  Binary size: ${BASELINE_BINARY_SIZE} bytes"
		echo ""
	fi
	echo "With SDK App:"
	echo "  App bundle size: ${WITHSDK_SIZE_KB} KB"
	echo "  Binary size: ${WITHSDK_BINARY_SIZE} bytes"
	echo ""
	if [[ $WITH_SDK_ONLY == "false" ]]; then
		echo "SDK Impact:"
		echo "  App bundle delta: ${SDK_SIZE_KB} KB"
		echo "  Binary delta: ${SDK_BINARY_SIZE} bytes"
	fi
	echo ""
fi
