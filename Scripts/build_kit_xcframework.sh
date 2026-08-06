#!/usr/bin/env bash
#
# build_kit_xcframework.sh
#
# Builds a distributable kit xcframework that links its dependencies dynamically.
#
# Kits that archive the SPM scheme absorb static partner SDKs (and the core SDK)
# into the kit binary. An app that also links those frameworks then gets two
# copies of every class and crashes at launch. This script archives a Dynamic
# scheme that links those frameworks at runtime instead.
#
# Kit configuration lives in Kits/matrix.json under `dynamic_xcframework`:
#
#   "dynamic_xcframework": {
#     "scheme": "mParticle-AppsFlyer-Dynamic",
#     "module": "mParticle_AppsFlyer",
#     "dependencies": [
#       {
#         "framework": "AppsFlyerLib",
#         "package_identity": "appsflyerframework",
#         "url": "https://github.com/AppsFlyerSDK/AppsFlyerFramework/releases/download/{version}/AppsFlyerLib-Dynamic.xcframework.zip"
#       }
#     ]
#   }
#
# `{version}` in `url` is replaced with the version pinned in the kit project's
# Package.resolved (matched by `package_identity`), so the binary links the same
# partner release SwiftPM resolves. Package.resolved is gitignored, so the script
# runs `xcodebuild -resolvePackageDependencies` to produce it when missing.
# Set `version` on a dependency to pin an exact release and skip resolution.
#
# Usage:
#   Scripts/build_kit_xcframework.sh <kit-name>
#
# Environment:
#   OUTPUT_DIR          Where the .xcframework and .zip are written (default: xcframeworks)
#   CORE_XCFRAMEWORK    Prebuilt mParticle_Apple_SDK.xcframework; built from source when unset
#   MATRIX_JSON         Path to Kits/matrix.json (default: Kits/matrix.json)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE_MODULE="mParticle_Apple_SDK"
MATRIX_JSON="${MATRIX_JSON:-${ROOT}/Kits/matrix.json}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT}/xcframeworks}"

BUILD_SETTINGS=(
	CODE_SIGN_IDENTITY=""
	CODE_SIGNING_REQUIRED=NO
	CODE_SIGNING_ALLOWED=NO
	SKIP_INSTALL=NO
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES
)

if [[ $# -lt 1 ]]; then
	echo "usage: $(basename "$0") <kit-name>" >&2
	exit 2
fi

KIT_NAME="$1"
BUILD_DIR="${ROOT}/build/kit-xcframework/${KIT_NAME}"
ARCHIVE_DIR="${BUILD_DIR}/archives"
CONFIG_JSON="${BUILD_DIR}/config.json"

load_kit_config() {
	mkdir -p "${BUILD_DIR}"
	python3 - "${MATRIX_JSON}" "${KIT_NAME}" "${CONFIG_JSON}" <<'PY'
import json, sys

matrix_path, kit_name, out_path = sys.argv[1:]
matrix = json.load(open(matrix_path))
kit = next((entry for entry in matrix if entry.get("name") == kit_name), None)
if kit is None:
    raise SystemExit(f"::error::Kit '{kit_name}' not found in {matrix_path}")

config = kit.get("dynamic_xcframework")
if not config:
    raise SystemExit(
        f"::error::Kit '{kit_name}' is missing dynamic_xcframework in {matrix_path}"
    )

for required in ("scheme", "module"):
    if required not in config:
        raise SystemExit(
            f"::error::Kit '{kit_name}' dynamic_xcframework is missing '{required}'"
        )

payload = {
    "name": kit_name,
    "local_path": kit["local_path"],
    "scheme": config["scheme"],
    "module": config["module"],
    "dependencies": config.get("dependencies", []),
}
json.dump(payload, open(out_path, "w"), indent=2)
print(json.dumps(payload))
PY
}

kit_field() {
	python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "${CONFIG_JSON}" "$1"
}

dependency_count() {
	python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["dependencies"]))' "${CONFIG_JSON}"
}

dependency_field() {
	python3 -c '
import json, sys
deps = json.load(open(sys.argv[1]))["dependencies"]
print(deps[int(sys.argv[2])].get(sys.argv[3], ""))
' "${CONFIG_JSON}" "$1" "$2"
}

find_kit_project() {
	local local_path="$1" project
	project="$(find "${ROOT}/${local_path}" -maxdepth 1 -name '*.xcodeproj' -type d | head -1)"
	if [[ -z ${project} ]]; then
		echo "::error::No .xcodeproj found under ${local_path}" >&2
		exit 1
	fi
	echo "${project}"
}

