#!/usr/bin/env python3
r"""
Write a small diagnostic report of an integration test run.

The CI script calls this before WireMock stops, so a failed run keeps the evidence of what
the application sent. The report holds counts, fixture names, field names, message types
and timings only. It never holds a request body, a header, an identifier or a value.

Usage:
    python3 diagnostic_report.py --admin-url http://localhost:8080 \
        --mappings-dir wiremock-recordings/mappings \
        --out artifacts/integration-diagnostics.json \
        --stage verify [--device-name NAME] [--device-id ID] [--mark NAME=EPOCH_MS ...]

The script always exits 0, so it never changes the outcome of the run that calls it.
"""

import argparse
import base64
import gzip
import json
import os
import platform
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

PLACEHOLDER_PREFIX = "${json-unit."
OPTIONAL_PLACEHOLDER = "${json-unit.ignore-element}"
JOURNAL_TIMEOUT_SECONDS = 10
COMMAND_TIMEOUT_SECONDS = 30
SAFE_PATH_SEGMENT = re.compile(r"v[0-9]+|[a-z][a-z_]*")


def is_placeholder(value: Any) -> bool:
    """Tells whether a fixture value is a json-unit placeholder rather than a literal."""
    return isinstance(value, str) and value.startswith(PLACEHOLDER_PREFIX)


def masked_path(url: str) -> str:
    """Keeps a request path's fixed words and replaces every key, ID and query with a mark."""
    path = url.split("?", 1)[0]
    segments = [
        segment if not segment or SAFE_PATH_SEGMENT.fullmatch(segment) else "{value}"
        for segment in path.split("/")
    ]
    return "/".join(segments)


def message_signature(message: Any) -> Tuple[Optional[str], ...]:
    """Builds the literal type, name and event type a message carries, for matching only."""
    if not isinstance(message, dict):
        return (None, None, None)

    def literal(key: str) -> Optional[str]:
        value = message.get(key)
        if isinstance(value, str) and not is_placeholder(value):
            return value
        return None

    return (literal("dt"), literal("n"), literal("et"))


def message_type(message: Any) -> Optional[str]:
    """Returns a message's protocol type code, such as e, ss or uac."""
    if isinstance(message, dict) and isinstance(message.get("dt"), str):
        return message["dt"]
    return None


def signature_matches(expected: Tuple[Optional[str], ...], actual: Tuple[Optional[str], ...]) -> bool:
    """Tells whether a sent message has every literal the fixture's message expects."""
    if expected[0] is None:
        return False
    return all(expected[index] is None or expected[index] == actual[index] for index in range(len(expected)))


def load_mappings(mappings_dir: Path) -> List[Dict[str, Any]]:
    """Reads each fixture's name, request pattern and expected body, escaped or not."""
    mappings = []
    for mapping_file in sorted(mappings_dir.glob("*.json")):
        try:
            mapping = json.loads(mapping_file.read_text())
        except (OSError, ValueError):
            mappings.append({"name": mapping_file.name, "unreadable": True})
            continue
        request = mapping.get("request", {})
        body = None
        for pattern in request.get("bodyPatterns", []):
            if "equalToJson" in pattern:
                body = pattern["equalToJson"]
                if isinstance(body, str):
                    try:
                        body = json.loads(body)
                    except ValueError:
                        body = None
        mappings.append(
            {
                "name": mapping_file.name,
                "id": mapping.get("id"),
                "method": request.get("method"),
                "url": {key: value for key, value in request.items() if key.startswith("url")},
                "body": body if isinstance(body, dict) else None,
            }
        )
    return mappings


def url_matches(spec: Dict[str, str], url: str) -> bool:
    """Applies a fixture's url, urlPath, urlPattern or urlPathPattern to a sent URL."""
    path = url.split("?", 1)[0]
    try:
        if "url" in spec:
            return spec["url"] == url
        if "urlPath" in spec:
            return spec["urlPath"] == path
        if "urlPattern" in spec:
            return re.fullmatch(spec["urlPattern"], url) is not None
        if "urlPathPattern" in spec:
            return re.fullmatch(spec["urlPathPattern"], path) is not None
    except re.error:
        return False
    return True


def read_json(url: str) -> Any:
    """Reads one JSON document from WireMock's admin API."""
    with urllib.request.urlopen(url, timeout=JOURNAL_TIMEOUT_SECONDS) as response:
        return json.loads(response.read().decode("utf-8"))


