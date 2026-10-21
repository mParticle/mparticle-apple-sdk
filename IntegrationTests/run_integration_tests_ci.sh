#!/bin/bash
# shellcheck disable=SC2155
# shellcheck disable=SC2312
# CI-specific integration test script that runs WireMock as a Java process
# instead of Docker (for GitHub Actions macOS runners)
set -e

# === Parse script-specific arguments ===
HTTP_PORT=${1:-8080}
# Use port 443 for HTTPS since the SDK connects to this port by default
# Note: This requires elevated privileges on macOS
HTTPS_PORT=${2:-443}
MAPPINGS_DIR=${3:-"./wiremock-recordings"}

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# === CI-specific configuration ===
WIREMOCK_JAR="${WIREMOCK_JAR:-../wiremock.jar}"
WIREMOCK_PID_FILE="${SCRIPT_DIR}/wiremock.pid"
WIREMOCK_LOG_FILE="${SCRIPT_DIR}/wiremock.log"

# Tracks which version was injected so we can restore the placeholder on cleanup
SDK_INJECTED_VERSION=""

# Set by create_wiremock_certificate
WIREMOCK_TLS_DIR=""
WIREMOCK_CA=""
WIREMOCK_KEYSTORE=""

# === Generate project with Tuist (using source-based distribution) ===
echo "🔄 Generating project with Tuist..."
tuist generate --no-open

inject_sdk_version() {
	local VERSION
	VERSION="${SDK_VERSION:-$(tr -d '[:space:]' <"${SCRIPT_DIR}/../VERSION" 2>/dev/null)}"

	if [[ -z ${VERSION} ]]; then
		echo "❌ Could not determine SDK version (set SDK_VERSION env var or ensure VERSION file exists)"
		exit 1
	fi

	echo "🔄 Injecting SDK version ${VERSION} into mapping files..."
	local MAPPINGS_FILES="${MAPPINGS_DIR}/mappings"

	python3 - "${VERSION}" "${MAPPINGS_FILES}" <<'EOF'
import sys, os, glob
version, mappings_dir = sys.argv[1], sys.argv[2]
for f in glob.glob(os.path.join(mappings_dir, '*.json')):
    with open(f, 'r') as fh:
        content = fh.read()
    if 'SDK_VERSION_PLACEHOLDER' in content:
        with open(f, 'w') as fh:
            fh.write(content.replace('SDK_VERSION_PLACEHOLDER', version))
EOF

	SDK_INJECTED_VERSION="${VERSION}"
	echo "✅ SDK version ${VERSION} injected"
}

restore_sdk_version_placeholder() {
	if [[ -z ${SDK_INJECTED_VERSION} ]]; then
		return 0
	fi

	echo "🔄 Restoring SDK_VERSION_PLACEHOLDER in mapping files..."
	local MAPPINGS_FILES="${MAPPINGS_DIR}/mappings"

	python3 - "${SDK_INJECTED_VERSION}" "${MAPPINGS_FILES}" <<'EOF'
import sys, os, glob
version, mappings_dir = sys.argv[1], sys.argv[2]
for f in glob.glob(os.path.join(mappings_dir, '*.json')):
    with open(f, 'r') as fh:
        content = fh.read()
    if version in content:
        with open(f, 'w') as fh:
            fh.write(content.replace(version, 'SDK_VERSION_PLACEHOLDER'))
EOF

	echo "✅ SDK_VERSION_PLACEHOLDER restored"
}

