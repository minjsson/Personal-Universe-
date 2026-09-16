//
//  UniverseProgress.swift
//  PersonalUniverse
//

import Foundation

struct UniverseProgress {
    let completedDays: Int
    let totalDays: Int

    var value: Double {
        guard totalDays > 0 else {
            return 0
        }

        return min(
            max(Double(completedDays) / Double(totalDays), 0),
            1
        )
    }

    var isComplete: Bool {
        value >= 1
    }
}
