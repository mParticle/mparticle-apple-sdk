#!/usr/bin/env bash

# shellcheck disable=SC2016,SC2310,SC2312

set -euo pipefail

readonly COMMENT_MARKER='<!-- swift-migration-progress -->'
readonly BAR_WIDTH=10
readonly RETAINED_MANIFEST='Tools/swift-migration-retained-objc.txt'

CLEANUP_DIRS=()
CREATED_TEMP_DIR=''

usage() {
	cat <<'EOF'
Usage:
  Tools/swift-migration-progress.sh report \
    --repo <path> --base <sha> --head <sha> --cloc <path> --output <markdown>
  Tools/swift-migration-progress.sh selftest --cloc <path>
EOF
}

fail() {
	printf 'swift-migration-progress: %s\n' "$*" >&2
	exit 1
}

cleanup() {
	local directory

	for directory in "${CLEANUP_DIRS[@]}"; do
		if [[ -n ${directory} && -d ${directory} ]]; then
			rm -rf -- "${directory}"
		fi
	done
}

trap cleanup EXIT

create_temp_dir() {
	CREATED_TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/swift-migration-progress.XXXXXX")
	CLEANUP_DIRS+=("${CREATED_TEMP_DIR}")
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

validate_cloc() {
	local cloc_path=$1

	[[ -f ${cloc_path} ]] || fail "cloc not found: ${cloc_path}"
	[[ -x ${cloc_path} ]] || fail "cloc is not executable: ${cloc_path}"
}

append_matching_files() {
	local root=$1
	local output=$2

	[[ -d ${root} ]] || return 0
	find "${root}" -type f \( -name '*.swift' -o -name '*.m' -o -name '*.mm' \) -print >>"${output}"
}

build_bucket_file_list() {
	local revision_root=$1
	local bucket=$2
	local output=$3
	local objc_root="${revision_root}/mParticle-Apple-SDK"
	local swift_root="${revision_root}/mParticle-Apple-SDK-Swift/Sources"

	: >"${output}"

	case "${bucket}" in
	core)
		if [[ -d ${objc_root} ]]; then
			find "${objc_root}" \
				\( -path "${objc_root}/Kits" -o -path "${objc_root}/Libraries" \) -prune -o \
				-type f \( -name '*.m' -o -name '*.mm' \) -print >>"${output}"
		fi
		if [[ -d ${swift_root} ]]; then
			find "${swift_root}" -path "${swift_root}/Kits" -prune -o \
				-type f -name '*.swift' -print >>"${output}"
		fi
		;;
	kits)
		# SDK kit infrastructure (mParticle-Apple-SDK/Kits and its Swift Sources
		# counterpart) plus every standalone kit package below Kits/**/Sources.
		# The short-term goal has no target here; only the long-term one does.
		append_matching_files "${objc_root}/Kits" "${output}"
		append_matching_files "${swift_root}/Kits" "${output}"
		if [[ -d "${revision_root}/Kits" ]]; then
			find "${revision_root}/Kits" -type f \
				\( -name '*.swift' -o -name '*.m' -o -name '*.mm' \) \
				-path '*/Sources/*' -print >>"${output}"
		fi
		;;
	*)
		fail "unknown source bucket: ${bucket}"
		;;
	esac
}

