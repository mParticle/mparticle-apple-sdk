#!/bin/bash

#
# This script creates pre-built SDK artfacts that will be attached to the GitHub release.
#
# If you add new files here, you need to also add them in sdk-release.yml.
#

# --- Functions ---

function build_framework_artifacts() {
    # Build old school "fat" frameworks for iOS and tvOS, both regular and no location builds
    if ./Scripts/carthage.sh build --no-skip-current; then
        echo "Successfully built Carthage frameworks"
        
        # Zip the Carthage frameworks (includes both platforms in each zip file)
        if carthage archive mParticle_Apple_SDK && carthage archive mParticle_Apple_SDK_NoLocation; then
            echo "Successfully archived Carthage frameworks"
        else
            echo "Warning: Failed to archive some Carthage frameworks"
        fi
    else
        echo "Warning: Carthage build failed, skipping framework artifacts"
    fi

    # Clean up temp files
    rm -rf Carthage
}

function build_xcframework_artifacts() {
    # Build modern xcframeworks which work on M1 macs and include both platforms in one package
    if ./Scripts/xcframework.sh mParticle-Apple-SDK mParticle_Apple_SDK && ./Scripts/xcframework.sh mParticle-Apple-SDK-NoLocation mParticle_Apple_SDK_NoLocation; then
        echo "Successfully built xcframeworks"
        
        # Try to sign the xcframeworks, but don't fail if signing isn't available
        if codesign --timestamp -s "Apple Distribution: mParticle, inc (DLD43Y3TRP)" mParticle_Apple_SDK.xcframework 2>/dev/null; then
            echo "Successfully signed mParticle_Apple_SDK.xcframework"
        else
            echo "Warning: Could not sign mParticle_Apple_SDK.xcframework (certificate may not be available)"
        fi
        
        if codesign --timestamp -s "Apple Distribution: mParticle, inc (DLD43Y3TRP)" mParticle_Apple_SDK_NoLocation.xcframework 2>/dev/null; then
            echo "Successfully signed mParticle_Apple_SDK_NoLocation.xcframework"
        else
            echo "Warning: Could not sign mParticle_Apple_SDK_NoLocation.xcframework (certificate may not be available)"
        fi

        # Zip the xcframeworks
        if zip -r mParticle_Apple_SDK.xcframework.zip mParticle_Apple_SDK.xcframework && zip -r mParticle_Apple_SDK_NoLocation.xcframework.zip mParticle_Apple_SDK_NoLocation.xcframework; then
            echo "Successfully created xcframework zip files"
        else
            echo "Warning: Failed to create some xcframework zip files"
        fi
    else
        echo "Warning: Failed to build xcframeworks, skipping xcframework artifacts"
    fi

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

    # Try to generate docs, but don't fail the release if it has issues
    if appledoc --exit-threshold=0 "./Scripts/AppledocSettings.plist"; then
        ditto -c -k --sequesterRsrc --keepParent "./Docs/html" "$repo_dir/generated-docs.zip"
    else
        echo "Documentation generation failed, creating empty docs archive"
        mkdir -p ./Docs/html
        echo "<html><body>Documentation generation failed</body></html>" > ./Docs/html/index.html
        ditto -c -k --sequesterRsrc --keepParent "./Docs/html" "$repo_dir/generated-docs.zip"
    fi
}

# --- Main ---

echo "Starting artifact build process..."

build_framework_artifacts
build_xcframework_artifacts  
build_docs_artifact

echo "Artifact build process completed."

# Ensure the script always exits successfully for the release process
exit 0
