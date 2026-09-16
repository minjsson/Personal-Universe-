//
//  GalaxyView.swift
//  PersonalUniverse
//

import SwiftUI

struct GalaxyView: View {
    let style: GalaxyStyle
    let progress: Double
    let isCurrent: Bool
    let isAnimated: Bool

    /// nil = complete galaxy
    /// 0...1 = progressive reveal
    let revealProgress: Double?

    /// The logical design size of the galaxy.
    /// The actual rendered galaxy scales to its available container.
    private let designSize: CGFloat = 270

    init(
        style: GalaxyStyle,
        progress: Double,
        isCurrent: Bool,
        isAnimated: Bool,
        revealProgress: Double? = nil
    ) {
        self.style = style
        self.progress = progress
        self.isCurrent = isCurrent
        self.isAnimated = isAnimated
        self.revealProgress = revealProgress
    }

    // MARK: - Progress

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var clampedRevealProgress: Double {
        min(max(revealProgress ?? 1, 0), 1)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width, geometry.size.height)
            let scale = availableSize / designSize

            galaxyContent
                .frame(width: designSize, height: designSize)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Galaxy Content

    private var galaxyContent: some View {
        ZStack {
            atmosphere

            // MARK: Background Dust

            ForEach(galaxyDust.indices, id: \.self) { index in
                let star = galaxyDust[index]

                Circle()
                    .fill(.white.opacity(star.opacity * revealOpacity(for: star.revealAt)))
                    .frame(width: star.size, height: star.size)
                    .position(galaxyPosition(x: star.x, y: star.y))
            }

            // MARK: Main Stars

            ForEach(galaxyStars.indices, id: \.self) { index in
                let star = galaxyStars[index]

                TwinklingGalaxyStar(
                    star: star,
                    isCurrent: isCurrent,
                    delay: Double(index) * 0.035,
                    isAnimated: isAnimated
                )
                .opacity(revealOpacity(for: star.revealAt))
                .scaleEffect(revealScale(for: star.revealAt))
                .position(galaxyPosition(x: star.x, y: star.y))
            }

            // MARK: Special Celestial Bodies

            ForEach(galaxyBodies.indices, id: \.self) { index in
                let body = galaxyBodies[index]

                GalaxyBodyView(
                    galaxyBody: body,
                    isCurrent: isCurrent,
                    isAnimated: isAnimated
                )
                .opacity(revealOpacity(for: body.revealAt))
                .scaleEffect(revealScale(for: body.revealAt))
                .position(galaxyPosition(x: body.x, y: body.y))
            }
        }
        .frame(width: designSize, height: designSize)
        .clipped()
    }

    // MARK: - Atmosphere

