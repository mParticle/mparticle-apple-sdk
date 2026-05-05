#!/usr/bin/env bash
#
# CocoaPods trunk push with retries. Treats trunk "duplicate entry" as success (transient 5xx after publish).
#
# Source from the repo root:   . Scripts/pod_push.sh
# On GitHub Actions, run `set +e` before calling—the default run shell uses bash -e; callers rely on
# explicit status checks inside this function instead of errexit aborting mid-retry.
#

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
