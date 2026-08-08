# iOS XQ Fitness App

Native SwiftUI fitness application for iPhone. Offline-only: routines, seven-day
training plans, exercises, and the newest two progress snapshots are stored
locally as versioned JSON.

Standalone Xcode project. Requires Xcode 16+, Swift 5.10+, XcodeGen (optional
regenerate), iOS 17+.

## Architecture

- SwiftUI MVVM for editors: parent-built `RoutineEditorModel` /
  `ExerciseEditorModel`, Views bind only; router-owned `NavigationStack`.
- `FitnessStore` owns domain mutations and observable snapshot state.
- `FitnessPersisting` is the storage seam; production uses atomic local JSON
  with recovery and host tests use an in-memory adapter.
- No API, authentication, analytics, or container workflow.

## Build and unit test

```bash
xcodegen generate   # optional; regenerates the Xcode project from project.yml
xcodebuild \
  -project ios-xq-fitness-app.xcodeproj \
  -scheme ios-xq-fitness-app \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
swift test --package-path FitnessCore
```

## UI tests (Simulator)

```bash
./scripts/run-ui-tests.sh
```

Every UI test resets and verifies an isolated `XQFitnessUITests` store before
its test body. Normal app data is never reset. See [BUILD_AND_TEST.md](BUILD_AND_TEST.md).

## Build and deploy an IPA

With the iPhone connected, unlocked, and trusted:

```bash
DEVELOPMENT_TEAM=<Apple-team-id> \
IOS_PROVISIONING_DEVICE_ID=<hardware-udid> \
./scripts/build-device-ipa.sh
```

`DEVELOPMENT_TEAM` defaults to `T99X93V7Y2`. `IOS_DEVICE_ID` defaults to the
plugged-in iPhone detected by `scripts/plugged-iphone-udid.sh` (David's iPhone
Air for `./scripts/build-device-ipa.sh`). Override with `IOS_DEVICE_NAME` or
`IOS_DEVICE_MODEL`. Use `INSTALL_TO_DEVICE=0` to export only.
