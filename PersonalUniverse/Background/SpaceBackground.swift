//
//  SpaceBackground.swift
//  PersonalUniverse
//
//  Created by Minjae Son on 8/7/26.
//

import SwiftUI

struct SpaceBackground: View {
    // IMPORTANT:
    // @State keeps the randomly generated stars stable.
    @State private var stars: [BackgroundStar] = {
        (0..<70).map { _ in
            BackgroundStar()
        }
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    ForEach(stars) { star in
                        Circle()
                            .fill(.white)
                            .frame(
                                width: star.size,
                                height: star.size
                            )
                            .position(
                                x: star.x * geometry.size.width,
                                y: star.y * geometry.size.height
                            )
                            .opacity(
                                star.twinkle(
                                    at: timeline.date
                                )
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Background Star

struct BackgroundStar: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let brightness: Double
    let twinkleDuration: Double
    let twinkleDelay: Double

    init() {
        x = CGFloat.random(in: 0.02...0.98)
        y = CGFloat.random(in: 0.02...0.98)
        size = CGFloat.random(in: 0.8...4.0)
        brightness = Double.random(in: 0.3...0.9)
        twinkleDuration = Double.random(in: 2.0...8.0)
        twinkleDelay = Double.random(in: 0...3.0)
    }

    func twinkle(at date: Date) -> Double {
        let time = date.timeIntervalSinceReferenceDate
        let phase = (time + twinkleDelay) / twinkleDuration * 2 * .pi
        let wave = (sin(phase) + 1) / 2
        return brightness * (0.4 + wave * 0.6)
    }
}

#Preview {
    SpaceBackground()
}
