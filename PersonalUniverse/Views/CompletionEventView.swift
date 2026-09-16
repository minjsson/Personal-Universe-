//
//  CompletionEventView.swift
//  PersonalUniverse
//

import SwiftUI

struct CompletionEventView: View {
    let style: GalaxyStyle
    let showActions: Bool
    let onReveal: () -> Void
    let onMyUniverse: () -> Void
    let onNewChallenge: () -> Void

    // MARK: - Animation State

    @State private var atmosphereAppeared = false
    @State private var galaxyAppeared = false

    // Explosive phase
    @State private var burst = false
    @State private var burstGlow = false

    // Ceremonial phase
    @State private var galaxySettled = false
    @State private var completionLight = false
    @State private var breathing = false
    @State private var animationFinished = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // MARK: - Space

            SpaceBackground()
                .ignoresSafeArea()

            // MARK: - Atmosphere

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(atmosphereAppeared ? 0.12 : 0),
                            .white.opacity(0.025),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 190
                    )
                )
                .frame(width: 380, height: 380)
                .blur(radius: 32)
                .scaleEffect(atmosphereAppeared ? 1 : 0.7)

            // MARK: - Completion Burst

            completionBurst

            // MARK: - Galaxy

            GalaxyView(
                style: style,
                progress: 1,
                isCurrent: false,
                isAnimated: true,
                revealProgress: 1
            )
            .scaleEffect(
                galaxyAppeared
                    ? (galaxySettled ? 1 : 0.92)
                    : 0.55
            )
            .opacity(galaxyAppeared ? 1 : 0)

            // MARK: - Central Completion Light

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(completionLight ? 0.24 : 0.02),
                            .white.opacity(completionLight ? 0.08 : 0),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 65
                    )
                )
                .frame(
                    width: completionLight ? 120 : 15,
                    height: completionLight ? 120 : 15
                )
                .blur(radius: completionLight ? 16 : 2)
                .scaleEffect(breathing ? 1.04 : 1)
                .opacity(galaxyAppeared ? 1 : 0)

            // MARK: - Actions

            if showActions {
                completionActions
                    .transition(
                        .opacity
                            .combined(with: .move(edge: .bottom))
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())

        // MARK: - Tap

        .onTapGesture {
            guard animationFinished else {
                return
            }

            guard !showActions else {
                return
            }

            onReveal()
        }

        // MARK: - Start

        .onAppear {
            startCompletionAnimation()
        }
    }

    // MARK: - Completion Burst

    private var completionBurst: some View {
        ZStack {
            // Large soft energy wave

            Circle()
                .stroke(
                    .white.opacity(burst ? 0 : 0.32),
                    lineWidth: 1
                )
                .frame(width: 70, height: 70)
                .scaleEffect(burst ? 4.0 : 0.2)
                .blur(radius: 0.5)

            // Second wave

            Circle()
                .stroke(
                    .white.opacity(burst ? 0 : 0.18),
                    lineWidth: 0.8
                )
                .frame(width: 90, height: 90)
                .scaleEffect(burst ? 2.8 : 0.15)

            // Central flash

            Circle()
                .fill(
                    .white.opacity(burstGlow ? 0.22 : 0)
                )
                .frame(width: 90, height: 90)
                .blur(radius: 18)

            // Small surrounding stars

            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * (.pi * 2 / 8)

                Circle()
                    .fill(
                        .white.opacity(burst ? 0 : 0.5)
                    )
                    .frame(width: 2.5, height: 2.5)
                    .offset(
                        x: CGFloat(cos(angle)) * (burst ? 125 : 15),
                        y: CGFloat(sin(angle)) * (burst ? 125 : 15)
                    )
            }
        }
        .opacity(galaxyAppeared ? 1 : 0)
    }

    // MARK: - Animation

    private func startCompletionAnimation() {
        animationFinished = false

        // -------------------------------------------------
        // PHASE 1
        // The universe reacts.
        // -------------------------------------------------

        withAnimation(.easeOut(duration: 0.8)) {
            atmosphereAppeared = true
        }

        // -------------------------------------------------
        // PHASE 2
        // Galaxy begins appearing.
        // -------------------------------------------------

        withAnimation(
            .easeOut(duration: 0.9)
                .delay(0.15)
        ) {
            galaxyAppeared = true
        }

        // -------------------------------------------------
        // PHASE 3
        // EXPLOSIVE MOMENT
        //
        // Something has been completed.
        // Energy leaves the center.
        // -------------------------------------------------

        withAnimation(
            .easeOut(duration: 1.15)
                .delay(0.55)
        ) {
            burst = true
        }

        withAnimation(
            .easeOut(duration: 0.45)
                .delay(0.55)
        ) {
            burstGlow = true
        }

        // -------------------------------------------------
        // PHASE 4
        // CEREMONIAL SETTLING
        //
        // The energy disappears.
        // The galaxy remains.
        // -------------------------------------------------

        withAnimation(
            .easeOut(duration: 0.9)
                .delay(1.65)
        ) {
            galaxySettled = true
        }

        // -------------------------------------------------
        // PHASE 5
        // A final quiet light.
        // -------------------------------------------------

        withAnimation(
            .easeInOut(duration: 1.0)
                .delay(1.9)
        ) {
            completionLight = true
        }

        // -------------------------------------------------
        // PHASE 6
        // Stillness.
        // -------------------------------------------------

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.4))

            guard !Task.isCancelled else {
                return
            }

            animationFinished = true

            withAnimation(
                .easeInOut(duration: 3.2)
                    .repeatForever(autoreverses: true)
            ) {
                breathing = true
            }
        }
    }

    // MARK: - Actions

    private var completionActions: some View {
        VStack {
            // MARK: Message

            VStack(spacing: 8) {
                Text("Your universe is complete.")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(.white)

                Text("What comes next?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .padding(.top, 72)

            Spacer()

            // MARK: Choices

            VStack(spacing: 12) {
                completionAction(
                    title: "My Universe",
                    action: onMyUniverse
                )

                completionAction(
                    title: "New Challenge",
                    action: onNewChallenge
                )
            }
            .frame(maxWidth: 280)
            .padding(.bottom, 42)
        }
    }

    // MARK: - Action

    private func completionAction(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .regular))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .contentShape(
                Rectangle()
                    .inset(by: -12)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Completion — Expanding") {
    CompletionEventView(
        style: .expanding,
        showActions: true,
        onReveal: {},
        onMyUniverse: {},
        onNewChallenge: {}
    )
}

#Preview("Completion — Cluster") {
    CompletionEventView(
        style: .cluster,
        showActions: true,
        onReveal: {},
        onMyUniverse: {},
        onNewChallenge: {}
    )
}

#Preview("Completion — Spiral") {
    CompletionEventView(
        style: .spiral,
        showActions: true,
        onReveal: {},
        onMyUniverse: {},
        onNewChallenge: {}
    )
}
