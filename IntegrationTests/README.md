# Integration Tests

Tools for recording mParticle Apple SDK API requests using WireMock for later use in integration testing.

## Prerequisites

Before getting started, install Tuist:

```bash
brew install tuist
```

Then generate the Xcode project:

```bash
cd IntegrationTests
tuist generate
```

This will create the `IntegrationTests.xcodeproj` and `IntegrationTests.xcworkspace` files and automatically open them in Xcode.

If you need to edit the Tuist project configuration (`Project.swift`):

```bash
tuist edit
```

This will open a temporary Xcode project for editing Tuist manifest files.

If you encounter any issues with project generation, you can clean the Tuist cache first:

```bash
tuist clean
tuist generate
```

## Overview

This project provides tools for recording mParticle SDK API requests by:
- Building mParticle SDK as an xcframework for iOS Simulator
- Generating a test iOS app using Tuist that links to the built framework
- Running the app in iOS Simulator
- Recording all API traffic with WireMock for later use in testing

The project builds the SDK into an xcframework stored in `temp_artifacts/` before each test run, ensuring tests always use your latest code changes. The framework is built for iOS Simulator only for faster compilation times during testing.

## Available Scripts

### `run_wiremock_recorder.sh` - Record API Requests for Testing

Records all mParticle SDK API requests using WireMock for later use in integration testing.

```bash
./run_wiremock_recorder.sh
```

**What it does:**
1. Builds mParticle SDK as xcframework for iOS Simulator
2. Generates Tuist project linked to the built framework
3. Builds the integration test application
4. Finds and resets iOS Simulators
5. Automatically selects available iPhone simulator (iPhone 17/16/15 priority)
6. Starts simulator
7. Installs test application
8. Starts WireMock in recording mode
9. Launches test application
10. Records all API traffic to mapping files
11. Waits for application completion
12. Stops WireMock and shows results

**Recorded Files:**
- `wiremock-recordings/mappings/*.json` - API request/response mappings
- `wiremock-recordings/__files/*` - Response body files

**Build Artifacts:**
- `temp_artifacts/mParticle_Apple_SDK.xcframework` - Compiled SDK framework (auto-generated, not committed to git)

### `sanitize_mapping.py` - Remove API Keys and Rename WireMock Mappings

Sanitizes WireMock mapping files by replacing API keys in URLs with regex patterns, removing API keys from filenames, and renaming files based on test name.

```bash
# Sanitize API keys and rename based on test name
python3 sanitize_mapping.py \
  wiremock-recordings/mappings/mapping-v1-us1-abc123-identify.json \
  --test-name identify
```

**What it does:**
- Replaces API keys in URLs with regex pattern `us1-[a-f0-9]+` (matches any mParticle API key)
- Renames mapping file based on test name
- Renames response body file based on test name
- Updates body filename reference in mapping JSON
- Creates clean, sanitized recordings without sensitive information

**Example transformations with `--test-name identify`:**
- URL: `/v2/us1-abc123def456.../events` → `/v2/us1-[a-f0-9]+/events`
- File: `mapping-v1-us1-abc123-identify.json` → `mapping-v1-identify.json`
- Body: `body-v1-us1-abc123-identify.json` → `body-v1-identify.json`

**Example with `--test-name log-event`:**
- URL: `/v2/us1-xyz789.../events` → `/v2/us1-[a-f0-9]+/events`
- File: `mapping-v2-us1-xyz789-events.json` → `mapping-v2-log-event.json`
- Body: `body-v2-us1-xyz789-events.json` → `body-v2-log-event.json`

### `transform_mapping_body.py` - Transform Request Bodies in WireMock Mappings

Transforms request body JSON in WireMock mappings with multiple operation modes.

```bash
# Display request body in readable format
python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json unescape

# Show escaped format for manual editing
python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json escape

# Replace dynamic fields and save
python3 transform_mapping_body.py wiremock-recordings/mappings/mapping-v1-identify.json unescape+update
```

**Operation modes:**

1. **`unescape`** - Convert equalToJson from escaped string to formatted JSON object
2. **`escape`** - Convert equalToJson from JSON object back to escaped string
3. **`unescape+update`** - Parse, replace dynamic fields with `${json-unit.ignore}`, convert to JSON object, and save

**Dynamic fields replaced with `${json-unit.ignore}`:**
`a`, `bid`, `bsv`, `ct`, `das`, `dfs`, `dlc`, `dn`, `dosv`, `est`, `ict`, `id`, `lud`, `sct`, `sid`, `vid`

## Troubleshooting

### Port Already in Use / No Recordings Created

