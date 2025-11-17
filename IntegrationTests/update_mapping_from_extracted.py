#!/usr/bin/env python3
"""
Script to update WireMock mapping from extracted request body file.

Usage:
    python3 update_mapping_from_extracted.py <extracted_file>

Example:
    python3 update_mapping_from_extracted.py wiremock-recordings/requests/identify_test.json
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any


def update_mapping(extracted_file: str) -> None:
    """
    Updates WireMock mapping from extracted request body file.
    
    Args:
        extracted_file: Path to extracted file
    """
    # Check if file exists
    extracted_path = Path(extracted_file)
    if not extracted_path.exists():
        print(f"❌ Error: extracted file not found: {extracted_file}")
        sys.exit(1)
    
    # Read extracted file
    try:
        with open(extracted_path, 'r', encoding='utf-8') as f:
            extracted_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from extracted file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading extracted file: {e}")
        sys.exit(1)
    
    # Extract data
    try:
        test_name = extracted_data.get('test_name')
        source_mapping = extracted_data.get('source_mapping')
        request_body = extracted_data.get('request_body')
        
        if not source_mapping:
            print("❌ Error: source_mapping not found in extracted file")
            sys.exit(1)
        
        if request_body is None:
            print("❌ Error: request_body not found in extracted file")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error extracting data from extracted file: {e}")
        sys.exit(1)
    
    # Check if source mapping exists
    mapping_path = Path(source_mapping)
    if not mapping_path.exists():
        print(f"❌ Error: source mapping not found: {source_mapping}")
        sys.exit(1)
    
    # Read source mapping
    try:
        with open(mapping_path, 'r', encoding='utf-8') as f:
            mapping_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from mapping: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading mapping: {e}")
        sys.exit(1)
    
    # Update request body in mapping
    try:
        # Convert request_body back to escaped JSON string
        escaped_json = json.dumps(request_body, ensure_ascii=False, separators=(',', ':'))
        
        # Update bodyPatterns
        if 'request' not in mapping_data:
            mapping_data['request'] = {}
        
        if 'bodyPatterns' not in mapping_data['request']:
            mapping_data['request']['bodyPatterns'] = [{}]
        
        mapping_data['request']['bodyPatterns'][0]['equalToJson'] = escaped_json
        
    except Exception as e:
        print(f"❌ Error updating mapping: {e}")
        sys.exit(1)
    
    # Save updated mapping
    try:
        with open(mapping_path, 'w', encoding='utf-8') as f:
            json.dump(mapping_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Mapping successfully updated: {mapping_path}")
        print(f"📝 Test: {test_name}")
        
    except Exception as e:
        print(f"❌ Error saving mapping: {e}")
        sys.exit(1)


def main():
    """Main function."""
    # Check command line arguments
    if len(sys.argv) != 2:
        print("❌ Error: invalid number of arguments")
        print()
        print("Usage:")
        print(f"    {sys.argv[0]} <extracted_file>")
        print()
        print("Example:")
        print(f"    {sys.argv[0]} wiremock-recordings/requests/identify_test.json")
        sys.exit(1)
    
    extracted_file = sys.argv[1]
    
    # Warning
    print("⚠️  WARNING: This script will overwrite the existing mapping!")
    print()
    
    update_mapping(extracted_file)


if __name__ == "__main__":
    main()

