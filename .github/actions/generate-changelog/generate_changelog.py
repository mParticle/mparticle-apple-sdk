#!/usr/bin/env python3
"""Auto-generate a CHANGELOG section with Core and Kits split from git history.

Extracts PR numbers from squash-merge commits, fetches PR titles via the GitHub CLI,
categorises by conventional-commit prefix, classifies commits as Core vs Kits by
changed file paths, updates CHANGELOG.md in-place, and outputs the release-notes.
"""

from __future__ import annotations

import os
import re
import subprocess  # nosec B404
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

CATEGORY_ORDER: list[str] = [
    "Breaking Changes",
    "Bug Fixes",
    "Features",
    "Changed",
    "Deprecated",
    "Removed",
    "Security",
]

_TYPE_TO_CATEGORY: dict[str, str] = {
    "feat": "Features",
    "fix": "Bug Fixes",
    "security": "Security",
    "deprecate": "Deprecated",
    "revert": "Removed",
}

_CC_REGEX = re.compile(
    r"^(?P<type>[a-zA-Z]+)(?:\([^)]*\))?(?P<bang>!)?:\s*(?P<desc>.*)$",
)
_PR_NUMBER_REGEX = re.compile(r"\(#(\d+)\)$")
_SEMVER_TAG_REGEX = re.compile(r"^v?(\d+\.\d+\.\d+)$")
_PRE_RELEASE_REGEX = re.compile(r"(alpha|beta|rc)")
_SKIP_PATTERNS = re.compile(
    r"^Merge pull request"
    r"|^Merge branch"
    r"|^Merge remote"
    r"|^Prepare release"
    r"|^Create \d"
    r"|[Mm]erge.*to (main|master|workstation)"
    r"|[Mm]erge (main|master) to",
)
_BREAKING_REGEX = re.compile(r"\bBREAKING\b", re.IGNORECASE)
_TRAILING_PR_REGEX = re.compile(r"\s*\(#\d+\)$")
_INTRO_SEPARATOR = re.compile(r"^---\s*$")
_VERSION_HEADING_REGEX = re.compile(r"^#\s+\[\d+\.\d+\.\d+\]")

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class Config:
    """Runtime configuration from environment variables."""

    version: str
    repo_url: str
    tag_prefix: str
    changelog_path: Path
    exclude_types: set[str]
    today: str = field(default_factory=lambda: date.today().isoformat())


@dataclass
class Entry:
    """A single changelog entry with category, scope (core or kit), and kit names."""

    category: str
    text: str
    is_kit: bool
    kit_names: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _run_cmd(cmd: list[str]) -> str:
    """Run a subprocess and return stripped stdout, or empty string on failure."""
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=False,
    )
    return "" if result.returncode != 0 else result.stdout.strip()


def _map_category(cc_type: str, *, breaking: bool) -> str:
    """Map conventional-commit type to changelog category."""
    if breaking:
        return "Breaking Changes"
    return _TYPE_TO_CATEGORY.get(cc_type, "Changed")


def _capitalise_first(text: str) -> str:
    """Uppercase the first character."""
    return text[0].upper() + text[1:] if text else text


def _get_changed_files(sha: str) -> list[str]:
    """Return list of file paths changed in the given commit."""
    out = _run_cmd(
        ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", sha],
    )
    return [p for p in out.splitlines() if p.strip()] if out else []


def _is_kit_commit(files: list[str]) -> bool:
    """True if any changed file is under kits/."""
    return any(f.startswith("kits/") for f in files)


def _is_core_commit(files: list[str]) -> bool:
    """True if any changed file is outside kits/ (or repo root)."""
    return any(not f.startswith("kits/") for f in files)


def _kit_path_to_display(path_segment: str) -> str:
    """Convert kit directory name to display name (e.g. clevertap -> CleverTap)."""
    if not path_segment:
        return path_segment
    return " ".join(part.capitalize() for part in path_segment.split("-"))


def _kit_names_from_files(files: list[str]) -> list[str]:
    """Extract unique kit display names from paths under kits/."""
    names: set[str] = set()
    for path in files:
        if not path.startswith("kits/"):
            continue
        parts = path.split("/")
        if len(parts) >= 2:
            names.add(_kit_path_to_display(parts[1]))
    return sorted(names)


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------


def find_last_tag(tag_prefix: str) -> str | None:
    """Find the latest semver release tag."""
    raw_tags = _run_cmd(["git", "tag"]).splitlines()
    if not raw_tags:
        return None

    prefix_re = (
        re.compile(f"^{re.escape(tag_prefix)}")
        if tag_prefix
        else re.compile(r"^v?\d")
    )

    versions: list[tuple[tuple[int, ...], str]] = []
    for tag in raw_tags:
        if not prefix_re.search(tag):
            continue
        if not _SEMVER_TAG_REGEX.match(tag):
            continue
        if _PRE_RELEASE_REGEX.search(tag):
            continue
        stripped = tag.lstrip("v")
        parts = tuple(int(p) for p in stripped.split("."))
        versions.append((parts, tag))

    if not versions:
        return None

    versions.sort(key=lambda v: v[0], reverse=True)
    return versions[0][1]


