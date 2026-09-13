import FitnessCore
import SwiftUI

struct ExerciseListView: View {
    let store: FitnessStore

    private var hasExercises: Bool {
        store.snapshot.routines.contains { !$0.days.flatMap(\.exercises).isEmpty }
    }

    var body: some View {
        Group {
            if !hasExercises {
                ContentUnavailableView(
                    "No Exercises Yet",
                    systemImage: "dumbbell",
                    description: Text("Add exercises to a routine to start tracking them.")
                )
                .accessibilityIdentifier(FitnessAccessibility.emptyExerciseList)
            } else {
                List {
                    ForEach(store.snapshot.routines) { routine in
                        let exercises = (try? store.exerciseProgress(routineID: routine.id)) ?? []
                        if !exercises.isEmpty {
                            Section(routine.name) {
                                ForEach(exercises) { progress in
                                    ExerciseProgressRow(progress: progress)
                                        .accessibilityIdentifier(
                                            "\(FitnessAccessibility.exerciseProgressRow).\(routine.id).\(progress.id)"
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercises")
    }
}

private struct ExerciseProgressRow: View {
    let progress: ExerciseProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progress.current.name)
                    .font(.headline)
                Spacer()
                Text(progressStatus)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(progressColor)
            }
            Text("\(progress.current.sets) sets · \(progress.current.reps) reps · \(progress.current.weightKg.formatted()) kg")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var progressStatus: String {
        switch progress.weight {
        case .first: "First record"
        case .increased: "Increased"
        case .decreased: "Decreased"
        case .maintained: "Same"
        }
    }

    private var progressColor: Color {
        switch progress.weight {
        case .first, .maintained: .secondary
        case .increased: .green
        case .decreased: .orange
        }
    }
}
