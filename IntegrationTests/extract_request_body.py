#!/usr/bin/env python3
"""
Script for extracting JSON request bodies from WireMock mappings.

Usage:
    python3 extract_request_body.py <mapping_file> <test_name> [--replace]

Example:
    python3 extract_request_body.py wiremock-recordings/mappings/mapping-v1-identify.json identify_test
    python3 extract_request_body.py wiremock-recordings/mappings/mapping-v1-identify.json identify_test --replace
"""

import json
import sys
import os
import argparse
from pathlib import Path
from typing import Dict, Any, List, Union


# Default list of fields to replace with ${json-unit.ignore}
# Based on existing WireMock mappings that contain dynamic/timestamp values
DEFAULT_REPLACE_FIELDS = [
    'a',       # App ID
    'bid',     # Bundle ID / Build ID
    'bsv',     # Build System Version
    'ct',      # Creation Time / Current Time
    'das',     # Device Application Stamp
    'dfs',     # Device Fingerprint String
    'dlc',     # Device Locale
    'dn',      # Device Name
    'dosv',    # Device OS Version
    'est',     # Event Start Time
    'ict',     # Init Config Time
    'id',      # ID (various message/event IDs)
    'lud',     # Last Update Date
    'sct',     # Session Creation Time
    'sid',     # Session ID
    'vid',     # Vendor ID
]


def replace_field_value(data: Union[Dict, List, Any], field_name: str, replacement_value: str) -> Union[Dict, List, Any]:
    """
    Recursively replaces the value of a specified field in a JSON structure.
    
    Args:
        data: JSON data (dict, list, or primitive value)
        field_name: Name of the field to replace
        replacement_value: New value to set for the field
        
    Returns:
        Modified data structure with replaced field values
    
    Example:
        data = {"id": "123", "name": "test", "nested": {"id": "456"}}
        result = replace_field_value(data, "id", "${json-unit.ignore}")
        # result = {"id": "${json-unit.ignore}", "name": "test", "nested": {"id": "${json-unit.ignore}"}}
    """
    if isinstance(data, dict):
        # For dictionaries, check each key
        result = {}
        for key, value in data.items():
            if key == field_name:
                # Replace the value for this field
                result[key] = replacement_value
            else:
                # Recursively process the value
                result[key] = replace_field_value(value, field_name, replacement_value)
        return result
    elif isinstance(data, list):
        # For lists, recursively process each item
        return [replace_field_value(item, field_name, replacement_value) for item in data]
    else:
        # For primitive values, return as is
        return data


def replace_fields_from_list(data: Union[Dict, List, Any], field_names: List[str], replacement_value: str = "${json-unit.ignore}") -> Union[Dict, List, Any]:
    """
    Replaces values of multiple fields in a JSON structure with a specified value.
    
    Args:
        data: JSON data (dict, list, or primitive value)
        field_names: List of field names to replace
        replacement_value: Value to use for replacement (default: "${json-unit.ignore}")
        
    Returns:
        Modified data structure with all specified fields replaced
    
    Example:
        data = {"id": "123", "ct": "1234567890", "name": "test", "nested": {"id": "456", "ct": "0987654321"}}
        result = replace_fields_from_list(data, ["id", "ct"])
        # result = {"id": "${json-unit.ignore}", "ct": "${json-unit.ignore}", "name": "test", 
        #           "nested": {"id": "${json-unit.ignore}", "ct": "${json-unit.ignore}"}}
        
        # Or with custom replacement value:
        result = replace_fields_from_list(data, ["id", "ct"], "IGNORED")
        # result = {"id": "IGNORED", "ct": "IGNORED", "name": "test", "nested": {"id": "IGNORED", "ct": "IGNORED"}}
    """
    result = data
    
    # Apply replacement for each field in the list
    for field_name in field_names:
        result = replace_field_value(result, field_name, replacement_value)
    
    return result

def extract_request_body(mapping_file: str, test_name: str, replace_fields: bool = False) -> None:
    """
    Extracts JSON body from WireMock mapping and saves it to a separate file.
    
    Args:
        mapping_file: Path to mapping file
        test_name: Test name
        replace_fields: If True, replaces known dynamic fields with ${json-unit.ignore}
    """
    # Check if mapping file exists
    mapping_path = Path(mapping_file)
    if not mapping_path.exists():
        print(f"❌ Error: mapping file not found: {mapping_file}")
        sys.exit(1)
    
    # Read mapping file
    try:
        with open(mapping_path, 'r', encoding='utf-8') as f:
            mapping_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from mapping file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading mapping file: {e}")
        sys.exit(1)
    
    # Extract request information
    try:
        request_data = mapping_data.get('request', {})
        method = request_data.get('method', 'UNKNOWN')
        url = request_data.get('url', 'UNKNOWN')
        
        body_patterns = request_data.get('bodyPatterns', [])
        
        # Check for body presence
        if not body_patterns:
            # This might be a GET request or another method without body
            print(f"⚠️  Warning: bodyPatterns not found in mapping")
            print(f"    Request method: {method}")
            print(f"    URL: {url}")
            print("    (GET requests usually don't have a body)")
            sys.exit(1)
        
        # Get escaped JSON string
        equal_to_json = body_patterns[0].get('equalToJson')
        if equal_to_json is None:
            print("❌ Error: equalToJson not found in bodyPatterns")
            sys.exit(1)
        
        # Parse escaped JSON string to get the actual JSON object
        # (unescape)
        request_body = json.loads(equal_to_json)
        
        # Apply field replacements if requested
        if replace_fields:
            print(f"🔄 Replacing {len(DEFAULT_REPLACE_FIELDS)} known dynamic fields with ${{json-unit.ignore}}")
            request_body = replace_fields_from_list(request_body, DEFAULT_REPLACE_FIELDS)
        
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from equalToJson: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error extracting body from mapping: {e}")
        sys.exit(1)
    
    # Form output structure
    output_data = {
        "test_name": test_name,
        "source_mapping": str(mapping_path),
        "request_method": method,
        "request_url": url,
        "request_body": request_body
    }
    
    # Create directory for saving extracted bodies
    output_dir = Path("wiremock-recordings/requests")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Form output filename
    output_file = output_dir / f"{test_name}.json"
    
    # Save to file with pretty-print for readability
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ JSON body successfully extracted and saved to: {output_file}")
        print(f"📝 Test name: {test_name}")
        print(f"🔗 Source mapping: {mapping_path}")
        
    except Exception as e:
        print(f"❌ Error saving file: {e}")
        sys.exit(1)


def main():
    # Set up command line argument parser
    parser = argparse.ArgumentParser(
        description='Extract JSON request bodies from WireMock mappings',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        'mapping_file',
        help='Path to WireMock mapping file'
    )
    
    parser.add_argument(
        'test_name',
        help='Test name for the output file'
    )
    
    parser.add_argument(
        '--replace',
        action='store_true',
        help='Replace known dynamic fields with ${json-unit.ignore}'
    )
    
    args = parser.parse_args()
    
    extract_request_body(args.mapping_file, args.test_name, replace_fields=args.replace)


if __name__ == "__main__":
    main()