    private var atmosphere: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(isCurrent ? 0.09 : 0.035),
                        .white.opacity(0.015),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: atmosphereRadius
                )
            )
            .frame(width: atmosphereRadius * 2, height: atmosphereRadius * 2)
            .blur(radius: atmosphereBlur)
    }

    private var atmosphereRadius: CGFloat {
        switch style {
        case .expanding:
            return 130
        case .cluster:
            return 105
        case .spiral:
            return 145
        }
    }

    private var atmosphereBlur: CGFloat {
        switch style {
        case .expanding:
            return 28
        case .cluster:
            return 26
        case .spiral:
            return 30
        }
    }

    // MARK: - Reveal

    private func revealOpacity(for threshold: Double) -> Double {
        guard revealProgress != nil else {
            return 1
        }

        return clampedRevealProgress >= threshold ? 1 : 0
    }

    private func revealScale(for threshold: Double) -> CGFloat {
        guard revealProgress != nil else {
            return 1
        }

        return clampedRevealProgress >= threshold ? 1 : 0.15
    }

    // MARK: - Spread

    private var galaxySpread: CGFloat {
        switch style {
        case .expanding:
            return 0.82 + CGFloat(clampedProgress) * 0.58
        case .cluster:
            return 0.84 + CGFloat(clampedProgress) * 0.24
        case .spiral:
            return 0.88 + CGFloat(clampedProgress) * 0.55
        }
    }

    // MARK: - Position

    private func galaxyPosition(x: CGFloat, y: CGFloat) -> CGPoint {
        let centerX: CGFloat
        let centerY: CGFloat

        switch style {
        case .expanding, .cluster:
            centerX = 100
            centerY = 100
        case .spiral:
            centerX = 88
            centerY = 96
        }

        return CGPoint(
            x: designSize / 2 + (x - centerX) * galaxySpread,
            y: designSize / 2 + (y - centerY) * galaxySpread
        )
    }

    // MARK: - Main Stars

    private var galaxyStars: [GalaxyStar] {
        switch style {
        case .expanding:
            return generateExpandingGalaxy()
        case .cluster:
            return generateClusterGalaxy()
        case .spiral:
            return generateSpiralGalaxy()
        }
    }

    // MARK: - Expanding Galaxy

    private func generateExpandingGalaxy() -> [GalaxyStar] {
        var generator = SeededRandomNumberGenerator(seed: 3817)
        var stars: [GalaxyStar] = []

        // MARK: Central Core

        stars.append(
            GalaxyStar(
                x: 100,
                y: 100,
                size: 5.4,
                opacity: 1,
                revealAt: 0
            )
        )

        stars.append(
            GalaxyStar(
                x: 106,
                y: 102,
                size: 3.8,
                opacity: 0.82,
                revealAt: 0.02
            )
        )

        stars.append(
            GalaxyStar(
                x: 94,
                y: 104,
                size: 3.2,
                opacity: 0.74,
                revealAt: 0.04
            )
        )

        // MARK: Gradual Outward Expansion

        let layers: [(count: Int, minRadius: Double, maxRadius: Double)] = [
            (10, 8, 22),
            (10, 18, 36),
            (10, 30, 52),
            (8, 46, 70)
        ]

        for (layerIndex, layer) in layers.enumerated() {
            for _ in 0..<layer.count {
                let angle = Double.random(in: 0...(Double.pi * 2), using: &generator)
                let distance = Double.random(in: layer.minRadius...layer.maxRadius, using: &generator)
                let angleOffset = Double.random(in: -0.12...0.12, using: &generator)
                let finalAngle = angle + angleOffset
                let x = 100 + CGFloat(cos(finalAngle) * distance)
                let y = 100 + CGFloat(sin(finalAngle) * distance)
                let normalizedDistance = (distance - 8) / 62
                let reveal = min(
                    max(
                        normalizedDistance + Double.random(in: -0.04...0.04, using: &generator),
                        0.03
                    ),
                    0.98
                )

                let sizeRange: ClosedRange<CGFloat>
                switch layerIndex {
                case 0:
                    sizeRange = 2.8...4.6
                case 1:
                    sizeRange = 2.3...4.2
                case 2:
                    sizeRange = 1.9...3.8
                default:
                    sizeRange = 1.6...3.4
                }

                stars.append(
                    GalaxyStar(
                        x: x,
                        y: y,
                        size: CGFloat.random(in: sizeRange, using: &generator),
                        opacity: Double.random(in: 0.32...0.82, using: &generator),
                        revealAt: reveal
                    )
                )
            }
        }

        // MARK: Loose Outer Stars

        let outerStars: [(angle: Double, distance: ClosedRange<Double>)] = [
            (0.35, 66...82),
            (0.82, 64...78),
            (1.65, 70...86),
            (2.35, 65...80),
            (3.05, 68...84),
            (4.15, 64...82),
            (4.85, 72...88),
            (5.55, 66...80)
        ]

        for outer in outerStars {
            let angle = outer.angle + Double.random(in: -0.18...0.18, using: &generator)
            let distance = Double.random(in: outer.distance, using: &generator)
            let x = 100 + CGFloat(cos(angle) * distance)
            let y = 100 + CGFloat(sin(angle) * distance)

            stars.append(
                GalaxyStar(
                    x: x,
                    y: y,
                    size: CGFloat.random(in: 1.3...2.8, using: &generator),
                    opacity: Double.random(in: 0.22...0.58, using: &generator),
                    revealAt: Double.random(in: 0.82...0.98, using: &generator)
                )
            )
        }

        // MARK: A Few Very Distant Stars

        for _ in 0..<4 {
            let angle = Double.random(in: 0...(Double.pi * 2), using: &generator)
            let distance = Double.random(in: 80...92, using: &generator)
            let x = 100 + CGFloat(cos(angle) * distance)
            let y = 100 + CGFloat(sin(angle) * distance)

            stars.append(
                GalaxyStar(
                    x: x,
                    y: y,
                    size: CGFloat.random(in: 0.9...1.8, using: &generator),
                    opacity: Double.random(in: 0.16...0.38, using: &generator),
                    revealAt: Double.random(in: 0.92...1.0, using: &generator)
                )
            )
        }

        return stars
    }

    // MARK: - Cluster Galaxy

    private func generateClusterGalaxy() -> [GalaxyStar] {
        var generator = SeededRandomNumberGenerator(seed: 7241)
        var stars: [GalaxyStar] = []

        // Bright but slightly irregular center

        stars.append(
            GalaxyStar(
                x: 100,
                y: 100,
                size: 6.2,
                opacity: 1,
                revealAt: 0
            )
        )

        stars.append(
            GalaxyStar(
                x: 105,
                y: 98,
                size: 4.5,
                opacity: 0.94,
                revealAt: 0.02
            )
        )

        stars.append(
            GalaxyStar(
                x: 95,
                y: 103,
                size: 4.2,
                opacity: 0.88,
                revealAt: 0.03
            )
        )

        // Dense central population

        for _ in 0..<38 {
            let angle = Double.random(in: 0...(Double.pi * 2), using: &generator)
            let randomValue = Double.random(in: 0...1, using: &generator)
            let distance = pow(randomValue, 1.65) * 38
            let horizontalStretch = Double.random(in: 0.86...1.10, using: &generator)
            let verticalStretch = Double.random(in: 0.82...1.08, using: &generator)
            let centerOffsetX = Double.random(in: -2.5...2.5, using: &generator)
            let centerOffsetY = Double.random(in: -2.0...2.0, using: &generator)
            let x = 100 + centerOffsetX + cos(angle) * distance * horizontalStretch
            let y = 100 + centerOffsetY + sin(angle) * distance * verticalStretch
            let reveal = min(
                max(
                    (distance / 38) + Double.random(in: -0.05...0.05, using: &generator),
                    0.035
                ),
                0.90
            )

            stars.append(
                GalaxyStar(
                    x: CGFloat(x),
                    y: CGFloat(y),
                    size: CGFloat.random(in: 1.8...4.2, using: &generator),
                    opacity: Double.random(in: 0.34...0.86, using: &generator),
                    revealAt: reveal
                )
            )
        }

        // Loose outer stars

        for _ in 0..<12 {
            let angle = Double.random(in: 0...(Double.pi * 2), using: &generator)
            let distance = Double.random(in: 28...54, using: &generator)
            let x = 100 + cos(angle) * distance * Double.random(in: 0.82...1.12, using: &generator)
            let y = 100 + sin(angle) * distance * Double.random(in: 0.78...1.08, using: &generator)
            let reveal = min(
                max(
                    distance / 54 + Double.random(in: -0.05...0.05, using: &generator),
                    0.38
                ),
                0.98
            )

            stars.append(
                GalaxyStar(
                    x: CGFloat(x),
                    y: CGFloat(y),
                    size: CGFloat.random(in: 1.5...3.4, using: &generator),
                    opacity: Double.random(in: 0.25...0.62, using: &generator),
                    revealAt: reveal
                )
            )
        }

        // A few slightly brighter members

        stars.append(
            GalaxyStar(
                x: 117,
                y: 92,
                size: 3.8,
                opacity: 0.72,
                revealAt: 0.28
            )
        )

        stars.append(
            GalaxyStar(
                x: 84,
                y: 108,
                size: 3.4,
                opacity: 0.66,
                revealAt: 0.34
            )
        )

        stars.append(
            GalaxyStar(
                x: 108,
                y: 120,
                size: 3.1,
                opacity: 0.58,
                revealAt: 0.48
            )
        )

        return stars
    }

    // MARK: - Spiral Galaxy

    private func generateSpiralGalaxy() -> [GalaxyStar] {
        var generator = SeededRandomNumberGenerator(seed: 9513)
        var stars: [GalaxyStar] = []

        // Bright center

        stars.append(
            GalaxyStar(
                x: 100,
                y: 100,
                size: 5.8,
                opacity: 1,
                revealAt: 0
            )
        )

        stars.append(
            GalaxyStar(
                x: 106,
                y: 98,
                size: 4,
                opacity: 0.86,
                revealAt: 0.02
            )
        )

        // MARK: Two Loose Spiral Arms

        for arm in 0..<2 {
            for i in 0..<23 {
                let armProgress = Double(i) / 22
                let baseAngle = armProgress * Double.pi * 2.0
                let armOffset = arm == 0 ? 0 : Double.pi
                let angle = baseAngle + armOffset + Double.random(in: -0.20...0.20, using: &generator)
                let distance = 8 + armProgress * 76 + Double.random(in: -5...5, using: &generator)
                let x = 100 + CGFloat(cos(angle) * distance)
                let y = 100 + CGFloat(sin(angle) * distance * 0.72)
                let normalizedDistance = min(max((distance - 8) / 76, 0), 1)
                let reveal = min(
                    max(
                        normalizedDistance + Double.random(in: -0.06...0.06, using: &generator),
                        0.04
                    ),
                    0.98
                )

                stars.append(
                    GalaxyStar(
                        x: x,
                        y: y,
                        size: CGFloat.random(in: 1.9...4.2, using: &generator),
                        opacity: Double.random(in: 0.32...0.88, using: &generator),
                        revealAt: reveal
                    )
                )
            }
        }

        // MARK: Additional Random Stars

        for _ in 0..<14 {
            let angle = Double.random(in: 0...(Double.pi * 2), using: &generator)
            let distance = Double.random(in: 12...82, using: &generator)
            let x = 100 + CGFloat(cos(angle) * distance)
            let y = 100 + CGFloat(sin(angle) * distance * 0.72)
            let normalizedDistance = min(max((distance - 12) / 70, 0), 1)
            let reveal = min(
                max(
                    normalizedDistance + Double.random(in: -0.06...0.06, using: &generator),
                    0.04
                ),
                0.98
            )

            stars.append(
                GalaxyStar(
                    x: x,
                    y: y,
                    size: CGFloat.random(in: 1.8...3.6, using: &generator),
                    opacity: Double.random(in: 0.28...0.68, using: &generator),
                    revealAt: reveal
                )
            )
        }

        return stars
    }

    // MARK: - Dust

    private var galaxyDust: [GalaxyStar] {
        let count: Int
        let radius: Double

        switch style {
        case .expanding:
            count = 55
            radius = 86
        case .cluster:
            count = 48
            radius = 62
        case .spiral:
            count = 68
            radius = 92
        }

        var generator = SeededRandomNumberGenerator(seed: 9137 + UInt64(styleIndex))
        var result: [GalaxyStar] = []

        for _ in 0..<count {
            let angle = Double.random(in: 0...(Double.pi * 2), using: &generator)
            let distance = Double.random(in: 15...radius, using: &generator)
            let x = 100 + CGFloat(cos(angle) * distance)
            let y = 100 + CGFloat(sin(angle) * distance)

            result.append(
                GalaxyStar(
                    x: x,
                    y: y,
                    size: CGFloat.random(in: 0.45...0.9, using: &generator),
                    opacity: Double.random(in: 0.06...0.16, using: &generator),
                    revealAt: min(
                        max(
                            distance / radius + Double.random(in: -0.10...0.10, using: &generator),
                            0
                        ),
                        0.98
                    )
                )
            )
        }

        return result
    }

    private var styleIndex: Int {
        switch style {
        case .expanding:
            return 1
        case .cluster:
            return 2
        case .spiral:
            return 3
        }
    }

    // MARK: - Celestial Bodies

    private var galaxyBodies: [GalaxyBody] {
        switch style {
        case .expanding:
            return [
                GalaxyBody(
                    x: 60,
                    y: 77,
                    size: 3.8,
                    type: .orbiting,
                    duration: 14,
                    startingAngle: 25,
                    revealAt: 0.28
                ),
                GalaxyBody(
                    x: 146,
                    y: 67,
                    size: 3.2,
                    type: .twinkling,
                    duration: 0,
                    startingAngle: 0,
                    revealAt: 0.48
                ),
                GalaxyBody(
                    x: 158,
                    y: 126,
                    size: 3.8,
                    type: .orbiting,
                    duration: 18,
                    startingAngle: 155,
                    revealAt: 0.68
                )
            ]

        case .cluster:
            return [
                GalaxyBody(
                    x: 82,
                    y: 85,
                    size: 4.2,
                    type: .twinkling,
                    duration: 0,
                    startingAngle: 0,
                    revealAt: 0.30
                ),
                GalaxyBody(
                    x: 123,
                    y: 96,
                    size: 3.4,
                    type: .orbiting,
                    duration: 10,
                    startingAngle: 60,
                    revealAt: 0.48
                ),
                GalaxyBody(
                    x: 74,
                    y: 119,
                    size: 3.5,
                    type: .orbiting,
                    duration: 12,
                    startingAngle: 205,
                    revealAt: 0.64
                )
            ]

        case .spiral:
            return [
                GalaxyBody(
                    x: 117,
                    y: 83,
                    size: 4.0,
                    type: .twinkling,
                    duration: 0,
                    startingAngle: 0,
                    revealAt: 0.20
                ),
                GalaxyBody(
                    x: 151,
                    y: 69,
                    size: 3.4,
                    type: .orbiting,
                    duration: 11,
                    startingAngle: 40,
                    revealAt: 0.38
                ),
                GalaxyBody(
                    x: 147,
                    y: 138,
                    size: 3.8,
                    type: .orbiting,
                    duration: 15,
                    startingAngle: 210,
                    revealAt: 0.58
                ),
                GalaxyBody(
                    x: 58,
                    y: 137,
                    size: 3.3,
                    type: .orbiting,
                    duration: 18,
                    startingAngle: 120,
                    revealAt: 0.78
                )
            ]
        }
    }
}

// MARK: - Deterministic Random Generator

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Preview

#Preview("Galaxy Styles") {
    ZStack {
        ScrollView {
            VStack(spacing: 80) {
                ForEach(GalaxyStyle.allCases, id: \.self) { style in
                    VStack(spacing: 20) {
                        Text(style.name)
                            .font(.headline)
                            .foregroundStyle(.white)

                        GalaxyView(
                            style: style,
                            progress: 0.75,
                            isCurrent: true,
                            isAnimated: true
                        )
                        .frame(width: 270, height: 270)
                    }
                }
            }
            .padding(.vertical, 60)
        }
    }
}
