#!/bin/bash

# Version to update
VERSION="$1"

if [[ -z ${VERSION} ]]; then
	echo "Error: Version argument is required"
	exit 1
fi

# Escape dots in version for use in sed patterns
ESCAPED_VERSION="${VERSION//./\\.}"

# Update SDK version in integration test mappings using sed
# This preserves the original file formatting (unlike jq which re-serializes)
find IntegrationTests/wiremock-recordings/mappings -name "*.json" -type f | while read -r mapping_file; do
	# Update "sdk": "x.y.z" field
	if grep -q '"sdk":' "${mapping_file}"; then
		sed -i '' 's/"sdk": "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"/"sdk": "'"${VERSION}"'"/' "${mapping_file}"
	fi
	# Update "sdk_version": "x.y.z" field (for v1 identify endpoints)
	if grep -q '"sdk_version":' "${mapping_file}"; then
		sed -i '' 's/"sdk_version": "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"/"sdk_version": "'"${VERSION}"'"/' "${mapping_file}"
	fi
done || true

# Update SDK version in config mapping urlPattern (sv=x.y.z with escaped dots)
config_file="IntegrationTests/wiremock-recordings/mappings/mapping-v4-config-get-config.json"
if [[ -f ${config_file} ]]; then
	# Match sv=X\.Y\.Z (escaped dots) and replace with new version (also escaped)
	sed -i '' 's/sv=[0-9][0-9]*\\\\.[0-9][0-9]*\\\\.[0-9][0-9]*/sv='"${ESCAPED_VERSION}"'/' "${config_file}"
	echo "Updated SDK version in ${config_file} urlPattern to sv=${ESCAPED_VERSION}"
else
	echo "Warning: ${config_file} not found"
fi
