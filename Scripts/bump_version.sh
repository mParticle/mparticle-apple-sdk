#!/bin/sh
# Writes a release version into every file that carries it. Run from the repository root:
#
#   Scripts/bump_version.sh <version> <patch|minor|major>
#
# The release tooling runs it, then updates CHANGELOG.md and opens the release pull request. It makes the same edits
# as the Release – Draft workflow: VERSION, s.version in the core podspecs and every podspec in Kits/matrix.json,
# kMParticleSDKVersion, the version strings in the Rokt, RoktSDKPlus, CleverTap and Branch kits, and
# CFBundleShortVersionString in Framework/Info.plist. A major bump also moves every kit's core SDK dependency to
# '~> MAJOR.0' and every kit Package.swift's `let version`. The integration test mappings carry
# SDK_VERSION_PLACEHOLDER, filled in only while the tests run, so they are left alone.
#
# Works with GNU and BSD tools; reads Kits/matrix.json with python3 (no jq).
set -eu

usage() {
	echo "usage: $0 <version> <patch|minor|major>, where <version> is like 1.2.3" >&2
	exit 2
}

VERSION="${1:-}"
BUMP="${2:-}"
# Anything but digits and dots (a newline included) is refused before any file is touched.
case "$VERSION" in
"" | *[!0-9.]*) usage ;;
*) ;;
esac
printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || usage
case "$BUMP" in
patch | minor | major) ;;
*) usage ;;
esac
MAJOR="${VERSION%%.*}"
MINOR_PATCH="${VERSION#*.}"
MINOR="${MINOR_PATCH%%.*}"
PATCH="${MINOR_PATCH#*.}"

fail() {
	echo "$0: $*" >&2
	exit 1
}

# The bump type decides whether the kits' core SDK pins move, so it must agree with the version.
[ -f VERSION ] || fail "run from the repository root (no VERSION file here)"
CURRENT="$(tr -d '[:space:]' <VERSION)"
printf '%s' "$CURRENT" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "VERSION holds '$CURRENT', not a version like 1.2.3"
# A release only moves forward. An exact version may skip numbers, but never repeats or lowers the current one.
CUR_MAJOR="${CURRENT%%.*}"
CUR_MINOR_PATCH="${CURRENT#*.}"
CUR_MINOR="${CUR_MINOR_PATCH%%.*}"
CUR_PATCH="${CUR_MINOR_PATCH#*.}"
if [ "$MAJOR" -lt "$CUR_MAJOR" ] ||
	{ [ "$MAJOR" -eq "$CUR_MAJOR" ] && [ "$MINOR" -lt "$CUR_MINOR" ]; } ||
	{ [ "$MAJOR" -eq "$CUR_MAJOR" ] && [ "$MINOR" -eq "$CUR_MINOR" ] && [ "$PATCH" -le "$CUR_PATCH" ]; }; then
	echo "$0: $VERSION is not newer than the current version $CURRENT" >&2
	exit 2
fi
if [ "$BUMP" = major ] && [ "$MAJOR" = "$CUR_MAJOR" ]; then
	echo "$0: a major bump needs a new major version, but $VERSION has the same major as $CURRENT" >&2
	exit 2
fi
if [ "$BUMP" != major ] && [ "$MAJOR" != "$CUR_MAJOR" ]; then
	echo "$0: $VERSION changes the major version from $CURRENT, so the bump is major, not $BUMP" >&2
	exit 2
fi

ROKT_KIT=Kits/rokt/rokt/Sources/mParticle-Rokt-Internal/MPRoktKitImplementation.swift
SDK_PLUS=Kits/rokt-sdk-plus/rokt-sdk-plus-ios/Sources/RoktSDKPlus/RoktSDKPlus.swift
SDK_PLUS_PACKAGE=Kits/rokt-sdk-plus/rokt-sdk-plus-ios/Package.swift
CLEVERTAP_KIT=Kits/clevertap/clevertap-7/Sources/mParticle-CleverTap/MPKitCleverTap.m
BRANCH_KIT=Kits/branchmetrics/branchmetrics-3/Sources/mParticle-BranchMetrics/MPKitBranchMetrics.m

# -I keeps python3 from importing modules out of the current directory.
KIT_PODSPECS="$(python3 -I -c '
import json, re, sys
for kit in json.load(open("Kits/matrix.json")):
    spec = kit.get("podspec")
    if spec:
        if not re.fullmatch(r"Kits/[A-Za-z0-9._/-]+\.podspec", spec) or ".." in spec.split("/"):
            sys.exit("Kits/matrix.json: unexpected podspec path " + repr(spec))
        print(spec)
')"
PODSPECS="mParticle-Apple-SDK.podspec mParticle-Apple-SDK-ObjC.podspec mParticle-Apple-SDK-Swift.podspec $KIT_PODSPECS"

