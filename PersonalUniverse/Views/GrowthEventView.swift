//
//  GrowthEventView.swift
//  PersonalUniverse
//

import SwiftUI

struct GrowthEventView: View {
    let style: GalaxyStyle
    let progress: Double

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
                            .white.opacity(appeared ? 0.10 : 0),
                            .white.opacity(0.015),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 28)

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
                    .white.opacity(pulse ? 0 : 0.25),
                    lineWidth: 1
                )
                .frame(
                    width: pulse ? 280 : 40,
                    height: pulse ? 280 : 40
                )
                .opacity(pulse ? 0 : 1)
        }
        .frame(width: 340, height: 340)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }

            withAnimation(.easeOut(duration: 1.2).delay(0.15)) {
                pulse = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Growth — 10% — Expanding") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .expanding,
            progress: 0.10
        )
    }
}

#Preview("Growth — 35% — Expanding") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .expanding,
            progress: 0.35
        )
    }
}

#Preview("Growth — 60% — Cluster") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .cluster,
            progress: 0.60
        )
    }
}

#Preview("Growth — 80% — Spiral") {
    ZStack {
        SpaceBackground()
            .ignoresSafeArea()

        GrowthEventView(
            style: .spiral,
            progress: 0.80
        )
    }
}
