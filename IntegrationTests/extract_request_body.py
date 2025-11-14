#!/usr/bin/env python3
"""
Script for extracting JSON request bodies from WireMock mappings.

Usage:
    python3 extract_request_body.py <mapping_file> <test_name>

Example:
    python3 extract_request_body.py wiremock-recordings/mappings/mapping-v1-identify.json identify_test
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, Any


def extract_request_body(mapping_file: str, test_name: str) -> None:
    """
    Extracts JSON body from WireMock mapping and saves it to a separate file.
    
    Args:
        mapping_file: Path to mapping file
        test_name: Test name
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
    # Check command line arguments
    if len(sys.argv) != 3:
        print("❌ Error: incorrect number of arguments")
        print()
        print("Usage:")
        print(f"    {sys.argv[0]} <mapping_file> <test_name>")
        print()
        print("Example:")
        print(f"    {sys.argv[0]} wiremock-recordings/mappings/mapping-v1-identify.json identify_test")
        sys.exit(1)
    
    mapping_file = sys.argv[1]
    test_name = sys.argv[2]
    
    extract_request_body(mapping_file, test_name)


if __name__ == "__main__":
    main()

