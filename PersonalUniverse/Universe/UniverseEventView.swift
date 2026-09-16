//
//  UniverseEventView.swift
//  PersonalUniverse
//

import SwiftUI

struct UniverseEventView: View {
    let event: UniverseEvent
    let style: GalaxyStyle
    let progress: Double
    let showActions: Bool
    let onReveal: () -> Void
    let onMyUniverse: () -> Void
    let onNewChallenge: () -> Void

    var body: some View {
        switch event {
        case .none:
            EmptyView()

        case .growth:
            GrowthEventView(
                style: style,
                progress: progress
            )

        case .completion:
            CompletionEventView(
                style: style,
                showActions: showActions,
                onReveal: onReveal,
                onMyUniverse: onMyUniverse,
                onNewChallenge: onNewChallenge
            )
        }
    }
}

// MARK: - Previews

#Preview("Growth — Expanding") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        UniverseEventView(
            event: .growth,
            style: .expanding,
            progress: 0.35,
            showActions: false,
            onReveal: {},
            onMyUniverse: {},
            onNewChallenge: {}
        )
    }
}

#Preview("Growth — Cluster") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        UniverseEventView(
            event: .growth,
            style: .cluster,
            progress: 0.60,
            showActions: false,
            onReveal: {},
            onMyUniverse: {},
            onNewChallenge: {}
        )
    }
}

#Preview("Growth — Spiral") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        UniverseEventView(
            event: .growth,
            style: .spiral,
            progress: 0.80,
            showActions: false,
            onReveal: {},
            onMyUniverse: {},
            onNewChallenge: {}
        )
    }
}

#Preview("Completion — Expanding") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        UniverseEventView(
            event: .completion,
            style: .expanding,
            progress: 1,
            showActions: false,
            onReveal: {},
            onMyUniverse: {},
            onNewChallenge: {}
        )
    }
}

#Preview("Completion — Cluster") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        UniverseEventView(
            event: .completion,
            style: .cluster,
            progress: 1,
            showActions: true,
            onReveal: {},
            onMyUniverse: {},
            onNewChallenge: {}
        )
    }
}

#Preview("Completion — Spiral") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        UniverseEventView(
            event: .completion,
            style: .spiral,
            progress: 1,
            showActions: true,
            onReveal: {},
            onMyUniverse: {},
            onNewChallenge: {}
        )
    }
}
