//
//  GalaxyStyle.swift
//  PersonalUniverse
//

import SwiftUI

enum GalaxyStyle: String, Codable, CaseIterable {
    case expanding
    case cluster
    case spiral

    var name: String {
        switch self {
        case .expanding:
            return "Expanding"
        case .cluster:
            return "Cluster"
        case .spiral:
            return "Spiral"
        }
    }
}
