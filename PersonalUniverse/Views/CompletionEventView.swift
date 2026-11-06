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

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var shouldAnimate: Bool { scenePhase == .active && !reduceMotion }

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
        GeometryReader { geometry in
            if showActions {
                ScrollView {
                    if geometry.size.width > geometry.size.height {
                        HStack(spacing: 24) {
                            artwork.frame(maxWidth: 280)
                            VStack(spacing: 24) {
                                completionMessage
                                completionChoices
                            }
                            .frame(maxWidth: 320)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    } else {
                        VStack(spacing: 24) {
                            completionMessage
                            Spacer(minLength: 0)
                            artwork.frame(maxWidth: 340)
                            Spacer(minLength: 0)
                            completionChoices
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                artwork
                    .frame(maxWidth: 340, maxHeight: 340)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard animationFinished, !showActions else { return }
            onReveal()
        }
        .task(id: shouldAnimate) {
            guard !reduceMotion else {
                settleWithoutMotion()
                return
            }
            guard scenePhase == .active else { return }
            if !animationFinished {
                startCompletionAnimation()
                do { try await Task.sleep(for: .seconds(3.4)) }
                catch { return }
                guard !Task.isCancelled else { return }
                animationFinished = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .onDisappear {
            withTransaction(Transaction(animation: nil)) { breathing = false }
        }
    }

    // All illumination stays inside the galaxy region, below the action layer.
    private var completionArtwork: some View {
        ZStack {
            // MARK: - Atmosphere

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(atmosphereAppeared ? 0.32 : 0),
                            .white.opacity(0.055),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 22)
                .scaleEffect(atmosphereAppeared ? 1 : 0.7)

            // MARK: - Completion Burst

            completionBurst

            // MARK: - Central Completion Light

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(completionLight ? 0.46 : 0.02),
                            .white.opacity(completionLight ? 0.18 : 0),
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

            // MARK: - Galaxy

            GalaxyView(
                style: style,
                progress: 1,
                isCurrent: true,
                isAnimated: true,
                revealProgress: 1
            )
            .scaleEffect(
                galaxyAppeared
                    ? (galaxySettled ? 1 : 0.92)
                    : 0.55
            )
            .opacity(galaxyAppeared ? 1 : 0)
        }
    }

    // MARK: - Completion Burst

    private var completionBurst: some View {
        ZStack {
            // Large soft energy wave

            Circle()
                .stroke(
                    .white.opacity(burst ? 0 : 0.65),
                    lineWidth: 1.4
                )
                .frame(width: 70, height: 70)
                .scaleEffect(burst ? 4.0 : 0.2)
                .blur(radius: 0.5)

            // Second wave

            Circle()
                .stroke(
                    .white.opacity(burst ? 0 : 0.4),
                    lineWidth: 1
                )
                .frame(width: 90, height: 90)
                .scaleEffect(burst ? 2.8 : 0.15)

            // Central flash

            Circle()
                .fill(
                    .white.opacity(burstGlow && !galaxySettled ? 0.32 : 0)
                )
                .frame(width: 90, height: 90)
                .blur(radius: 18)

            // Small surrounding stars

            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * (.pi * 2 / 8)

                Circle()
                    .fill(
                        .white.opacity(burst ? 0 : 0.8)
                    )
                    .frame(width: 3, height: 3)
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

        // The View's task owns the delayed phase and is cancelled on disappearance.
    }

    private func settleWithoutMotion() {
        withTransaction(Transaction(animation: nil)) {
            atmosphereAppeared = true
            galaxyAppeared = true
            burst = true
            burstGlow = true
            galaxySettled = true
            completionLight = true
            breathing = false
            animationFinished = true
        }
    }

    // MARK: - Actions

    private var artwork: some View {
        UniverseArtwork { completionArtwork }
            .clipped()
            .allowsHitTesting(false)
    }

    private var completionMessage: some View {
        VStack(spacing: 8) {
            Text("Your universe is complete.")
                .font(.title3)
                .foregroundStyle(.white)
            Text("What comes next?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var completionChoices: some View {
        VStack(spacing: 12) {
            completionAction(title: "My Universe", action: onMyUniverse)
            completionAction(title: "New Challenge", action: onNewChallenge)
        }
        .frame(maxWidth: 280)
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

                Spacer()

                UniverseNavigationArrow(symbol: UniverseSymbols.forward)
            }
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .contentShape(
                Rectangle()
                    .inset(by: -12)
            )
        }
        .buttonStyle(UniverseNavigationButtonStyle())
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
    .background { SpaceSceneBackground().ignoresSafeArea() }
}

#Preview("Completion — Cluster") {
    CompletionEventView(
        style: .cluster,
        showActions: true,
        onReveal: {},
        onMyUniverse: {},
        onNewChallenge: {}
    )
    .background { SpaceSceneBackground().ignoresSafeArea() }
}

#Preview("Completion — Spiral") {
    CompletionEventView(
        style: .spiral,
        showActions: true,
        onReveal: {},
        onMyUniverse: {},
        onNewChallenge: {}
    )
    .background { SpaceSceneBackground().ignoresSafeArea() }
}
