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
import re
from pathlib import Path
from typing import Dict, Any, List, Union, Tuple


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


def sanitize_url(url: str) -> str:
    """
    Replaces API key in URL with a placeholder.
    
    Matches patterns like:
    - /v2/us1-XXXXXXXX/events -> /v2/{API_KEY}/events
    - /v1/us1-XXXXXXXX/identify -> /v1/{API_KEY}/identify
    
    Args:
        url: Original URL that may contain API key
        
    Returns:
        Sanitized URL with API key replaced by {API_KEY}
    """
    # Pattern to match API keys like "api-key"
    # Format: us1-{32 hex characters}
    api_key_pattern = r'us1-[a-f0-9]{32}'
    
    # Replace API key with placeholder
    sanitized = re.sub(api_key_pattern, '{API_KEY}', url)
    
    return sanitized


def sanitize_body_filename(filename: str) -> Tuple[str, str]:
    """
    Removes API key from body filename and returns both old and new names.
    
    Args:
        filename: Original filename that may contain API key
        
    Returns:
        Tuple of (old_filename, new_filename)
    """
    if not filename:
        return (filename, filename)
    
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


def rename_body_file(old_filename: str, new_filename: str) -> bool:
    """
    Renames body file if names are different.
    
    Args:
        old_filename: Current filename
        new_filename: New filename to rename to
        
    Returns:
        True if file was renamed, False otherwise
    """
    if old_filename == new_filename:
        return False
    
    old_path = Path("wiremock-recordings/__files") / old_filename
    new_path = Path("wiremock-recordings/__files") / new_filename
    
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
    Загружает и парсит файл маппинга.
    
    Args:
        mapping_file: Путь к файлу маппинга
        
    Returns:
        Tuple (Path к файлу, данные маппинга из JSON)
    """
    # Проверяем существование файла
    mapping_path = Path(mapping_file)
    if not mapping_path.exists():
        print(f"❌ Error: mapping file not found: {mapping_file}")
        sys.exit(1)
    
    # Читаем файл маппинга
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


def rename_mapping_file(mapping_path: Path) -> Path:
    """
    Консистентно переименовывает файл маппинга, если в имени есть API key.
    
    Args:
        mapping_path: Path к файлу маппинга
        
    Returns:
        Path к переименованному файлу (или к исходному, если переименование не требуется)
    """
    filename = mapping_path.name
    
    # Убираем API key из имени файла
    api_key_pattern = r'-us1-[a-f0-9]{32}'
    if re.search(api_key_pattern, filename):
        new_filename = re.sub(api_key_pattern, '', filename)
        new_path = mapping_path.parent / new_filename
        
        if new_path.exists():
            print(f"⚠️  Warning: Target mapping file already exists: {new_path}")
            return mapping_path
        
        try:
            mapping_path.rename(new_path)
            print(f"📝 Renamed mapping file: {filename} -> {new_filename}")
            return new_path
        except Exception as e:
            print(f"❌ Error renaming mapping file: {e}")
            return mapping_path
    
    return mapping_path


def rename_response_body_and_update_mapping(mapping_data: Dict[str, Any]) -> Tuple[Dict[str, Any], bool]:
    """
    Переименовывает тело ответа (bodyFileName) и обновляет его имя в данных маппинга.
    
    Args:
        mapping_data: Данные маппинга из JSON
        
    Returns:
        Tuple (обновленные данные маппинга, был ли переименован файл)
    """
    response_data = mapping_data.get('response', {})
    original_body_filename = response_data.get('bodyFileName', '')
    
    if not original_body_filename:
        return (mapping_data, False)
    
    old_body_filename, new_body_filename = sanitize_body_filename(original_body_filename)
    
    if old_body_filename == new_body_filename:
        return (mapping_data, False)
    
    # Переименовываем файл
    if rename_body_file(old_body_filename, new_body_filename):
        # Обновляем mapping data с новым именем файла
        mapping_data['response']['bodyFileName'] = new_body_filename
        print(f"🔐 Updated body filename reference in mapping")
        return (mapping_data, True)
    
    return (mapping_data, False)


def extract_and_save_request_body(
    mapping_data: Dict[str, Any], 
    test_name: str, 
    mapping_path: Path,
    replace_fields: bool = False
) -> None:
    """
    Извлекает тело запроса из маппинга, применяет замены полей и сохраняет в файл.
    
    Args:
        mapping_data: Данные маппинга из JSON
        test_name: Имя теста для output файла
        mapping_path: Path к исходному файлу маппинга
        replace_fields: Применять ли замены полей на ${json-unit.ignore}
    """
    try:
        request_data = mapping_data.get('request', {})
        method = request_data.get('method', 'UNKNOWN')
        url = request_data.get('url') or request_data.get('urlPattern', 'UNKNOWN')
        
        body_patterns = request_data.get('bodyPatterns', [])
        
        # Проверяем наличие body
        if not body_patterns:
            print(f"⚠️  Warning: bodyPatterns not found in mapping")
            print(f"    Request method: {method}")
            print(f"    URL: {url}")
            print("    (GET requests usually don't have a body)")
            sys.exit(1)
        
        # Получаем escaped JSON string
        equal_to_json = body_patterns[0].get('equalToJson')
        if equal_to_json is None:
            print("❌ Error: equalToJson not found in bodyPatterns")
            sys.exit(1)
        
        # Парсим escaped JSON string в actual JSON object
        request_body = json.loads(equal_to_json)
        
        # Применяем замены полей если указано
        if replace_fields:
            print(f"🔄 Replacing {len(DEFAULT_REPLACE_FIELDS)} known dynamic fields with ${{json-unit.ignore}}")
            request_body = replace_fields_from_list(request_body, DEFAULT_REPLACE_FIELDS)
        
    except json.JSONDecodeError as e:
        print(f"❌ Error: failed to parse JSON from equalToJson: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error extracting body from mapping: {e}")
        sys.exit(1)
    
    # Формируем структуру для output
    output_data = {
        "test_name": test_name,
        "source_mapping": str(mapping_path),
        "request_method": method,
        "request_url": url,
        "request_body": request_body
    }
    
    # Создаем директорию для сохранения
    output_dir = Path("wiremock-recordings/requests")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Формируем имя output файла
    output_file = output_dir / f"{test_name}.json"
    
    # Сохраняем в файл
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ JSON body successfully extracted and saved to: {output_file}")
        print(f"📝 Test name: {test_name}")
        print(f"🔗 Source mapping: {mapping_path}")
        
    except Exception as e:
        print(f"❌ Error saving file: {e}")
        sys.exit(1)


def sanitize_and_save_mapping(mapping_data: Dict[str, Any], mapping_path: Path) -> Dict[str, Any]:
    """
    Санитизирует URL в маппинге (убирает API key) и сохраняет файл.
    
    Args:
        mapping_data: Данные маппинга из JSON
        mapping_path: Path к файлу маппинга
        
    Returns:
        Обновленные данные маппинга
    """
    request_data = mapping_data.get('request', {})
    original_url = request_data.get('url') or request_data.get('urlPattern', 'UNKNOWN')
    
    # Санитизируем URL для удаления API key
    sanitized_url = sanitize_url(original_url)
    
    # Проверяем, был ли изменен URL
    url_was_sanitized = (original_url != sanitized_url)
    if url_was_sanitized:
        print(f"🔐 Sanitized API key from URL:")
        print(f"   Before: {original_url}")
        print(f"   After:  {sanitized_url}")
        # Обновляем mapping data с sanitized URL
        if 'url' in request_data:
            mapping_data['request']['url'] = sanitized_url
        if 'urlPattern' in request_data:
            mapping_data['request']['urlPattern'] = sanitized_url
    
    return (mapping_data, url_was_sanitized)


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
    
    mapping_path, mapping_data = load_mapping_file(args.mapping_file)
    mapping_path = rename_mapping_file(mapping_path)
    mapping_data, body_file_was_renamed = rename_response_body_and_update_mapping(mapping_data)
    mapping_data, url_was_sanitized = sanitize_and_save_mapping(mapping_data, mapping_path)
    extract_and_save_request_body(mapping_data, args.test_name, mapping_path, args.replace)
    
    mapping_was_modified = url_was_sanitized or body_file_was_renamed
    if mapping_was_modified:
        try:
            with open(mapping_path, 'w', encoding='utf-8') as f:
                json.dump(mapping_data, f, indent=2, ensure_ascii=False)
            print(f"✅ Regenerated mapping file with sanitized data: {mapping_path}")
        except Exception as e:
            print(f"❌ Error saving updated mapping file: {e}")
            sys.exit(1)


if __name__ == "__main__":
    main()

