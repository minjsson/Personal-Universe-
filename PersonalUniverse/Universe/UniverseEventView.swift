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
        SpaceSceneBackground()
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
        SpaceSceneBackground()
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
        SpaceSceneBackground()
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
        SpaceSceneBackground()
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
        SpaceSceneBackground()
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
        SpaceSceneBackground()
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

#if DEBUG
/// Isolated lighting review: actual renderers, no database or service side effects.
struct UniverseLightingReview: View {
    private let arguments = ProcessInfo.processInfo.arguments
    @State private var showActions = false

    private var style: GalaxyStyle {
        if arguments.contains("--lighting-cluster") { return .cluster }
        if arguments.contains("--lighting-spiral") { return .spiral }
        return .expanding
    }

    var body: some View {
        ZStack {
            SpaceSceneBackground().ignoresSafeArea()
            if arguments.contains("--lighting-growth") {
                GrowthEventView(style: style, progress: 0.35)
            } else if arguments.contains("--lighting-completion") {
                CompletionEventView(
                    style: style, showActions: showActions,
                    onReveal: { showActions = true },
                    onMyUniverse: {}, onNewChallenge: {}
                )
            } else {
                VStack(spacing: 24) {
                    Text("Draw every day").font(.title2).foregroundStyle(.white)
                    GalaxyView(style: style, progress: 0.35, isCurrent: true,
                               isAnimated: true, revealProgress: 0.35)
                        .frame(width: 340, height: 340)
                    Text("Day 11 of 30").foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
