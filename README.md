# iOS XQ Fitness App

Native SwiftUI fitness application for iPhone. Offline-only: routines,
customer-managed training sessions, exercises, and the newest two progress
snapshots are stored locally as versioned JSON.

Standalone Xcode project. Requires Xcode 16+, Swift 5.10+, XcodeGen (optional
regenerate), iOS 17+.

## Architecture

- SwiftUI MVVM for editors: parent-built `RoutineEditorModel` /
  `ExerciseEditorModel`, Views bind only; router-owned `NavigationStack`.
- `FitnessStore` owns domain mutations and observable snapshot state.
- `FitnessPersisting` is the storage seam; production uses atomic local JSON
  with recovery and host tests use an in-memory adapter.
- No API, authentication, analytics, or container workflow.

## Fitness migration from old app

Migration uses one user-visible JSON export. Apps cannot read another app's
private sandbox, so do not copy files from the old app's container.

1. Open old Fitness app.
2. Open Fitness Data and choose **Export Fitness Data**.
3. Save or share `fitness-data.json` to Files, AirDrop, or another destination.
4. Install the merged XQ Finance + Fitness app.
5. Open Fitness.
6. Open Fitness Data and choose **Import Fitness Data**, then select the saved JSON.
7. Confirm replacement if merged app already contains Fitness data.

Export and import use versioned `FitnessSnapshot` JSON. Schema versions 1 and 2
are supported; future versions are rejected with an actionable error. Schema 1
is migrated to schema 2 while preserving UUIDs, names, notes, training days,
exercises, sessions, and snapshots. Import never replaces existing data without
explicit confirmation.

This repository contains the merged app source, not the old app source. If only
an old IPA or device backup exists, launch the old app after restoring it to a
device or simulator, use its in-app exporter, then import the resulting JSON.
The merged app does not attempt private-sandbox extraction from an IPA or backup.

## Build and unit test

```bash
./scripts/build.sh
./scripts/run-unit-tests.sh
```

Both commands resolve the committed Swift package pins and use deterministic
build paths. Override destinations and paths with `IOS_BUILD_DESTINATION`,
`IOS_TEST_DESTINATION`, `IOS_DERIVED_DATA_PATH`, or
`IOS_SOURCE_PACKAGES_PATH`.

## UI tests (Simulator)

```bash
./scripts/run-ui-tests.sh
```

Every UI test resets and verifies an isolated `XQFitnessUITests` store before
its test body. Normal app data is never reset. See [BUILD_AND_TEST.md](BUILD_AND_TEST.md).

Physical-device UI tests target the dedicated `IphoneTest` device by default:

```bash
./scripts/run-device-ui-tests.sh
```

Override device selection with `IOS_DEVICE_NAME` or `IOS_DEVICE_ID`.

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
