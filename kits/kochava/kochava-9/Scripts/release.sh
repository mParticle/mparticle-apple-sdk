VERSION="$1"
PREFIXED_VERSION="v$1"
NOTES="$2"

# Update version number
#

# Update VERSION file
echo $PREFIXED_VERSION >VERSION

# Make the release commit in git
#

git add VERSION
git commit -m "chore(release): $VERSION [skip ci]

$NOTES"
