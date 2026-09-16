//
//  MyUniverseView.swift
//  PersonalUniverse
//

import SwiftUI
import SwiftData

struct MyUniverseView: View {
    // MARK: - Data

    @Query(
        sort: \UniverseChallenge.startDate,
        order: .reverse
    )
    private var challenges: [UniverseChallenge]

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Navigation

    @State private var selectedChallenge: UniverseChallenge?

    // MARK: - Universe Camera

    @State private var zoom: CGFloat = 1.0
    @State private var accumulatedZoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero

    // -------------------------------------------------
    // Camera initialization state.
    //
    // This prevents onAppear from resetting the camera
    // when returning from ChallengeJourneyView.
    // -------------------------------------------------

    @State private var hasInitializedCamera = false

    // MARK: - Constants

    private let minimumZoom: CGFloat = 0.65
    private let maximumZoom: CGFloat = 2.4
    private let minimumDistanceFromCenter: CGFloat = 230
    private let maximumDistanceFromCenter: CGFloat = 430
    private let minimumGalaxyDistance: CGFloat = 175

    // MARK: - Center Challenge

    /// Determines which galaxy owns the center position.
    ///
    /// Priority:
    /// 1. Active challenge
    /// 2. Most recently started completed challenge
    ///
    /// Important:
    /// The center galaxy is NOT necessarily the current/glowing galaxy.
    /// When there is no active challenge, the latest completed challenge
    /// remains at the center but has no glow.

    private var centerChallenge: UniverseChallenge? {
        // 1. Active challenge always takes the center.

        if let activeChallenge = challenges.first(where: {
            $0.status == .active
        }) {
            return activeChallenge
        }

        // 2. If there is no active challenge,
        //    the most recently started completed challenge
        //    remains at the center.

        return challenges
            .filter {
                $0.status == .completed
            }
            .max {
                $0.startDate < $1.startDate
            }
    }

    // MARK: - Completed Galaxies

    /// Completed challenges that are NOT the center galaxy.
    ///
    /// Their universeX / universeY values are permanent.
    /// They should never be regenerated or moved.

