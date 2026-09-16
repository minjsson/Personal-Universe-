//
//  WidgetDeepLink.swift
//  PersonalUniverse
//

import Foundation

enum WidgetDeepLink {
    static let scheme = "personaluniverse"
    static let myUniverse = URL(string: "\(scheme)://my-universe")!
    static let createChallenge = URL(string: "\(scheme)://create-challenge")!

    static func url(hasActiveChallenge: Bool) -> URL {
        hasActiveChallenge ? myUniverse : createChallenge
    }
}
