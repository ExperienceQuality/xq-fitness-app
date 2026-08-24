import XCTest

import XQXCUITestSupport

enum TestApplication {
    static let descriptor = ApplicationDescriptor(
        bundleIdentifier: "com.xq.fitness.ios-xq-fitness-app",
        launchConfiguration: LaunchConfiguration(
            arguments: ["--xq-ui-testing"],
            resetArguments: ["--xq-ui-testing-reset"]
        )
    )
}

extension BaseUITestCase {
    /// Keeps the fitness suite's named evidence calls while diagnostics are
    /// supplied by the shared package.
    func captureScreenshot(named name: String) {
        attachDiagnostics(named: name)
    }
}

@MainActor
class FitnessUITestCase: BaseUITestCase {
    override class var applicationDescriptor: ApplicationDescriptor {
        TestApplication.descriptor
    }

    var fitnessApp: XCUIApplication {
        guard let application else {
            preconditionFailure("Fitness UI tests must launch through shared setUp")
        }
        return application
    }

    override func verifyInitialState(in app: XCUIApplication) {
        RoutineListScreen(application: app).emptyState.requireExistence()
    }

    @discardableResult
    func relaunchPreservingTestData() -> XCUIApplication {
        relaunchApplication(reset: false)
    }

    @discardableResult
    func resetToCleanState() -> XCUIApplication {
        let app = relaunchApplication(reset: true)
        RoutineListScreen(application: app).emptyState.requireExistence()
        return app
    }
}
