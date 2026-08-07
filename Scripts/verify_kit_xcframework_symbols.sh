#!/usr/bin/env bash
#
# verify_kit_xcframework_symbols.sh
#
# Fails if a kit xcframework defines any ObjC class or Swift symbol that one of
# its dependency xcframeworks also defines.
#
# A kit framework must reference its dependencies dynamically. When it absorbs a
# static copy of them instead, an app that links both the kit and the dependency
# ends up with two copies of every class, which splits singleton state and
# crashes at launch.
#
# Usage:
#   verify_kit_xcframework_symbols.sh <kit.xcframework> <dependency.xcframework>...
#
set -euo pipefail

if [[ $# -lt 2 ]]; then
	echo "usage: $(basename "$0") <kit.xcframework> <dependency.xcframework>..." >&2
	exit 2
fi

KIT_XCFRAMEWORK="$1"
shift
DEPENDENCY_XCFRAMEWORKS=("$@")

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# ObjC classes and metaclasses, plus mangled Swift symbols. Restricting to these
# avoids false positives from linker-generated and runtime support symbols.
# shellcheck disable=SC2016 # $ is regex anchoring, not a shell expansion
INTERESTING_SYMBOLS='^_OBJC_(CLASS|METACLASS)_\$_|^_\$s'

slice_platform() {
	# ios-arm64_x86_64-simulator -> ios
	echo "${1%%-*}"
}

slice_variant() {
	# ios-arm64_x86_64-simulator -> simulator; ios-arm64 -> device
	case "$1" in
	*-simulator) echo "simulator" ;;
	*-maccatalyst) echo "maccatalyst" ;;
	*) echo "device" ;;
	esac
}

binary_for_slice() {
	local slice_dir="$1"
	find "${slice_dir}" -maxdepth 3 -type f -perm -u+x -path '*.framework/*' \
		! -path '*/Headers/*' ! -path '*/Modules/*' ! -path '*/_CodeSignature/*' \
		! -path '*/Frameworks/*' 2>/dev/null | head -1
}

# Writes the defined symbols of every architecture in a Mach-O binary.
defined_symbols() {
	local binary="$1"
	nm -gU -arch all "${binary}" 2>/dev/null |
		awk '{ print $NF }' |
		grep -E "${INTERESTING_SYMBOLS}" |
		sort -u
}

# Finds the dependency slice matching a kit slice by platform and variant.
matching_slice() {
	local xcframework="$1" platform="$2" variant="$3"
	local candidate name candidate_platform candidate_variant
	for candidate in "${xcframework}"/*/; do
		[[ -d ${candidate} ]] || continue
		name="$(basename "${candidate}")"
		candidate_platform="$(slice_platform "${name}")"
		candidate_variant="$(slice_variant "${name}")"
		[[ ${candidate_platform} == "${platform}" ]] || continue
		[[ ${candidate_variant} == "${variant}" ]] || continue
		echo "${candidate}"
		return 0
	done
	return 1
}

failures=0
checked_slices=0

for kit_slice in "${KIT_XCFRAMEWORK}"/*/; do
	[[ -d ${kit_slice} ]] || continue
	slice_name="$(basename "${kit_slice}")"
	kit_binary="$(binary_for_slice "${kit_slice}")"
	if [[ -z ${kit_binary} ]]; then
		echo "::warning::No framework binary found in slice ${slice_name}; skipping"
		continue
	fi

	platform="$(slice_platform "${slice_name}")"
	variant="$(slice_variant "${slice_name}")"
	kit_symbols="${WORK_DIR}/kit-${slice_name}.txt"
	defined_symbols "${kit_binary}" >"${kit_symbols}"
	checked_slices=$((checked_slices + 1))

	for dependency in "${DEPENDENCY_XCFRAMEWORKS[@]}"; do
		dependency_name="$(basename "${dependency}" .xcframework)"

		# shellcheck disable=SC2310 # a missing slice is handled, not fatal
		if ! dependency_slice="$(matching_slice "${dependency}" "${platform}" "${variant}")"; then
			echo "::warning::${dependency_name} has no ${platform}/${variant} slice; skipping"
			continue
		fi

		dependency_binary="$(binary_for_slice "${dependency_slice}")"
		if [[ -z ${dependency_binary} ]]; then
			echo "::warning::No framework binary found in ${dependency_name}/$(basename "${dependency_slice}"); skipping"
			continue
		fi

		dependency_symbols="${WORK_DIR}/${dependency_name}-${slice_name}.txt"
		defined_symbols "${dependency_binary}" >"${dependency_symbols}"

		duplicates="${WORK_DIR}/duplicates-${dependency_name}-${slice_name}.txt"
		comm -12 "${kit_symbols}" "${dependency_symbols}" >"${duplicates}"
		duplicate_count="$(wc -l <"${duplicates}" | tr -d ' ')"

		if [[ ${duplicate_count} -gt 0 ]]; then
			failures=$((failures + 1))
			echo "::error::${slice_name}: kit redefines ${duplicate_count} symbol(s) from ${dependency_name}"
			echo "  The kit statically absorbed ${dependency_name} instead of linking it dynamically."
			echo "  First 20 duplicated symbols:"
			head -20 "${duplicates}" | sed 's/^/    /'
		else
			echo "✅ ${slice_name}: no symbols shared with ${dependency_name}"
		fi
	done
done

if [[ ${checked_slices} -eq 0 ]]; then
	echo "::error::No slices found in ${KIT_XCFRAMEWORK}"
	exit 1
fi

if [[ ${failures} -gt 0 ]]; then
	echo
	echo "::error::Duplicate symbol check failed for $(basename "${KIT_XCFRAMEWORK}")"
	exit 1
fi

echo "✅ $(basename "${KIT_XCFRAMEWORK}") shares no symbols with its dependencies"
