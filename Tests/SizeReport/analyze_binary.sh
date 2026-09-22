#!/bin/bash
#
# SDK Binary Size Attribution
#
# Breaks a built mParticle framework down into Mach-O images, segments, sections and
# symbols, so a size-report delta can be traced back to the code that caused it.
#
# measure_size.sh answers "how big is it". This answers "which bytes, and whose".
#
# Usage: ./analyze_binary.sh <framework-path> [--json] [--top N]
#
# Options:
#   --json    Output aggregates as single-line JSON (for CI)
#   --top N   Show the N largest symbols per image (default 25, text output only)
#
# Example:
#   ./analyze_binary.sh build/mParticle_Apple_SDK.xcframework/ios-arm64/mParticle_Apple_SDK.framework
#

# This script is built almost entirely out of command substitutions feeding report
# text, the same style measure_size.sh uses. SC2311/SC2312 fire on every one of them
# and disabling them per-line would be 35 comments, so disable them for the file.
# shellcheck disable=SC2311,SC2312

set -e

# Sections holding Swift runtime metadata. Emitted per type regardless of use and,
# for public symbols, not strippable - so this total is the cost of Swift's runtime
# model rather than of any executed code.
SWIFT_SECTIONS="__swift5_typeref __swift5_reflstr __swift5_assocty __swift5_fieldmd __swift5_proto __swift5_protos __swift5_types __swift5_builtin __swift5_capture __swift5_mpenum __swift5_replace __swift5_replac2 __constg_swiftt"

# Sections holding Objective-C metadata. Every @objc declaration - including Swift
# ones - contributes here, and none of it can be dead-stripped.
OBJC_SECTIONS="__objc_classlist __objc_classname __objc_classrefs __objc_const __objc_data __objc_catlist __objc_ivar __objc_methlist __objc_methname __objc_methtype __objc_nlclslist __objc_nlcatlist __objc_protolist __objc_protorefs __objc_selrefs __objc_stubs __objc_superrefs __objc_imageinfo __objc_intobj __objc_arraydata __objc_arrayobj __objc_dictobj __cfstring"

# Third-party / dependency modules to attribute separately, as Swift mangling prefixes.
TRACKED_MODULES="13RoktContracts 25mParticle_Apple_SDK_Swift"

FRAMEWORK=""
OUTPUT_JSON=false
TOP_N=25

while [[ $# -gt 0 ]]; do
	case $1 in
	--json)
		OUTPUT_JSON=true
		shift
		;;
	--top)
		TOP_N="$2"
		shift 2
		;;
	-*)
		echo "Unknown argument: $1" >&2
		exit 1
		;;
	*)
		FRAMEWORK="$1"
		shift
		;;
	esac
done

if [[ -z ${FRAMEWORK} ]] || [[ ! -d ${FRAMEWORK} ]]; then
	echo "Usage: $0 <framework-path> [--json] [--top N]" >&2
	exit 1
fi

