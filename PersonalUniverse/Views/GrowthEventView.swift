//
//  GrowthEventView.swift
//  PersonalUniverse
//

import SwiftUI

struct GrowthEventView: View {
    let style: GalaxyStyle
    let progress: Double

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var shouldAnimate: Bool { scenePhase == .active && !reduceMotion }

    @State private var appeared = false
    @State private var pulse = false

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // MARK: - Atmosphere

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(appeared ? 0.30 : 0),
                            .white.opacity(0.055),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 20)

            // MARK: - Revealed Galaxy

            GalaxyView(
                style: style,
                progress: clampedProgress,
                isCurrent: true,
                isAnimated: true,
                revealProgress: clampedProgress
            )
            .scaleEffect(appeared ? 1 : 0.75)
            .opacity(appeared ? 1 : 0)

            // MARK: - Growth Pulse

            Circle()
                .stroke(
                    .white.opacity(pulse ? 0 : 0.70),
                    lineWidth: 1.4
                )
                .frame(
                    width: pulse ? 280 : 40,
                    height: pulse ? 280 : 40
                )
                .opacity(pulse ? 0 : 1)
        }
        .frame(width: 340, height: 340)
        .clipped()
        .allowsHitTesting(false)
        .task(id: shouldAnimate) {
            guard !reduceMotion else {
                withTransaction(Transaction(animation: nil)) { appeared = true; pulse = true }
                return
            }
            guard scenePhase == .active else { return }
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }

            withAnimation(.easeOut(duration: 1.5).delay(0.15)) {
                pulse = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Growth — 10% — Expanding") {
    ZStack {
        SpaceSceneBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .expanding,
            progress: 0.10
        )
    }
}

#Preview("Growth — 35% — Expanding") {
    ZStack {
        SpaceSceneBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .expanding,
            progress: 0.35
        )
    }
}

#Preview("Growth — 60% — Cluster") {
    ZStack {
        SpaceSceneBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .cluster,
            progress: 0.60
        )
    }
}

#Preview("Growth — 80% — Spiral") {
    ZStack {
        SpaceSceneBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .spiral,
            progress: 0.80
        )
    }
}
