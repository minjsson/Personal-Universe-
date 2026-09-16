//
//  GalaxyBodyView.swift
//  PersonalUniverse
//

import SwiftUI

struct GalaxyBodyView: View {
    let galaxyBody: GalaxyBody
    let isCurrent: Bool
    let isAnimated: Bool
    @State private var twinkle = false
    @State private var orbitAngle: Double

    init(galaxyBody: GalaxyBody, isCurrent: Bool, isAnimated: Bool) {
        self.galaxyBody = galaxyBody
        self.isCurrent = isCurrent
        self.isAnimated = isAnimated
        _orbitAngle = State(initialValue: galaxyBody.startingAngle)
    }

    var body: some View {
        
        ZStack {
            if galaxyBody.type == .orbiting {
                Circle()
                    .stroke(.white.opacity(isCurrent ? 0.10 : 0.05), lineWidth: 0.7)
                    .frame(width: galaxyBody.size * 7, height: galaxyBody.size * 3.2)
                    .rotationEffect(.degrees(galaxyBody.startingAngle))

                Circle()
                    .fill(.white)
                    .frame(width: galaxyBody.size, height: galaxyBody.size)
                    .shadow(color: .white.opacity(0.35), radius: galaxyBody.size)
                    .offset(x: galaxyBody.size * 3.5)
                    .rotationEffect(.degrees(orbitAngle))
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: galaxyBody.size, height: galaxyBody.size)
                    .opacity(twinkle ? 0.45 : 0.95)
                    .shadow(color: .white.opacity(0.3), radius: galaxyBody.size)
                    .scaleEffect(twinkle ? 0.8 : 1)
            }
        }
        .onAppear {
            guard isAnimated else { return }
            switch galaxyBody.type {
            case .orbiting:
                withAnimation(
                    .linear(duration: galaxyBody.duration)
                        .repeatForever(autoreverses: false)
                ) {
                    orbitAngle += 360
                }
            case .twinkling:
                withAnimation(
                    .easeInOut(duration: 1.7)
                        .repeatForever(autoreverses: true)
                ) {
                    twinkle = true
                }
            }
        }
    }
}
