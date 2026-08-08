# iOS XQ Fitness Build And Test Workflow

Native SwiftUI iPhone app with **unit** tests in host-testable `FitnessCore` and
**UI** tests in `AppUITests`.

## Basics

- Unit: `FitnessCore` SwiftPM package (`swift test --package-path FitnessCore`)
- App scheme (build): `ios-xq-fitness-app`
- UI scheme: `ios-xq-fitness-app-ui-tests` → `ios-xq-fitness-appUITests`
- App bundle ID: `com.xq.fitness.ios-xq-fitness-app`
- UI-test bundle ID: `com.xq.fitness.ios-xq-fitness-appUITests`

## Unit

```bash
xcodebuild \
  -project ios-xq-fitness-app.xcodeproj \
  -scheme ios-xq-fitness-app \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
swift test --package-path FitnessCore
```

## UI (Simulator)

```bash
./scripts/run-ui-tests.sh
```

Optional: `IOS_SIMULATOR_NAME='iPhone 16 Pro'`.

The suite uses `--xq-ui-testing` and `--xq-ui-testing-reset`, so it stores data
under `XQFitnessUITests` and cannot reset normal application data. Each run
retains a timestamped XCResult beneath `build/ui-test-results/`. Shared
`FitnessUITestCase` setup performs that reset and requires the empty routine
state before every test body.

## Physical device (optional)

```bash
./scripts/run-device-ui-tests.sh
DEVELOPMENT_TEAM=<Apple-team-id> \
IOS_PROVISIONING_DEVICE_ID=<hardware-udid> \
./scripts/build-device-ipa.sh
```

Requires a trusted iPhone and valid Apple Development signing. Override the
device with `IOS_DEVICE_ID`, or let `scripts/plugged-iphone-udid.sh` detect the
plugged-in phone (defaults to `iPhone Air` when multiple are connected). Device
installs prune stale `.xctrunner` apps first to avoid the free-profile
three-app limit.
