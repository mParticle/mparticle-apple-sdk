#!/bin/bash
set -euo pipefail

# Build an xcframework from an SPM package (no .xcodeproj required).
# Usage:
#   ./Scripts/build_kit_xcframework.sh \
#     --path Kits/braze/braze-12 \
#     --scheme mParticle-Braze \
#     --module mParticle_Braze \
#     --platforms iOS,tvOS \
#     --output xcframeworks/

usage() {
	echo "Usage: $0 --path <kit-path> --scheme <scheme> --module <module> --platforms <iOS[,tvOS]> --output <dir>"
	exit 1
}

PACKAGE_PATH=""
SCHEME=""
MODULE=""
PLATFORMS=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--path)
		PACKAGE_PATH="$2"
		shift 2
		;;
	--scheme)
		SCHEME="$2"
		shift 2
		;;
	--module)
		MODULE="$2"
		shift 2
		;;
	--platforms)
		PLATFORMS="$2"
		shift 2
		;;
	--output)
		OUTPUT_DIR="$2"
		shift 2
		;;
	*) usage ;;
	esac
done

[[ -z ${PACKAGE_PATH} || -z ${SCHEME} || -z ${MODULE} || -z ${PLATFORMS} || -z ${OUTPUT_DIR} ]] && usage

BUILD_SETTINGS="CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES"

# Signal Package.swift to use dynamic library type (required for framework output).
export BUILD_XCFRAMEWORK=1

ARCHIVES_DIR="$(mktemp -d)"
trap 'rm -rf "$ARCHIVES_DIR"' EXIT

mkdir -p "${OUTPUT_DIR}"
OUTPUT_DIR="$(cd "${OUTPUT_DIR}" && pwd)"

# Remember the absolute package path for header lookup before cd-ing.
PACKAGE_ABS_PATH="$(cd "${PACKAGE_PATH}" && pwd)"

cd "${PACKAGE_PATH}"

# The SPM target name matches the scheme. Public headers live under include/.
HEADERS_DIR="Sources/${SCHEME}/include"

XCFRAMEWORK_ARGS=""
FRAMEWORK_NAME="${SCHEME}.framework"

IFS=',' read -ra PLATFORM_LIST <<<"${PLATFORMS}"
for PLATFORM in "${PLATFORM_LIST[@]}"; do
	case "${PLATFORM}" in
	iOS)
		DEST_DEVICE="generic/platform=iOS"
		DEST_SIM="generic/platform=iOS Simulator"
		SUFFIX="iOS"
		;;
	tvOS)
		DEST_DEVICE="generic/platform=tvOS"
		DEST_SIM="generic/platform=tvOS Simulator"
		SUFFIX="tvOS"
		;;
	*)
		echo "Error: Unknown platform: ${PLATFORM}" >&2
		exit 1
		;;
	esac

	ARCHIVE_DEVICE="${ARCHIVES_DIR}/${MODULE}-${SUFFIX}"
	ARCHIVE_SIM="${ARCHIVES_DIR}/${MODULE}-${SUFFIX}_Simulator"

	echo "==> Archiving ${SCHEME} for ${PLATFORM} (device)..."
	# shellcheck disable=SC2086,SC2016
	xcodebuild archive \
		-skipPackagePluginValidation \
		-scheme "${SCHEME}" \
		-destination "${DEST_DEVICE}" \
		-archivePath "${ARCHIVE_DEVICE}" \
		${BUILD_SETTINGS} \
		'INSTALL_PATH=$(LOCAL_LIBRARY_DIR)/Frameworks'

	echo "==> Archiving ${SCHEME} for ${PLATFORM} (simulator)..."
	# shellcheck disable=SC2086,SC2016
	xcodebuild archive \
		-skipPackagePluginValidation \
		-scheme "${SCHEME}" \
		-destination "${DEST_SIM}" \
		-archivePath "${ARCHIVE_SIM}" \
		${BUILD_SETTINGS} \
		'INSTALL_PATH=$(LOCAL_LIBRARY_DIR)/Frameworks'

	# Post-process: copy headers and module map into framework bundles.
	for ARCHIVE_PATH in "${ARCHIVE_DEVICE}.xcarchive" "${ARCHIVE_SIM}.xcarchive"; do
		FW_PATH="${ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}"
		if [[ -d ${FW_PATH} && -d "${PACKAGE_ABS_PATH}/${HEADERS_DIR}" ]]; then
			mkdir -p "${FW_PATH}/Headers"
			cp "${PACKAGE_ABS_PATH}/${HEADERS_DIR}"/*.h "${FW_PATH}/Headers/"

			mkdir -p "${FW_PATH}/Modules"
			cat >"${FW_PATH}/Modules/module.modulemap" <<-MODULEMAP
				framework module ${MODULE} {
				    umbrella header "${MODULE}.h"
				    export *
				    module * { export * }
				}
			MODULEMAP
		fi
	done

	XCFRAMEWORK_ARGS+=" -archive ${ARCHIVE_DEVICE}.xcarchive -framework ${FRAMEWORK_NAME}"
	XCFRAMEWORK_ARGS+=" -archive ${ARCHIVE_SIM}.xcarchive -framework ${FRAMEWORK_NAME}"
done

echo "==> Creating xcframework for ${MODULE}..."
# shellcheck disable=SC2086
xcodebuild -create-xcframework ${XCFRAMEWORK_ARGS} -output "${OUTPUT_DIR}/${MODULE}.xcframework"

echo "==> Zipping ${MODULE}.xcframework..."
(cd "${OUTPUT_DIR}" && zip -qr "${MODULE}.xcframework.zip" "${MODULE}.xcframework" && rm -rf "${MODULE}.xcframework")

echo "==> Done: ${OUTPUT_DIR}/${MODULE}.xcframework.zip"