def _fetch_pr_title(pr_number: str) -> str | None:
    """Fetch PR title from GitHub via gh CLI."""
    title = _run_cmd(
        ["gh", "pr", "view", pr_number, "--json", "title", "--jq", ".title"],
    )
    return title or None


def _parse_commit(title: str) -> tuple[str, bool, str]:
    """Parse conventional-commit title into (type, breaking, description)."""
    cc_type = ""
    breaking = False
    description = title

    if cc_match := _CC_REGEX.match(description):
        cc_type = cc_match.group("type").lower()
        breaking = cc_match.group("bang") == "!"
        description = cc_match.group("desc")

    if _BREAKING_REGEX.search(description):
        breaking = True

    return cc_type, breaking, description


def _entry_from_commit(message: str, cfg: Config, sha: str) -> Entry | None:
    """Convert a commit message into a changelog Entry, or None to skip."""
    if _SKIP_PATTERNS.search(message):
        return None

    pr_match = _PR_NUMBER_REGEX.search(message)
    pr_number = pr_match.group(1) if pr_match else None

    title = message
    if pr_number and (pr_title := _fetch_pr_title(pr_number)):
        title = pr_title

    cc_type, breaking, description = _parse_commit(title)

    if not breaking and cc_type and cc_type in cfg.exclude_types:
        return None

    category = _map_category(cc_type, breaking=breaking)
    description = _capitalise_first(description)
    description = _TRAILING_PR_REGEX.sub("", description)

    short_sha = sha[:8] if len(sha) >= 8 else sha
    commit_link = f"([{short_sha}]({cfg.repo_url}/commit/{sha}))"
    if pr_number:
        text = f"- {description} (#{pr_number}) {commit_link}"
    else:
        text = f"- {description} {commit_link}"

    return Entry(category=category, text=text, is_kit=False, kit_names=[])


def collect_entries(last_tag: str | None, cfg: Config) -> list[Entry]:
    """Walk git log from last_tag to HEAD and build entries with Core/Kit scope."""
    log_range = f"{last_tag}..HEAD" if last_tag else "HEAD"
    log_output = _run_cmd(
        ["git", "log", "--first-parent", "--pretty=format:%H %s", log_range],
    )
    if not log_output:
        return []

    entries: list[Entry] = []
    for line in log_output.splitlines():
        if not line.strip():
            continue
        parts = line.split(" ", 1)
        if len(parts) != 2:
            continue
        sha, message = parts
        entry = _entry_from_commit(message, cfg, sha)
        if not entry:
            continue

        files = _get_changed_files(sha)
        in_kits = _is_kit_commit(files)
        in_core = _is_core_commit(files)
        kit_names = _kit_names_from_files(files) if in_kits else []

        if in_core and in_kits:
            entries.append(Entry(entry.category, entry.text, is_kit=False))
            entries.append(
                Entry(entry.category, entry.text, is_kit=True, kit_names=kit_names)
            )
        elif in_kits:
            entries.append(
                Entry(entry.category, entry.text, is_kit=True, kit_names=kit_names)
            )
        else:
            entries.append(Entry(entry.category, entry.text, is_kit=False))

    return entries


def _render_category_block(entries: list[Entry], is_kit: bool) -> str:
    """Render Core entries as markdown (flat list by category)."""
    scope_entries = [e for e in entries if e.is_kit == is_kit]
    if not scope_entries:
        return ""

    lines: list[str] = []
    for category in CATEGORY_ORDER:
        cat_entries = [e.text for e in scope_entries if e.category == category]
        if not cat_entries:
            continue
        lines.extend((f"#### {category}", ""))
        lines.extend(cat_entries)
        lines.append("")
    return "\n".join(lines).rstrip()


def _render_kits_block(entries: list[Entry]) -> str:
    """Render kit entries grouped by kit name, then by category."""
    kit_entries = [e for e in entries if e.is_kit and e.kit_names]
    if not kit_entries:
        return ""

    kit_to_entries: dict[str, list[Entry]] = {}
    for e in kit_entries:
        for kit_name in e.kit_names:
            kit_to_entries.setdefault(kit_name, []).append(e)

    lines: list[str] = []
    for kit_name in sorted(kit_to_entries):
        entries_for_kit = kit_to_entries[kit_name]
        lines.append(f"#### {kit_name}")
        lines.append("")
        for category in CATEGORY_ORDER:
            cat_entries = [
                e.text for e in entries_for_kit if e.category == category
            ]
            if not cat_entries:
                continue
            lines.append(f"##### {category}")
            lines.append("")
            lines.extend(cat_entries)
            lines.append("")
    return "\n".join(lines).rstrip()


