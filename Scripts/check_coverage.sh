python3 -m venv venv
source venv/bin/activate

SCHEME="mParticle-Apple-SDK"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro,OS=latest"
RESULT_BUNDLE_PATH="./build/TestResults.xcresult"

rm -rf "$RESULT_BUNDLE_PATH"

xcodebuild test \
  -project ../mParticle-Apple-SDK.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  
xcrun xccov view --report --json "$RESULT_BUNDLE_PATH" > ./build/coverage.json

python check_coverage.py

deactivate

rm -rf venv
