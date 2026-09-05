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

## Continuous integration

GitHub Actions runs for pull requests, pushes to `main`, and manual dispatches.
Both jobs use `macos-15` with Xcode 16.4:

- **Core tests** runs the `FitnessCore` SwiftPM tests.
- **iOS UI tests** runs the UI-test scheme on iPhone 16 with iOS 18.5.

CI disables code signing and needs no signing credentials or repository
secrets. A failed or cancelled iOS UI-test run uploads its XCResult for
diagnosis.

To reproduce both jobs locally with the same Xcode and simulator:

```bash
export DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer

swift test --package-path FitnessCore

mkdir -p build/results

xcodebuild \
  -project ios-xq-fitness-app.xcodeproj \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -resolvePackageDependencies

xcodebuild \
  -project ios-xq-fitness-app.xcodeproj \
  -scheme ios-xq-fitness-app-ui-tests \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -derivedDataPath build/DerivedData \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -disableAutomaticPackageResolution \
  -resultBundlePath build/results/ui-tests.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
```

## Physical device (optional)

```bash
./scripts/run-device-ui-tests.sh
DEVELOPMENT_TEAM=<Apple-team-id> \
IOS_PROVISIONING_DEVICE_ID=<hardware-udid> \
./scripts/build-device-ipa.sh
```

Requires a trusted iPhone and valid Apple Development signing. Override the
device with `IOS_DEVICE_ID`, or let `scripts/plugged-iphone-udid.sh` detect the
plugged-in phone. Defaults: `iPhone` for `./scripts/run-device-ui-tests.sh`,
`David` (iPhone Air) for `./scripts/build-device-ipa.sh`. Device installs prune
stale `.xctrunner` apps first to avoid the free-profile three-app limit.
