#!/bin/bash

# === Parse script-specific arguments ===
HTTP_PORT=${1:-8080}
HTTPS_PORT=${2:-443}
MAPPINGS_DIR=${3:-"./wiremock-recordings"}
TARGET_URL=${4:-"https://config2.mparticle.com"}

# Source common functions (will use HTTP_PORT, HTTPS_PORT, MAPPINGS_DIR if set)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# === Check required environment variables for recording ===
if [ -z "$MPARTICLE_API_KEY" ] || [ -z "$MPARTICLE_API_SECRET" ]; then
  echo "❌ Error: MPARTICLE_API_KEY and MPARTICLE_API_SECRET environment variables must be set for recording mode"
  echo "   Real API keys are required to record actual API responses from mParticle servers"
  exit 1
fi

# === Build framework and generate project ===
build_framework

echo "🔄 Generating project with Tuist..."
tuist generate --no-open

# === Script-specific configuration ===
CONTAINER_NAME="wiremock-recorder"

# === Prepare local directory for mappings ===
mkdir -p "${MAPPINGS_DIR}/mappings"
mkdir -p "${MAPPINGS_DIR}/__files"

# Create proxy mappings for recording
create_proxy_mappings

# Trap to ensure cleanup on exit
trap stop_wiremock EXIT INT TERM

build_application
find_app_path
reset_simulators
find_available_device
find_device
start_wiremock "record"
wait_for_wiremock
echo "📝 WireMock is running and recording traffic to: ${MAPPINGS_DIR}"
echo "🔗 Admin UI: http://localhost:${HTTP_PORT}/__admin"
echo "🔗 HTTPS Proxy: https://localhost:${HTTPS_PORT}"
echo ""
echo "Press Ctrl+C to stop WireMock and exit..."
echo ""
start_simulator
install_application
launch_application
wait_for_app_completion
