#!/usr/bin/env bash
#
# verify_kit_xcframework_import.sh
#
# Builds the distributable AppsFlyer kit xcframework (representative kit) and
# checks two things manual xcframework consumers depend on:
#
#   1. The kit does not redefine symbols from the core SDK or AppsFlyer, which
#      would give an app two copies of those classes. Enforced by the build.
#   2. Kit public headers compile against the core SDK xcframework module
#      (mParticle_Apple_SDK), not only the SPM/CocoaPods ObjC module name.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${ROOT}/build/xcframework-import-smoke}"
CORE_MODULE="mParticle_Apple_SDK"
KIT_NAME="appsflyer-6"
KIT_MODULE="mParticle_AppsFlyer"
SMOKE_SOURCE="${ROOT}/Tests/XCFrameworkImportSmoke/smoke.m"

# build_kit_xcframework.sh builds the core SDK here when it is not given a
# prebuilt one.
CORE_XCFRAMEWORK="${ROOT}/build/kit-xcframework/${KIT_NAME}/${CORE_MODULE}.xcframework"
KIT_XCFRAMEWORK="${BUILD_DIR}/${KIT_MODULE}.xcframework"

framework_search_path() {
	local xcf="$1"
	find "${xcf}" -type d -path '*/ios-*simulator/*.framework' -maxdepth 2 | head -1 | xargs dirname
}

build_xcframeworks() {
	echo "🏗️  Building distributable ${KIT_NAME} kit xcframework..."
	chmod +x "${ROOT}/Scripts/build_kit_xcframework.sh"
	rm -rf "${KIT_XCFRAMEWORK}"
	OUTPUT_DIR="${BUILD_DIR}" "${ROOT}/Scripts/build_kit_xcframework.sh" "${KIT_NAME}"
}

compile_smoke_test() {
	echo "🧪 Compiling ObjC smoke test against xcframework modules..."
	local core_fw_path kit_fw_path sdk_path

	core_fw_path="$(framework_search_path "${CORE_XCFRAMEWORK}")"
	kit_fw_path="$(framework_search_path "${KIT_XCFRAMEWORK}")"
	sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"

	if [[ -z ${core_fw_path} || -z ${kit_fw_path} ]]; then
		echo "::error::Could not locate simulator framework slices in xcframeworks"
		exit 1
	fi

	clang -fsyntax-only -fmodules -fobjc-arc \
		-isysroot "${sdk_path}" \
		-iframework "${core_fw_path}" \
		-iframework "${kit_fw_path}" \
		"${SMOKE_SOURCE}"

	echo "✅ Kit xcframework import smoke test passed"
}

mkdir -p "${BUILD_DIR}"
build_xcframeworks
compile_smoke_test