escape_mapping_bodies() {
	echo "🔄 Converting mapping bodies to escaped format (WireMock-compatible)..."
	local MAPPINGS_FILES="${MAPPINGS_DIR}/mappings"

	if [[ -d ${MAPPINGS_FILES} ]] && [[ -n "$(ls -A "${MAPPINGS_FILES}"/*.json 2>/dev/null)" ]]; then
		for mapping_file in "${MAPPINGS_FILES}"/*.json; do
			if [[ -f ${mapping_file} ]]; then
				python3 transform_mapping_body.py "${mapping_file}" escape >/dev/null 2>&1 || {
					echo "⚠️  Failed to escape $(basename "${mapping_file}")"
				}
			fi
		done
	fi
}

unescape_mapping_bodies() {
	echo "🔄 Converting mapping bodies back to unescaped format (readable)..."
	local MAPPINGS_FILES="${MAPPINGS_DIR}/mappings"

	if [[ -d ${MAPPINGS_FILES} ]] && [[ -n "$(ls -A "${MAPPINGS_FILES}"/*.json 2>/dev/null)" ]]; then
		for mapping_file in "${MAPPINGS_FILES}"/*.json; do
			if [[ -f ${mapping_file} ]]; then
				python3 transform_mapping_body.py "${mapping_file}" unescape >/dev/null 2>&1 || {
					echo "⚠️  Failed to unescape $(basename "${mapping_file}")"
				}
			fi
		done
	fi
}

create_wiremock_certificate() {
	# With pinning disabled the SDK still requires system trust, so WireMock serves a certificate
	# from a throwaway CA that the simulator is told to trust.
	echo "🔐 Creating a throwaway certificate authority for WireMock's HTTPS port..."
	WIREMOCK_TLS_DIR="$(mktemp -d)"
	local CONFIG="${WIREMOCK_TLS_DIR}/openssl.cnf"
	cat >"${CONFIG}" <<'EOF'
[req]
distinguished_name = dn
[dn]
[ca]
basicConstraints = critical, CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
[server]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = IP:127.0.0.1, DNS:localhost
EOF
	(
		cd "${WIREMOCK_TLS_DIR}" &&
			openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 2 -subj "/CN=mParticle Integration Tests CA" \
				-config "${CONFIG}" -extensions ca -keyout ca.key -out ca.pem &&
			openssl req -new -newkey rsa:2048 -nodes -subj "/CN=127.0.0.1" -config "${CONFIG}" \
				-keyout server.key -out server.csr &&
			openssl x509 -req -sha256 -days 2 -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial \
				-extfile "${CONFIG}" -extensions server -out server.pem &&
			openssl pkcs12 -export -name wiremock -inkey server.key -in server.pem -certfile ca.pem \
				-passout pass:password -out wiremock.p12
	) >"${WIREMOCK_TLS_DIR}/openssl.log" 2>&1 || {
		echo "❌ Could not create the WireMock certificate:"
		cat "${WIREMOCK_TLS_DIR}/openssl.log"
		exit 1
	}
	WIREMOCK_CA="${WIREMOCK_TLS_DIR}/ca.pem"
	WIREMOCK_KEYSTORE="${WIREMOCK_TLS_DIR}/wiremock.p12"
	echo "✅ Certificate created"
}

trust_wiremock_certificate() {
	echo "🔐 Trusting the WireMock certificate authority on the simulator..."
	xcrun simctl keychain "${DEVICE_ID}" add-root-cert "${WIREMOCK_CA}"
	echo "✅ Certificate authority trusted"
}

start_wiremock_java() {
	echo "🚀 Starting WireMock as Java process..."

	# Stop any existing WireMock
	stop_wiremock_java

	# Check if JAR exists
	if [[ ! -f ${WIREMOCK_JAR} ]]; then
		echo "❌ WireMock JAR not found at: ${WIREMOCK_JAR}"
		exit 1
	fi

	# Convert MAPPINGS_DIR to absolute path
	local ABS_MAPPINGS_DIR="$(cd "${MAPPINGS_DIR}" && pwd)"

	# Start WireMock in background
	# Use sudo if HTTPS_PORT is privileged (< 1024)
	if [[ ${HTTPS_PORT} -lt 1024 ]]; then
		echo "ℹ️  Using sudo to bind to privileged port ${HTTPS_PORT}"
		sudo java -jar "${WIREMOCK_JAR}" \
			--port "${HTTP_PORT}" \
			--https-port "${HTTPS_PORT}" \
			--https-keystore "${WIREMOCK_KEYSTORE}" \
			--keystore-type PKCS12 \
			--root-dir "${ABS_MAPPINGS_DIR}" \
			--verbose 2>&1 | sudo tee "${WIREMOCK_LOG_FILE}" >/dev/null &
	else
		java -jar "${WIREMOCK_JAR}" \
			--port "${HTTP_PORT}" \
			--https-port "${HTTPS_PORT}" \
			--https-keystore "${WIREMOCK_KEYSTORE}" \
			--keystore-type PKCS12 \
			--root-dir "${ABS_MAPPINGS_DIR}" \
			--verbose \
			>"${WIREMOCK_LOG_FILE}" 2>&1 &
	fi

	echo $! >"${WIREMOCK_PID_FILE}"
	echo "✅ WireMock started with PID: $(cat "${WIREMOCK_PID_FILE}")"
}

stop_wiremock_java() {
	if [[ -f ${WIREMOCK_PID_FILE} ]]; then
		local pid=$(cat "${WIREMOCK_PID_FILE}")
		if kill -0 "${pid}" 2>/dev/null; then
			echo "🛑 Stopping WireMock (PID: ${pid})..."
			kill "${pid}" 2>/dev/null || sudo kill "${pid}" 2>/dev/null || true
			sleep 2
			kill -9 "${pid}" 2>/dev/null || sudo kill -9 "${pid}" 2>/dev/null || true
		fi
		rm -f "${WIREMOCK_PID_FILE}"
	fi
	# Also try to kill any remaining WireMock processes (may need sudo if started with sudo)
	pkill -f "wiremock" 2>/dev/null || true
	sudo pkill -f "wiremock" 2>/dev/null || true
}

wait_for_wiremock_java() {
	echo "⏳ Waiting for WireMock to start..."
	local MAX_RETRIES=30
	local RETRY_COUNT=0

	while [[ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]]; do
		# Check HTTP admin endpoint
		# shellcheck disable=SC2312
		if curl -s -o /dev/null -w "%{http_code}" http://localhost:"${HTTP_PORT}"/__admin/mappings 2>/dev/null | grep -q "200"; then
			# Also verify HTTPS is working (skip certificate validation with -k)
			# shellcheck disable=SC2312
			if curl -k -s -o /dev/null -w "%{http_code}" https://localhost:"${HTTPS_PORT}"/__admin/mappings 2>/dev/null | grep -q "200"; then
				echo "✅ WireMock is ready! (HTTP: ${HTTP_PORT}, HTTPS: ${HTTPS_PORT})"
				return 0
			fi
		fi
		RETRY_COUNT=$((RETRY_COUNT + 1))
		echo "Waiting... (${RETRY_COUNT}/${MAX_RETRIES})"
		sleep 1
	done

	echo "❌ WireMock failed to start within ${MAX_RETRIES} seconds"
	echo "📋 WireMock logs:"
	cat "${WIREMOCK_LOG_FILE}" || true
	exit 1
}

show_wiremock_logs_java() {
	echo ""
	echo "📋 WireMock logs:"
	echo "════════════════════════════════════════════════════════════════"
	cat "${WIREMOCK_LOG_FILE}" 2>/dev/null || echo "❌ Could not retrieve logs"
	echo "════════════════════════════════════════════════════════════════"
	echo ""
}

verify_wiremock_results() {
	echo ""
	echo "🔍 Verifying WireMock results..."
	echo ""

	local WIREMOCK_PORT=${HTTP_PORT}
	local FAILED=false

	# Count all requests
	local SERVED=$(curl -s http://localhost:"${WIREMOCK_PORT}"/__admin/requests)
	local TOTAL=$(printf '%s\n' "${SERVED}" | jq '.requests | length')
	local UNMATCHED=$(curl -s http://localhost:"${WIREMOCK_PORT}"/__admin/requests/unmatched | jq '.requests | length')
	local MATCHED=$((TOTAL - UNMATCHED))

	echo "📊 WireMock summary:"
	echo "──────────────────────────────"
	echo "  Total requests:     ${TOTAL}"
	echo "  Matched requests:   ${MATCHED}"
	echo "  Unmatched requests: ${UNMATCHED}"
	echo "──────────────────────────────"
	echo ""

	if [[ ${TOTAL} -eq 0 ]]; then
		echo "❌ The application sent no requests."
		FAILED=true
	fi

	# Check for unmatched requests
	if [[ ${UNMATCHED} -gt 0 ]]; then
		echo "❌ Found requests that did not match any mappings:"
		curl -s http://localhost:"${WIREMOCK_PORT}"/__admin/requests/unmatched |
			jq -r '.requests[] | "  [\(.method)] \(.url)"'
		FAILED=true
	else
		echo "✅ All incoming requests matched their mappings."
	fi

	# A mapping no request matched is a request the application no longer sends.
	echo ""
	echo "🧩 Checking: were all mappings invoked..."

	local USED_IDS=$(printf '%s\n' "${SERVED}" | jq -r '.requests[] | select(.wasMatched) | .stubMapping.id')
	local UNUSED_FOUND=false
	for mapping_file in "${MAPPINGS_DIR}"/mappings/*.json; do
		if ! grep -qxF "$(jq -r '.id' "${mapping_file}")" <<<"${USED_IDS}"; then
			if [[ ${UNUSED_FOUND} == false ]]; then
				echo "❌ Some mappings were not invoked by the application:"
				UNUSED_FOUND=true
			fi
			echo "  $(basename "${mapping_file}")"
		fi
	done

	if [[ ${UNUSED_FOUND} == false ]]; then
		echo "✅ All recorded mappings were invoked by the application."
	else
		FAILED=true
	fi

	if [[ ${FAILED} == true ]]; then
		echo ""
		show_wiremock_logs_java
		stop_wiremock_java
		exit 1
	fi

	echo ""
	echo "🎉 Verification completed successfully!"
}

# Cleanup function
cleanup() {
	unescape_mapping_bodies
	restore_sdk_version_placeholder
	stop_wiremock_java
	rm -rf "${WIREMOCK_TLS_DIR}"
}

# Error handler
error_handler() {
	local exit_code=$?
	echo ""
	echo "❌ Script failed with exit code: ${exit_code}"
	show_wiremock_logs_java
	unescape_mapping_bodies
	restore_sdk_version_placeholder
	stop_wiremock_java
	exit "${exit_code}"
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
inject_sdk_version
escape_mapping_bodies
create_wiremock_certificate
start_wiremock_java
wait_for_wiremock_java
echo "📝 WireMock is running in verification mode"
echo "🔗 Admin UI: http://localhost:${HTTP_PORT}/__admin"
echo "🔗 HTTPS Endpoint: https://localhost:${HTTPS_PORT}"
echo ""
start_simulator
trust_wiremock_certificate
install_application
launch_application
wait_for_app_completion
# A run cut short leaves its last recordings unused; report that cause instead
if kill -0 "${APP_PID}" 2>/dev/null; then
	echo "❌ The application was still running when the wait ended, so its run is incomplete."
	show_wiremock_logs_java
	stop_wiremock_java
	exit 1
fi
verify_wiremock_results
unescape_mapping_bodies
restore_sdk_version_placeholder
stop_wiremock_java
