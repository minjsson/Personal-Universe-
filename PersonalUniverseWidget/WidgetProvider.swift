//
//  WidgetProvider.swift
//  PersonalUniverseWidget
//

import WidgetKit

struct WidgetProvider: TimelineProvider {
    // MARK: - Placeholder

    func placeholder(in context: Context) -> WidgetUniverseEntry {
        WidgetUniverseEntry(
            date: .now,
            universe: .previewActive
        )
    }

    // MARK: - Snapshot

    func getSnapshot(
        in context: Context,
        completion: @escaping (WidgetUniverseEntry) -> Void
    ) {
        let universe = WidgetDataManager.load()

        completion(
            WidgetUniverseEntry(
                date: .now,
                universe: universe
            )
        )
    }

    // MARK: - Timeline

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<WidgetUniverseEntry>) -> Void
    ) {
        let universe = WidgetDataManager.load()

        let entry = WidgetUniverseEntry(
            date: .now,
            universe: universe
        )

        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: .now
        ) ?? .now.addingTimeInterval(900)

        let timeline = Timeline(
            entries: [entry],
            policy: .after(refreshDate)
        )

        completion(timeline)
    }
}
