//
//  GalaxyStar.swift
//  PersonalUniverse
//

import SwiftUI

struct GalaxyStar {
    
    let x: CGFloat
    let y: CGFloat
    
    /// Visual diameter.
    let size: CGFloat
    
    /// Base opacity.
    let opacity: Double
    
    /// Progress at which this star appears
    /// during a growth/completion animation.
    let revealAt: Double
    
    init(
        x: CGFloat,
        y: CGFloat,
        size: CGFloat,
        opacity: Double,
        revealAt: Double = 0
    ) {
        self.x = x
        self.y = y
        self.size = size
        self.opacity = opacity
        self.revealAt = revealAt
    }
}
