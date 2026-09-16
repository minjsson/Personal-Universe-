//
//  UniverseChallenge.swift
//  PersonalUniverse
//

import Foundation
import SwiftData

// MARK: - Challenge Length

enum ChallengeLength: Int, Codable, CaseIterable {
    case seven = 7
    case fourteen = 14
    case thirty = 30
    case fifty = 50
    case oneHundred = 100

    var days: Int {
        rawValue
    }
}

// MARK: - Challenge Status

enum ChallengeStatus: String, Codable {
    case active
    case completed
    case missed
}

// MARK: - Universe Challenge

@Model
final class UniverseChallenge {
    // MARK: - Identity

    var id: UUID = UUID()
    var title: String
    var startDate: Date

    // MARK: - Configuration

    private var lengthRawValue: Int

    // MARK: - State

    private var statusRawValue: String

    // MARK: - Galaxy

    var galaxyRawValue: String

    // MARK: - Notification

    /// Whether daily reminders are enabled for this challenge.
    var reminderEnabled: Bool

    /// Hour of the day when the daily reminder should fire.
    ///
    /// 0 = 12:00 AM
    /// 23 = 11:00 PM
    var reminderHour: Int

    /// Minute of the hour when the daily reminder should fire.
    var reminderMinute: Int

    // MARK: - Universe Position

    /// Persistent position inside My Universe.
    ///
    /// nil means the challenge has not received
    /// a completed-galaxy position yet.
    ///
    /// The current challenge does not use this
    /// position while it is active.
    var universeX: Double?
    var universeY: Double?

    // MARK: - Relationship

    @Relationship(
        deleteRule: .cascade,
        inverse: \ChallengeDay.challenge
    )
    var days: [ChallengeDay] = []

    // MARK: - Length

    var length: ChallengeLength {
        get {
            ChallengeLength(rawValue: lengthRawValue) ?? .seven
        }
        set {
            lengthRawValue = newValue.rawValue
        }
    }

    // MARK: - Status

    var status: ChallengeStatus {
        get {
            ChallengeStatus(rawValue: statusRawValue) ?? .active
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }

    // MARK: - Galaxy

    var galaxy: GalaxyStyle {
        get {
            GalaxyStyle(rawValue: galaxyRawValue) ?? .expanding
        }
        set {
            galaxyRawValue = newValue.rawValue
        }
    }

    // MARK: - Ordered Days

    var orderedDays: [ChallengeDay] {
        days.sorted {
            $0.dayNumber < $1.dayNumber
        }
    }

    // MARK: - Progress

    var completedDayCount: Int {
        days.filter {
            $0.status == .completed
        }.count
    }

    var missedDayCount: Int {
        days.filter {
            $0.status == .missed
        }.count
    }

    var upcomingDayCount: Int {
        days.filter {
            $0.status == .upcoming
        }.count
    }

    var progress: Double {
        guard !days.isEmpty else {
            return 0
        }
        return Double(completedDayCount) / Double(days.count)
    }

    // MARK: - Completion

    var isCompleted: Bool {
        !days.isEmpty && completedDayCount == days.count
    }

    // MARK: - Current Day

    /// The challenge day corresponding to today's calendar date.
    ///
    /// The current day changes only when the calendar date changes
    /// at 12:00 AM.
    ///
    /// Completing today's day does NOT advance currentDay.
    /// The completed day remains the current day until midnight.
    var currentDay: ChallengeDay? {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        return orderedDays.first { day in
            guard let dayDate = date(for: day, calendar: calendar) else {
                return false
            }
            return calendar.startOfDay(for: dayDate) == today
        }
    }

    // MARK: - Today

    /// The challenge day corresponding to the current calendar date.
    ///
    /// The app day changes at 12:00 AM.
    ///
    /// This does not change stored state.
    var today: ChallengeDay? {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)
        return orderedDays.first {
            guard let dayDate = date(for: $0, calendar: calendar) else {
                return false
            }
            return calendar.startOfDay(for: dayDate) == today
        }
    }

    // MARK: - Init

    init(
        title: String,
        length: ChallengeLength,
        startDate: Date = Calendar.current.startOfDay(for: .now),
        galaxy: GalaxyStyle = .expanding,
        reminderEnabled: Bool = false,
        reminderHour: Int = Calendar.current.component(.hour, from: .now),
        reminderMinute: Int = Calendar.current.component(.minute, from: .now)
    ) {
        self.title = title
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.lengthRawValue = length.rawValue
        self.statusRawValue = ChallengeStatus.active.rawValue
        self.galaxyRawValue = galaxy.rawValue
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.universeX = nil
        self.universeY = nil
        self.days = (1...length.days).map {
            ChallengeDay(dayNumber: $0)
        }
        
        for day in self.days {
            day.challenge = self
        }
    }

    // MARK: - Automatic State Update

    /// Updates days that are now in the past.
    ///
    /// Rule:
    /// - completed → never changes
    /// - missed → never changes
    /// - upcoming + date before today → missed
    /// - today's upcoming day → remains upcoming
    /// - future upcoming days → remain upcoming
    func updateMissedDays(calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: .now)

        for day in orderedDays {
            guard day.status == .upcoming else {
                continue
            }
            guard let dayDate = date(for: day, calendar: calendar) else {
                continue
            }
            let dayStart = calendar.startOfDay(for: dayDate)

            if dayStart < today {
                day.markAsMissed()
            }
        }
        updateCompletionStatus()
    }

    // MARK: - Day Date

    func date(
        for day: ChallengeDay,
        calendar: Calendar = .current
    ) -> Date? {
        guard day.dayNumber >= 1 else {
            return nil
        }
        return calendar.date(
            byAdding: .day,
            value: day.dayNumber - 1,
            to: calendar.startOfDay(for: startDate)
        )
    }

    // MARK: - Completion Status

    func updateCompletionStatus() {
        guard !days.isEmpty else {
            status = .active
            return
        }
        if completedDayCount == days.count {
            status = .completed
            return
        }
        if days.allSatisfy({
            $0.status == .completed || $0.status == .missed
        }) {
            status = .missed
            return
        }
        status = .active
    }

    // MARK: - Complete Day

    func completeDay(
        _ day: ChallengeDay,
        at date: Date = .now
    ) {
        guard day.challenge === self else {
            return
        }
        guard day.status == .upcoming else {
            return
        }
        day.complete(at: date)
        updateCompletionStatus()
    }
}
