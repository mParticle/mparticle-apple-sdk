#!/bin/bash

# Version to update
VERSION="$1"

if [[ -z ${VERSION} ]]; then
	echo "Error: Version argument is required"
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/../IntegrationTests/transform_mapping_body.py"

find IntegrationTests/wiremock-recordings/mappings -name "*.json" -type f | while read -r mapping_file; do
	python3 "${PYTHON_SCRIPT}" "${mapping_file}" update-version --version "${VERSION}"
done || true
