//
//  TwinklingGalaxyStar.swift
//  PersonalUniverse
//

import SwiftUI

struct TwinklingGalaxyStar: View {
    let star: GalaxyStar
    let isCurrent: Bool
    let delay: Double
    let isAnimated: Bool
    @State private var twinkle = false

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: star.size, height: star.size)
            .opacity(star.opacity * (twinkle ? 0.55 : 1.0))
            .shadow(color: .white.opacity(isCurrent ? 0.30 : 0.15), radius: star.size * 1.4)
            .scaleEffect(twinkle ? 0.82 : 1.0)
            .onAppear {
                guard isAnimated else { return }
                withAnimation(
                    .easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    twinkle = true
                }
            }
    }
}
