#!/bin/bash
set -e

WIREMOCK_PORT=8080
MAPPINGS_DIR="./wiremock-recordings/mappings"

echo "🔍 Verifying WireMock results..."
echo

# === Count all requests ===
TOTAL=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests | jq '.requests | length')
UNMATCHED=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests/unmatched | jq '.requests | length')
MATCHED=$((TOTAL - UNMATCHED))
PROXIED=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests | jq '[.requests[] | select(.wasProxyRequest==true)] | length')

echo "📊 WireMock summary:"
echo "──────────────────────────────"
echo "  Total requests:     $TOTAL"
echo "  Matched requests:   $MATCHED"
echo "  Unmatched requests: $UNMATCHED"
echo "  Proxied requests:   $PROXIED"
echo "──────────────────────────────"
echo

# === Check for unmatched requests ===
if [ "$UNMATCHED" -gt 0 ]; then
  echo "❌ Found requests that did not match any mappings:"
  curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests/unmatched | \
    jq -r '.requests[] | "  [\(.method)] \(.url)"'
  echo
else
  echo "✅ All incoming requests matched their mappings."
  echo
fi

# === Check for missed mappings ===
echo "🧩 Checking: were all mappings invoked..."
MISSING=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests | \
  jq -r --slurpfile m <(jq -s '[.[].request | {method: (.method // "ANY"), url: (.url // .urlPattern // .urlPath // .urlPathPattern)}]' ${MAPPINGS_DIR}/*.json) '
    ([(.requests? // .)[] | {method: .request.method, url: .request.url}] | unique) as $actual |
    ($m[0] - $actual)[] | "\(.method) \(.url)"' || true)

if [ -n "$MISSING" ]; then
  echo "⚠️  These mappings were not invoked by the application:"
  echo "$MISSING"
else
  echo "✅ All recorded mappings were invoked by the application."
fi

echo
echo "🎯 Verification complete."

