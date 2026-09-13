import XCTest

@MainActor
final class ExerciseTabTests: FitnessUITestCase {
    func testAddedExerciseAppearsInExercisesTab() {
        let app = fitnessApp
        let routines = RoutineListScreen(application: app)

        routines.openCreateRoutine().save(name: "Progress Plan")
        routines.openRoutine(named: "Progress Plan")

        var workspace = RoutineWorkspaceScreen(application: app)
        var day = workspace.openDay(1)
        day.openAddExercise().save(name: "Bench Press", sets: "3", reps: "8", weight: "60")
        workspace = day.backToWorkspace()

        day = workspace.openDay(3)
        day.openAddExercise().save(name: "Bench Press", sets: "4", reps: "10", weight: "65")

        app.tabBars.buttons["Exercises"].tapWhenHittable()

        app.staticTexts["Bench Press"].requireExistence()
        app.staticTexts["4 sets · 10 reps · 65 kg"].requireExistence()
        app.staticTexts["First record"].requireExistence()
        captureScreenshot(named: "Exercises tab with first record")
    }
}
