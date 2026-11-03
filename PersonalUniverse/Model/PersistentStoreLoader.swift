import Observation
import SwiftData
import OSLog

@Observable
@MainActor
final class PersistentStoreLoader {
    private(set) var container: ModelContainer?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    private(set) var backupError: String?
    private(set) var backupDate: Date?
    private(set) var restoredArchive: URL?
    private let backup: StoreBackup?
    private var isBackingUp = false
    private var backupRequested = false
    private let makeContainer: () throws -> ModelContainer

    init(backup: StoreBackup? = StoreBackup(storeURL: ModelConfiguration(schema: Schema([UniverseChallenge.self, ChallengeDay.self])).url), makeContainer: @escaping () throws -> ModelContainer = {
        let schema = Schema([UniverseChallenge.self, ChallengeDay.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }) {
        self.makeContainer = makeContainer
        self.backup = backup
        self.backupDate = backup?.backupDate
    }

    func updateBackup() async {
        guard container != nil, let backup else { return }
        if isBackingUp { backupRequested = true; return }
        isBackingUp = true
        defer {
            isBackingUp = false
            if backupRequested {
                backupRequested = false
                Task { await updateBackup() }
            }
        }
        do {
            try container?.mainContext.save()
            try await Task.detached(priority: .utility) { try backup.create() }.value
            backupDate = backup.backupDate
            backupError = nil
        } catch {
            Logger(subsystem: "PersonalUniverse", category: "Storage")
                .error("Unable to create backup: \(String(describing: error), privacy: .private)")
            backupError = "A recovery backup could not be updated. Check available storage and try again. Existing database files have been kept."
        }
    }

    func restoreBackup() async {
        guard container == nil, !isLoading, let backup else { return }
        isLoading = true
        errorMessage = nil
        do {
            restoredArchive = try await Task.detached(priority: .userInitiated) { try backup.restore() }.value
            isLoading = false
            open()
            if container == nil {
                errorMessage = "The backup could not be opened with this app version. The original files and backup have been preserved. Try updating the app."
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func open() {
        guard container == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // Do not let SwiftData create an empty store over a recoverable missing DB.
            if let backup, backup.backupDate != nil, !backup.storeExists {
                errorMessage = "Your database file is missing, but a recovery backup is available. Restore the backup to recover your saved universe."
                return
            }
            container = try makeContainer()
        } catch {
            Logger(subsystem: "PersonalUniverse", category: "Storage")
                .error("Unable to open store: \(String(describing: error), privacy: .private)")
            errorMessage = "Your saved data has not been deleted. Try again. If this continues, restart the app and check available device storage."
        }
    }
}
