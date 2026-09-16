//
//  GalaxyBody.swift
//  PersonalUniverse
//

import SwiftUI

enum GalaxyBodyType {
    case orbiting
    case twinkling
}

struct GalaxyBody {
    
    let x: CGFloat
    let y: CGFloat
    
    let size: CGFloat
    let type: GalaxyBodyType
    
    let duration: Double
    let startingAngle: Double
    
    let revealAt: Double
    
    init(
        x: CGFloat,
        y: CGFloat,
        size: CGFloat,
        type: GalaxyBodyType,
        duration: Double,
        startingAngle: Double,
        revealAt: Double = 0
    ) {
        self.x = x
        self.y = y
        self.size = size
        self.type = type
        self.duration = duration
        self.startingAngle = startingAngle
        self.revealAt = revealAt
    }
}
