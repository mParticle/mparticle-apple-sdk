#!/usr/bin/env bash
# abi-guard-selftest.sh — proves abi-guard.sh detects breakage:
#   1. the real, unmodified Include/ tree PASSES `check`
#   2. a deliberately mutated COPY (never the real tree) FAILS `check`
# Never writes inside mParticle-Apple-SDK/Include or Tools/abi-baseline.txt.
#
# ponytail: no `set -e` here — we intentionally capture non-zero exit codes
# from the guard rather than letting them abort this script.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GUARD="${SCRIPT_DIR}/abi-guard.sh"
REAL_INCLUDE="${REPO_ROOT}/mParticle-Apple-SDK/Include"

TMPDIR=""
# shellcheck disable=SC2329 # invoked indirectly via `trap ... EXIT` below
cleanup() { [[ -n ${TMPDIR} ]] && rm -rf "${TMPDIR}"; }
trap cleanup EXIT

fail=0

# 1. Clean, real tree must PASS.
bash "${GUARD}" check
clean_status=$?
if [[ ${clean_status} -ne 0 ]]; then
	echo "abi-guard-selftest: clean-tree check did not exit 0 (got ${clean_status})" >&2
	fail=1
fi

# 2. A mutated COPY must FAIL. Never touch the real Include dir.
TMPDIR="$(mktemp -d)"
cp -R "${REAL_INCLUDE}" "${TMPDIR}/Include"
target="${TMPDIR}/Include/MPAudience.h"
awk '/^@end/ && !done { print "- (void)mpAbiGuardCanary;"; done = 1 } { print }' "${target}" >"${target}.tmp" && mv "${target}.tmp" "${target}"

mutated_output="$(bash "${GUARD}" check "${TMPDIR}/Include" 2>&1)"
mutated_status=$?
if [[ ${mutated_status} -eq 0 ]]; then
	echo "abi-guard-selftest: mutated-copy check exited 0 (expected non-zero)" >&2
	echo "${mutated_output}" >&2
	fail=1
fi

if [[ ${fail} -eq 0 ]]; then
	echo "SELFTEST PASS"
	exit 0
else
	echo "SELFTEST FAIL"
	exit 1
fi
