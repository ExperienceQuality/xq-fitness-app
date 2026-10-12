import FitnessCore
import SwiftUI
import UniformTypeIdentifiers

private struct FitnessExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(snapshot: FitnessSnapshot) throws {
        data = try FitnessSnapshotImport.encode(snapshot)
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct FitnessRootView: View {
    let store: FitnessStore
    @State private var router = AppRouter()
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument: FitnessExportDocument?
    @State private var pendingImport: FitnessSnapshot?
    @State private var importError: String?
    @State private var showingReplaceConfirmation = false

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            RoutineListView(
                store: store,
                router: router,
                onExport: beginExport,
                onImport: { isImporting = true }
            )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .routine(let routineID):
                        RoutineWorkspaceView(store: store, router: router, routineID: routineID)
                    case let .trainingDay(routineID, dayID):
                        TrainingDayView(
                            store: store,
                            router: router,
                            routineID: routineID,
                            dayID: dayID
                        )
                    case .snapshotReport(let routineID):
                        SnapshotReportView(store: store, routineID: routineID)
                    }
                }
        }
        .sheet(item: $router.sheet) { destination in
            switch destination {
            case .createRoutine:
                RoutineEditorView(model: RoutineEditorModel(store: store))
            case let .trainingSession(routineID, sessionID):
                TrainingSessionEditorView(
                    model: TrainingSessionEditorModel(
                        store: store,
                        routineID: routineID,
                        sessionID: sessionID
                    )
                )
            case let .exercise(routineID, dayID, exerciseID):
                ExerciseEditorView(
                    model: ExerciseEditorModel(
                        store: store,
                        routineID: routineID,
                        dayID: dayID,
                        exerciseID: exerciseID
                    )
                )
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "fitness-data.json"
        ) { result in
            if case .failure(let error) = result {
                importError = "Could not export Fitness data: \(error.localizedDescription)"
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: importFile
        )
        .confirmationDialog(
            "Replace Existing Fitness Data?",
            isPresented: $showingReplaceConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace Existing Data", role: .destructive) {
                replacePendingImport()
            }
            Button("Cancel", role: .cancel) {
                pendingImport = nil
            }
        } message: {
            Text("This replaces all routines, training sessions, exercises, notes, and snapshots currently on this device.")
        }
        .alert("Fitness Data Error", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "Unknown Fitness data error.")
                .accessibilityIdentifier(FitnessAccessibility.dataImportError)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )
    }

    private func beginExport() {
        do {
            exportDocument = try FitnessExportDocument(snapshot: store.snapshot)
            isExporting = true
        } catch {
            importError = "Could not export Fitness data: \(error.localizedDescription)"
        }
    }

    private func importFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let imported = try FitnessSnapshotImport.decode(data: Data(contentsOf: url))
            if store.snapshot.routines.isEmpty {
                try store.importSnapshot(imported, replacingExisting: false)
            } else {
                pendingImport = imported
                showingReplaceConfirmation = true
            }
        } catch {
            importError = (error as? LocalizedError)?.errorDescription ??
                "Could not import Fitness data: \(error.localizedDescription)"
        }
    }

    private func replacePendingImport() {
        guard let pendingImport else { return }
        do {
            try store.importSnapshot(pendingImport, replacingExisting: true)
            self.pendingImport = nil
        } catch {
            importError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

private struct RoutineListView: View {
    let store: FitnessStore
    let router: AppRouter
    let onExport: () -> Void
    let onImport: () -> Void

    var body: some View {
        Group {
            if store.snapshot.routines.isEmpty {
                ContentUnavailableView {
                    Label("No Routines Yet", systemImage: "figure.strengthtraining.traditional")
                        .accessibilityIdentifier(FitnessAccessibility.emptyRoutineList)
                } description: {
                    Text("Create a simple weekly routine. Everything stays on this device.")
                } actions: {
                    Button("Create Routine") {
                        router.sheet = .createRoutine
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(FitnessAccessibility.createRoutineButton)
                }
            } else {
                List(store.snapshot.routines) { routine in
                    NavigationLink(value: AppRoute.routine(routine.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(.headline)

                            if let notes = routine.notes {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("\(FitnessAccessibility.routineRow).\(routine.id.uuidString)")
                }
            }
        }
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Import Fitness Data", action: onImport)
                        .accessibilityIdentifier(FitnessAccessibility.importDataButton)
                    Button("Export Fitness Data", action: onExport)
                        .accessibilityIdentifier(FitnessAccessibility.exportDataButton)
                } label: {
                    Label("Fitness Data", systemImage: "arrow.up.arrow.down")
                        .accessibilityIdentifier(FitnessAccessibility.dataMenuButton)
                }

                if !store.snapshot.routines.isEmpty {
                    Button {
                        router.sheet = .createRoutine
                    } label: {
                        Label("Create Routine", systemImage: "plus")
                    }
                    .accessibilityIdentifier(FitnessAccessibility.createRoutineButton)
                }
            }
        }
    }
}

private struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: RoutineEditorModel

    init(model: RoutineEditorModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("Name", text: $model.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier(FitnessAccessibility.routineNameField)

                    TextField("Notes (optional)", text: $model.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier(FitnessAccessibility.routineNotesField)
                }

                if let validationMessage = model.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(XQPalette.destructive)
                            .accessibilityIdentifier(FitnessAccessibility.editorError)
                    }
                }

                Section {
                    Text("Saved locally on this device. Online sync can be added later without changing this flow.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save() {
                            dismiss()
                        }
                    }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier(FitnessAccessibility.routineSaveButton)
                }
            }
        }
    }
}

private struct TrainingSessionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TrainingSessionEditorModel

    init(model: TrainingSessionEditorModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section("Training Session") {
                    TextField("Name", text: $model.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier(FitnessAccessibility.trainingSessionNameField)
                }

                if let validationMessage = model.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(XQPalette.destructive)
                            .accessibilityIdentifier(FitnessAccessibility.editorError)
                    }
                }
            }
            .navigationTitle(model.isEditing ? "Rename Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save() {
                            dismiss()
                        }
                    }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier(FitnessAccessibility.trainingSessionSaveButton)
                }
            }
        }
    }
}

#Preview("Empty routines") {
    let store = try! FitnessStore(persistence: InMemoryFitnessPersistence())
    return FitnessRootView(store: store)
}
