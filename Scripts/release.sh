VERSION="$1"
PREFIXED_VERSION="v$1"
NOTES="$2"

# Update version number
# 

# Update constant in codebase
sed -i '' 's/NSString \*const kMParticleSDKVersion = @".*/NSString *const kMParticleSDKVersion = @"'"$VERSION"'";/' mParticle-Apple-SDK/MPIConstants.m

# Update framework plist file
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $VERSION" Framework/Info.plist

# Update Carthage release json file
jq --indent 3 '. += {'"\"$VERSION\""': "'"https://github.com/mParticle/mparticle-apple-sdk/releases/download/$PREFIXED_VERSION/mParticle_Apple_SDK.framework.zip?alt=https://github.com/mParticle/mparticle-apple-sdk/releases/download/$PREFIXED_VERSION/mParticle_Apple_SDK.xcframework.zip"'"}' mParticle_Apple_SDK.json > tmp.json
mv tmp.json mParticle_Apple_SDK.json

# Update CocoaPods podspec file
sed -i '' 's/\(^    s.version[^=]*= \).*/\1"'"$VERSION"'"/' mParticle-Apple-SDK.podspec

# Update SPM package.swift file
SDK_URL="https:\/\/github.com\/mParticle\/mparticle-apple-sdk\/releases\/download\/$PREFIXED_VERSION\/mParticle_Apple_SDK.xcframework.zip"
SDK_CHECKSUM=$(swift package compute-checksum mParticle_Apple_SDK.xcframework.zip)
sed -i '' 's/\(^let mParticle_Apple_SDK_URL[^=]*= \).*/\1"'"$SDK_URL"'"/' Package.swift
sed -i '' 's/\(^let mParticle_Apple_SDK_Checksum[^=]*= \).*/\1"'"$SDK_CHECKSUM"'"/' Package.swift
SDK_URL="https:\/\/github.com\/mParticle\/mparticle-apple-sdk\/releases\/download\/$PREFIXED_VERSION\/mParticle_Apple_SDK_NoLocation.xcframework.zip"
SDK_CHECKSUM=$(swift package compute-checksum mParticle_Apple_SDK_NoLocation.xcframework.zip)
sed -i '' 's/\(^let mParticle_Apple_SDK_NoLocation_URL[^=]*= \).*/\1"'"$SDK_URL"'"/' Package.swift
sed -i '' 's/\(^let mParticle_Apple_SDK_NoLocation_Checksum[^=]*= \).*/\1"'"$SDK_CHECKSUM"'"/' Package.swift

# Make the release commit in git
#

git add Package.swift
git add mParticle-Apple-SDK.podspec
git add mParticle_Apple_SDK.json
git add CHANGELOG.md
git add mParticle-Apple-SDK/MPIConstants.m
git add Framework/Info.plist
git commit -m "chore(release): $VERSION [skip ci]

$NOTES"

./Scripts/make_artifacts.sh
ls mParticle_Apple_SDK.framework.zip mParticle_Apple_SDK_NoLocation.framework.zip mParticle_Apple_SDK.xcframework.zip mParticle_Apple_SDK_NoLocation.xcframework.zip generated-docs.zip || exit 1
