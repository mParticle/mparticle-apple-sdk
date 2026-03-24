#!/usr/bin/env bash
set -euo pipefail

# Publish mParticle Apple SDK and all kit podspecs to CocoaPods trunk.
#
# Prerequisites:
#   pod trunk register developers@mparticle.com 'mParticle Developers' --description='<your machine>'
#   (confirm via email link)

cd "$(dirname "$0")/.."

PUSH_FLAGS=(--allow-warnings --synchronous)

echo "==> Publishing Swift SDK (dependency of core)..."
pod trunk push mParticle-Apple-SDK-Swift/mParticle-Apple-SDK-Swift.podspec "${PUSH_FLAGS[@]}"

echo "==> Publishing core SDK..."
pod trunk push mParticle-Apple-SDK.podspec "${PUSH_FLAGS[@]}"

echo "==> Publishing kit podspecs..."
# shellcheck disable=SC2312
mapfile -t KIT_PODSPECS < <(jq -r '.[] | select(.podspec) | .podspec' Kits/matrix.json)
PIDS=()
for podspec in "${KIT_PODSPECS[@]}"; do
	echo "  - ${podspec}"
	pod trunk push "${podspec}" "${PUSH_FLAGS[@]}" &
	PIDS+=($!)
done

FAILED=0
for pid in "${PIDS[@]}"; do
	wait "${pid}" || FAILED=1
done

if [[ ${FAILED} -ne 0 ]]; then
	echo "==> ERROR: One or more kit podspec publishes failed" >&2
	exit 1
fi
echo "==> Done"
