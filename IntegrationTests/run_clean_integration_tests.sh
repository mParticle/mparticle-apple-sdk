#!/bin/bash
set -e

# === Parse script-specific arguments ===
HTTP_PORT=${1:-8080}
HTTPS_PORT=${2:-443}
MAPPINGS_DIR=${3:-"./wiremock-recordings"}

# Source common functions (will use HTTP_PORT, HTTPS_PORT, MAPPINGS_DIR if set)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# === Build framework and generate project ===
build_framework

echo "🔄 Generating project with Tuist..."
tuist generate --no-open

# === Script-specific configuration ===
CONTAINER_NAME="wiremock-verify"

escape_mapping_bodies() {
	echo "🔄 Converting mapping bodies to escaped format (WireMock-compatible)..."
	local MAPPINGS_FILES="${MAPPINGS_DIR}/mappings"

	if [ -d "$MAPPINGS_FILES" ] && [ "$(ls -A $MAPPINGS_FILES/*.json 2>/dev/null)" ]; then
		for mapping_file in "$MAPPINGS_FILES"/*.json; do
			if [ -f "$mapping_file" ]; then
				python3 transform_mapping_body.py "$mapping_file" escape >/dev/null 2>&1 || {
					echo "⚠️  Failed to escape $(basename $mapping_file)"
				}
			fi
		done
	fi
}

unescape_mapping_bodies() {
	echo "🔄 Converting mapping bodies back to unescaped format (readable)..."
	local MAPPINGS_FILES="${MAPPINGS_DIR}/mappings"

	if [ -d "$MAPPINGS_FILES" ] && [ "$(ls -A $MAPPINGS_FILES/*.json 2>/dev/null)" ]; then
		for mapping_file in "$MAPPINGS_FILES"/*.json; do
			if [ -f "$mapping_file" ]; then
				python3 transform_mapping_body.py "$mapping_file" unescape >/dev/null 2>&1 || {
					echo "⚠️  Failed to unescape $(basename $mapping_file)"
				}
			fi
		done
	fi
}

verify_wiremock_results() {
	echo ""
	echo "🔍 Verifying WireMock results..."
	echo ""

	local WIREMOCK_PORT=${HTTP_PORT}

	# Count all requests
	local TOTAL=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests | jq '.requests | length')
	local UNMATCHED=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests/unmatched | jq '.requests | length')
	local MATCHED=$((TOTAL - UNMATCHED))

	echo "📊 WireMock summary:"
	echo "──────────────────────────────"
	echo "  Total requests:     $TOTAL"
	echo "  Matched requests:   $MATCHED"
	echo "  Unmatched requests: $UNMATCHED"
	echo "──────────────────────────────"
	echo ""

	# Check for unmatched requests
	if [ "$UNMATCHED" -gt 0 ]; then
		echo "❌ Found requests that did not match any mappings:"
		curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests/unmatched |
			jq -r '.requests[] | "  [\(.method)] \(.url)"'
		echo ""
		show_wiremock_logs
		stop_wiremock
		exit 1
	else
		echo "✅ All incoming requests matched their mappings."
	fi

	# Check for unused mappings by comparing URLs (not IDs, as WireMock generates new ones)
	echo ""
	echo "🧩 Checking: were all mappings invoked..."

	# Get all non-proxy mapping URLs from files
	local EXPECTED_MAPPINGS=$(jq -r 'select(.response.proxyBaseUrl == null) | "\(.request.method // "ANY") \(.request.url // .request.urlPattern // .request.urlPath // .request.urlPathPattern)"' ${MAPPINGS_DIR}/mappings/*.json 2>/dev/null | sort)

	# Get all actual request URLs
	local ACTUAL_REQUESTS=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests |
		jq -r '.requests[] | "\(.request.method) \(.request.url)"' | sort | uniq)

	# Check each expected mapping
	local UNUSED_FOUND=false
	while IFS= read -r mapping; do
		if [ -n "$mapping" ]; then
			local method=$(echo "$mapping" | awk '{print $1}')
			local url=$(echo "$mapping" | awk '{$1=""; print $0}' | sed 's/^ //')

			# Check if mapping was used
			local matched=false

			# For patterns, check by comparing base structure
			if echo "$url" | grep -q '\[' || echo "$url" | grep -q '\\'; then
				# It's a pattern - extract the fixed parts
				# /v2/us1-[a-f0-9]+/events -> /v2 and /events
				# /v4/.../config\?... -> /v4 and /config
				local url_start=$(echo "$url" | cut -d'[' -f1 | cut -d'\' -f1)

				# Check if there's a request with same method and starting path
				if echo "$ACTUAL_REQUESTS" | grep -Fq "$method $url_start"; then
					matched=true
				fi
			else
				# Exact URL match
				if echo "$ACTUAL_REQUESTS" | grep -Fq "$mapping"; then
					matched=true
				fi
			fi

			if [ "$matched" = false ]; then
				if [ "$UNUSED_FOUND" = false ]; then
					echo "⚠️  Some mappings were not invoked by the application:"
					UNUSED_FOUND=true
				fi
				echo "  $mapping"
			fi
		fi
	done <<<"$EXPECTED_MAPPINGS"

	if [ "$UNUSED_FOUND" = false ]; then
		echo "✅ All recorded mappings were invoked by the application."
	fi

	echo ""
	echo "🎉 Verification completed successfully!"
}

# Cleanup function to restore mappings and stop WireMock
cleanup() {
	unescape_mapping_bodies
	stop_wiremock
}

# Error handler that shows logs before cleanup
error_handler() {
	local exit_code=$?
	echo ""
	echo "❌ Script failed with exit code: $exit_code"
	show_wiremock_logs
	unescape_mapping_bodies
	stop_wiremock
	exit $exit_code
}

# Trap to ensure cleanup on exit or error
trap cleanup EXIT INT TERM
trap error_handler ERR

# === Main execution flow ===
build_application
find_app_path
reset_simulators
find_available_device
find_device
remove_proxy_mappings
escape_mapping_bodies
start_wiremock "verify"
wait_for_wiremock
echo "📝 WireMock is running in verification mode"
echo "🔗 Admin UI: http://localhost:${HTTP_PORT}/__admin"
echo "🔗 HTTPS Endpoint: https://localhost:${HTTPS_PORT}"
echo ""
start_simulator
install_application
launch_application
wait_for_app_completion
verify_wiremock_results
unescape_mapping_bodies
stop_wiremock
