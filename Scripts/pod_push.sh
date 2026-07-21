#!/usr/bin/env bash
#
# CocoaPods trunk push with retries. Treats trunk "duplicate entry" as success (transient 5xx after publish).
# Poll trunk until a pod version is visible (used before publishing dependent podspecs in CI).
#
# Source from the repo root:   . Scripts/pod_push.sh
# On GitHub Actions, run `set +e` before calling—the default run shell uses bash -e; callers rely on
# explicit status checks inside this function instead of errexit aborting mid-retry.
#

# Poll https://trunk.cocoapods.org until the given version exists for the pod.
# Usage: wait_for_pod_version_on_trunk <pod_name> <version> [post_success_sleep_seconds]
# post_success_sleep_seconds: optional extra sleep after the version is found (e.g. 300 for CDN).
wait_for_pod_version_on_trunk() {
	local pod_name="$1"
	local version="$2"
	local post_success_sleep="${3:-0}"
	local max_attempts=30
	local sleep_seconds=60
	local i found

	echo "⏳ Polling CocoaPods trunk for ${pod_name} ${version}..."
	for ((i = 1; i <= max_attempts; i++)); do
		found=$(
			curl -sf "https://trunk.cocoapods.org/api/v1/pods/${pod_name}" |
				jq -r --arg v "${version}" '.versions[] | select(.name == $v) | .name' 2>/dev/null || true
		)
		if [[ ${found} == "${version}" ]]; then
			echo "✅ ${pod_name} ${version} confirmed on CocoaPods trunk"
			if [[ ${post_success_sleep} -gt 0 ]]; then
				echo "⏳ Waiting ${post_success_sleep}s for CDN propagation..."
				sleep "${post_success_sleep}"
			fi
			return 0
		fi
		if [[ ${i} -eq ${max_attempts} ]]; then
			echo "❌ Timed out after $((max_attempts * sleep_seconds))s waiting for ${pod_name} ${version} on trunk"
			return 1
		fi
		echo "  Attempt ${i}/${max_attempts}: Not yet available. Retrying in ${sleep_seconds}s..."
		sleep "${sleep_seconds}"
	done
	return 1
}

trunk_push_with_retries() {
	local podspec="$1"
	local attempt status
	local -a push_flags=(--allow-warnings --synchronous)

	for attempt in 1 2 3; do
		status=0
		pod trunk push "${podspec}" "${push_flags[@]}" >pod_trunk_push.log 2>&1 || status=$?
		cat pod_trunk_push.log
		if [[ ${status} -eq 0 ]]; then
			return 0
		fi
		if grep -qiF 'duplicate entry' pod_trunk_push.log; then
			echo "✅ ${podspec}: already on trunk; treating push as successful."
			return 0
		fi
		if [[ ${attempt} -lt 3 ]]; then
			echo "Attempt ${attempt} failed for ${podspec}, retrying in 3 minutes..."
			sleep 180
		else
			return 1
		fi
	done
}