# Trims one manifest line and prints the path it holds, or nothing for a blank
# line or a comment.
clean_manifest_line() {
	local path=${1%$'\r'}

	path=${path#"${path%%[![:space:]]*}"}
	path=${path%"${path##*[![:space:]]}"}
	if [[ ${path} == '#'* ]]; then
		return 0
	fi
	printf '%s' "${path}"
}

# Reads the reviewed list of Objective-C implementations the migration will not
# delete and writes the validated, repository-relative paths to a lookup file.
# A stale, misplaced, or non-Objective-C entry is a hard failure so the manifest
# cannot silently stop matching the tree it describes.
load_retained_manifest() {
	local revision_root=$1
	local output=$2
	local manifest="${revision_root}/${RETAINED_MANIFEST}"
	local line
	local path
	local bucket

	: >"${output}"
	if [[ ! -f ${manifest} ]]; then
		return 0
	fi

	while IFS= read -r line || [[ -n ${line} ]]; do
		path=$(clean_manifest_line "${line}")
		if [[ -z ${path} ]]; then
			continue
		fi
		if [[ ${path} != *.m && ${path} != *.mm ]]; then
			fail "retained manifest entry is not an Objective-C implementation: ${path}"
		fi
		bucket=$(classify_path "${path}")
		if [[ -z ${bucket} ]]; then
			fail "retained manifest entry is outside every counted bucket: ${path}"
		fi
		if [[ ! -f "${revision_root}/${path}" ]]; then
			fail "retained manifest entry does not exist: ${path}"
		fi
		printf '%s\n' "${path}" >>"${output}"
	done <"${manifest}"
}

# The head revision owns the scope definition, but path matching alone would
# misread a retained implementation this pull request renamed or deleted: its
# base-side path is absent from the head manifest and would count as in-scope,
# inflating short-term progress with work nobody did. Carry over the base
# manifest entries whose file no longer exists at head, which covers both the
# rename and the boundary-deletion case. Entries whose file survives at head
# are left out on purpose — dropping one is a deliberate reclassification, and
# the head definition should then apply to both revisions.
#
# The base manifest is read leniently. It may be missing entirely, or describe
# paths that predate the current layout, and neither is this comparison's
# problem to police.
load_base_retained_paths() {
	local base_root=$1
	local head_root=$2
	local head_paths=$3
	local output=$4
	local manifest="${base_root}/${RETAINED_MANIFEST}"
	local line
	local path

	cp "${head_paths}" "${output}"
	if [[ ! -f ${manifest} ]]; then
		return 0
	fi

	while IFS= read -r line || [[ -n ${line} ]]; do
		path=$(clean_manifest_line "${line}")
		if [[ -z ${path} ]]; then
			continue
		fi
		if [[ -f "${base_root}/${path}" && ! -f "${head_root}/${path}" ]]; then
			printf '%s\n' "${path}" >>"${output}"
		fi
	done <"${manifest}"
}

# Splits one bucket's absolute file list into the in-scope and retained lists
# cloc is run against. Matching happens on repository-relative paths so the
# manifest reads the same as the repository layout.
partition_bucket_file_list() {
	local revision_root=$1
	local combined=$2
	local retained_paths=$3
	local inscope_output=$4
	local retained_output=$5
	local relative="${combined}.relative"

	awk -v prefix="${revision_root}/" '
		index($0, prefix) == 1 { print substr($0, length(prefix) + 1) }
	' "${combined}" >"${relative}"

	if [[ -s ${retained_paths} ]]; then
		grep -Fxf "${retained_paths}" "${relative}" >"${relative}.retained" || true
		grep -Fxvf "${retained_paths}" "${relative}" >"${relative}.inscope" || true
	else
		: >"${relative}.retained"
		cp "${relative}" "${relative}.inscope"
	fi

	awk -v prefix="${revision_root}/" '{ print prefix $0 }' "${relative}.inscope" >"${inscope_output}"
	awk -v prefix="${revision_root}/" '{ print prefix $0 }' "${relative}.retained" >"${retained_output}"
}

CLOC_SWIFT=0
CLOC_OBJC=0

count_file_list() {
	local file_list=$1
	local cloc_path=$2
	local json=$3
	local counts
	local objc
	local objcpp

	CLOC_SWIFT=0
	CLOC_OBJC=0
	if [[ ! -s ${file_list} ]]; then
		return
	fi

	"${cloc_path}" \
		--quiet \
		--skip-uniqueness \
		--json \
		--include-lang=Swift,Objective-C,Objective-C++ \
		--list-file="${file_list}" >"${json}"

	counts=$(jq -r '[(.Swift.code // 0), (."Objective-C".code // 0), (."Objective-C++".code // 0)] | @tsv' "${json}")
	IFS=$'\t' read -r CLOC_SWIFT objc objcpp <<<"${counts}"
	CLOC_OBJC=$((objc + objcpp))
}

COUNT_SWIFT=0
COUNT_OBJC=0
COUNT_OBJC_RETAINED=0

count_bucket() {
	local revision_root=$1
	local bucket=$2
	local cloc_path=$3
	local working_dir=$4
	local retained_paths=$5
	local combined="${working_dir}/${bucket}-files.txt"
	local inscope="${working_dir}/${bucket}-files-in-scope.txt"
	local retained="${working_dir}/${bucket}-files-retained.txt"

	mkdir -p "${working_dir}"
	build_bucket_file_list "${revision_root}" "${bucket}" "${combined}"
	partition_bucket_file_list \
		"${revision_root}" "${combined}" "${retained_paths}" "${inscope}" "${retained}"

	count_file_list "${inscope}" "${cloc_path}" "${working_dir}/${bucket}-cloc.json"
	COUNT_SWIFT=${CLOC_SWIFT}
	COUNT_OBJC=${CLOC_OBJC}

	count_file_list "${retained}" "${cloc_path}" "${working_dir}/${bucket}-cloc-retained.json"
	COUNT_OBJC_RETAINED=${CLOC_OBJC}
}

materialize_revision() {
	local repo=$1
	local revision=$2
	local destination=$3

	mkdir -p "${destination}"
	git -C "${repo}" archive --format=tar "${revision}" | tar -xf - -C "${destination}"
}

percentage() {
	local swift=$1
	local objc=$2

	awk -v swift="${swift}" -v objc="${objc}" 'BEGIN {
        total = swift + objc
        if (total == 0) {
            printf "0.00"
        } else {
            printf "%.2f", (swift / total) * 100
        }
    }'
}

format_integer() {
	perl -e '$number = shift; 1 while $number =~ s/^(-?\d+)(\d{3})/$1,$2/; print $number' "$1"
}

# Retained Objective-C is a floor, not a target, so it gets a plain SLOC figure
# and a signed delta only when the boundary actually thinned or grew.
format_retained() {
	local base=$1
	local head=$2

	if ((head == base)); then
		format_integer "${head}"
		return
	fi
	printf '%s (%+d)' "$(format_integer "${head}")" "$((head - base))"
}

