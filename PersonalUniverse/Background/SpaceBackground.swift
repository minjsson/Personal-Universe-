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
    @State private var ambientEvent: AmbientSpaceEvent?

    private var animateBackground: Bool { !reduceMotion && scenePhase == .active }

    // 무작위 별의 위치는 View 갱신 중에도 유지합니다.
    @State private var stars: [BackgroundStar] = {
        (0..<70).map { _ in
            BackgroundStar()
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animateBackground)) { timeline in
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
                    if let ambientEvent, animateBackground {
                        AmbientSpaceEventView(event: ambientEvent, date: timeline.date)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: animateBackground) {
            ambientEvent = nil
            guard animateBackground else { return }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(Double.random(in: 12...26)))
                    guard !Task.isCancelled else { return }
                    ambientEvent = AmbientSpaceEvent(kind: AmbientSpaceEvent.Kind.allCases.randomElement() ?? .meteor)
                    try await Task.sleep(for: .seconds(6))
                    ambientEvent = nil
                }
            } catch {
                ambientEvent = nil
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
