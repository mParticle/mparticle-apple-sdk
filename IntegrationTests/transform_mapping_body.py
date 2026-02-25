#!/usr/bin/env python3
"""
Script for transforming request body in WireMock mappings.

This script can:
- Unescape JSON body from string to formatted JSON object
- Escape JSON body from object back to string format
- Update dynamic fields with ${json-unit.ignore} placeholder
- Replace SDK_VERSION_PLACEHOLDER with the actual SDK version

Usage:
    python3 transform_mapping_body.py <mapping_file> <mode> [--version VERSION]

Modes:
    unescape        - Convert equalToJson from escaped string to formatted JSON object in file
    escape          - Convert equalToJson from JSON object back to escaped string in file
    unescape+update - Parse, replace dynamic fields with ${json-unit.ignore}, convert to JSON object, and save
    update-version  - Replace SDK_VERSION_PLACEHOLDER with the provided --version value

Examples:
    python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json unescape
    python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json escape
    python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json unescape+update
    python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json update-version --version 8.41.1
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, Any, List, Union


# Default list of fields to replace with ${json-unit.ignore}
# Based on existing WireMock mappings that contain dynamic/timestamp values
DEFAULT_REPLACE_FIELDS = [
    'a',       # App ID
    'bid',     # Bundle ID / Build ID
    'bsv',     # Build System Version
    'ck',      # Cookies (appears after first API response)
    'ct',      # Creation Time / Current Time
    'das',     # Device Application Stamp
    'dfs',     # Device Fingerprint String
    'dlc',     # Device Locale
    'dn',      # Device Name
    'dosv',    # Device OS Version
    'el',      # Event Length (duration in milliseconds for timed events)
    'en',      # Event Number (position in session, e.g., 0, 1, 2...)
    'est',     # Event Start Time
    'iba',     # Instruction Base Address (memory address for errors)
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
    """
    if isinstance(data, dict):
        result = {}
        for key, value in data.items():
            if key == field_name:
                result[key] = replacement_value
            else:
                result[key] = replace_field_value(value, field_name, replacement_value)
        return result
    elif isinstance(data, list):
        return [replace_field_value(item, field_name, replacement_value) for item in data]
    else:
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
    """
    result = data
    for field_name in field_names:
        result = replace_field_value(result, field_name, replacement_value)
    return result


def load_mapping_file(mapping_file: str) -> tuple[Path, Dict[str, Any]]:
    """
    Loads and parses mapping file.
    
    Args:
        mapping_file: Path to mapping file
        
    Returns:
        Tuple (Path to file, mapping data from JSON)
    """
    mapping_path = Path(mapping_file)
    if not mapping_path.exists():
        print(f"❌ Error: mapping file not found: {mapping_file}")
        sys.exit(1)
    
    try:
        with open(mapping_path, 'r', encoding='utf-8') as f:
            mapping_data = json.load(f)
        return (mapping_path, mapping_data)
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from mapping file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading mapping file: {e}")
        sys.exit(1)


def get_request_body_from_mapping(mapping_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extracts and unescapes request body from mapping data.
    
    Args:
        mapping_data: Mapping data from JSON
        
    Returns:
        Parsed request body as JSON object
    """
    try:
        request_data = mapping_data.get('request', {})
        body_patterns = request_data.get('bodyPatterns', [])
        
        if not body_patterns:
            print("❌ Error: bodyPatterns not found in mapping")
            sys.exit(1)
        
        equal_to_json = body_patterns[0].get('equalToJson')
        if equal_to_json is None:
            print("❌ Error: equalToJson not found in bodyPatterns")
            sys.exit(1)
        
        # If equalToJson is already a dict/list (JSON object), return it directly
        if isinstance(equal_to_json, (dict, list)):
            return equal_to_json
        
        # Otherwise, parse escaped JSON string to actual JSON object
        request_body = json.loads(equal_to_json)
        return request_body
        
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from equalToJson: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error extracting body from mapping: {e}")
        sys.exit(1)