def build_section(entries: list[Entry], cfg: Config) -> str:
    """Build full release section with ### Core and ### Kits."""
    core_block = _render_category_block(entries, is_kit=False)
    kits_block = _render_kits_block(entries)

    parts: list[str] = []
    parts.append("### Core")
    parts.append("")
    if core_block:
        parts.append(core_block)
        parts.append("")
    else:
        parts.append("- No core changes in this release.")
        parts.append("")

    parts.append("### Kits")
    parts.append("")
    if kits_block:
        parts.append(kits_block)
        parts.append("")
    else:
        parts.append("- No kit-specific changes in this release.")
        parts.append("")

    return "\n".join(parts)


def _insert_after_intro(lines: list[str], new_section: str, cfg: Config) -> list[str]:
    """Insert the new version section after the first --- (intro separator)."""
    output: list[str] = []
    inserted = False
    after_sep = False

    prev_tag = find_last_tag(cfg.tag_prefix)
    new_version_tag = (
        f"v{cfg.version}"
        if not cfg.tag_prefix
        else f"{cfg.tag_prefix}{cfg.version}"
    )
    compare_from = prev_tag or new_version_tag
    compare_link = f"{cfg.repo_url}/compare/{compare_from}...{new_version_tag}"
    header = (
        f"\n# [{cfg.version}]({compare_link}) ({cfg.today})\n\n"
        f"{new_section}\n\n---\n"
    )

    for line in lines:
        if (
            not inserted
            and after_sep
            and _VERSION_HEADING_REGEX.match(line.rstrip())
        ):
            output.append(header)
            inserted = True
        output.append(line)
        if _INTRO_SEPARATOR.match(line.rstrip()):
            after_sep = True
        else:
            after_sep = False

    if not inserted:
        output.append(header)

    return output


def update_changelog(
    cfg: Config,
    section_body: str,
) -> None:
    """Write the generated section into the changelog file."""
    path = cfg.changelog_path
    if not path.is_file():
        raise FileNotFoundError(f"CHANGELOG not found: {path}")

    original = path.read_text(encoding="utf-8").splitlines(keepends=True)
    result = _insert_after_intro(original, section_body, cfg)
    path.write_text("".join(result), encoding="utf-8")


def _write_github_output(name: str, value: str) -> None:
    """Append a multi-line output variable to GITHUB_OUTPUT."""
    output_file = os.environ.get("GITHUB_OUTPUT")
    if not output_file:
        return
    delim = "EOF"
    with open(output_file, "a", encoding="utf-8") as fh:
        fh.write(f"{name}<<{delim}\n{value}\n{delim}\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    """Run the generator and update CHANGELOG."""
    repo_url = os.environ.get("INPUT_REPO_URL", "").strip()
    if not repo_url and os.environ.get("GITHUB_REPOSITORY"):
        repo_url = f"https://github.com/{os.environ['GITHUB_REPOSITORY']}"

    version = os.environ.get("INPUT_VERSION", "").strip()
    if not version:
        print("INPUT_VERSION is required", file=sys.stderr)
        return 1

    changelog_path = Path(
        os.environ.get("INPUT_CHANGELOG_PATH", "CHANGELOG.md"),
    ).resolve()
    exclude_raw = os.environ.get("INPUT_EXCLUDE_TYPES", "").strip()
    exclude_types = {t.strip().lower() for t in exclude_raw.split(",") if t.strip()}

    cfg = Config(
        version=version,
        repo_url=repo_url or "https://github.com/mParticle/mparticle-apple-sdk",
        tag_prefix=os.environ.get("INPUT_TAG_PREFIX", "").strip(),
        changelog_path=changelog_path,
        exclude_types=exclude_types,
    )

    last_tag = find_last_tag(cfg.tag_prefix)
    entries = collect_entries(last_tag, cfg)
    section_body = build_section(entries, cfg)

    prev_tag = find_last_tag(cfg.tag_prefix)
    new_version_tag = f"v{cfg.version}" if not cfg.tag_prefix else f"{cfg.tag_prefix}{cfg.version}"
    compare_from = prev_tag or new_version_tag
    compare_link = f"{cfg.repo_url}/compare/{compare_from}...{new_version_tag}"

    release_notes = (
        f"# [{cfg.version}]({compare_link}) ({cfg.today})\n\n"
        f"{section_body}"
    )

    update_changelog(cfg, section_body)
    _write_github_output("release-notes", release_notes)

    print(f"Updated {cfg.changelog_path} with release {cfg.version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
