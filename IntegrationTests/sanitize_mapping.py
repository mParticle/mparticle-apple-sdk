#!/usr/bin/env python3
"""
Script for sanitizing WireMock mapping files by:
- Replacing API keys in URLs with regex pattern: us1-[a-f0-9]+
- Removing API keys from filenames
- Renaming files based on test name

Usage:
    python3 sanitize_mapping.py <mapping_file> --test-name <test_name>

Example:
    python3 sanitize_mapping.py wiremock-recordings/mappings/mapping-v1-us1-abc123-identify.json --test-name identify
    
    Before: /v2/us1-abc123def456.../events  →  After: /v2/us1-[a-f0-9]+/events
"""

import json
import sys
import argparse
import re
from pathlib import Path
from typing import Dict, Any, Tuple


def sanitize_url(url: str) -> str:
    """
    Replaces API key in URL with a regex pattern for WireMock.
    
    Matches patterns like:
    - /v2/us1-abc123.../events -> /v2/us1-[a-f0-9]+/events
    - /v1/us1-xyz789.../identify -> /v1/us1-[a-f0-9]+/identify
    
    Args:
        url: Original URL that may contain API key
        
    Returns:
        Sanitized URL with API key replaced by regex pattern us1-[a-f0-9]+
    """
    # Pattern to match API keys like "us1-{32 hex characters}"
    api_key_pattern = r'us1-[a-f0-9]{32}'
    
    # Replace API key with regex pattern for WireMock
    sanitized = re.sub(api_key_pattern, 'us1-[a-f0-9]+', url)
    
    return sanitized


def sanitize_body_filename(filename: str, test_name: str = None) -> Tuple[str, str]:
    """
    Removes API key from body filename and optionally renames based on test name.
    
    Args:
        filename: Original filename that may contain API key
        test_name: Optional test name to use for renaming
        
    Returns:
        Tuple of (old_filename, new_filename)
    """
    if not filename:
        return (filename, filename)
    
    # If test_name is provided, use it for the new filename
    if test_name:
        # Get file extension
        ext = Path(filename).suffix
        new_filename = f"body-{test_name}{ext}"
        return (filename, new_filename)
    
    # Otherwise, just remove API key from filename
    # Pattern to match API keys in filename
    api_key_pattern = r'us1-[a-f0-9]{32}'
    
    # Find API key in filename
    match = re.search(api_key_pattern, filename)
    if not match:
        # No API key found, return as is
        return (filename, filename)
    
    # Replace API key pattern with generic name
    # Example: body-v2-us1-XXX-events-YYY.json -> body-v2-events-YYY.json
    new_filename = re.sub(r'-us1-[a-f0-9]{32}', '', filename)
    
    return (filename, new_filename)


def rename_body_file(old_filename: str, new_filename: str, base_path: Path) -> bool:
    """
    Renames body file if names are different.
    
    Args:
        old_filename: Current filename
        new_filename: New filename to rename to
        base_path: Base path to the mapping file directory
        
    Returns:
        True if file was renamed, False otherwise
    """
    if old_filename == new_filename:
        return False
    
    # Construct paths relative to the mapping file location
    files_dir = base_path.parent.parent / "__files"
    old_path = files_dir / old_filename
    new_path = files_dir / new_filename
    
    if not old_path.exists():
        print(f"⚠️  Warning: Body file not found: {old_path}")
        return False
    
    if new_path.exists():
        print(f"⚠️  Warning: Target body file already exists: {new_path}")
        return False
    
    try:
        old_path.rename(new_path)
        print(f"📝 Renamed body file: {old_filename} -> {new_filename}")
        return True
    except Exception as e:
        print(f"❌ Error renaming body file: {e}")
        return False


