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

    override func verifyInitialState(in application: XCUIApplication) {
        RoutineListScreen(application: application).emptyState.requireExistence()
    }

    @discardableResult
    func relaunchPreservingTestData() -> XCUIApplication {
        relaunchApplication(TestApplication.descriptor, reset: false)
    }

    @discardableResult
    func resetToCleanState() -> XCUIApplication {
        let app = relaunchApplication(TestApplication.descriptor, reset: true)
        RoutineListScreen(application: app).emptyState.requireExistence()
        return app
    }
}