def read_journal(admin_url: str) -> Tuple[Optional[List[Dict[str, Any]]], Optional[str]]:
    """Returns the served requests oldest first, or the reason the journal could not be read."""
    try:
        journal = read_json(admin_url.rstrip("/") + "/__admin/requests")
    except (urllib.error.URLError, OSError, ValueError) as error:
        return None, f"WireMock's request journal could not be read ({type(error).__name__})"
    if not isinstance(journal, dict) or not isinstance(journal.get("requests"), list):
        return None, "WireMock's request journal had no request list"
    if journal.get("requestJournalDisabled"):
        return None, "WireMock's request journal is disabled"
    served = [event for event in journal["requests"] if isinstance(event, dict)]
    served.sort(key=lambda event: event.get("request", {}).get("loggedDate") or 0)
    return served, None


def request_body(request: Dict[str, Any]) -> Any:
    """Parses a sent body as JSON, decompressing it where the SDK sent it compressed."""
    body = request.get("body")
    if isinstance(body, str) and body:
        try:
            return json.loads(body)
        except ValueError:
            pass
    encoded = request.get("bodyAsBase64")
    if isinstance(encoded, str) and encoded:
        try:
            raw = base64.b64decode(encoded)
            if raw[:2] == b"\x1f\x8b":
                raw = gzip.decompress(raw)
            return json.loads(raw.decode("utf-8"))
        except (ValueError, OSError, EOFError):
            return None
    return None


def required_fields(expected: Dict[str, Any]) -> List[str]:
    """Lists the field names a fixture needs present, leaving out optional placeholders."""
    return sorted(key for key, value in expected.items() if value != OPTIONAL_PLACEHOLDER)


def compare_with_fixture(body: Dict[str, Any], mapping: Dict[str, Any]) -> Dict[str, Any]:
    """Names the fields and messages a fixture expects that a sent body lacks, by name and position."""
    expected = mapping["body"] or {}
    expected_messages = expected.get("msgs") if isinstance(expected.get("msgs"), list) else []
    sent_messages = body.get("msgs") if isinstance(body.get("msgs"), list) else []
    unclaimed = [message_signature(message) for message in sent_messages]
    missing_messages = []
    for position, message in enumerate(expected_messages, start=1):
        signature = message_signature(message)
        found = next((index for index, sent in enumerate(unclaimed) if signature_matches(signature, sent)), None)
        if found is None:
            missing_messages.append({"position": position, "type": message_type(message)})
        else:
            unclaimed.pop(found)
    return {
        "fixture": mapping["name"],
        "expected_message_count": len(expected_messages),
        "shared_message_count": len(expected_messages) - len(missing_messages),
        "missing_fields": [field for field in required_fields(expected) if field not in body],
        "missing_messages": missing_messages,
    }