# Package.resolved is gitignored, so a fresh checkout has none. Generate it
# before reading partner versions from it.
ensure_package_resolution() {
	local resolved="$1"

	if [[ -f ${resolved} ]]; then
		return
	fi

	# Runs inside a command substitution; keep stdout clean for the version.
	echo "📦 Resolving SPM dependencies for $(basename "${KIT_PROJECT}")" >&2
	xcodebuild -resolvePackageDependencies \
		-project "${KIT_PROJECT}" \
		-clonedSourcePackagesDirPath "${BUILD_DIR}/SourcePackages" >&2

	if [[ ! -f ${resolved} ]]; then
		echo "::error::xcodebuild did not produce ${resolved}. Set version in matrix.json." >&2
		exit 1
	fi
}

resolve_dependency_version() {
	local index="$1" package_identity version resolved
	package_identity="$(dependency_field "${index}" package_identity)"
	version="$(dependency_field "${index}" version)"

	if [[ -n ${version} ]]; then
		echo "${version}"
		return
	fi

	if [[ -z ${package_identity} ]]; then
		echo "::error::Dependency is missing package_identity or version" >&2
		exit 1
	fi

	resolved="${KIT_PROJECT}/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
	ensure_package_resolution "${resolved}"

	version="$(python3 -c '
import json, sys
identity = sys.argv[2]
pins = json.load(open(sys.argv[1]))["pins"]
for pin in pins:
    if pin["identity"].startswith(identity):
        print(pin["state"]["version"])
        break
' "${resolved}" "${package_identity}")"

	if [[ -z ${version} ]]; then
		echo "::error::No Package.resolved pin matching '${package_identity}'. Set version in matrix.json." >&2
		exit 1
	fi
	echo "${version}"
}

# Downloads a partner xcframework zip and sets DEPENDENCY_XCFRAMEWORK_PATH.
fetch_dependency_xcframework() {
	local index="$1"
	local framework version url_template url destination staging unpacked

	framework="$(dependency_field "${index}" framework)"
	version="$(resolve_dependency_version "${index}")"
	url_template="$(dependency_field "${index}" url)"

	if [[ -z ${framework} || -z ${url_template} ]]; then
		echo "::error::Dependency is missing framework or url" >&2
		exit 1
	fi

	url="${url_template//\{version\}/${version}}"
	destination="${BUILD_DIR}/${framework}.xcframework"
	DEPENDENCY_XCFRAMEWORK_PATH="${destination}"

	if [[ -d ${destination} ]]; then
		echo "♻️  Reusing ${destination}"
		return
	fi

	staging="${BUILD_DIR}/${framework}-download"
	echo "⬇️  Fetching ${framework} ${version}"
	rm -rf "${staging}"
	mkdir -p "${staging}"
	if ! curl -fsSL -o "${staging}/${framework}.xcframework.zip" "${url}"; then
		echo "::error::Failed to download ${url}" >&2
		exit 1
	fi
	unzip -q "${staging}/${framework}.xcframework.zip" -d "${staging}"

	unpacked="$(find "${staging}" -maxdepth 2 -name "${framework}.xcframework" -type d | head -1)"
	if [[ -z ${unpacked} ]]; then
		# Some zips nest a differently named xcframework; take the first one found.
		unpacked="$(find "${staging}" -maxdepth 2 -name '*.xcframework' -type d | head -1)"
	fi
	if [[ -z ${unpacked} ]]; then
		echo "::error::No .xcframework found in ${url}" >&2
		exit 1
	fi
	mv "${unpacked}" "${destination}"
	rm -rf "${staging}"
}

# Sets CORE_XCFRAMEWORK_PATH.
build_core_xcframework() {
	local destination="${BUILD_DIR}/${CORE_MODULE}.xcframework"

	if [[ -n ${CORE_XCFRAMEWORK-} ]]; then
		CORE_XCFRAMEWORK_PATH="${CORE_XCFRAMEWORK}"
		echo "♻️  Using prebuilt core SDK at ${CORE_XCFRAMEWORK_PATH}"
		return
	fi

	CORE_XCFRAMEWORK_PATH="${destination}"
	if [[ -d ${destination} ]]; then
		echo "♻️  Reusing ${destination}"
		return
	fi

	echo "🏗️  Building core SDK xcframework"
	(
		cd "${ROOT}"
		chmod +x ./Scripts/xcframework.sh
		rm -rf archives "${CORE_MODULE}.xcframework"
		./Scripts/xcframework.sh mParticle-Apple-SDK
		mv "${CORE_MODULE}.xcframework" "${destination}"
		rm -rf archives
	)
}

