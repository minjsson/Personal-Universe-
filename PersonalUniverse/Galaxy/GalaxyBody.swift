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
    
}