def describe_request(
    event: Dict[str, Any],
    order: int,
    origin_ms: Optional[int],
    mappings: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """Summarises one served request without its body, headers, identifiers or values."""
    request = event.get("request", {})
    url = request.get("url") or ""
    method = request.get("method")
    logged = request.get("loggedDate")
    by_id = {mapping.get("id"): mapping["name"] for mapping in mappings if mapping.get("id")}
    stub_id = (event.get("stubMapping") or {}).get("id")
    matched = bool(event.get("wasMatched"))
    summary: Dict[str, Any] = {
        "order": order,
        "offset_ms": logged - origin_ms if isinstance(logged, int) and origin_ms is not None else None,
        "method": method,
        "path": masked_path(url),
        "matched": matched,
        "fixture": by_id.get(stub_id) if matched else None,
    }
    body = request_body(request)
    if not isinstance(body, dict):
        summary["body"] = "none" if not request.get("body") and not request.get("bodyAsBase64") else "not JSON"
        return summary

    summary["body_fields"] = sorted(body.keys())
    candidates = [
        mapping
        for mapping in mappings
        if mapping.get("body") is not None and mapping.get("method") == method and url_matches(mapping["url"], url)
    ]
    sent_messages = body.get("msgs") if isinstance(body.get("msgs"), list) else []
    if sent_messages:
        summary["messages"] = []
        for message in sent_messages:
            signature = message_signature(message)
            summary["messages"].append(
                {
                    "type": message_type(message),
                    "expected_by": [
                        mapping["name"]
                        for mapping in candidates
                        if any(
                            signature_matches(message_signature(expected), signature)
                            for expected in mapping["body"].get("msgs", [])
                        )
                    ],
                }
            )
    if not matched and candidates:
        comparisons = [compare_with_fixture(body, mapping) for mapping in candidates]
        # The fixture sharing the most sent messages is the one this request most likely replaced.
        comparisons.sort(
            key=lambda item: (
                -item["shared_message_count"],
                len(item["missing_messages"]) + len(item["missing_fields"]),
                item["fixture"],
            )
        )
        summary["closest_fixture"] = comparisons[0]
    return summary


def run_command(arguments: List[str]) -> Optional[str]:
    """Runs a version command and returns its output, or None where it is unavailable."""
    try:
        completed = subprocess.run(
            arguments,
            capture_output=True,
            text=True,
            timeout=COMMAND_TIMEOUT_SECONDS,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    output = (completed.stdout or "") + (completed.stderr or "")
    return output.strip() or None


def simulator_details(device_id: str) -> Dict[str, Any]:
    """Reads the simulator's model and runtime; the device's own ID stays out of the report."""
    details: Dict[str, Any] = {}
    if not device_id:
        return details
    listing = run_command(["xcrun", "simctl", "list", "devices", "--json"])
    runtimes = run_command(["xcrun", "simctl", "list", "runtimes", "--json"])
    try:
        devices = json.loads(listing or "{}").get("devices", {})
        runtime_list = json.loads(runtimes or "{}").get("runtimes", [])
    except ValueError:
        return details
    for runtime_id, entries in devices.items():
        for entry in entries:
            if entry.get("udid") == device_id:
                details["model"] = entry.get("deviceTypeIdentifier")
                details["state"] = entry.get("state")
                details["runtime"] = runtime_id
                for runtime in runtime_list:
                    if runtime.get("identifier") == runtime_id:
                        details["runtime_version"] = runtime.get("version")
                        details["runtime_build"] = runtime.get("buildversion")
    return details


def environment(device_name: str, device_id: str) -> Dict[str, Any]:
    """Records the runner, toolchain and simulator versions the run used."""
    xcode = run_command(["xcodebuild", "-version"])
    java = run_command(["java", "-version"])
    simulator = {"name": device_name or None}
    simulator.update(simulator_details(device_id))
    return {
        "runner": {
            "os": platform.system(),
            "os_version": run_command(["sw_vers", "-productVersion"]) or platform.release(),
            "arch": platform.machine(),
            "image": os.environ.get("ImageOS"),
            "image_version": os.environ.get("ImageVersion"),
        },
        "xcode": " ".join(xcode.splitlines()) if xcode else None,
        "java": java.splitlines()[0] if java else None,
        "wiremock": os.environ.get("WIREMOCK_VERSION"),
        "simulator": simulator,
    }


def timeline(marks: Dict[str, int], served: Optional[List[Dict[str, Any]]], origin_ms: Optional[int]) -> Dict[str, Any]:
    """Places the run's marks and the first identify, config and upload requests on one clock."""
    points: Dict[str, Optional[int]] = dict(marks)
    firsts = {"first_identify": "/identify", "first_config": "/config", "first_upload": "/events"}
    for name, fragment in firsts.items():
        points[name] = None
        for event in served or []:
            request = event.get("request", {})
            if fragment in (request.get("url") or "").split("?", 1)[0]:
                points[name] = request.get("loggedDate")
                break
    result: Dict[str, Any] = {
        "origin": "wiremock_ready" if "wiremock_ready" in marks else "first_request",
        "origin_utc": (
            time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(origin_ms / 1000)) if origin_ms is not None else None
        ),
    }
    for name, value in points.items():
        result[f"{name}_ms"] = value - origin_ms if isinstance(value, int) and origin_ms is not None else None
    return result


def build_report(arguments: argparse.Namespace, marks: Dict[str, int]) -> Dict[str, Any]:
    """Assembles the whole report from the journal, the fixtures and the run's marks."""
    mappings = load_mappings(Path(arguments.mappings_dir))
    served, unavailable = read_journal(arguments.admin_url)
    origin_ms = marks.get("wiremock_ready")
    if origin_ms is None and served:
        origin_ms = served[0].get("request", {}).get("loggedDate")

    report: Dict[str, Any] = {
        "stage": arguments.stage,
        "journal": {"available": served is not None, "reason": unavailable},
        "environment": environment(arguments.device_name, arguments.device_id),
        "timeline": timeline(marks, served, origin_ms),
        "unreadable_fixtures": [mapping["name"] for mapping in mappings if mapping.get("unreadable")],
    }
    if served is None:
        # Counts stay null here: an unread journal is not a run with no requests.
        report["counts"] = {"total": None, "matched": None, "unmatched": None}
        report["unused_fixtures"] = None
        report["requests"] = None
        return report

    used_ids = {(event.get("stubMapping") or {}).get("id") for event in served if event.get("wasMatched")}
    matched = sum(1 for event in served if event.get("wasMatched"))
    report["counts"] = {"total": len(served), "matched": matched, "unmatched": len(served) - matched}
    report["unused_fixtures"] = [
        mapping["name"] for mapping in mappings if mapping.get("id") and mapping["id"] not in used_ids
    ]
    report["requests"] = [
        describe_request(event, order, origin_ms, mappings) for order, event in enumerate(served, start=1)
    ]
    return report


def seconds(milliseconds: Optional[int]) -> str:
    """Formats a timeline offset for the log."""
    return "n/a" if milliseconds is None else f"+{milliseconds / 1000:.1f} s"


def print_summary(report: Dict[str, Any], out: str) -> None:
    """Prints the report's headline facts to the job log."""
    print("")
    print(f"🩺 Diagnostic report ({report['stage']}) written to {out}")
    counts = report["counts"]
    if report["journal"]["available"]:
        print(f"  Journal: {counts['total']} requests, {counts['matched']} matched, {counts['unmatched']} unmatched")
        print(f"  Fixtures not invoked: {', '.join(report['unused_fixtures']) or 'none'}")
    else:
        print(f"  Journal: unavailable. {report['journal']['reason']}")
    for request in report.get("requests") or []:
        if request["matched"]:
            continue
        line = f"  Unmatched #{request['order']} {request['method']} {request['path']} at {seconds(request['offset_ms'])}"
        messages = request.get("messages") or []
        if messages:
            line += f", {len(messages)} messages"
        closest = request.get("closest_fixture")
        closest_name = closest["fixture"] if closest else None
        if closest:
            gaps = [f"message {item['position']} ({item['type']})" for item in closest["missing_messages"]]
            gaps += [f"field {field}" for field in closest["missing_fields"]]
            line += f"; closest fixture {closest_name}"
            line += f" is missing {', '.join(gaps)}" if gaps else " has every expected message and field"
        others = sorted({name for message in messages for name in message["expected_by"]} - {closest_name})
        if others:
            line += f"; its messages are also expected by {', '.join(others)}"
        print(line)
    marks = report["timeline"]
    points = [(key[: -len("_ms")], value) for key, value in marks.items() if key.endswith("_ms")]
    points.sort(key=lambda point: (point[1] is None, point[1] or 0))
    print("  Timeline: " + ", ".join(f"{name} {seconds(value)}" for name, value in points))
    env = report["environment"]
    simulator = env["simulator"]
    facts = [
        f"simulator {simulator.get('name') or 'n/a'}",
        f"runtime {simulator.get('runtime_version') or 'n/a'} ({simulator.get('runtime_build') or 'n/a'})",
        env["xcode"] or "Xcode n/a",
        f"{env['runner']['os']} {env['runner']['os_version']}",
        f"image {env['runner']['image'] or 'n/a'} {env['runner']['image_version'] or ''}".strip(),
        f"WireMock {env['wiremock'] or 'n/a'}",
    ]
    print(f"  Environment: {'; '.join(facts)}")
    print("")


def parse_marks(values: List[str]) -> Dict[str, int]:
    """Reads NAME=EPOCH_MS marks, skipping any that are empty or malformed."""
    marks = {}
    for value in values:
        name, _, number = value.partition("=")
        if name and number.isdigit():
            marks[name] = int(number)
    return marks


def main() -> int:
    """Writes the report and its summary; every failure is reported and exits 0."""
    parser = argparse.ArgumentParser(description="Write a diagnostic report of an integration test run.")
    parser.add_argument("--admin-url", required=True)
    parser.add_argument("--mappings-dir", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--stage", required=True)
    parser.add_argument("--device-name", default="")
    parser.add_argument("--device-id", default="")
    parser.add_argument("--mark", action="append", default=[])
    arguments = parser.parse_args()

    try:
        report = build_report(arguments, parse_marks(arguments.mark))
        out = Path(arguments.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, indent=2) + "\n")
        print_summary(report, arguments.out)
    except Exception as error:  # the report must never fail the run
        print(f"⚠️  Could not write the diagnostic report ({type(error).__name__})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