progress_bar() {
	local percent=$1
	local units
	local full_cells
	local partial_units
	local partial_cell=''
	local index=0
	local bar=''

	units=$(awk -v percent="${percent}" -v width="${BAR_WIDTH}" 'BEGIN {
		value = (percent / 100) * width
		full = int(value)
		partial = int(((value - full) * 8) + 0.5)
		if (partial == 8) {
			full += 1
			partial = 0
		}
		if (full < 0) full = 0
		if (full > width) full = width
		printf "%d\t%d", full, partial
	}')
	IFS=$'\t' read -r full_cells partial_units <<<"${units}"

	case "${partial_units}" in
	1) partial_cell='▏' ;;
	2) partial_cell='▎' ;;
	3) partial_cell='▍' ;;
	4) partial_cell='▌' ;;
	5) partial_cell='▋' ;;
	6) partial_cell='▊' ;;
	7) partial_cell='▉' ;;
	*) ;;
	esac

	while ((index < BAR_WIDTH)); do
		if ((index < full_cells)); then
			bar+='█'
		elif ((index == full_cells)) && [[ -n ${partial_cell} ]]; then
			bar+="${partial_cell}"
		else
			bar+='░'
		fi
		index=$((index + 1))
	done

	printf '%s' "${bar}"
}

DELTA_ICON=''
DELTA_TEXT=''

calculate_delta() {
	local base=$1
	local head=$2
	local delta

	delta=$(awk -v base="${base}" -v head="${head}" 'BEGIN { printf "%+.2f", head - base }')
	case "${delta}" in
	+0.00 | -0.00)
		DELTA_ICON='➖'
		DELTA_TEXT='0.00'
		;;
	+*)
		DELTA_ICON='🚀'
		DELTA_TEXT=${delta}
		;;
	*)
		DELTA_ICON='↩️'
		DELTA_TEXT=${delta}
		;;
	esac
}

