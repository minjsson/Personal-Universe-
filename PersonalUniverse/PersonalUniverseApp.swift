//
//  PersonalUniverseApp.swift
//  PersonalUniverse
//

import SwiftUI
import SwiftData

@main
struct PersonalUniverseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UniverseChallenge.self,
            ChallengeDay.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
