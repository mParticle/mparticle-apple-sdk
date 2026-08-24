#!/usr/bin/env bash
# abi-guard.sh — snapshot / diff the public ObjC ABI surface under
# mParticle-Apple-SDK/Include/*.h (class/protocol names, selectors, property
# nullability, enum members). Parses header text only — never eval/execs
# header contents. See Tools/README.md for usage + baseline-update policy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_HEADER_DIR="${REPO_ROOT}/mParticle-Apple-SDK/Include"
BASELINE="${SCRIPT_DIR}/abi-baseline.txt"

usage() {
	echo "Usage: $(basename "$0") {snapshot [header-dir]|update|check [header-dir]}" >&2
	exit 1
}

# Extracts ABI-relevant tokens from a single header: @interface/@protocol
# declarations, @property lines (nullability included), method declarations
# (- / +, joined across continuation lines), and NS_ENUM/NS_OPTIONS members.
extract_tokens() {
	awk '
    function stripline(line,    p, q, e, out, rest) {
      out = ""
      while (1) {
        if (in_comment) {
          e = index(line, "*/")
          if (e == 0) { return out }
          line = substr(line, e + 2)
          in_comment = 0
          continue
        }
        p = index(line, "/*")
        q = index(line, "//")
        if (p > 0 && (q == 0 || p < q)) {
          out = out substr(line, 1, p - 1)
          rest = substr(line, p + 2)
          e = index(rest, "*/")
          if (e == 0) { in_comment = 1; return out }
          line = substr(rest, e + 2)
          continue
        } else if (q > 0) {
          out = out substr(line, 1, q - 1)
          return out
        } else {
          out = out line
          return out
        }
      }
    }
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function squeeze(s) { gsub(/[ \t]+/, " ", s); return s }
    {
      line = trim(squeeze(stripline($0)))
      if (line == "") next

      if (in_enum) {
        if (line ~ /^}/) { in_enum = 0; enum_name = ""; next }
        name = line
        sub(/=.*/, "", name)
        gsub(/,/, "", name)
        name = trim(name)
        if (name != "") print "ENUM|" enum_name "|" name
        next
      }
      if (line ~ /NS_(ENUM|OPTIONS)\(/) {
        tmp = line
        sub(/^.*NS_(ENUM|OPTIONS)\([^,]+,[ \t]*/, "", tmp)
        sub(/\).*$/, "", tmp)
        enum_name = trim(tmp)
        if (line ~ /\{/) { in_enum = 1 }
        next
      }
      if (pending != "") {
        pending = pending " " line
        if (pending ~ /;[ \t]*$/) { print "METHOD|" pending; pending = "" }
        next
      }
      if (line ~ /^[-+][ \t]*\(/) {
        if (line ~ /;[ \t]*$/) { print "METHOD|" line } else { pending = line }
        next
      }
      if (line ~ /^@property/) { print "PROP|" line; next }
      if (line ~ /^@interface/) { print "IFACE|" line; next }
      if (line ~ /^@protocol/) { print "PROTO|" line; next }
    }
  ' "$1"
}

snapshot() {
	local dir="${1:-${DEFAULT_HEADER_DIR}}"
	if [[ ! -d ${dir} ]]; then
		echo "abi-guard: header dir not found: ${dir}" >&2
		exit 1
	fi
	local f
	for f in "${dir}"/*.h; do
		[[ -e ${f} ]] || continue
		extract_tokens "${f}"
	done | sort
}

cmd_update() {
	snapshot "${DEFAULT_HEADER_DIR}" >"${BASELINE}"
	echo "abi-guard: baseline updated at ${BASELINE}"
}

cmd_check() {
	local dir="${1:-${DEFAULT_HEADER_DIR}}"
	if [[ ! -f ${BASELINE} ]]; then
		echo "abi-guard: no baseline at ${BASELINE} — run '$(basename "$0") update' first" >&2
		exit 1
	fi
	local current
	current="$(mktemp)"
	trap 'rm -f "$current"' RETURN
	snapshot "${dir}" >"${current}"
	if diff -u "${BASELINE}" "${current}"; then
		echo "abi-guard: check PASSED — no public ABI diff"
		return 0
	else
		echo "abi-guard: check FAILED — public ABI diff detected (see above)" >&2
		return 1
	fi
}

case "${1-}" in
snapshot)
	shift
	snapshot "${1-}"
	;;
update) cmd_update ;;
check)
	shift
	cmd_check "${1-}"
	;;
*) usage ;;
esac