# Absolute path to the directory holding the .framework for a platform variant.
slice_search_path() {
	local xcframework="$1" variant="$2" platform="$3" slice platform_key
	platform_key="$(printf '%s' "${platform}" | tr '[:upper:]' '[:lower:]')"

	case "${variant}" in
	device)
		slice="$(find "${xcframework}" -maxdepth 1 -type d -name "${platform_key}-arm64" | head -1)"
		;;
	simulator)
		slice="$(find "${xcframework}" -maxdepth 1 -type d -name "${platform_key}-*-simulator" | head -1)"
		;;
	*)
		echo "::error::Unknown variant ${variant}" >&2
		exit 1
		;;
	esac

	if [[ -z ${slice} ]]; then
		echo "::error::No ${platform} ${variant} slice in $(basename "${xcframework}")" >&2
		exit 1
	fi
	echo "${slice}"
}

# Sets ARCHIVE_PATH. Links the Dynamic scheme against core + partner frameworks.
archive_slice() {
	local variant="$1" platform_name="$2"
	local platform archive_path search_paths=() path

	case "${variant}" in
	device)
		platform="generic/platform=${platform_name}"
		archive_path="${ARCHIVE_DIR}/${MODULE}-${platform_name}"
		;;
	simulator)
		platform="generic/platform=${platform_name} Simulator"
		archive_path="${ARCHIVE_DIR}/${MODULE}-${platform_name}_Simulator"
		;;
	*)
		echo "::error::Unknown variant ${variant}" >&2
		exit 1
		;;
	esac

	path="$(slice_search_path "${CORE_XCFRAMEWORK_PATH}" "${variant}" "${platform_name}")"
	search_paths+=("${path}")

	for path in "${DEPENDENCY_PATHS[@]}"; do
		search_paths+=("$(slice_search_path "${path}" "${variant}" "${platform_name}")")
	done

	echo "🏗️  Archiving ${MODULE} for ${platform}"
	xcodebuild archive \
		-project "${KIT_PROJECT}" \
		-scheme "${KIT_SCHEME}" \
		-destination "${platform}" \
		-archivePath "${archive_path}" \
		"${BUILD_SETTINGS[@]}" \
		MPARTICLE_DEPENDENCY_FRAMEWORK_PATHS="${search_paths[*]}"

	ARCHIVE_PATH="${archive_path}.xcarchive"
}

main() {
	local local_path count index device_archive simulator_archive
	local verify_args=()

	load_kit_config >/dev/null
	local_path="$(kit_field local_path)"
	KIT_SCHEME="$(kit_field scheme)"
	MODULE="$(kit_field module)"
	KIT_PROJECT="$(find_kit_project "${local_path}")"

	mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"
	echo "📌 Building ${KIT_NAME} (${MODULE}) via ${KIT_SCHEME}"

	build_core_xcframework

	DEPENDENCY_PATHS=()
	count="$(dependency_count)"
	for ((index = 0; index < count; index++)); do
		fetch_dependency_xcframework "${index}"
		DEPENDENCY_PATHS+=("${DEPENDENCY_XCFRAMEWORK_PATH}")
	done

	rm -rf "${ARCHIVE_DIR}" "${OUTPUT_DIR:?}/${MODULE}.xcframework"
	mkdir -p "${ARCHIVE_DIR}"

	# iOS only for now; kits that also ship tvOS can extend destinations later.
	archive_slice device iOS
	device_archive="${ARCHIVE_PATH}"
	archive_slice simulator iOS
	simulator_archive="${ARCHIVE_PATH}"

	xcodebuild -create-xcframework \
		-archive "${device_archive}" -framework "${MODULE}.framework" \
		-archive "${simulator_archive}" -framework "${MODULE}.framework" \
		-output "${OUTPUT_DIR}/${MODULE}.xcframework"

	rm -rf "${ARCHIVE_DIR}"

	echo "🔍 Verifying the kit does not redefine its dependencies"
	chmod +x "${ROOT}/Scripts/verify_kit_xcframework_symbols.sh"
	verify_args=(
		"${OUTPUT_DIR}/${MODULE}.xcframework"
		"${CORE_XCFRAMEWORK_PATH}"
	)
	if [[ ${#DEPENDENCY_PATHS[@]} -gt 0 ]]; then
		verify_args+=("${DEPENDENCY_PATHS[@]}")
	fi
	"${ROOT}/Scripts/verify_kit_xcframework_symbols.sh" "${verify_args[@]}"

	(cd "${OUTPUT_DIR}" && rm -f "${MODULE}.xcframework.zip" && zip -qr "${MODULE}.xcframework.zip" "${MODULE}.xcframework")
	echo "✅ ${OUTPUT_DIR}/${MODULE}.xcframework.zip"
}

main "$@"
