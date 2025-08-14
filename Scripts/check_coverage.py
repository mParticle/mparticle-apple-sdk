import sys
import json
import os


files_to_check = set()

COVERAGE_THRESHOLD=90

IGNORED_PATHS = [
    "UnitTests"
]

GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"

def is_ignored(path):
    for ignore in IGNORED_PATHS:
        if ignore in path:
            return True
    
    return False

with open("./build/coverage.json") as f:
    data = json.load(f)
    
failed_files = []

def matched_file_list(full_path):
    return any(full_path.endwith(check_path) for check_path in files_to_check)

for target in data.get("targets", []):
    for file in target.get("files", []):
        path = file.get("path", file["name"])
        
        if files_to_check and not matched_file_list(path):
            continue
            
        if is_ignored(path):
            continue
            
        coverage = file.get("lineCoverage", 0) * 100
        
        if coverage == 100:
            color = GREEN
            continue
        elif coverage >= COVERAGE_THRESHOLD:
            color = GREEN
        else:
            color = RED
            failed_files.append((path, coverage))
            
        print(f"{color}{path}: {coverage:.3f}%{RESET}")
