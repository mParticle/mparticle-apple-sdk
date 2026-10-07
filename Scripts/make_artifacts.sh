#!/bin/bash

#
# This script creates pre-built SDK artifacts that will be attached to the GitHub release.
#

# A signing, verification or zip failure must fail the release, not publish unsigned artifacts.
set -euo pipefail

# --- Functions ---

function build_xcframework_artifacts() {
	# Remove leftovers from an earlier run; zip -r adds to an existing archive.
	rm -rf archives mParticle_Apple_SDK.xcframework mParticle_Apple_SDK_Swift.xcframework \
		mParticle_Apple_SDK.xcframework.zip mParticle_Apple_SDK_Swift.xcframework.zip

	# Build modern xcframeworks which work on M1 macs and include both platforms in one package
	./Scripts/xcframework.sh mParticle-Apple-SDK mParticle_Apple_SDK

	IDENTITY="Apple Distribution: mParticle, inc (DLD43Y3TRP)"

	# Apps embed both xcframeworks side by side. Signing an xcframework wrapper only seals its
	# file manifest - it does not add a code signature to the Mach-O binaries inside - so sign
	# every platform slice's framework first, then the wrapper. Simulator slices already carry
	# an automatic ad-hoc signature from the archive step (device slices do not), so --force is
	# required or codesign refuses to replace it.
	for module in mParticle_Apple_SDK mParticle_Apple_SDK_Swift; do
		for framework in "${module}".xcframework/*/"${module}".framework; do
			codesign --force --timestamp -s "${IDENTITY}" "${framework}"
		done
		codesign --force --timestamp -s "${IDENTITY}" "${module}.xcframework"
		codesign --verify --deep --strict --verbose=2 "${module}.xcframework"
		zip -r "${module}.xcframework.zip" "${module}.xcframework"
	done

	# Clean up temp files
	rm -rf archives mParticle_Apple_SDK.xcframework mParticle_Apple_SDK_Swift.xcframework
}

# --- Main ---

build_xcframework_artifacts
