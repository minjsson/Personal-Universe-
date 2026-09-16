//
//  ChallengeDay.swift
//  PersonalUniverse
//

import Foundation
import SwiftData

@Model
final class ChallengeDay {
    // MARK: - Identity

    var dayNumber: Int

    // MARK: - State

    private var statusRawValue: String
    var reflection: String
    var completedAt: Date?

    // MARK: - Relationship

    var challenge: UniverseChallenge?

    // MARK: - Status

    var status: DayStatus {
        get {
            DayStatus(rawValue: statusRawValue) ?? .upcoming
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }

    // MARK: - Reflection

    var hasReflection: Bool {
        !reflection
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // MARK: - Convenience

    var isCompleted: Bool {
        status == .completed
    }

    var isMissed: Bool {
        status == .missed
    }

    var isUpcoming: Bool {
        status == .upcoming
    }

    // MARK: - Init

    init(
        dayNumber: Int,
        status: DayStatus = .upcoming,
        reflection: String = ""
    ) {
        self.dayNumber = dayNumber
        self.statusRawValue = status.rawValue
        self.reflection = reflection
        self.completedAt = nil
        self.challenge = nil
    }

    // MARK: - Completion

    func complete(at date: Date = .now) {
        guard status == .upcoming else {
            return
        }
        status = .completed
        completedAt = date
    }

    // MARK: - Missed

    func markAsMissed() {
        guard status == .upcoming else {
            return
        }
        status = .missed
    }
}
