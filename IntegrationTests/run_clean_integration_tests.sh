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

apply_user_friendly_mappings() {
  echo "🔄 Applying user-friendly mappings to WireMock..."
  local REQUESTS_DIR="${MAPPINGS_DIR}/requests"
  
  if [ -d "$REQUESTS_DIR" ] && [ "$(ls -A $REQUESTS_DIR/*.json 2>/dev/null)" ]; then
    local APPLIED_COUNT=0
    for request_file in "$REQUESTS_DIR"/*.json; do
      if [ -f "$request_file" ]; then
        echo "  📝 Applying: $(basename $request_file)"
        python3 update_mapping_from_extracted.py "$request_file" 2>/dev/null || {
          echo "  ⚠️  Failed to apply $(basename $request_file)"
        }
        APPLIED_COUNT=$((APPLIED_COUNT + 1))
      fi
    done
    echo "✅ Applied $APPLIED_COUNT user-friendly mapping(s)"
  else
    echo "⚠️  No user-friendly mappings found in $REQUESTS_DIR (skipping)"
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
    curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests/unmatched | \
      jq -r '.requests[] | "  [\(.method)] \(.url)"'
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
  local ACTUAL_REQUESTS=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests | \
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
  done <<< "$EXPECTED_MAPPINGS"
  
  if [ "$UNUSED_FOUND" = false ]; then
    echo "✅ All recorded mappings were invoked by the application."
  fi
  
  echo ""
  echo "🎉 Verification completed successfully!"
}

# Trap to ensure cleanup on exit
trap stop_wiremock EXIT INT TERM

# === Main execution flow ===
build_application
find_app_path
reset_simulators
find_available_device
find_device
apply_user_friendly_mappings
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
stop_wiremock
