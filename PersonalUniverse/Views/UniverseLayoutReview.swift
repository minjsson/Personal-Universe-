#if DEBUG
import SwiftUI
import SwiftData

/// Disposable in-memory fixtures for checking real screens at different phone sizes.
struct UniverseLayoutReview: View {
    private let arguments = ProcessInfo.processInfo.arguments
    @State private var container: ModelContainer?
    @State private var challenge: UniverseChallenge?
    @State private var message: String?
    @State private var showEditor = true

    var body: some View {
        Group {
            if let container, let challenge {
                Group {
                    if arguments.contains("--layout-editor") {
                        NavigationStack {
                            ChallengeJourneyView(challenge: challenge)
                                .sheet(isPresented: $showEditor) {
                                    ChallengeSettingsView(challenge: challenge)
                                }
                        }
                    } else if arguments.contains("--layout-setup") {
                        NavigationStack { EnterChallengeView() }
                    } else if arguments.contains("--layout-reflection") {
                        ReflectionView(reflection: .constant(""), onComplete: { false })
                    } else {
                        ContentView()
                    }
                }
                .modelContainer(container)
            } else {
                Text(message ?? "Loading layout preview…")
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard container == nil else { return }
            do {
                let schema = Schema([UniverseChallenge.self, ChallengeDay.self])
                let memory = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
                let title = arguments.contains("--layout-long-title") ? "Learn Swift one small step at a time" : "Swift"
                let finalDay = arguments.contains("--layout-final-day")
                let start = finalDay ? Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now : .now
                let item = UniverseChallenge(title: title, length: finalDay ? .seven : .thirty, startDate: start,
                                             galaxy: .spiral, reminderEnabled: false)
                if finalDay {
                    for day in item.orderedDays.prefix(6) { item.completeDay(day) }
                }
                memory.mainContext.insert(item)
                try memory.mainContext.save()
                challenge = item
                container = memory
            } catch {
                message = "Layout preview could not be created: \(error.localizedDescription)"
            }
        }
    }
}
#endif
