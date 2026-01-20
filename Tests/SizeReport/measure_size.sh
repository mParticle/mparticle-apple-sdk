#!/bin/bash
#
# SDK Size Measurement Script
#
# This script builds both the baseline and with-SDK test apps,
# and measures their sizes to determine the SDK's size impact.
#
# The SDK is built FROM SOURCE using the main Xcode project to ensure
# that source code changes in PRs are reflected in the size measurement.
#
# Usage: ./measure_size.sh [--json] [--with-sdk-only]
#
# Options:
#   --json           Output results as JSON
#   --with-sdk-only  Only build and measure the with-SDK app
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

# Parse arguments
OUTPUT_JSON=false
WITH_SDK_ONLY=false
for arg in "$@"; do
	case ${arg} in
	--json)
		OUTPUT_JSON=true
		;;
	--with-sdk-only)
		WITH_SDK_ONLY=true
		;;
	*)
		echo "Unknown argument: ${arg}" >&2
		exit 1
		;;
	esac
done

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build SDK from source
build_sdk_from_source() {
	echo "Building SDK from source..." >&2

	local SDK_PROJECT="${REPO_ROOT}/mParticle-Apple-SDK.xcodeproj"
	local ARCHIVES_DIR="${BUILD_DIR}/sdk-archives"

	# Build for iOS device (Release, arm64)
	# Redirect all xcodebuild output to stderr to keep stdout clean for JSON output
	echo "  Archiving for iOS device..." >&2
	xcodebuild archive \
		-project "${SDK_PROJECT}" \
		-scheme "mParticle-Apple-SDK-NoLocation" \
		-destination "generic/platform=iOS" \
		-archivePath "${ARCHIVES_DIR}/mParticle-Apple-SDK-iOS" \
		SKIP_INSTALL=NO \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		-quiet >&2 2>&1

	# Create xcframework from the archive
	echo "  Creating xcframework..." >&2
	xcodebuild -create-xcframework \
		-archive "${ARCHIVES_DIR}/mParticle-Apple-SDK-iOS.xcarchive" -framework mParticle_Apple_SDK.framework \
		-output "${BUILD_DIR}/mParticle_Apple_SDK.xcframework" \
		>&2 2>&1 || true

	if [[ ! -d "${BUILD_DIR}/mParticle_Apple_SDK.xcframework" ]]; then
		echo "Error: Failed to build SDK xcframework" >&2
		exit 1
	fi

	echo "  SDK built successfully" >&2
}

# Function to get directory size in KB
get_dir_size_kb() {
	local dir_path="$1"
	local size_output
	if [[ -d ${dir_path} ]]; then
		# Get size in KB
		size_output=$(du -sk "${dir_path}" 2>/dev/null) || true
		echo "${size_output}" | cut -f1
	else
		echo "0"
	fi
}

# Function to get app size from the built .app bundle
get_app_size() {
	local app_path="$1"
	get_dir_size_kb "${app_path}"
}

# Function to get executable size from the main binary
get_executable_size() {
	local app_path="$1"
	local app_name
	app_name=$(basename "${app_path}" .app)
	local binary_path="${app_path}/${app_name}"
	if [[ -f ${binary_path} ]]; then
		stat -f%z "${binary_path}" 2>/dev/null || stat -c%s "${binary_path}" 2>/dev/null || echo "0"
	else
		echo "0"
	fi
}

# Function to build an app
# All xcodebuild output is redirected to stderr to keep stdout clean for JSON output
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
		-quiet >&2 2>&1 || {
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
			-quiet >&2 2>&1
	}
}

# Build SDK from source first (required for with-SDK app)
build_sdk_from_source

# Measure xcframework size
XCFRAMEWORK_PATH="${BUILD_DIR}/mParticle_Apple_SDK.xcframework"
XCFRAMEWORK_SIZE_KB=0
if [[ -d ${XCFRAMEWORK_PATH} ]]; then
	# shellcheck disable=SC2311
	XCFRAMEWORK_SIZE_KB=$(get_dir_size_kb "${XCFRAMEWORK_PATH}")
