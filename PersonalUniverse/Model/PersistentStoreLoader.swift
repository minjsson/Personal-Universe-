import Observation
import SwiftData
import OSLog

@Observable
@MainActor
final class PersistentStoreLoader {
    private(set) var container: ModelContainer?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    private let makeContainer: () throws -> ModelContainer

    init(makeContainer: @escaping () throws -> ModelContainer = {
        let schema = Schema([UniverseChallenge.self, ChallengeDay.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [configuration])
    }) {
        self.makeContainer = makeContainer
    }

    func open() {
        guard container == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            container = try makeContainer()
        } catch {
            Logger(subsystem: "PersonalUniverse", category: "Storage")
                .error("Unable to open store: \(String(describing: error), privacy: .private)")
            errorMessage = "Your saved data has not been deleted. Try again. If this continues, restart the app and check available device storage."
        }
    }
}
