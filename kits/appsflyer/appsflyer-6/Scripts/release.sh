VERSION="$1"
PREFIXED_VERSION="v$1"
NOTES="$2"

# Update version number
#

# Update CocoaPods podspec file
sed -i '' 's/\(^    s.version[^=]*= \).*/\1"'"$VERSION"'"/' mParticle-AppsFlyer.podspec

# Make the release commit in git
#

git add mParticle-AppsFlyer.podspec
git add mParticle_AppsFlyer.json
git add CHANGELOG.md
git commit -m "chore(release): $VERSION [skip ci]

$NOTES"
