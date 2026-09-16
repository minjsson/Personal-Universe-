//
//  WidgetGalaxyView.swift
//  PersonalUniverseWidget
//

import SwiftUI
import WidgetKit

struct WidgetGalaxyView: View {
    let universe: WidgetUniverseData

    @Environment(\.widgetFamily)
    private var family

    // MARK: - Galaxy Style

    private var galaxyStyle: GalaxyStyle {
        GalaxyStyle(rawValue: universe.galaxyRawValue) ?? .expanding
    }

    // MARK: - Body

    var body: some View {
        GalaxyView(
            style: galaxyStyle,
            progress: universe.progress,
            isCurrent: universe.hasActiveChallenge,
            isAnimated: false,
            revealProgress: universe.progress
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
