//
//  GalaxyModel.swift
//  PersonalUniverse
//

import SwiftUI

struct GalaxyPoint {
    
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
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
