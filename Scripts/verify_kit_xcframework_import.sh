#!/usr/bin/env bash
#
# verify_kit_xcframework_import.sh
#
# Ensures kit public headers compile against the core SDK xcframework module
# (mParticle_Apple_SDK), not only the SPM/CocoaPods ObjC module name.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${ROOT}/build/xcframework-import-smoke}"
CORE_SCHEME="mParticle-Apple-SDK"
CORE_MODULE="mParticle_Apple_SDK"
KIT_PROJECT="${ROOT}/Kits/appsflyer/appsflyer-6/mParticle-AppsFlyer.xcodeproj"
KIT_SCHEME="mParticle-AppsFlyer"
KIT_MODULE="mParticle_AppsFlyer"
SMOKE_SOURCE="${ROOT}/Tests/XCFrameworkImportSmoke/smoke.m"

BUILD_SETTINGS=(
	CODE_SIGN_IDENTITY=""
	CODE_SIGNING_REQUIRED=NO
	CODE_SIGNING_ALLOWED=NO
	SKIP_INSTALL=NO
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES
)

framework_search_path() {
	local xcf="$1"
	find "${xcf}" -type d -path '*/ios-*simulator/*.framework' -maxdepth 2 | head -1 | xargs dirname
}

build_core_xcframework() {
	echo "🏗️  Building core SDK xcframework..."
	cd "${ROOT}"
	chmod +x ./Scripts/xcframework.sh
	rm -rf archives "${CORE_MODULE}.xcframework"
	./Scripts/xcframework.sh "${CORE_SCHEME}" "${CORE_MODULE}"
	mv "${CORE_MODULE}.xcframework" "${BUILD_DIR}/"
	rm -rf archives
}

build_kit_xcframework() {
	echo "🏗️  Building AppsFlyer kit xcframework (representative kit)..."
	local archive_root="${BUILD_DIR}/archives"
	mkdir -p "${archive_root}"
	rm -rf "${archive_root}" "${BUILD_DIR}/${KIT_MODULE}.xcframework"

	xcodebuild archive -project "${KIT_PROJECT}" -scheme "${KIT_SCHEME}" \
		-destination "generic/platform=iOS Simulator" \
		-archivePath "${archive_root}/${KIT_MODULE}-iOS_Simulator" \
		"${BUILD_SETTINGS[@]}"

	xcodebuild -create-xcframework \
		-archive "${archive_root}/${KIT_MODULE}-iOS_Simulator.xcarchive" -framework "${KIT_MODULE}.framework" \
		-output "${BUILD_DIR}/${KIT_MODULE}.xcframework"

	rm -rf "${archive_root}"
}

compile_smoke_test() {
	echo "🧪 Compiling ObjC smoke test against xcframework modules..."
	local core_xcf="${BUILD_DIR}/${CORE_MODULE}.xcframework"
	local kit_xcf="${BUILD_DIR}/${KIT_MODULE}.xcframework"
	local core_fw_path
	local kit_fw_path
	local sdk_path

	core_fw_path="$(framework_search_path "${core_xcf}")"
	kit_fw_path="$(framework_search_path "${kit_xcf}")"
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
build_core_xcframework
build_kit_xcframework
compile_smoke_test
