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

1. Make changes to SDK source code
2. Run `./run_wiremock_recorder.sh`
3. Script automatically uses your latest changes, runs the app, and records API traffic
4. Review recorded mappings in `wiremock-recordings/`
5. Commit mappings to document expected API behavior

**Note:** No need to rebuild the SDK separately - the project links directly to source files and automatically picks up your changes!