    private var completedChallenges: [UniverseChallenge] {
        challenges.filter {
            $0.status == .completed &&
            $0.id != centerChallenge?.id
        }
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: Background

                SpaceBackground()
                    .ignoresSafeArea()

                // MARK: Content

                if challenges.isEmpty {
                    emptyUniverseView(
                        in: geometry.size
                    )
                } else {
                    universeCanvas(
                        in: geometry.size
                    )
                }
            }
        }
        .navigationTitle("My Universe")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: Navigation

        .navigationDestination(
            item: $selectedChallenge
        ) { challenge in
            ChallengeJourneyView(
                challenge: challenge
            )
        }

        // MARK: Lifecycle

        .onAppear {
            assignMissingUniversePositions()

            // -------------------------------------------------
            // Initialize the camera ONLY the first time this
            // MyUniverseView appears.
            //
            // When returning from ChallengeJourneyView,
            // onAppear may run again, but the camera is NOT
            // reset because hasInitializedCamera is already true.
            // -------------------------------------------------

            if !hasInitializedCamera {
                hasInitializedCamera = true
                returnToCurrentGalaxy()
            }
        }
    }

    // MARK: - Universe Canvas

    @ViewBuilder
    private func universeCanvas(
        in size: CGSize
    ) -> some View {
        ZStack {
            // Transparent drag surface.
            //
            // This allows the whole universe to be dragged.
            // It does NOT have a tap action, so tapping empty
            // space cannot open the current challenge.

            Color.clear
                .contentShape(Rectangle())

            // MARK: Older Completed Galaxies

            ForEach(completedChallenges) { challenge in
                completedGalaxyView(
                    challenge: challenge,
                    in: size
                )
            }

            // MARK: Center Galaxy

            if let centerChallenge {
                currentGalaxyView(
                    challenge: centerChallenge,
                    in: size
                )
            }
        }
        .frame(
            width: size.width,
            height: size.height
        )

        // MARK: Camera

        .scaleEffect(
            zoom,
            anchor: .center
        )
        .offset(
            x: offset.width,
            y: offset.height
        )

        // -------------------------------------------------
        // Important:
        //
        // The universe remains draggable.
        // Galaxy-specific tap gestures are attached
        // directly to their visual circles.
        // -------------------------------------------------

        .contentShape(Rectangle())
        .simultaneousGesture(
            universeGestures
        )
        .animation(
            .easeInOut(duration: 0.45),
            value: zoom
        )
        .animation(
            .easeInOut(duration: 0.45),
            value: offset
        )
    }

    // MARK: - Center Galaxy

    @ViewBuilder
    private func currentGalaxyView(
        challenge: UniverseChallenge,
        in size: CGSize
    ) -> some View {
        let isActuallyCurrent = challenge.status == .active

        VStack(spacing: 7) {
            // MARK: Galaxy

            galaxyVisual(
                challenge: challenge,
                isCurrent: isActuallyCurrent,
                isCenter: true
            )
            .contentShape(Circle())
            .onTapGesture {
                // Only the actual galaxy circle
                // selects this challenge.

                selectedChallenge = challenge
            }

            // MARK: Title

            Text(challenge.title)
                .font(
                    .system(
                        size: 20,
                        weight: .medium
                    )
                )
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 180)

                // The title is visual only.
                // It cannot become a large tappable area.

                .allowsHitTesting(false)
        }

        // MARK: Center Position

        // The center galaxy is ALWAYS positioned
        // at the center of the My Universe content area.

        .position(
            x: size.width / 2,
            y: size.height / 2
        )
        .zIndex(100)
    }

    // MARK: - Completed Galaxy

    @ViewBuilder
    private func completedGalaxyView(
        challenge: UniverseChallenge,
        in size: CGSize
    ) -> some View {
        VStack(spacing: 7) {
            // MARK: Galaxy

            galaxyVisual(
                challenge: challenge,
                isCurrent: false,
                isCenter: false
            )
            .contentShape(Circle())
            .onTapGesture {
                // IMPORTANT:
                //
                // This selects THIS exact challenge.
                //
                // Therefore an older galaxy opens its own
                // ChallengeJourneyView instead of the current one.

                selectedChallenge = challenge
            }

            // MARK: Title

            Text(challenge.title)
                .font(
                    .system(
                        size: 12,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.42)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 130)

                // Visual only.

                .allowsHitTesting(false)
        }

        // MARK: Permanent Position

        // All completed galaxies use the SAME coordinate origin
        // as the center galaxy.
        //
        // universeX / universeY are persistent SwiftData values.
        // Therefore existing galaxies do not move.

        .position(
            x: size.width / 2 + CGFloat(challenge.universeX ?? 0),
            y: size.height / 2 + CGFloat(challenge.universeY ?? 0)
        )
        .zIndex(1)
    }

    // MARK: - Galaxy Visual

    @ViewBuilder
    private func galaxyVisual(
        challenge: UniverseChallenge,
        isCurrent: Bool,
        isCenter: Bool
    ) -> some View {
        ZStack {
            // MARK: Current Atmosphere

            // IMPORTANT:
            //
            // Glow is based on isCurrent,
            // NOT isCenter.
            //
            // Therefore a completed center galaxy
            // does NOT glow.

            if isCurrent {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.14),
                                .white.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 125
                        )
                    )
                    .frame(
                        width: 250,
                        height: 250
                    )
                    .blur(radius: 18)
                    .allowsHitTesting(false)

                Circle()
                    .stroke(
                        .white.opacity(0.10),
                        lineWidth: 1
                    )
                    .frame(
                        width: 205,
                        height: 205
                    )
                    .blur(radius: 1)
                    .allowsHitTesting(false)
            }

            // MARK: Galaxy

            GalaxyView(
                style: challenge.galaxy,
                progress: challenge.progress,
                isCurrent: isCurrent,
                isAnimated: isCurrent,
                revealProgress: challenge.progress
            )
            .frame(
                width: isCenter ? 190 : 125,
                height: isCenter ? 190 : 125
            )
            .allowsHitTesting(false)
        }

        // IMPORTANT:
        //
        // This frame defines the actual tappable galaxy area.
        //
        // The large 250pt glow does NOT become tappable.

        .frame(
            width: isCenter ? 190 : 125,
            height: isCenter ? 190 : 125
        )
    }

    // MARK: - Gestures

    private var universeGestures: some Gesture {
        SimultaneousGesture(
            dragGesture,
            magnificationGesture
        )
        .simultaneously(
            with: doubleTapGesture
        )
    }

    // MARK: - Drag

    private var dragGesture: some Gesture {
        DragGesture(
            minimumDistance: 8
        )
        .onChanged { value in
            offset = CGSize(
                width: accumulatedOffset.width + value.translation.width,
                height: accumulatedOffset.height + value.translation.height
            )
        }
        .onEnded { value in
            accumulatedOffset = CGSize(
                width: accumulatedOffset.width + value.translation.width,
                height: accumulatedOffset.height + value.translation.height
            )
            offset = accumulatedOffset
        }
    }

    // MARK: - Magnification

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let proposed = accumulatedZoom * value

                zoom = min(
                    max(
                        proposed,
                        minimumZoom
                    ),
                    maximumZoom
                )
            }
            .onEnded { _ in
                accumulatedZoom = zoom
            }
    }

    // MARK: - Double Tap

    private var doubleTapGesture: some Gesture {
        TapGesture(
            count: 2
        )
        .onEnded {
            returnToCurrentGalaxy()
        }
    }

    // MARK: - Return Home

    private func returnToCurrentGalaxy() {
        withAnimation(
            .spring(
                response: 0.55,
                dampingFraction: 0.82
            )
        ) {
            zoom = 1.0
            accumulatedZoom = 1.0
            offset = .zero
            accumulatedOffset = .zero
        }
    }

    // MARK: - Assign Positions

    private func assignMissingUniversePositions() {
        let missing = completedChallenges.filter {
            $0.universeX == nil ||
            $0.universeY == nil
        }

        guard !missing.isEmpty else {
            return
        }

        var occupied: [(Double, Double)] = []

        // MARK: Existing Permanent Positions

        for challenge in completedChallenges {
            if let x = challenge.universeX,
               let y = challenge.universeY {
                occupied.append((x, y))
            }
        }

        // MARK: Assign Only Missing Positions

        // Existing galaxies NEVER receive a new position.

        for challenge in missing {
            let position = generatePosition(
                avoiding: occupied
            )

            challenge.universeX = Double(position.x)
            challenge.universeY = Double(position.y)

            occupied.append(
                (
                    Double(position.x),
                    Double(position.y)
                )
            )
        }

        saveChanges()
    }

    // MARK: - Random Position

    private func generatePosition(
        avoiding occupied: [(Double, Double)]
    ) -> CGPoint {
        for _ in 0..<500 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let radius = CGFloat.random(
                in: minimumDistanceFromCenter...maximumDistanceFromCenter
            )
            let x = cos(angle) * radius
            let y = sin(angle) * radius

            let isFarEnough = occupied.allSatisfy {
                existingX,
                existingY in
                let dx = x - CGFloat(existingX)
                let dy = y - CGFloat(existingY)
                let distance = sqrt(dx * dx + dy * dy)

                return distance >= minimumGalaxyDistance
            }

            if isFarEnough {
                return CGPoint(
                    x: x,
                    y: y
                )
            }
        }

        // MARK: Fallback

        let angle = CGFloat.random(in: 0...(2 * .pi))

        return CGPoint(
            x: cos(angle) * maximumDistanceFromCenter,
            y: sin(angle) * maximumDistanceFromCenter
        )
    }

    // MARK: - Save

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save universe positions: \(error)")
        }
    }

    // MARK: - Empty Universe

    private func emptyUniverseView(
        in size: CGSize
    ) -> some View {
        VStack(spacing: 20) {
            Text("Your universe is waiting.")
                .font(.title2)
                .foregroundStyle(.white)

            Text("Begin something small.\nLet it become part of your universe.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .position(
            x: size.width / 2,
            y: size.height / 2
        )
    }
}