def set_request_body_in_mapping(mapping_data: Dict[str, Any], request_body: Dict[str, Any], as_string: bool = True) -> Dict[str, Any]:
    """
    Sets request body in mapping data.
    
    Args:
        mapping_data: Mapping data from JSON
        request_body: Request body as JSON object
        as_string: If True, convert to escaped string. If False, keep as JSON object.
        
    Returns:
        Updated mapping data
    """
    try:
        # Update mapping data
        if 'request' not in mapping_data:
            mapping_data['request'] = {}
        if 'bodyPatterns' not in mapping_data['request']:
            mapping_data['request']['bodyPatterns'] = [{}]
        
        if as_string:
            # Convert JSON object to escaped string (for escape mode)
            escaped_json = json.dumps(request_body, ensure_ascii=False)
            mapping_data['request']['bodyPatterns'][0]['equalToJson'] = escaped_json
        else:
            # Keep as JSON object (for unescape mode)
            mapping_data['request']['bodyPatterns'][0]['equalToJson'] = request_body
        
        mapping_data['request']['bodyPatterns'][0]['ignoreExtraElements'] = False
        
        return mapping_data
        
    except Exception as e:
        print(f"❌ Error setting body in mapping: {e}")
        sys.exit(1)


def mode_unescape(mapping_data: Dict[str, Any], mapping_path: Path) -> None:
    """
    Mode: unescape
    Converts equalToJson from escaped string to formatted JSON object and saves to file.
    
    Args:
        mapping_data: Mapping data from JSON
        mapping_path: Path to mapping file
    """
    request_body = get_request_body_from_mapping(mapping_data)
    
    print(f"📄 Mapping file: {mapping_path}")
    print(f"🔄 Converting equalToJson from string to formatted JSON object...")
    
    # Replace escaped string with actual JSON object
    if 'request' in mapping_data and 'bodyPatterns' in mapping_data['request']:
        mapping_data['request']['bodyPatterns'][0]['equalToJson'] = request_body
        mapping_data['request']['bodyPatterns'][0]['ignoreExtraElements'] = False
    
    # Save updated mapping back to file
    try:
        # Save updated mapping
        with open(mapping_path, 'w', encoding='utf-8') as f:
            json.dump(mapping_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Mapping file updated successfully!")
        print(f"📝 equalToJson is now a formatted JSON object:\n")
        print(json.dumps(request_body, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"❌ Error saving updated mapping file: {e}")
        sys.exit(1)


def mode_escape(mapping_data: Dict[str, Any], mapping_path: Path) -> None:
    """
    Mode: escape
    Converts equalToJson from JSON object to escaped string and saves to file.
    
    Args:
        mapping_data: Mapping data from JSON
        mapping_path: Path to mapping file
    """
    # Check if equalToJson is already a string (nothing to do)
    try:
        equal_to_json = mapping_data['request']['bodyPatterns'][0]['equalToJson']
        
        # If it's already a string, nothing to escape
        if isinstance(equal_to_json, str):
            print(f"📄 Mapping file: {mapping_path}")
            print(f"ℹ️  equalToJson is already a string (escaped format)")
            print(f"✅ No action needed")
            return
        
        # It's a JSON object, convert it to string
        print(f"📄 Mapping file: {mapping_path}")
        print(f"🔄 Converting equalToJson from JSON object to escaped string...")
        
        escaped_json = json.dumps(equal_to_json, ensure_ascii=False)
        mapping_data['request']['bodyPatterns'][0]['equalToJson'] = escaped_json
        mapping_data['request']['bodyPatterns'][0]['ignoreExtraElements'] = False
        
        # Save updated mapping back to file
        with open(mapping_path, 'w', encoding='utf-8') as f:
            json.dump(mapping_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Mapping file updated successfully!")
        print(f"📝 equalToJson is now an escaped string")
        
    except KeyError:
        print(f"❌ Error: equalToJson not found in mapping")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


def mode_unescape_update(mapping_data: Dict[str, Any], mapping_path: Path) -> None:
    """
    Mode: unescape+update
    Unescapes body, replaces dynamic fields, converts to JSON object, and saves back to mapping file.
    
    Args:
        mapping_data: Mapping data from JSON
        mapping_path: Path to mapping file
    """
    request_body = get_request_body_from_mapping(mapping_data)
    
    print(f"📄 Mapping file: {mapping_path}")
    print(f"🔄 Replacing {len(DEFAULT_REPLACE_FIELDS)} dynamic fields with ${{json-unit.ignore}}...")
    
    # Replace dynamic fields
    updated_body = replace_fields_from_list(request_body, DEFAULT_REPLACE_FIELDS)
    
    # Update mapping data with modified body as JSON object (not string)
    mapping_data = set_request_body_in_mapping(mapping_data, updated_body, as_string=False)
    
    # Save updated mapping back to file
    try:
        # Save updated mapping
        with open(mapping_path, 'w', encoding='utf-8') as f:
            json.dump(mapping_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Mapping file updated successfully!")
        print(f"📝 Updated body with replaced fields:\n")
        print(json.dumps(updated_body, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"❌ Error saving updated mapping file: {e}")
        sys.exit(1)


def mode_update_version(mapping_data: Dict[str, Any], mapping_path: Path, version: str) -> None:
    """
    Mode: update-version
    Replaces SDK_VERSION_PLACEHOLDER with the provided version in body patterns and urlPattern.

    Args:
        mapping_data: Mapping data from JSON
        mapping_path: Path to mapping file
        version: SDK version string to substitute (e.g. "8.41.1")
    """
    VERSION_PLACEHOLDER = "SDK_VERSION_PLACEHOLDER"
    updated = False

    request = mapping_data.get('request', {})

    # Update sdk / sdk_version fields inside bodyPatterns
    for pattern in request.get('bodyPatterns', []):
        equal_to_json = pattern.get('equalToJson')
        if equal_to_json is None:
            continue

        as_string = isinstance(equal_to_json, str)
        body = json.loads(equal_to_json) if as_string else equal_to_json

        new_body = replace_field_value(body, 'sdk', version)
        new_body = replace_field_value(new_body, 'sdk_version', version)

        if new_body != body:
            pattern['equalToJson'] = json.dumps(new_body, ensure_ascii=False) if as_string else new_body
            updated = True

    # Update SDK_VERSION_PLACEHOLDER in urlPattern (escape dots so it works as a regex)
    url_pattern = request.get('urlPattern')
    if url_pattern and VERSION_PLACEHOLDER in url_pattern:
        version_regex = version.replace('.', '\\.')
        mapping_data['request']['urlPattern'] = url_pattern.replace(VERSION_PLACEHOLDER, version_regex)
        updated = True

    if updated:
        try:
            with open(mapping_path, 'w', encoding='utf-8') as f:
                json.dump(mapping_data, f, indent=2, ensure_ascii=False)
            print(f"✅ Updated SDK version to {version} in {mapping_path}")
        except Exception as e:
            print(f"❌ Error saving {mapping_path}: {e}")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description='Transform request body in WireMock mappings',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Modes:
  unescape        Convert equalToJson from escaped string to formatted JSON object
  escape          Convert equalToJson from JSON object back to escaped string
  unescape+update Parse, replace dynamic fields, convert to JSON object, and save
  update-version  Replace SDK_VERSION_PLACEHOLDER with --version value

Examples:
  python3 transform_mapping_body.py mappings/mapping-v1-identify.json unescape
  python3 transform_mapping_body.py mappings/mapping-v1-identify.json escape
  python3 transform_mapping_body.py mappings/mapping-v1-identify.json unescape+update
  python3 transform_mapping_body.py mappings/mapping-v1-identify.json update-version --version 8.41.1
        """
    )

    parser.add_argument(
        'mapping_file',
        help='Path to WireMock mapping file'
    )

    parser.add_argument(
        'mode',
        choices=['unescape', 'escape', 'unescape+update', 'update-version'],
        help='Operation mode'
    )

    parser.add_argument(
        '--version',
        help='SDK version to substitute for SDK_VERSION_PLACEHOLDER (required for update-version mode)'
    )

    args = parser.parse_args()

    if args.mode == 'update-version' and not args.version:
        parser.error('--version is required for update-version mode')

    # Load mapping file
    mapping_path, mapping_data = load_mapping_file(args.mapping_file)

    # Execute based on mode
    if args.mode == 'unescape':
        mode_unescape(mapping_data, mapping_path)
    elif args.mode == 'escape':
        mode_escape(mapping_data, mapping_path)
    elif args.mode == 'unescape+update':
        mode_unescape_update(mapping_data, mapping_path)
    elif args.mode == 'update-version':
        mode_update_version(mapping_data, mapping_path, args.version)


if __name__ == "__main__":
    main()

