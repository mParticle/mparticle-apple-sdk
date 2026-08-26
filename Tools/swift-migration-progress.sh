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
	kit)
		append_matching_files "${objc_root}/Kits" "${output}"
		append_matching_files "${swift_root}/Kits" "${output}"
		;;
	standalone)
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
		path=${line%$'\r'}
		path=${path#"${path%%[![:space:]]*}"}
		path=${path%"${path##*[![:space:]]}"}
		if [[ -z ${path} || ${path} == '#'* ]]; then
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
	Kits/*/Sources/*)
		printf 'standalone'
		;;
	mParticle-Apple-SDK-Swift/Sources/Kits/* | mParticle-Apple-SDK/Kits/*)
		printf 'kit'
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
KIT_SWIFT_ADDED=0
KIT_OBJC_REMOVED=0
STANDALONE_SWIFT_ADDED=0
STANDALONE_OBJC_REMOVED=0

add_swift_movement() {
	local bucket=$1
	local lines=$2

	case "${bucket}" in
	core) CORE_SWIFT_ADDED=$((CORE_SWIFT_ADDED + lines)) ;;
	kit) KIT_SWIFT_ADDED=$((KIT_SWIFT_ADDED + lines)) ;;
	standalone) STANDALONE_SWIFT_ADDED=$((STANDALONE_SWIFT_ADDED + lines)) ;;
	*) ;;
	esac
}

add_objc_movement() {
	local bucket=$1
	local lines=$2

	case "${bucket}" in
	core) CORE_OBJC_REMOVED=$((CORE_OBJC_REMOVED + lines)) ;;
	kit) KIT_OBJC_REMOVED=$((KIT_OBJC_REMOVED + lines)) ;;
	standalone) STANDALONE_OBJC_REMOVED=$((STANDALONE_OBJC_REMOVED + lines)) ;;
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
	KIT_SWIFT_ADDED=0
	KIT_OBJC_REMOVED=0
	STANDALONE_SWIFT_ADDED=0
	STANDALONE_OBJC_REMOVED=0

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

# Emits both goal rows for one area: the short-term target (in-scope
# Objective-C only) and the long-term target (all Objective-C, which the
# retained public API surface can only satisfy in a future major release).
write_area_rows() {
	local label=$1
	local base_swift=$2
	local base_inscope=$3
	local base_retained=$4
	local head_swift=$5
	local head_inscope=$6
	local head_retained=$7
	local base_total=$((base_inscope + base_retained))
	local head_total=$((head_inscope + head_retained))
	local base_percent
	local head_percent
	local bar

	base_percent=$(percentage "${base_swift}" "${base_inscope}")
	head_percent=$(percentage "${head_swift}" "${head_inscope}")
	bar=$(progress_bar "${head_percent}")
	calculate_delta "${base_percent}" "${head_percent}"
	printf '| %s | Short term — in scope | `%s` | %s%% | %s%% | %s | %s | %s %s pp |\n' \
		"${label}" "${bar}" "${base_percent}" "${head_percent}" \
		"$(format_integer "${head_swift}")" "$(format_integer "${head_inscope}")" \
		"${DELTA_ICON}" "${DELTA_TEXT}"

	base_percent=$(percentage "${base_swift}" "${base_total}")
	head_percent=$(percentage "${head_swift}" "${head_total}")
	bar=$(progress_bar "${head_percent}")
	calculate_delta "${base_percent}" "${head_percent}"
	printf '| %s | Long term — all Objective-C | `%s` | %s%% | %s%% | %s | %s | %s %s pp |\n' \
		"${label}" "${bar}" "${base_percent}" "${head_percent}" \
		"$(format_integer "${head_swift}")" "$(format_integer "${head_total}")" \
		"${DELTA_ICON}" "${DELTA_TEXT}"
}

write_report() {
	local output=$1
	local base=$2
	local head=$3
	local cloc_version=$4
	local short_base=${base:0:12}
	local short_head=${head:0:12}

	mkdir -p "$(dirname "${output}")"
	{
		printf '%s\n' "${COMMENT_MARKER}"
		printf '%s\n\n' '## 🐦 Swift Migration Progress'
		printf 'Production implementation code at `%s` compared with `%s`.\n\n' "${short_head}" "${short_base}"
		printf '%s\n' '| Area | Goal | Progress | Base | This PR | Swift SLOC | Objective-C remaining | Change |'
		printf '%s\n' '|---|---|:---:|---:|---:|---:|---:|---:|'
		write_area_rows 'Core SDK' \
			"${BASE_CORE_SWIFT}" "${BASE_CORE_OBJC}" "${BASE_CORE_OBJC_RETAINED}" \
			"${HEAD_CORE_SWIFT}" "${HEAD_CORE_OBJC}" "${HEAD_CORE_OBJC_RETAINED}"
		write_area_rows 'SDK kit infrastructure' \
			"${BASE_KIT_SWIFT}" "${BASE_KIT_OBJC}" "${BASE_KIT_OBJC_RETAINED}" \
			"${HEAD_KIT_SWIFT}" "${HEAD_KIT_OBJC}" "${HEAD_KIT_OBJC_RETAINED}"
		write_area_rows 'Standalone kits' \
			"${BASE_STANDALONE_SWIFT}" "${BASE_STANDALONE_OBJC}" "${BASE_STANDALONE_OBJC_RETAINED}" \
			"${HEAD_STANDALONE_SWIFT}" "${HEAD_STANDALONE_OBJC}" "${HEAD_STANDALONE_OBJC_RETAINED}"
		printf '\n'
		printf 'Objective-C retained by design: Core SDK %s · SDK kit infrastructure %s · Standalone kits %s.\n\n' \
			"$(format_retained "${BASE_CORE_OBJC_RETAINED}" "${HEAD_CORE_OBJC_RETAINED}")" \
			"$(format_retained "${BASE_KIT_OBJC_RETAINED}" "${HEAD_KIT_OBJC_RETAINED}")" \
			"$(format_retained "${BASE_STANDALONE_OBJC_RETAINED}" "${HEAD_STANDALONE_OBJC_RETAINED}")"
		printf '%s\n\n' "### This PR's code movement"
		printf '%s\n' '| Area | Swift lines added | Objective-C lines removed |'
		printf '%s\n' '|---|---:|---:|'
		printf '| Core SDK | %s | %s |\n' \
			"$(format_integer "${CORE_SWIFT_ADDED}")" "$(format_integer "${CORE_OBJC_REMOVED}")"
		printf '| SDK kit infrastructure | %s | %s |\n' \
			"$(format_integer "${KIT_SWIFT_ADDED}")" "$(format_integer "${KIT_OBJC_REMOVED}")"
		printf '| Standalone kits | %s | %s |\n\n' \
			"$(format_integer "${STANDALONE_SWIFT_ADDED}")" "$(format_integer "${STANDALONE_OBJC_REMOVED}")"
		printf '%s\n\n' '<details>'
		printf '%s\n\n' '<summary>How this is measured</summary>'
		printf '%s\n' '- Current composition uses production source lines of code (SLOC) from `cloc`; comments and blank lines are excluded.'
		printf '%s\n' '- **Short term — in scope** excludes the Objective-C the migration will not delete, so 100% is the end of this project: every in-scope implementation gone.'
		printf '%s\n' '- **Long term — all Objective-C** keeps the full denominator. Reaching 100% there means the public API itself becomes Swift, which is a breaking change reserved for a future major release.'
		printf '%s\n' '- The gap between the two rows is the retained public/kit contract, runtime-identity, and boundary-glue surface listed in `Tools/swift-migration-retained-objc.txt`.'
		printf '%s\n' '- Retained wrappers keep their Objective-C interface but still shed logic to Swift. That thinning moves the long-term row and the retained figure, not the short-term row.'
		printf '%s\n' '- Both revisions are measured with the manifest from the head revision, so a manifest edit does not by itself move the reported change.'
		printf '%s\n' '- Pull request movement uses physical additions/deletions from `git diff base...head --numstat`; it counts retained files too and is intentionally separate from SLOC totals.'
		printf '%s\n' '- Core excludes SDK kit infrastructure and vendored libraries. Standalone kits include only files below `Kits/**/Sources`.'
		printf '%s\n' '- Tests, examples, headers, build outputs, vendored libraries, and the `MParticle/Sources` Swift overlay are excluded.'
		printf '%s\n\n' '- Objective-C++ (`.mm`) is included in the Objective-C figures and removed counts.'
		printf 'Generated with `cloc` %s. This report is informational and does not gate migration direction.\n\n' "${cloc_version}"
		printf '%s\n' '</details>'
	} >"${output}"
}

BASE_CORE_SWIFT=0
BASE_CORE_OBJC=0
BASE_CORE_OBJC_RETAINED=0
BASE_KIT_SWIFT=0
BASE_KIT_OBJC=0
BASE_KIT_OBJC_RETAINED=0
BASE_STANDALONE_SWIFT=0
BASE_STANDALONE_OBJC=0
BASE_STANDALONE_OBJC_RETAINED=0
HEAD_CORE_SWIFT=0
HEAD_CORE_OBJC=0
HEAD_CORE_OBJC_RETAINED=0
HEAD_KIT_SWIFT=0
HEAD_KIT_OBJC=0
HEAD_KIT_OBJC_RETAINED=0
HEAD_STANDALONE_SWIFT=0
HEAD_STANDALONE_OBJC=0
HEAD_STANDALONE_OBJC_RETAINED=0

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
	local retained_paths

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
	retained_paths="${workspace}/retained-paths.txt"
	load_retained_manifest "${head_root}" "${retained_paths}"

	count_bucket "${base_root}" core "${cloc_path}" "${workspace}/base-core" "${retained_paths}"
	BASE_CORE_SWIFT=${COUNT_SWIFT}
	BASE_CORE_OBJC=${COUNT_OBJC}
	BASE_CORE_OBJC_RETAINED=${COUNT_OBJC_RETAINED}
	count_bucket "${base_root}" kit "${cloc_path}" "${workspace}/base-kit" "${retained_paths}"
	BASE_KIT_SWIFT=${COUNT_SWIFT}
	BASE_KIT_OBJC=${COUNT_OBJC}
	BASE_KIT_OBJC_RETAINED=${COUNT_OBJC_RETAINED}
	count_bucket "${base_root}" standalone "${cloc_path}" "${workspace}/base-standalone" "${retained_paths}"
	BASE_STANDALONE_SWIFT=${COUNT_SWIFT}
	BASE_STANDALONE_OBJC=${COUNT_OBJC}
	BASE_STANDALONE_OBJC_RETAINED=${COUNT_OBJC_RETAINED}

	count_bucket "${head_root}" core "${cloc_path}" "${workspace}/head-core" "${retained_paths}"
	HEAD_CORE_SWIFT=${COUNT_SWIFT}
	HEAD_CORE_OBJC=${COUNT_OBJC}
	HEAD_CORE_OBJC_RETAINED=${COUNT_OBJC_RETAINED}
	count_bucket "${head_root}" kit "${cloc_path}" "${workspace}/head-kit" "${retained_paths}"
	HEAD_KIT_SWIFT=${COUNT_SWIFT}
	HEAD_KIT_OBJC=${COUNT_OBJC}
	HEAD_KIT_OBJC_RETAINED=${COUNT_OBJC_RETAINED}
	count_bucket "${head_root}" standalone "${cloc_path}" "${workspace}/head-standalone" "${retained_paths}"
	HEAD_STANDALONE_SWIFT=${COUNT_SWIFT}
	HEAD_STANDALONE_OBJC=${COUNT_OBJC}
	HEAD_STANDALONE_OBJC_RETAINED=${COUNT_OBJC_RETAINED}

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
	local advanced_base_sha
	local pr_head_sha
	local migration_report
	local flat_report
	local regression_report
	local thin_report
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
	assert_contains "${migration_report}" '| Core SDK | Short term — in scope |'
	assert_contains "${migration_report}" '| Core SDK | Long term — all Objective-C |'
	assert_contains "${migration_report}" '| 25.00% | 42.86% | 3 | 4 | 🚀 +17.86 pp |'
	assert_contains "${migration_report}" '| 16.67% | 27.27% | 3 | 8 | 🚀 +10.60 pp |'
	assert_contains "${migration_report}" '| 33.33% | 100.00% | 2 | 0 | 🚀 +66.67 pp |'
	assert_contains "${migration_report}" '| 100.00% | 100.00% | 1 | 0 | ➖ 0.00 pp |'
	assert_contains "${migration_report}" '| 33.33% | 33.33% | 1 | 2 | ➖ 0.00 pp |'
	assert_contains "${migration_report}" \
		'Objective-C retained by design: Core SDK 4 · SDK kit infrastructure 0 · Standalone kits 2.'
	assert_contains "${migration_report}" '| Core SDK | 1 | 4 |'
	assert_contains "${migration_report}" '| SDK kit infrastructure | 1 | 2 |'
	assert_contains "${migration_report}" '| Standalone kits | 0 | 0 |'

	write_fixture_file "${fixture}" 'README.md' $'No production source changes.\n'
	git -C "${fixture}" add README.md
	git -C "${fixture}" commit -q -m 'unrelated fixture'
	flat_sha=$(git -C "${fixture}" rev-parse HEAD)
	flat_report="${fixture}/flat-report.md"
	generate_report "${fixture}" "${migration_sha}" "${flat_sha}" "${cloc_path}" "${flat_report}"
	flat_count=$(grep -Fc '➖ 0.00 pp' "${flat_report}")
	[[ ${flat_count} -eq 6 ]] || fail 'self-test expected six flat migration goal rows'

	write_fixture_file "${fixture}" 'mParticle-Apple-SDK/Event/Regression.m' $'@implementation Regression\n@end\n'
	git -C "${fixture}" add 'mParticle-Apple-SDK/Event/Regression.m'
	git -C "${fixture}" commit -q -m 'regression fixture'
	regression_sha=$(git -C "${fixture}" rev-parse HEAD)
	regression_report="${fixture}/regression-report.md"
	generate_report "${fixture}" "${migration_sha}" "${regression_sha}" "${cloc_path}" "${regression_report}"
	assert_contains "${regression_report}" '| 42.86% | 33.33% | 3 | 6 | ↩️ -9.53 pp |'
	assert_contains "${regression_report}" '| 27.27% | 23.08% | 3 | 10 | ↩️ -4.19 pp |'

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
	assert_contains "${thin_report}" '| 27.27% | 33.33% | 3 | 6 | 🚀 +6.06 pp |'
	assert_contains "${thin_report}" \
		'Objective-C retained by design: Core SDK 2 (-2) · SDK kit infrastructure 0 · Standalone kits 2.'
	assert_contains "${thin_report}" '| Core SDK | 0 | 2 |'

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
	assert_contains "${divergent_report}" '| Standalone kits | 0 | 0 |'

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