classify_path() {
	local path=$1

	case "${path}" in
	Kits/*/Sources/* | mParticle-Apple-SDK-Swift/Sources/Kits/* | mParticle-Apple-SDK/Kits/*)
		# SDK kit infrastructure and every standalone kit package. The
		# short-term goal excludes all of it; the long-term one counts it.
		printf 'kits'
		;;
	mParticle-Apple-SDK-Swift/Sources/*)
		printf 'core'
		;;
	mParticle-Apple-SDK/Libraries/*) ;;
	mParticle-Apple-SDK/*)
		printf 'core'
		;;
	*) ;;
	esac
}

CORE_SWIFT_ADDED=0
CORE_OBJC_REMOVED=0
KITS_SWIFT_ADDED=0
KITS_OBJC_REMOVED=0

add_swift_movement() {
	local bucket=$1
	local lines=$2

	case "${bucket}" in
	core) CORE_SWIFT_ADDED=$((CORE_SWIFT_ADDED + lines)) ;;
	kits) KITS_SWIFT_ADDED=$((KITS_SWIFT_ADDED + lines)) ;;
	*) ;;
	esac
}

add_objc_movement() {
	local bucket=$1
	local lines=$2

	case "${bucket}" in
	core) CORE_OBJC_REMOVED=$((CORE_OBJC_REMOVED + lines)) ;;
	kits) KITS_OBJC_REMOVED=$((KITS_OBJC_REMOVED + lines)) ;;
	*) ;;
	esac
}

measure_diff_movement() {
	local repo=$1
	local base=$2
	local head=$3
	local diff_file=$4
	local added
	local deleted
	local first_path
	local old_path
	local new_path
	local bucket

	CORE_SWIFT_ADDED=0
	CORE_OBJC_REMOVED=0
	KITS_SWIFT_ADDED=0
	KITS_OBJC_REMOVED=0

	git -C "${repo}" diff --find-renames --numstat -z "${base}...${head}" -- >"${diff_file}"
	while IFS=$'\t' read -r -d '' added deleted first_path; do
		old_path=${first_path}
		new_path=${first_path}

		if [[ -z ${first_path} ]]; then
			IFS= read -r -d '' old_path
			IFS= read -r -d '' new_path
		fi

		if [[ ${added} != '-' && ${added} != *[!0-9]* && ${new_path} == *.swift ]]; then
			bucket=$(classify_path "${new_path}")
			add_swift_movement "${bucket}" "${added}"
		fi

		if [[ ${deleted} != '-' && ${deleted} != *[!0-9]* && (${old_path} == *.m || ${old_path} == *.mm) ]]; then
			bucket=$(classify_path "${old_path}")
			add_objc_movement "${bucket}" "${deleted}"
		fi
	done <"${diff_file}"
}

# Emits one goal row: the given Swift total against the given Objective-C
# total for that goal. The two goals differ in which buckets count at all
# (short term excludes kits entirely; long term includes everything), not
# just in whether a retained surface is added on top of the same buckets.
write_progress_row() {
	local goal=$1
	local base_swift=$2
	local base_objc=$3
	local head_swift=$4
	local head_objc=$5
	local base_percent
	local head_percent
	local bar

	base_percent=$(percentage "${base_swift}" "${base_objc}")
	head_percent=$(percentage "${head_swift}" "${head_objc}")
	bar=$(progress_bar "${head_percent}")
	calculate_delta "${base_percent}" "${head_percent}"
	printf '| %s | `%s` | %s%% | %s%% | %s | %s | %s %s pp |\n' \
		"${goal}" "${bar}" "${base_percent}" "${head_percent}" \
		"$(format_integer "${head_swift}")" "$(format_integer "${head_objc}")" \
		"${DELTA_ICON}" "${DELTA_TEXT}"
}

write_report() {
	local output=$1
	local base=$2
	local head=$3
	local cloc_version=$4
	local short_base=${base:0:12}
	local short_head=${head:0:12}
	local base_long_swift=$((BASE_CORE_SWIFT + BASE_KITS_SWIFT))
	local base_long_objc=$((BASE_CORE_OBJC + BASE_CORE_OBJC_RETAINED + BASE_KITS_OBJC + BASE_KITS_OBJC_RETAINED))
	local head_long_swift=$((HEAD_CORE_SWIFT + HEAD_KITS_SWIFT))
	local head_long_objc=$((HEAD_CORE_OBJC + HEAD_CORE_OBJC_RETAINED + HEAD_KITS_OBJC + HEAD_KITS_OBJC_RETAINED))

	mkdir -p "$(dirname "${output}")"
	{
		printf '%s\n' "${COMMENT_MARKER}"
		printf '%s\n\n' '## 🐦 Swift Migration Progress'
		printf 'Production implementation code at `%s` compared with `%s`.\n\n' "${short_head}" "${short_base}"
		printf '%s\n' '| Goal | Progress | Base | This PR | Swift SLOC | Objective-C remaining | Change |'
		printf '%s\n' '|---|:---:|---:|---:|---:|---:|---:|'
		write_progress_row 'Short term — everything except kits and the public API' \
			"${BASE_CORE_SWIFT}" "${BASE_CORE_OBJC}" \
			"${HEAD_CORE_SWIFT}" "${HEAD_CORE_OBJC}"
		write_progress_row 'Long term — everything, including all kits and the public API' \
			"${base_long_swift}" "${base_long_objc}" \
			"${head_long_swift}" "${head_long_objc}"
		printf '\n'
		printf 'Objective-C retained by design in Core SDK (the permanent public API surface): %s.\n\n' \
			"$(format_retained "${BASE_CORE_OBJC_RETAINED}" "${HEAD_CORE_OBJC_RETAINED}")"
		printf '%s\n\n' "### This PR's code movement"
		printf '%s\n' '| Area | Swift lines added | Objective-C lines removed |'
		printf '%s\n' '|---|---:|---:|'
		printf '| Core SDK | %s | %s |\n' \
			"$(format_integer "${CORE_SWIFT_ADDED}")" "$(format_integer "${CORE_OBJC_REMOVED}")"
		printf '| Kits (infrastructure + standalone) | %s | %s |\n\n' \
			"$(format_integer "${KITS_SWIFT_ADDED}")" "$(format_integer "${KITS_OBJC_REMOVED}")"
		printf '%s\n\n' '<details>'
		printf '%s\n\n' '<summary>How this is measured</summary>'
		printf '%s\n' '- Current composition uses production source lines of code (SLOC) from `cloc`; comments and blank lines are excluded.'
		printf '%s\n' '- **Short term** is Core SDK only, excluding the Objective-C the migration will not delete (the retained public API surface). 100% here is the end of this project.'
		printf '%s\n' '- **Long term** is everything: Core SDK, SDK kit infrastructure, every standalone kit, and the retained public API surface. 100% here means the public API itself becomes Swift and every kit converts, which is a breaking change reserved for a future major release.'
		printf '%s\n' '- The retained public API surface (`Tools/swift-migration-retained-objc.txt`) is the entire gap between the two goals within Core SDK. Thinning a retained wrapper moves the long-term goal and the retained figure, not the short-term one.'
		printf '%s\n' '- Both revisions are measured with the manifest from the head revision, so a manifest edit does not by itself move the reported change. A retained file this pull request renamed or deleted still counts as retained at the base.'
		printf '%s\n' '- Pull request movement uses physical additions/deletions from `git diff base...head --numstat`; it counts retained files too and is intentionally separate from SLOC totals.'
		printf '%s\n' '- Core SDK excludes SDK kit infrastructure and vendored libraries. Kits covers SDK kit infrastructure (`mParticle-Apple-SDK/Kits`) and every standalone kit below `Kits/**/Sources` — no kit has a short-term goal.'
		printf '%s\n' '- Tests, examples, headers, build outputs, vendored libraries, and the `MParticle/Sources` Swift overlay are excluded.'
		printf '%s\n\n' '- Objective-C++ (`.mm`) is included in the Objective-C figures and removed counts.'
		printf 'Generated with `cloc` %s. This report is informational and does not gate migration direction.\n\n' "${cloc_version}"
		printf '%s\n' '</details>'
	} >"${output}"
}

BASE_CORE_SWIFT=0
BASE_CORE_OBJC=0
BASE_CORE_OBJC_RETAINED=0
BASE_KITS_SWIFT=0
BASE_KITS_OBJC=0
BASE_KITS_OBJC_RETAINED=0
HEAD_CORE_SWIFT=0
HEAD_CORE_OBJC=0
HEAD_CORE_OBJC_RETAINED=0
HEAD_KITS_SWIFT=0
HEAD_KITS_OBJC=0
HEAD_KITS_OBJC_RETAINED=0

generate_report() {
	local repo=$1
	local base=$2
	local head=$3
	local cloc_path=$4
	local output=$5
	local workspace
	local base_root
	local head_root
	local base_commit
	local head_commit
	local cloc_version
	local head_retained_paths
	local base_retained_paths

	[[ -d ${repo} ]] || fail "repository not found: ${repo}"
	git -C "${repo}" rev-parse --git-dir >/dev/null 2>&1 || fail "not a Git repository: ${repo}"
	git -C "${repo}" cat-file -e "${base}^{commit}" 2>/dev/null || fail "base revision is not a commit: ${base}"
	git -C "${repo}" cat-file -e "${head}^{commit}" 2>/dev/null || fail "head revision is not a commit: ${head}"
	validate_cloc "${cloc_path}"
	base_commit=$(git -C "${repo}" rev-parse "${base}^{commit}")
	head_commit=$(git -C "${repo}" rev-parse "${head}^{commit}")

	create_temp_dir
	workspace=${CREATED_TEMP_DIR}
	base_root="${workspace}/base"
	head_root="${workspace}/head"
	materialize_revision "${repo}" "${base_commit}" "${base_root}"
	materialize_revision "${repo}" "${head_commit}" "${head_root}"

	# The head revision owns the scope definition for both sides of the
	# comparison, so editing the manifest cannot masquerade as code movement.
	head_retained_paths="${workspace}/retained-paths-head.txt"
	base_retained_paths="${workspace}/retained-paths-base.txt"
	load_retained_manifest "${head_root}" "${head_retained_paths}"
	load_base_retained_paths \
		"${base_root}" "${head_root}" "${head_retained_paths}" "${base_retained_paths}"

	count_bucket "${base_root}" core "${cloc_path}" "${workspace}/base-core" "${base_retained_paths}"
	BASE_CORE_SWIFT=${COUNT_SWIFT}
	BASE_CORE_OBJC=${COUNT_OBJC}
	BASE_CORE_OBJC_RETAINED=${COUNT_OBJC_RETAINED}
	count_bucket "${base_root}" kits "${cloc_path}" "${workspace}/base-kits" "${base_retained_paths}"
	BASE_KITS_SWIFT=${COUNT_SWIFT}
	BASE_KITS_OBJC=${COUNT_OBJC}
	BASE_KITS_OBJC_RETAINED=${COUNT_OBJC_RETAINED}

	count_bucket "${head_root}" core "${cloc_path}" "${workspace}/head-core" "${head_retained_paths}"
	HEAD_CORE_SWIFT=${COUNT_SWIFT}
	HEAD_CORE_OBJC=${COUNT_OBJC}
	HEAD_CORE_OBJC_RETAINED=${COUNT_OBJC_RETAINED}
	count_bucket "${head_root}" kits "${cloc_path}" "${workspace}/head-kits" "${head_retained_paths}"
	HEAD_KITS_SWIFT=${COUNT_SWIFT}
	HEAD_KITS_OBJC=${COUNT_OBJC}
	HEAD_KITS_OBJC_RETAINED=${COUNT_OBJC_RETAINED}

	measure_diff_movement "${repo}" "${base_commit}" "${head_commit}" "${workspace}/movement-numstat"
	cloc_version=$("${cloc_path}" --version | tr -d '\r\n')
	write_report "${output}" "${base_commit}" "${head_commit}" "${cloc_version}"
}

write_fixture_file() {
	local root=$1
	local relative_path=$2
	local contents=$3
	local path="${root}/${relative_path}"

	mkdir -p "$(dirname "${path}")"
	printf '%s' "${contents}" >"${path}"
}

assert_contains() {
	local file=$1
	local expected=$2

	grep -Fq "${expected}" "${file}" || fail "self-test expected to find: ${expected}"
}

assert_manifest_rejects() {
	local root=$1
	local expectation=$2
	local log="${root}/rejection.log"

	if (load_retained_manifest "${root}" "${root}/validated.txt") >"${log}" 2>&1; then
		fail "self-test expected a rejected retained manifest: ${expectation}"
	fi
	assert_contains "${log}" "${expectation}"
}

# Exercises manifest parsing and validation against throwaway directory trees,
# independent of the Git fixture.
run_manifest_validation_selftest() {
	local workspace=$1
	local accepted="${workspace}/accepted"
	local missing="${workspace}/missing"
	local not_objc="${workspace}/not-objc"
	local unbucketed="${workspace}/unbucketed"
	local vendored="${workspace}/vendored"
	local validated="${accepted}/validated.txt"

	write_fixture_file "${accepted}" 'mParticle-Apple-SDK/Utils/Kept.m' $'@implementation Kept\n@end\n'
	write_fixture_file "${accepted}" "${RETAINED_MANIFEST}" \
		$'# leading comment\n\n   mParticle-Apple-SDK/Utils/Kept.m   \n\n# trailing comment\n'
	load_retained_manifest "${accepted}" "${validated}"
	[[ "$(wc -l <"${validated}" | tr -d ' ')" == '1' ]] ||
		fail 'self-test expected exactly one accepted retained manifest entry'
	assert_contains "${validated}" 'mParticle-Apple-SDK/Utils/Kept.m'

	write_fixture_file "${missing}" "${RETAINED_MANIFEST}" $'mParticle-Apple-SDK/Utils/Gone.m\n'
	assert_manifest_rejects "${missing}" 'retained manifest entry does not exist'

	write_fixture_file "${not_objc}" 'mParticle-Apple-SDK-Swift/Sources/Kept.swift' $'let kept = 1\n'
	write_fixture_file "${not_objc}" "${RETAINED_MANIFEST}" $'mParticle-Apple-SDK-Swift/Sources/Kept.swift\n'
	assert_manifest_rejects "${not_objc}" 'not an Objective-C implementation'

	write_fixture_file "${unbucketed}" 'UnitTests/ObjCTests/Kept.m' $'@implementation Kept\n@end\n'
	write_fixture_file "${unbucketed}" "${RETAINED_MANIFEST}" $'UnitTests/ObjCTests/Kept.m\n'
	assert_manifest_rejects "${unbucketed}" 'outside every counted bucket'

	write_fixture_file "${vendored}" 'mParticle-Apple-SDK/Libraries/Vendor/Kept.m' $'@implementation Kept\n@end\n'
	write_fixture_file "${vendored}" "${RETAINED_MANIFEST}" $'mParticle-Apple-SDK/Libraries/Vendor/Kept.m\n'
	assert_manifest_rejects "${vendored}" 'outside every counted bucket'
}

run_selftest() {
	local cloc_path=$1
	local fixture
	local base_sha
	local migration_sha
	local flat_sha
	local regression_sha
	local thin_sha
	local renamed_sha
	local retired_sha
	local advanced_base_sha
	local pr_head_sha
	local migration_report
	local flat_report
	local regression_report
	local thin_report
	local renamed_report
	local retired_report
	local divergent_report
	local flat_count

	validate_cloc "${cloc_path}"
	create_temp_dir
	fixture=${CREATED_TEMP_DIR}

	git -C "${fixture}" init -q
	git -C "${fixture}" config user.name 'Swift Migration Self-Test'
	git -C "${fixture}" config user.email 'swift-migration-selftest@example.invalid'

	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Data Model/Core.m' $'// comment\n\n@implementation Core\n@end\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Data Model/Space Name.m' $'@implementation Spaced\n@end\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Event/Core.mm' $'@implementation ObjectiveCpp\n@end\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK-Swift/Sources/Core.swift' $'// comment\n\nlet core = 1\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK-Swift/Sources/Rename Me.swift' $'let renamed = 1\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Kits/Kit.m' $'@implementation Kit\n@end\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK-Swift/Sources/Kits/Kit.swift' $'let kit = 1\n'
	write_fixture_file "${fixture}" 'Kits/vendor/vendor-1/Sources/Kit.m' $'@implementation Standalone\n@end\n'
	write_fixture_file "${fixture}" 'Kits/vendor/vendor-1/Sources/Kit.swift' $'let standalone = 1\n'
	write_fixture_file "${fixture}" 'Kits/rokt/rokt/Sources/Kit.m' $'@implementation Rokt\n@end\n'
	write_fixture_file "${fixture}" 'Kits/rokt-sdk-plus/plus/Sources/Kit.swift' $'let roktPlus = 1\n'
	write_fixture_file "${fixture}" 'UnitTests/SwiftTests/Excluded.swift' $'let excludedTest = 1\nlet excludedTestTwo = 2\n'
	write_fixture_file "${fixture}" 'Example/Excluded.m' $'int excludedExample(void) { return 1; }\n'
	write_fixture_file "${fixture}" 'build/Generated/Excluded.swift' $'let excludedBuildOutput = 1\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Include/Excluded.h' $'int excludedHeader(void);\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Libraries/Vendor/Excluded.m' $'int excludedVendor(void) { return 1; }\n'
	write_fixture_file "${fixture}" 'MParticle/Sources/Excluded.swift' $'let excludedOverlay = 1\n'
	write_fixture_file "${fixture}" 'Kits/vendor/vendor-1/Tests/Excluded.m' $'int excludedKitTest(void) { return 1; }\n'
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Utils/Retained Contract.m' \
		$'// contract wrapper\n\n@implementation RetainedContract\n- (int)value { return 1; }\n- (int)other { return 2; }\n@end\n'
	write_fixture_file "${fixture}" "${RETAINED_MANIFEST}" \
		$'# retained by design\n\nmParticle-Apple-SDK/Utils/Retained Contract.m\nKits/vendor/vendor-1/Sources/Kit.m\n'

	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'base fixture'
	base_sha=$(git -C "${fixture}" rev-parse HEAD)

	rm "${fixture}/mParticle-Apple-SDK/Data Model/Core.m"
	printf '%s' $'// comment\n\nlet core = 1\nlet coreTwo = 2\n' >"${fixture}/mParticle-Apple-SDK-Swift/Sources/Core.swift"
	rm "${fixture}/mParticle-Apple-SDK/Kits/Kit.m"
	printf '%s' $'let kit = 1\nlet kitTwo = 2\n' >"${fixture}/mParticle-Apple-SDK-Swift/Sources/Kits/Kit.swift"
	git -C "${fixture}" mv \
		'mParticle-Apple-SDK-Swift/Sources/Rename Me.swift' \
		'mParticle-Apple-SDK-Swift/Sources/Renamed File.swift'
	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'migration fixture'
	migration_sha=$(git -C "${fixture}" rev-parse HEAD)

	migration_report="${fixture}/migration-report.md"
	generate_report "${fixture}" "${base_sha}" "${migration_sha}" "${cloc_path}" "${migration_report}"
	assert_contains "${migration_report}" \
		'| Short term — everything except kits and the public API |'
	assert_contains "${migration_report}" \
		'| Long term — everything, including all kits and the public API |'
	assert_contains "${migration_report}" '| 25.00% | 42.86% | 3 | 4 | 🚀 +17.86 pp |'
	assert_contains "${migration_report}" '| 23.81% | 36.84% | 7 | 12 | 🚀 +13.03 pp |'
	assert_contains "${migration_report}" \
		'Objective-C retained by design in Core SDK (the permanent public API surface): 4.'
	assert_contains "${migration_report}" '| Core SDK | 1 | 4 |'
	assert_contains "${migration_report}" '| Kits (infrastructure + standalone) | 1 | 2 |'

	write_fixture_file "${fixture}" 'README.md' $'No production source changes.\n'
	git -C "${fixture}" add README.md
	git -C "${fixture}" commit -q -m 'unrelated fixture'
	flat_sha=$(git -C "${fixture}" rev-parse HEAD)
	flat_report="${fixture}/flat-report.md"
	generate_report "${fixture}" "${migration_sha}" "${flat_sha}" "${cloc_path}" "${flat_report}"
	flat_count=$(grep -Fc '➖ 0.00 pp' "${flat_report}")
	[[ ${flat_count} -eq 2 ]] || fail 'self-test expected two flat migration goal rows'

	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Event/Regression.m' $'@implementation Regression\n@end\n'
	git -C "${fixture}" add 'mParticle-Apple-SDK/Event/Regression.m'
	git -C "${fixture}" commit -q -m 'regression fixture'
	regression_sha=$(git -C "${fixture}" rev-parse HEAD)
	regression_report="${fixture}/regression-report.md"
	generate_report "${fixture}" "${migration_sha}" "${regression_sha}" "${cloc_path}" "${regression_report}"
	assert_contains "${regression_report}" '| 42.86% | 33.33% | 3 | 6 | ↩️ -9.53 pp |'
	assert_contains "${regression_report}" '| 36.84% | 33.33% | 7 | 14 | ↩️ -3.51 pp |'

	git -C "${fixture}" switch -q -c selftest-thin "${migration_sha}"
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Utils/Retained Contract.m' \
		$'// contract wrapper\n\n@implementation RetainedContract\n@end\n'
	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'retained thinning fixture'
	thin_sha=$(git -C "${fixture}" rev-parse HEAD)
	thin_report="${fixture}/thin-report.md"
	generate_report "${fixture}" "${migration_sha}" "${thin_sha}" "${cloc_path}" "${thin_report}"
	# Thinning a retained wrapper is invisible to the short-term goal and real
	# progress toward the long-term one.
	assert_contains "${thin_report}" '| 42.86% | 42.86% | 3 | 4 | ➖ 0.00 pp |'
	assert_contains "${thin_report}" '| 36.84% | 41.18% | 7 | 10 | 🚀 +4.34 pp |'
	assert_contains "${thin_report}" \
		'Objective-C retained by design in Core SDK (the permanent public API surface): 2 (-2).'
	assert_contains "${thin_report}" '| Core SDK | 0 | 2 |'

	# Renaming a retained implementation and updating the manifest moves no
	# logic, so every goal row and the retained figure must stay flat.
	git -C "${fixture}" switch -q -c selftest-rename "${migration_sha}"
	git -C "${fixture}" mv \
		'mParticle-Apple-SDK/Utils/Retained Contract.m' \
		'mParticle-Apple-SDK/Utils/Renamed Contract.m'
	write_fixture_file "${fixture}" "${RETAINED_MANIFEST}" \
		$'# retained by design\n\nmParticle-Apple-SDK/Utils/Renamed Contract.m\nKits/vendor/vendor-1/Sources/Kit.m\n'
	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'retained rename fixture'
	renamed_sha=$(git -C "${fixture}" rev-parse HEAD)
	renamed_report="${fixture}/renamed-report.md"
	generate_report "${fixture}" "${migration_sha}" "${renamed_sha}" "${cloc_path}" "${renamed_report}"
	assert_contains "${renamed_report}" '| 42.86% | 42.86% | 3 | 4 | ➖ 0.00 pp |'
	assert_contains "${renamed_report}" '| 36.84% | 36.84% | 7 | 12 | ➖ 0.00 pp |'
	assert_contains "${renamed_report}" \
		'Objective-C retained by design in Core SDK (the permanent public API surface): 4.'

	# Retiring a retained implementation is long-term progress only; the
	# short-term goal never counted it.
	git -C "${fixture}" switch -q -c selftest-retire "${migration_sha}"
	rm "${fixture}/mParticle-Apple-SDK/Utils/Retained Contract.m"
	write_fixture_file "${fixture}" "${RETAINED_MANIFEST}" \
		$'# retained by design\n\nKits/vendor/vendor-1/Sources/Kit.m\n'
	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'retained retirement fixture'
	retired_sha=$(git -C "${fixture}" rev-parse HEAD)
	retired_report="${fixture}/retired-report.md"
	generate_report "${fixture}" "${migration_sha}" "${retired_sha}" "${cloc_path}" "${retired_report}"
	assert_contains "${retired_report}" '| 42.86% | 42.86% | 3 | 4 | ➖ 0.00 pp |'
	assert_contains "${retired_report}" '| 36.84% | 46.67% | 7 | 8 | 🚀 +9.83 pp |'
	assert_contains "${retired_report}" \
		'Objective-C retained by design in Core SDK (the permanent public API surface): 0 (-4).'

	git -C "${fixture}" switch -q -c selftest-pr "${migration_sha}"
	write_fixture_file "${fixture}" 'mParticle-Apple-SDK-Swift/Sources/PR Only.swift' $'let prOne = 1\nlet prTwo = 2\n'
	rm "${fixture}/mParticle-Apple-SDK/Event/Core.mm"
	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'pull request fixture'
	pr_head_sha=$(git -C "${fixture}" rev-parse HEAD)

	git -C "${fixture}" switch -q -c selftest-base "${migration_sha}"
	write_fixture_file "${fixture}" 'Kits/vendor/vendor-1/Sources/Base Only.m' $'@implementation BaseOnly\n@end\n'
	rm "${fixture}/Kits/vendor/vendor-1/Sources/Kit.swift"
	git -C "${fixture}" add --all
	git -C "${fixture}" commit -q -m 'advanced base fixture'
	advanced_base_sha=$(git -C "${fixture}" rev-parse HEAD)

	divergent_report="${fixture}/divergent-report.md"
	generate_report "${fixture}" "${advanced_base_sha}" "${pr_head_sha}" "${cloc_path}" "${divergent_report}"
	assert_contains "${divergent_report}" '| Core SDK | 2 | 2 |'
	assert_contains "${divergent_report}" '| Kits (infrastructure + standalone) | 0 | 0 |'

	[[ "$(percentage 0 0)" == '0.00' ]] || fail 'self-test expected a zero-denominator percentage of 0.00'
	run_manifest_validation_selftest "${fixture}/manifest-validation"
	printf '%s\n' 'swift-migration-progress: SELFTEST PASS'
}

parse_report_arguments() {
	local repo=''
	local base=''
	local head=''
	local cloc_path=''
	local output=''

	shift
	while (($# > 0)); do
		case "$1" in
		--repo | --base | --head | --cloc | --output)
			(($# >= 2)) || fail "missing value for $1"
			case "$1" in
			--repo) repo=$2 ;;
			--base) base=$2 ;;
			--head) head=$2 ;;
			--cloc) cloc_path=$2 ;;
			--output) output=$2 ;;
			*) fail "unsupported report option: $1" ;;
			esac
			shift 2
			;;
		*)
			fail "unknown report argument: $1"
			;;
		esac
	done

	[[ -n ${repo} ]] || fail 'report requires --repo'
	[[ -n ${base} ]] || fail 'report requires --base'
	[[ -n ${head} ]] || fail 'report requires --head'
	[[ -n ${cloc_path} ]] || fail 'report requires --cloc'
	[[ -n ${output} ]] || fail 'report requires --output'

	generate_report "${repo}" "${base}" "${head}" "${cloc_path}" "${output}"
}

parse_selftest_arguments() {
	local cloc_path=''

	shift
	while (($# > 0)); do
		case "$1" in
		--cloc)
			(($# >= 2)) || fail 'missing value for --cloc'
			cloc_path=$2
			shift 2
			;;
		*)
			fail "unknown selftest argument: $1"
			;;
		esac
	done

	[[ -n ${cloc_path} ]] || fail 'selftest requires --cloc'
	run_selftest "${cloc_path}"
}

main() {
	require_command git
	require_command jq
	require_command perl

	(($# > 0)) || {
		usage >&2
		exit 2
	}

	case "$1" in
	report) parse_report_arguments "$@" ;;
	selftest) parse_selftest_arguments "$@" ;;
	-h | --help)
		usage
		;;
	*)
		usage >&2
		fail "unknown command: $1"
		;;
	esac
}

main "$@"
