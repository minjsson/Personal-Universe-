//
//  GalaxyComponents.swift
//  PersonalUniverse
//
//  Created by Minjae Son on 8/16/26.
//

import SwiftUI

struct GalaxyOrbitModifier: ViewModifier {
    let galaxyBody: GalaxyBody
    let index: Int
    let isAnimated: Bool
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(
                .degrees(galaxyBody.type == .orbiting ? rotation : 0)
            )
            .onAppear {
                guard isAnimated else { return }
                guard galaxyBody.type == .orbiting else { return }
                withAnimation(
                    .linear(duration: galaxyBody.duration)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}
