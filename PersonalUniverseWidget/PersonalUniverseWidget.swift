//
//  PersonalUniverseWidget.swift
//  PersonalUniverseWidget
//

import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct PersonalUniverseWidgetBundle: WidgetBundle {
    var body: some Widget {
        PersonalUniverseWidget()
    }
}

// MARK: - Widget

struct PersonalUniverseWidget: Widget {
    let kind = "PersonalUniverseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WidgetProvider()
        ) { entry in
            WidgetRootView(universe: entry.universe)
                .widgetURL(
                    WidgetDeepLink.url(
                        hasActiveChallenge: entry.universe.hasActiveChallenge
                    )
                )
                .containerBackground(for: .widget) {
                    Color.black
                }
        }
        .configurationDisplayName("Personal Universe")
        .description("A small window into your universe.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}

// MARK: - Root View

struct WidgetRootView: View {
    let universe: WidgetUniverseData

    @Environment(\.widgetFamily)
    private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(universe: universe)

        case .systemMedium:
            MediumWidgetView(universe: universe)

        case .systemLarge:
            LargeWidgetView(universe: universe)

        default:
            SmallWidgetView(universe: universe)
        }
    }
}

// MARK: - Preview

#Preview(
    "Small - Active",
    as: .systemSmall
) {
    PersonalUniverseWidget()
} timeline: {
    WidgetUniverseEntry(
        date: .now,
        universe: .previewActive
    )
}

#Preview(
    "Medium - Active",
    as: .systemMedium
) {
    PersonalUniverseWidget()
} timeline: {
    WidgetUniverseEntry(
        date: .now,
        universe: .previewActive
    )
}

#Preview(
    "Large - Active",
    as: .systemLarge
) {
    PersonalUniverseWidget()
} timeline: {
    WidgetUniverseEntry(
        date: .now,
        universe: .previewActive
    )
}

#Preview(
    "Small - Empty",
    as: .systemSmall
) {
    PersonalUniverseWidget()
} timeline: {
    WidgetUniverseEntry(
        date: .now,
        universe: .empty
    )
}
