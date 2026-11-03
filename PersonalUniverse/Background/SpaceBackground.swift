//
//  SpaceBackground.swift
//  PersonalUniverse
//
//  Created by Minjae Son on 8/7/26.
//

import SwiftUI

struct SpaceBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var isVisible = false
    private var animateBackground: Bool { isVisible && !reduceMotion && scenePhase == .active }

    // 무작위 별의 위치는 View 갱신 중에도 유지합니다.
    @State private var stars: [BackgroundStar] = {
        (0..<70).map { _ in
            BackgroundStar()
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animateBackground)) { timeline in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                for star in stars {
                    let rect = CGRect(x: star.x * size.width - star.size / 2,
                                      y: star.y * size.height - star.size / 2,
                                      width: star.size, height: star.size)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(star.twinkle(at: timeline.date))))
                }
            }
        }

        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .allowsHitTesting(false)
        .accessibilityHidden(true)

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
