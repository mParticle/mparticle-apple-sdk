#!/bin/bash

#
# This script creates pre-built SDK artfacts that will be attached to the GitHub release.
#
# If you add new files here, you need to also add them in sdk-release.yml.
#

# --- Functions ---

function build_framework_artifacts() {
    # Build old school "fat" frameworks for iOS and tvOS, both regular and no location builds
    ./Scripts/carthage.sh build --no-skip-current

    # Zip the Carthage frameworks (includes both platforms in each zip file)
    carthage archive mParticle_Apple_SDK 
    carthage archive mParticle_Apple_SDK_NoLocation

    # Clean up temp files
    rm -rf Carthage
}

function build_xcframework_artifacts() {
    # Build modern xcframeworks which work on M1 macs and include both platforms in one package
    ./Scripts/xcframework.sh mParticle-Apple-SDK mParticle_Apple_SDK
    ./Scripts/xcframework.sh mParticle-Apple-SDK-NoLocation mParticle_Apple_SDK_NoLocation

    # Sign the xcframeworks
    codesign --timestamp -s "Apple Distribution: mParticle, inc (DLD43Y3TRP)" mParticle_Apple_SDK.xcframework
    codesign --timestamp -s "Apple Distribution: mParticle, inc (DLD43Y3TRP)" mParticle_Apple_SDK_NoLocation.xcframework

    # Zip the xcframeworks
    zip -r mParticle_Apple_SDK.xcframework.zip mParticle_Apple_SDK.xcframework
    zip -r mParticle_Apple_SDK_NoLocation.xcframework.zip mParticle_Apple_SDK_NoLocation.xcframework

    # Clean up temp files
    rm -rf archives mParticle_Apple_SDK.xcframework mParticle_Apple_SDK_NoLocation.xcframework
}

function build_docs_artifact() {
    local repo_dir="$(pwd)"
    local temp_dir="$HOME/temp"

    # Install appledoc
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    git clone https://github.com/mparticle/appledoc
    cd appledoc
    sudo sh install-appledoc.sh
    cd "$repo_dir"

    appledoc --exit-threshold=2 "./Scripts/AppledocSettings.plist"
    ditto -c -k --sequesterRsrc --keepParent "./Docs/html" "$repo_dir/generated-docs.zip"
}

# --- Main ---

build_framework_artifacts
build_xcframework_artifacts
build_docs_artifact