# Every Mach-O image the framework ships: the framework binary itself, plus any
# framework nested under Frameworks/ (which ships as a separate dylib, with its own
# headers, __LINKEDIT and code signature).
list_images() {
	local fw="$1"
	local name
	name=$(basename "${fw}" .framework)
	if [[ -f "${fw}/${name}" ]]; then
		echo "${fw}/${name}"
	fi
	local nested
	for nested in "${fw}"/Frameworks/*.framework; do
		if [[ -d ${nested} ]]; then
			list_images "${nested}"
		fi
	done
}

# "SEG <name> <bytes>" / "SEC <segment> <name> <bytes>" for one image.
image_layout() {
	size -m "$1" 2>/dev/null | awk '
		/^Segment / { seg = $2; sub(/:$/, "", seg); print "SEG", seg, $3; next }
		/^[[:space:]]+Section / { sec = $2; sub(/:$/, "", sec); print "SEC", seg, sec, $3 }
	'
}

# Total bytes across a named set of sections.
sum_sections() {
	local layout="$1"
	local wanted="$2"
	echo "${layout}" | awk -v wanted="${wanted}" '
		BEGIN { n = split(wanted, w, " "); for (i = 1; i <= n; i++) keep[w[i]] = 1 }
		$1 == "SEC" && ($3 in keep) { total += $4 }
		END { print total + 0 }
	'
}

segment_bytes() {
	echo "$1" | awk -v seg="$2" '$1 == "SEG" && $2 == seg { print $3 + 0; found = 1 } END { if (!found) print 0 }'
}

# Per-symbol sizes, approximated by address delta.
#
# Mach-O symbol tables carry no size field, so llvm-nm --print-size reports 0 for
# every symbol. Sizes are approximated instead from the distance to the next symbol
# in the same section, using nm -m to get each symbol's (segment,section).
#
# Pairing per section rather than per symbol type matters: type letters like "S"
# cover several sections at once, so pairing by type alone straddles section
# boundaries and reports one symbol with the size of the whole gap. The last symbol
# in each section has no successor and is dropped, so totals here run slightly
# under the true figure.
symbol_sizes() {
	nm -m -n "$1" 2>/dev/null |
		perl -ne '
			next unless /^([0-9a-fA-F]+)\s+\((__[A-Za-z_]+),(__[A-Za-z0-9_.]+)\)\s+(.*)$/;
			my ($addr, $sect, $rest) = (hex($1), "$2,$3", $4);
			# Strip nm -m attribute words so what is left is the symbol name. Taking the
			# last whitespace field instead would truncate Objective-C selectors.
			$rest =~ s/^(?:\(was\ a\ private\ external\)\s*|non-external\s*|private\ external\s*|external\s*|weak\ external\s*|weak\ definition\s*|absolute\s*|no\ dead\ strip\s*|referenced\ dynamically\s*|\[[^\]]*\]\s*)+//;
			next unless length $rest;
			if (defined $prev_addr{$sect}) {
				my $size = $addr - $prev_addr{$sect};
				# A single symbol larger than this is an address-delta artifact, not a
				# real symbol: some sections contain far-apart absolute addresses.
				printf("%d\t%s\n", $size, $prev_name{$sect}) if $size > 0 && $size < 1048576;
			}
			$prev_addr{$sect} = $addr;
			$prev_name{$sect} = $rest;
		'
}

# Bytes attributable to one module, matched on its Swift mangling prefix.
module_bytes() {
	echo "$1" | awk -F'\t' -v m="$2" 'index($2, m) { total += $1 } END { print total + 0 }'
}

human() {
	awk -v b="$1" 'BEGIN {
		if (b >= 1048576) printf "%.2f MB", b / 1048576
		else if (b >= 1024) printf "%.1f KB", b / 1024
		else printf "%d B", b
	}'
}

IMAGES=$(list_images "${FRAMEWORK}")
IMAGE_COUNT=$(echo "${IMAGES}" | grep -c . || true)

TOTAL_FILE=0
TOTAL_TEXT=0
TOTAL_SWIFT_META=0
TOTAL_OBJC_META=0
TOTAL_LINKEDIT=0
TOTAL_EXPORTS=0
JSON_IMAGES=""

for image in ${IMAGES}; do
	name=$(basename "${image}")
	file_size=$(stat -f%z "${image}")
	layout=$(image_layout "${image}")
	symbols=$(symbol_sizes "${image}")

	text=$(sum_sections "${layout}" "__text")
	swift_meta=$(sum_sections "${layout}" "${SWIFT_SECTIONS}")
	objc_meta=$(sum_sections "${layout}" "${OBJC_SECTIONS}")
	linkedit=$(segment_bytes "${layout}" "__LINKEDIT")
	# -U suppresses undefined symbols. Without it, nm -g also lists what the image
	# *imports*, which inflated this count by 8-17% and made it move when a dependency
	# changed. -gU matches dyld_info -exports exactly.
	exports=$(nm -gU "${image}" 2>/dev/null | grep -c . || true)
	archs=$(lipo -archs "${image}" 2>/dev/null || echo "unknown")

	TOTAL_FILE=$((TOTAL_FILE + file_size))
	TOTAL_TEXT=$((TOTAL_TEXT + text))
	TOTAL_SWIFT_META=$((TOTAL_SWIFT_META + swift_meta))
	TOTAL_OBJC_META=$((TOTAL_OBJC_META + objc_meta))
	TOTAL_LINKEDIT=$((TOTAL_LINKEDIT + linkedit))
	TOTAL_EXPORTS=$((TOTAL_EXPORTS + exports))

	if [[ ${OUTPUT_JSON} == "false" ]]; then
		echo ""
		echo "=============================================================="
		echo "Image: ${name}  (${archs})"
		echo "=============================================================="
		echo "  File size:        $(human "${file_size}")"
		echo "  __text:           $(human "${text}")"
		echo "  Swift metadata:   $(human "${swift_meta}")"
		echo "  ObjC metadata:    $(human "${objc_meta}")"
		echo "  __LINKEDIT:       $(human "${linkedit}")"
		echo "  Exported symbols: ${exports}"
		echo ""
		echo "  Module attribution:"
		for mod in ${TRACKED_MODULES}; do
			mod_total=$(module_bytes "${symbols}" "${mod}")
			printf "    %-28s %s\n" "${mod#[0-9][0-9]}" "$(human "${mod_total}")"
		done
		echo ""
		echo "  Segments and sections:"
		echo "${layout}" | awk '
			$1 == "SEG" { printf "    %-18s %10d\n", $2, $3; next }
			$1 == "SEC" { printf "      %-16s %10d\n", $3, $4 }
		'
		echo ""
		echo "  Top ${TOP_N} symbols (size approximated by address delta):"
		echo "${symbols}" | sort -rn | head -"${TOP_N}" | while IFS=$'\t' read -r sz sym; do
			printf "    %8d  %s\n" "${sz}" "$(xcrun swift-demangle --compact "${sym}" 2>/dev/null || echo "${sym}")"
		done
	else
		JSON_IMAGES="${JSON_IMAGES}${JSON_IMAGES:+,}{\"name\":\"${name}\",\"file_bytes\":${file_size},\"text_bytes\":${text},\"swift_metadata_bytes\":${swift_meta},\"objc_metadata_bytes\":${objc_meta},\"linkedit_bytes\":${linkedit},\"exported_symbols\":${exports}}"
	fi
done

if [[ ${OUTPUT_JSON} == "true" ]]; then
	echo "{\"images\":[${JSON_IMAGES}],\"image_count\":${IMAGE_COUNT},\"total_file_bytes\":${TOTAL_FILE},\"total_text_bytes\":${TOTAL_TEXT},\"total_swift_metadata_bytes\":${TOTAL_SWIFT_META},\"total_objc_metadata_bytes\":${TOTAL_OBJC_META},\"total_linkedit_bytes\":${TOTAL_LINKEDIT},\"total_exported_symbols\":${TOTAL_EXPORTS}}"
else
	echo ""
	echo "=============================================================="
	echo "Totals across ${IMAGE_COUNT} Mach-O image(s)"
	echo "=============================================================="
	printf "  %-20s %s\n" "File size" "$(human "${TOTAL_FILE}")"
	printf "  %-20s %s\n" "__text" "$(human "${TOTAL_TEXT}")"
	printf "  %-20s %s\n" "Swift metadata" "$(human "${TOTAL_SWIFT_META}")"
	printf "  %-20s %s\n" "ObjC metadata" "$(human "${TOTAL_OBJC_META}")"
	printf "  %-20s %s\n" "__LINKEDIT" "$(human "${TOTAL_LINKEDIT}")"
	printf "  %-20s %s\n" "Exported symbols" "${TOTAL_EXPORTS}"
	echo ""
fi
