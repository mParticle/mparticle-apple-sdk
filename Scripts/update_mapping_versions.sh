#!/bin/bash

# Version to update
VERSION="$1"

if [ -z "$VERSION" ]; then
	echo "Error: Version argument is required"
	exit 1
fi

# Update SDK version in integration test mappings
# Update "sdk" field in all mapping files
find IntegrationTests/wiremock-recordings/mappings -name "*.json" -type f | while read -r mapping_file; do
	# Update top-level "sdk" field
	if jq -e '.request.bodyPatterns[0].equalToJson.sdk' "${mapping_file}" >/dev/null 2>&1; then
		tmp_file=$(mktemp)
		jq --indent 2 '.request.bodyPatterns[0].equalToJson.sdk = "'"${VERSION}"'"' "${mapping_file}" >"$tmp_file" && mv "$tmp_file" "${mapping_file}"
	fi
	# Update "client_sdk.sdk_version" field (for v1 identify endpoints)
	if jq -e '.request.bodyPatterns[0].equalToJson.client_sdk.sdk_version' "${mapping_file}" >/dev/null 2>&1; then
		tmp_file=$(mktemp)
		jq --indent 2 '.request.bodyPatterns[0].equalToJson.client_sdk.sdk_version = "'"${VERSION}"'"' "${mapping_file}" >"$tmp_file" && mv "$tmp_file" "${mapping_file}"
	fi
done || true

# Update SDK version in config mapping urlPattern (sv=...)
ESCAPED_VERSION="${VERSION//./\\.}"
config_file="IntegrationTests/wiremock-recordings/mappings/mapping-v4-config-get-config.json"
if [ -f "$config_file" ]; then
	# Use jq with sub() function to replace version in urlPattern (matching escaped dots \.)
	tmp_file=$(mktemp)
	jq --indent 2 --arg new_version "$ESCAPED_VERSION" '.request.urlPattern |= sub("sv=\\d+\\\\\\.\\d+\\\\\\.\\d+"; "sv=" + $new_version)' "$config_file" >"$tmp_file" && mv "$tmp_file" "$config_file"
	echo "Updated SDK version in $config_file urlPattern to sv=${ESCAPED_VERSION}"
else
	echo "Warning: $config_file not found"
fi