If you see "port already allocated" errors or if no API requests were recorded, it's likely that the ports (8080 and 443) where WireMock should be running are already occupied by another container or application.

Check what's running on the ports:

```bash
# Check running Docker containers
docker ps

# Check what's using port 443
lsof -i :443

# Check what's using port 8080
lsof -i :8080
```

Stop any conflicting Docker containers:

```bash
docker stop <container-name>
docker rm <container-name>
```

If another application is using the ports, terminate it before running the script.

## Development Workflow

### Initial Recording of API Requests

1. **Write test code in the integration app:**
   - Make changes to SDK source code (if needed)
   - Edit `IntegrationTests/Sources/main.swift` to test your new or existing SDK functionality
   - Add code to call the specific SDK methods you want to record
   - **Best practice:** Temporary comment out calls to unrelated your new code to record only relevant API requests
   
2. **Run the WireMock recorder:**
   ```bash
   ./run_wiremock_recorder.sh
   ```
   The script automatically builds the SDK as an xcframework with your latest changes, runs the app, and records all API traffic

3. **Review and filter recorded mappings:**
   - All recordings are saved to `wiremock-recordings/mappings/`
   - The script records **all** API requests made during the test run
   - **Keep only the mappings related to your new test code**
   - Delete any unrelated or duplicate recordings
   
   **Tip:** To get cleaner recordings, modify `main.swift` to call only the specific SDK method you're testing, avoiding unrelated API calls

4. **Verify the recordings:**
   - Check that the recorded mappings match your expected API behavior
   - Review request URLs, methods, and bodies
   - Verify response data in `wiremock-recordings/__files/`

### Sanitizing and Processing Recorded Mappings

After recording, you should sanitize and process mappings to remove sensitive data and handle dynamic values:

1. **Sanitize and rename mapping file:**
   ```bash
   python3 sanitize_mapping.py \
     wiremock-recordings/mappings/mapping-v1-us1-abc123-identify.json \
     --test-name identify
   ```
   
   This automatically:
   - Replaces API keys in URLs with regex pattern `us1-[a-f0-9]+`
   - Renames the mapping file to `mapping-v1-identify.json` (or based on your test name)
   - Renames the response body file to `body-v1-identify.json`
   - Updates all references in the mapping JSON

2. **Transform request body (replace dynamic fields):**
   ```bash
   # Replace dynamic fields and save
   python3 transform_mapping_body.py \
     wiremock-recordings/mappings/mapping-v1-identify.json \
     unescape+update
   ```
   
   This replaces dynamic fields (timestamps, IDs, device info) with `${json-unit.ignore}`

3. **Verify the changes:**
   ```bash
   # Check that API keys are replaced with regex pattern
   grep "us1-\[a-f0-9\]+" wiremock-recordings/mappings/mapping-v1-identify.json
   
   # Should show the regex pattern us1-[a-f0-9]+
   
   # Verify files were renamed correctly
   ls -l wiremock-recordings/mappings/mapping-v1-identify.json
   ls -l wiremock-recordings/__files/body-v1-identify.json
   
   # View the transformed request body
   wiremock-recordings/mappings/mapping-identify.json
   ```

4. **Commit the sanitized files:**
   ```bash
   git add wiremock-recordings/mappings/mapping-identify.json
   git add wiremock-recordings/__files/body-identify.json
   git commit -m "Add sanitized identify request mapping"
   ```

**Alternative workflow - manual editing of request body:**

If you need to manually edit the request body:

1. **Edit the request body manually:**
   ```bash
   open wiremock-recordings/mappings/mapping-identify.json
   ```

2. **Commit the changes:**
   ```bash
   git add wiremock-recordings/mappings/mapping-identify.json
   git commit -m "Update identify request mapping"
   ```

### Running Integration Tests

Use the verification script to run full end-to-end integration tests:

```bash
./run_clean_integration_tests.sh
```

**What the verification script does:**

1. **Rebuilds SDK:** Compiles mParticle SDK as xcframework for iOS Simulator from latest source code
2. **Regenerates project:** Runs Tuist to regenerate project linked to the new xcframework
3. **Resets environment:** Cleans simulators and builds test app
4. **📝 Prepares mappings:** Escapes request body JSON in WireMock mappings for proper matching
5. **Starts WireMock:** Launches WireMock container in verification mode with updated mappings
6. **Runs tests:** Executes test app in simulator
7. **Verifies results:** Checks that all requests matched mappings and all mappings were invoked
8. **Returns exit code:** Exits with code 1 if any verification fails (CI/CD compatible)

**Note:** The SDK xcframework is built fresh on each run, stored in `temp_artifacts/mParticle_Apple_SDK.xcframework`. This ensures tests always use your latest code changes.

