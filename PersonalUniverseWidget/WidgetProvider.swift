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
                universe: universe.projected(at: .now)
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
            universe: universe.projected(at: .now)
        )

        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: .now
        ) ?? .now.addingTimeInterval(900)

        // Supply midnight explicitly; a refresh request is not an exact delivery time.
        let calendar = Calendar.autoupdatingCurrent
        var entries = [entry]
        if let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: entry.date)) {
            entries.append(WidgetUniverseEntry(date: midnight, universe: universe.projected(at: midnight, calendar: calendar)))
        }
        let timeline = Timeline(
            entries: entries,
            policy: .after(refreshDate)
        )

        completion(timeline)
    }
}
