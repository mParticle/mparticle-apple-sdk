#!/bin/bash

# Script to publish all MyModules modules to CocoaPods
#
# Usage:
#   ./publish_pods.sh [version] [--dry-run]
#
# Examples:
#   ./publish_pods.sh 1.0.0              # Publish version 1.0.0
#   ./publish_pods.sh 1.0.0 --dry-run   # Only check without publishing
#   ./publish_pods.sh                    # Publish version 1.0.0 (default)

# Don't use set -e to have control over error handling

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for output messages
info() {
	echo -e "${BLUE}ℹ ${NC}$1"
}

success() {
	echo -e "${GREEN}✓${NC} $1"
}

warning() {
	echo -e "${YELLOW}⚠${NC} $1"
}

error() {
	echo -e "${RED}✗${NC} $1"
}

# Check arguments
VERSION=${1:-"1.0.0"}
DRY_RUN=${2:-""}
PODSPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$DRY_RUN" == "--dry-run" ] || [ "$DRY_RUN" == "-n" ]; then
	warning "DRY-RUN MODE: publishing will not be performed, only checks"
	DRY_RUN_MODE=true
else
	DRY_RUN_MODE=false
fi

info "Publishing MyModules pods version: $VERSION"
info "Directory: $PODSPEC_DIR"
echo ""

# Check for podspec files
PODSPECS=(
	"MyModules-B.podspec"
	"MyModules-BObjC.podspec"
	"MyModules-A.podspec"
)

info "Checking for podspec files..."
for podspec in "${PODSPECS[@]}"; do
	if [ ! -f "$PODSPEC_DIR/$podspec" ]; then
		error "File $podspec not found!"
		exit 1
	fi
	success "Found: $podspec"
done
echo ""

# Check version in podspec files
info "Checking versions in podspec files..."
for podspec in "${PODSPECS[@]}"; do
	PODSPEC_VERSION=$(grep -E "s\.version\s*=" "$PODSPEC_DIR/$podspec" | sed -E "s/.*['\"](.*)['\"].*/\1/" | tr -d ' ')
	if [ "$PODSPEC_VERSION" != "$VERSION" ]; then
		warning "Version in $podspec ($PODSPEC_VERSION) doesn't match specified ($VERSION)"
		read -p "Update version in $podspec to $VERSION? (y/n) " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			if [[ $OSTYPE == "darwin"* ]]; then
				# macOS
				sed -i '' "s/s\.version.*=.*['\"].*['\"]/s.version          = \"$VERSION\"/" "$PODSPEC_DIR/$podspec"
			else
				# Linux
				sed -i "s/s\.version.*=.*['\"].*['\"]/s.version          = \"$VERSION\"/" "$PODSPEC_DIR/$podspec"
			fi
			success "Version updated in $podspec"
		fi
	else
		success "Version in $podspec is correct: $PODSPEC_VERSION"
	fi
done
echo ""

# Check that user is registered in CocoaPods
info "Checking CocoaPods registration..."
if ! pod trunk me &>/dev/null; then
	error "You are not registered in CocoaPods Trunk"
	info "Register with command:"
	echo "  pod trunk register your.email@example.com 'Your Name'"
	exit 1
fi
success "CocoaPods registration confirmed"
echo ""

# Lint check before publishing
info "Checking podspec files (lint)..."
LINT_ERRORS=0

for podspec in "${PODSPECS[@]}"; do
	info "Checking $podspec..."
	if pod spec lint "$PODSPEC_DIR/$podspec" --allow-warnings 2>&1 | tee /tmp/lint_${podspec}.log; then
		success "$podspec passed check"
	else
		error "$podspec failed check"
		LINT_ERRORS=$((LINT_ERRORS + 1))
	fi
	echo ""
done

if [ $LINT_ERRORS -gt 0 ]; then
	error "Some podspec files failed check. Fix errors before publishing."
	exit 1
fi

# Publishing confirmation
warning "You are about to publish the following pods to CocoaPods Trunk:"
for podspec in "${PODSPECS[@]}"; do
	echo "  - $podspec (version $VERSION)"
done
echo ""
read -p "Continue publishing? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	info "Publishing cancelled"
	exit 0
fi
echo ""

# Publishing in correct order
info "Starting publishing..."
echo ""

# Publishing modules
if [ "$DRY_RUN_MODE" = true ]; then
	info "DRY-RUN MODE: skipping publishing"
	echo ""
	info "Would publish the following modules:"
	echo "  1. MyModules-B.podspec"
	echo "  2. MyModules-BObjC.podspec"
	echo "  3. MyModules-A.podspec"
	echo ""
	info "For real publishing run script without --dry-run"
else
	# 1. MyModules-B (base module, no dependencies)
	info "[1/3] Publishing MyModules-B..."
	if pod trunk push "$PODSPEC_DIR/MyModules-B.podspec" --allow-warnings; then
		success "MyModules-B successfully published"
	else
		error "Error publishing MyModules-B"
		exit 1
	fi
	echo ""

	# 2. MyModules-BObjC (depends on B)
	info "[2/3] Publishing MyModules-BObjC..."
	if pod trunk push "$PODSPEC_DIR/MyModules-BObjC.podspec" --allow-warnings; then
		success "MyModules-BObjC successfully published"
	else
		error "Error publishing MyModules-BObjC"
		exit 1
	fi
	echo ""

	# 3. MyModules-A (depends on BObjC)
	info "[3/3] Publishing MyModules-A..."
	if pod trunk push "$PODSPEC_DIR/MyModules-A.podspec" --allow-warnings; then
		success "MyModules-A successfully published"
	else
		error "Error publishing MyModules-A"
		exit 1
	fi
	echo ""
fi

# Final message
if [ "$DRY_RUN_MODE" = false ]; then
	success "All modules successfully published to CocoaPods!"
	echo ""
	info "Now you can use in Podfile:"
	echo "  pod 'MyModules-A', '~> $VERSION'"
	echo ""
	info "Or individual modules:"
	echo "  pod 'MyModules-B', '~> $VERSION'"
	echo "  pod 'MyModules-BObjC', '~> $VERSION'"
	echo ""
else
	success "Check completed successfully!"
	echo ""
	info "All checks passed. Ready to publish."
	echo ""
fi