def load_mapping_file(mapping_file: str) -> Tuple[Path, Dict[str, Any]]:
    """
    Loads and parses mapping file.
    
    Args:
        mapping_file: Path to mapping file
        
    Returns:
        Tuple (Path to file, mapping data from JSON)
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
        return (mapping_path, mapping_data)
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from mapping file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading mapping file: {e}")
        sys.exit(1)


def rename_mapping_file(mapping_path: Path, test_name: str = None) -> Tuple[Path, bool]:
    """
    Consistently renames mapping file if it contains API key or test name is provided.
    
    Args:
        mapping_path: Path to mapping file
        test_name: Optional test name to use for renaming
        
    Returns:
        Tuple (Path to renamed file or original, whether file was renamed)
    """
    filename = mapping_path.name
    
    # If test_name is provided, use it for the new filename
    if test_name:
        ext = mapping_path.suffix
        new_filename = f"mapping-{test_name}{ext}"
        new_path = mapping_path.parent / new_filename
        
        if new_path.exists() and new_path != mapping_path:
            print(f"⚠️  Warning: Target mapping file already exists: {new_path}")
            return (mapping_path, False)
        
        if new_filename != filename:
            try:
                mapping_path.rename(new_path)
                print(f"📝 Renamed mapping file: {filename} -> {new_filename}")
                return (new_path, True)
            except Exception as e:
                print(f"❌ Error renaming mapping file: {e}")
                return (mapping_path, False)
        
        return (mapping_path, False)
    
    # Otherwise, just remove API key from filename
    api_key_pattern = r'-us1-[a-f0-9]{32}'
    if re.search(api_key_pattern, filename):
        new_filename = re.sub(api_key_pattern, '', filename)
        new_path = mapping_path.parent / new_filename
        
        if new_path.exists():
            print(f"⚠️  Warning: Target mapping file already exists: {new_path}")
            return (mapping_path, False)
        
        try:
            mapping_path.rename(new_path)
            print(f"📝 Renamed mapping file: {filename} -> {new_filename}")
            return (new_path, True)
        except Exception as e:
            print(f"❌ Error renaming mapping file: {e}")
            return (mapping_path, False)
    
    return (mapping_path, False)


def sanitize_mapping_data(mapping_data: Dict[str, Any], mapping_path: Path, test_name: str = None) -> Tuple[Dict[str, Any], bool]:
    """
    Sanitizes mapping data by:
    1. Removing API key from URL
    2. Renaming response body file and updating reference
    
    Args:
        mapping_data: Mapping data from JSON
        mapping_path: Path to mapping file (for locating body files)
        test_name: Optional test name to use for renaming body file
        
    Returns:
        Tuple (updated mapping data, whether any changes were made)
    """
    changes_made = False
    
    # Sanitize URL
    request_data = mapping_data.get('request', {})
    original_url = request_data.get('url') or request_data.get('urlPattern', '')
    
    if original_url:
        sanitized_url = sanitize_url(original_url)
        
        if original_url != sanitized_url:
            print(f"🔐 Sanitized API key from URL:")
            print(f"   Before: {original_url}")
            print(f"   After:  {sanitized_url}")
            
            # After sanitization, URL contains regex pattern, so use urlPattern
            # Remove 'url' if it exists and use 'urlPattern' instead
            if 'url' in request_data:
                del mapping_data['request']['url']
                print(f"   Changed 'url' to 'urlPattern' (contains regex)")
            mapping_data['request']['urlPattern'] = sanitized_url
            
            changes_made = True
    
    # Sanitize response body filename
    response_data = mapping_data.get('response', {})
    original_body_filename = response_data.get('bodyFileName', '')
    
    if original_body_filename:
        old_body_filename, new_body_filename = sanitize_body_filename(original_body_filename, test_name)
        
        if old_body_filename != new_body_filename:
            # Rename the file
            if rename_body_file(old_body_filename, new_body_filename, mapping_path):
                # Update mapping data with new filename
                mapping_data['response']['bodyFileName'] = new_body_filename
                print(f"🔐 Updated body filename reference in mapping:")
                print(f"   Before: {old_body_filename}")
                print(f"   After:  {new_body_filename}")
                changes_made = True
    
    return (mapping_data, changes_made)


def save_mapping_file(mapping_data: Dict[str, Any], mapping_path: Path) -> None:
    """
    Saves mapping data to file.
    
    Args:
        mapping_data: Mapping data to save
        mapping_path: Path where to save the file
    """
    try:
        with open(mapping_path, 'w', encoding='utf-8') as f:
            json.dump(mapping_data, f, indent=2, ensure_ascii=False)
        print(f"✅ Saved updated mapping file: {mapping_path}")
    except Exception as e:
        print(f"❌ Error saving mapping file: {e}")
        sys.exit(1)


def main():
    # Set up command line argument parser
    parser = argparse.ArgumentParser(
        description='Sanitize WireMock mapping files by removing API keys and renaming based on test name',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Sanitize API keys and rename files
  python3 sanitize_mapping.py wiremock-recordings/mappings/mapping-v1-us1-abc123-identify.json --test-name identify
  python3 sanitize_mapping.py wiremock-recordings/mappings/mapping-v2-us1-abc123-events.json --test-name log-event
        """
    )
    
    parser.add_argument(
        'mapping_file',
        help='Path to WireMock mapping file'
    )
    
    parser.add_argument(
        '--test-name',
        dest='test_name',
        required=True,
        help='Test name to use for renaming mapping and body files (e.g., "log-event", "identify", "transaction-complex-attrs")'
    )
    
    args = parser.parse_args()
    
    print(f"🔍 Processing mapping file: {args.mapping_file}")
    print(f"📝 Test name: {args.test_name}")
    print()
    
    # Load mapping file
    mapping_path, mapping_data = load_mapping_file(args.mapping_file)
    
    # Sanitize mapping data (URL and body filename)
    mapping_data, data_changes_made = sanitize_mapping_data(mapping_data, mapping_path, args.test_name)
    
    # Rename mapping file itself
    mapping_path, file_was_renamed = rename_mapping_file(mapping_path, args.test_name)
    
    # Save mapping file if any changes were made
    if data_changes_made:
        save_mapping_file(mapping_data, mapping_path)
    
    # Print summary
    print()
    if data_changes_made or file_was_renamed:
        print("✅ Sanitization complete!")
        if file_was_renamed:
            print("   - Mapping file renamed")
        if data_changes_made:
            print("   - Mapping data updated")
    else:
        print("ℹ️  No changes needed - mapping is already sanitized")


if __name__ == "__main__":
    main()

