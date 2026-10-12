import XCTest
import XQXCUITestSupport

@MainActor
final class FitnessDataMigrationTests: FitnessUITestCase {
    func testFitnessDataMenuExposesExportAndImportActions() {
        let app = fitnessApp
        app.buttons[FitnessAccessibility.dataMenuButton].tapWhenHittable()

        app.buttons[FitnessAccessibility.exportDataButton].requireExistence()
        app.buttons[FitnessAccessibility.importDataButton].requireExistence()
    }
}