fi

# Build baseline app (if not with-sdk-only)
BASELINE_SIZE_KB=0
BASELINE_EXECUTABLE_SIZE=0
if [[ ${WITH_SDK_ONLY} == "false" ]]; then
	build_app \
		"${SCRIPT_DIR}/SizeTestApp/SizeTestApp.xcodeproj" \
		"SizeTestApp" \
		"${BUILD_DIR}/SizeTestApp.xcarchive"

	# Find the .app in archive or DerivedData
	if [[ -d "${BUILD_DIR}/SizeTestApp.xcarchive" ]]; then
		BASELINE_APP="${BUILD_DIR}/SizeTestApp.xcarchive/Products/Applications/SizeTestApp.app"
	else
		BASELINE_APP=$(find "${BUILD_DIR}/DerivedData/SizeTestApp" -name "SizeTestApp.app" -type d 2>/dev/null | head -1 || true)
	fi

	if [[ -d ${BASELINE_APP} ]]; then
		# shellcheck disable=SC2311
		BASELINE_SIZE_KB=$(get_app_size "${BASELINE_APP}")
		# shellcheck disable=SC2311
		BASELINE_EXECUTABLE_SIZE=$(get_executable_size "${BASELINE_APP}")
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
	WITHSDK_APP=$(find "${BUILD_DIR}/DerivedData/SizeTestAppWithSDK" -name "SizeTestAppWithSDK.app" -type d 2>/dev/null | head -1 || true)
fi

WITHSDK_SIZE_KB=0
WITHSDK_EXECUTABLE_SIZE=0
if [[ -d ${WITHSDK_APP} ]]; then
	# shellcheck disable=SC2311
	WITHSDK_SIZE_KB=$(get_app_size "${WITHSDK_APP}")
	# shellcheck disable=SC2311
	WITHSDK_EXECUTABLE_SIZE=$(get_executable_size "${WITHSDK_APP}")
fi

# Calculate SDK impact
SDK_SIZE_KB=$((WITHSDK_SIZE_KB - BASELINE_SIZE_KB))
SDK_EXECUTABLE_SIZE=$((WITHSDK_EXECUTABLE_SIZE - BASELINE_EXECUTABLE_SIZE))

# Output results
if [[ ${OUTPUT_JSON} == "true" ]]; then
	# Output compact single-line JSON for CI compatibility
	echo "{\"baseline_app_size_kb\":${BASELINE_SIZE_KB},\"baseline_executable_size_bytes\":${BASELINE_EXECUTABLE_SIZE},\"with_sdk_app_size_kb\":${WITHSDK_SIZE_KB},\"with_sdk_executable_size_bytes\":${WITHSDK_EXECUTABLE_SIZE},\"sdk_impact_kb\":${SDK_SIZE_KB},\"sdk_executable_impact_bytes\":${SDK_EXECUTABLE_SIZE},\"xcframework_size_kb\":${XCFRAMEWORK_SIZE_KB}}"
else
	echo ""
	echo "=== SDK Size Measurement Results ==="
	echo ""
	echo "XCFramework:"
	echo "  Size: ${XCFRAMEWORK_SIZE_KB} KB"
	echo ""
	if [[ ${WITH_SDK_ONLY} == "false" ]]; then
		echo "Baseline App (no SDK):"
		echo "  App bundle size: ${BASELINE_SIZE_KB} KB"
		echo "  Executable size: ${BASELINE_EXECUTABLE_SIZE} bytes"
		echo ""
	fi
	echo "With SDK App:"
	echo "  App bundle size: ${WITHSDK_SIZE_KB} KB"
	echo "  Executable size: ${WITHSDK_EXECUTABLE_SIZE} bytes"
	echo ""
	if [[ ${WITH_SDK_ONLY} == "false" ]]; then
		echo "SDK Impact:"
		echo "  App bundle delta: ${SDK_SIZE_KB} KB"
		echo "  Executable delta: ${SDK_EXECUTABLE_SIZE} bytes"
	fi
	echo ""
fi
