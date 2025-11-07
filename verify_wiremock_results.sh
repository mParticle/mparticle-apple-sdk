#!/bin/bash
set -e

WIREMOCK_PORT=8080
MAPPINGS_DIR="./wiremock-recordings/mappings"

echo "🔍 Проверка результатов WireMock..."
echo

# === Считаем все запросы ===
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

# === Проверяем лишние запросы (unmatched) ===
if [ "$UNMATCHED" -gt 0 ]; then
  echo "❌ Найдены запросы, которые не совпали с маппингами:"
  curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests/unmatched | \
    jq -r '.requests[] | "  [\(.method)] \(.url)"'
  echo
else
  echo "✅ Все пришедшие запросы нашли свои маппинги."
  echo
fi

# === Проверяем пропущенные маппинги ===
echo "🧩 Проверка: все ли маппинги были вызваны..."
MISSING=$(curl -s http://localhost:${WIREMOCK_PORT}/__admin/requests | \
  jq -r --slurpfile m <(jq -s '[.[].request | {method: (.method // "ANY"), url: (.url // .urlPattern // .urlPath // .urlPathPattern)}]' ${MAPPINGS_DIR}/*.json) '
    ([(.requests? // .)[] | {method: .request.method, url: .request.url}] | unique) as $actual |
    ($m[0] - $actual)[] | "\(.method) \(.url)"' || true)

if [ -n "$MISSING" ]; then
  echo "⚠️  Эти маппинги не были вызваны приложением:"
  echo "$MISSING"
else
  echo "✅ Все записанные маппинги были вызваны приложением."
fi

echo
echo "🎯 Проверка завершена."

