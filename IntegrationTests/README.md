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
- Generating a test iOS app using Tuist
- Linking directly to local SDK source code
- Running the app in iOS Simulator
- Recording all API traffic with WireMock for later use in testing

The project uses Tuist with `.local(path: "../")` package reference, which allows Xcode to resolve the local SDK package and use source files directly, automatically picking up your latest code changes.

## Available Scripts

### `run_wiremock_recorder.sh` - Record API Requests for Testing

Records all mParticle SDK API requests using WireMock for later use in integration testing.

```bash
./run_wiremock_recorder.sh
```

**What it does:**
1. Generates Tuist project with local SDK sources
2. Builds the integration test application
3. Finds and resets iOS Simulators
4. Automatically selects available iPhone simulator (iPhone 17/16/15 priority)
5. Starts simulator
6. Installs test application
7. Starts WireMock in recording mode
8. Launches test application
9. Records all API traffic to mapping files
10. Waits for application completion
11. Stops WireMock and shows results

**Recorded Files:**
- `wiremock-recordings/mappings/*.json` - API request/response mappings
- `wiremock-recordings/__files/*` - Response body files

### `extract_request_body.py` - Extract Request Body from WireMock Mapping

Extracts JSON request body from a WireMock mapping file for easier editing and maintenance.

```bash
# Extract request body without field replacements
python3 extract_request_body.py wiremock-recordings/mappings/mapping-v1-identify.json identify_test

# Extract with field replacements (replaces dynamic fields with ${json-unit.ignore})
python3 extract_request_body.py wiremock-recordings/mappings/mapping-v1-identify.json identify_test --replace
```

**What it does:**
- Extracts the JSON request body from WireMock mapping file
- Optionally replaces known dynamic fields (IDs, timestamps, device info) with `${json-unit.ignore}`
- Saves extracted body to `wiremock-recordings/requests/{test_name}.json`
- Makes it easier to edit and maintain test request bodies

**Dynamic fields replaced with `--replace`:**
`a`, `bid`, `bsv`, `ct`, `das`, `dfs`, `dlc`, `dn`, `dosv`, `est`, `ict`, `id`, `lud`, `sct`, `sid`, `vid`

**Output file format:**
```json
{
  "test_name": "identify_test",
  "source_mapping": "wiremock-recordings/mappings/mapping-v1-identify.json",
  "request_method": "POST",
  "request_url": "/v1/identify",
  "request_body": { ... }
}
```

### `update_mapping_from_extracted.py` - Update WireMock Mapping from Extracted Body

Updates a WireMock mapping file with a modified request body from an extracted JSON file.

```bash
python3 update_mapping_from_extracted.py wiremock-recordings/requests/identify_test.json
```

**What it does:**
- Reads the extracted request body from JSON file
- Updates the source WireMock mapping file with the modified request body
- Preserves all WireMock configuration (response, headers, etc.)
- Creates backup of original mapping file

**Use case:** After extracting and editing a request body, use this script to apply changes back to the mapping.

**Note:** This script is automatically called by the test runner when executing integration tests with modified request bodies.

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
   The script automatically uses your latest changes, runs the app, and records all API traffic

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

### Editing and Maintaining Test Request Bodies

After recording, you should update request bodies to make them more maintainable (e.g., replace dynamic values):

1. **Extract request body from mapping:**
   ```bash
   # Extract with automatic field replacement (recommended)
   python3 extract_request_body.py \
     wiremock-recordings/mappings/mapping-v1-identify.json \
     identify_test \
     --replace
   ```
   
   This creates `wiremock-recordings/requests/identify_test.json` with dynamic fields replaced by `${json-unit.ignore}`

2. **Edit the extracted request body** (optional):
   - Open `wiremock-recordings/requests/identify_test.json`
   - Modify the `request_body` section as needed
   - Add or remove fields, change expected values, etc.

3. **Update the mapping file with changes:**
   ```bash
   python3 update_mapping_from_extracted.py \
     wiremock-recordings/requests/identify_test.json
   ```
   
   This updates the original mapping file with your changes

4. **Commit both files:**
   ```bash
   git add wiremock-recordings/mappings/mapping-v1-identify.json
   git add wiremock-recordings/requests/identify_test.json
   git commit -m "Update identify request mapping"
   ```

### Running Integration Tests

When running integration tests, the test framework will:
1. Automatically look for extracted request bodies in `wiremock-recordings/requests/`
2. Apply any changes from extracted bodies to the mappings before starting WireMock
3. Run tests against the updated mappings

### Benefits of This Workflow

- ✅ **Cleaner recordings:** Test only specific SDK methods to avoid recording unrelated API calls
- ✅ **Dynamic values ignored:** Timestamps, IDs, and device info are automatically ignored in matching
- ✅ **Easy maintenance:** Request bodies are stored in separate, readable JSON files
- ✅ **Clear diffs:** Changes to request expectations are easy to review in git diffs
- ✅ **No manual JSON escaping:** No need to edit escaped JSON strings in mapping files
- ✅ **Fast iteration:** SDK changes are automatically picked up without rebuilding