ALL_KIT_PODSPECS=""
ALL_KIT_PACKAGES=""
if [ "$BUMP" = major ]; then
	ALL_KIT_PODSPECS="$(find Kits -type f -name '*.podspec' | sort)"
	ALL_KIT_PACKAGES="$(find Kits -type f -name Package.swift | sort)"
fi

# Every file must exist, and every path must be plain, before the first edit.
for file in $PODSPECS $ALL_KIT_PODSPECS $ALL_KIT_PACKAGES mParticle-Apple-SDK/MPIConstants.m Framework/Info.plist \
	"$ROKT_KIT" "$SDK_PLUS" "$SDK_PLUS_PACKAGE" "$CLEVERTAP_KIT" "$BRANCH_KIT"; do
	case "$file" in
	*[!A-Za-z0-9._/-]*) fail "unexpected file name '$file'" ;;
	*) ;;
	esac
	[ -f "$file" ] || fail "$file is missing"
done

# sed -i differs between GNU and BSD sed, so each file is rewritten through a temporary copy, removed on failure.
tmp=""
trap '[ -z "$tmp" ] || rm -f "$tmp"' EXIT
trap '[ -z "$tmp" ] || rm -f "$tmp"; exit 1' HUP INT TERM

replace() {
	file="$1"
	shift
	tmp="$file.bump.$$"
	sed "$@" "$file" >"$tmp"
	if cmp -s "$tmp" "$file"; then
		rm -f "$tmp"
	else
		mv "$tmp" "$file"
	fi
	tmp=""
}

# Fails when an edit found nothing to change, so a moved or reworded version string stops the bump.
expect() {
	grep -Fq -- "$2" "$1" || fail "$1 does not read $2 after the bump"
}

for spec in $PODSPECS; do
	replace "$spec" \
		-e 's/\(s\.version[^=]*=[[:space:]]*\)"[^"]*"/\1"'"$VERSION"'"/' \
		-e "s/\(s\.version[^=]*=[[:space:]]*\)'[^']*'/\1\"$VERSION\"/"
	grep -Eq "s\.version[^=]*=[[:space:]]*\"$(printf '%s' "$VERSION" | sed 's/\./\\./g')\"" "$spec" ||
		fail "$spec has no s.version reading $VERSION after the bump"
done

replace mParticle-Apple-SDK/MPIConstants.m -e "s/kMParticleSDKVersion = @\"[^\"]*\"/kMParticleSDKVersion = @\"$VERSION\"/"
expect mParticle-Apple-SDK/MPIConstants.m "kMParticleSDKVersion = @\"$VERSION\""

replace "$ROKT_KIT" -e "s/static let kitVersion = \"[^\"]*\"/static let kitVersion = \"$VERSION\"/"
expect "$ROKT_KIT" "static let kitVersion = \"$VERSION\""
replace "$SDK_PLUS" -e "s/public static let version = \"[^\"]*\"/public static let version = \"$VERSION\"/"
expect "$SDK_PLUS" "public static let version = \"$VERSION\""
replace "$SDK_PLUS_PACKAGE" -e "s/^let version = \"[^\"]*\"/let version = \"$VERSION\"/"
expect "$SDK_PLUS_PACKAGE" "let version = \"$VERSION\""
replace "$CLEVERTAP_KIT" -e "s/kLibVersion = @\"[^\"]*\"/kLibVersion = @\"$VERSION\"/"
expect "$CLEVERTAP_KIT" "kLibVersion = @\"$VERSION\""
replace "$BRANCH_KIT" -e "s/registerPluginName:@\"mParticleKit\" version:@\"[^\"]*\"/registerPluginName:@\"mParticleKit\" version:@\"$VERSION\"/"
expect "$BRANCH_KIT" "registerPluginName:@\"mParticleKit\" version:@\"$VERSION\""

# The <string> on the line after the CFBundleShortVersionString key.
replace Framework/Info.plist -e "/<key>CFBundleShortVersionString<\/key>/{n;s|<string>[^<]*</string>|<string>$VERSION</string>|;}"
sed -n '/<key>CFBundleShortVersionString<\/key>/{n;p;}' Framework/Info.plist | grep -Fq "<string>$VERSION</string>" ||
	fail "Framework/Info.plist has no CFBundleShortVersionString reading $VERSION after the bump"

if [ "$BUMP" = major ]; then
	# Podspec: 'mParticle-Apple-SDK' (or a subspec), '~> X.Y' becomes '~> MAJOR.0'.
	for spec in $ALL_KIT_PODSPECS; do
		replace "$spec" -e "s/\('mParticle-Apple-SDK[^']*'\), '~> [^']*'/\1, '~> $MAJOR.0'/"
	done
	# Kit Package.swift: `let version` pins the core SDK (.upToNextMajor), so it moves to the new version.
	for package in $ALL_KIT_PACKAGES; do
		replace "$package" -e "s/^let version = \"[^\"]*\"/let version = \"$VERSION\"/"
	done
fi

# VERSION last: it is the file that starts a release, so it changes only once everything else has.
printf '%s\n' "$VERSION" >VERSION
