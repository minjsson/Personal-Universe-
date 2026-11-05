//
//  WidgetUniverseData.swift
//  PersonalUniverseWidget
//

import Foundation

// MARK: - Day State

enum WidgetDayState: String, Codable {
    case completed
    case upcoming
    case missed
}

// MARK: - Widget Day Data

struct WidgetDayData: Identifiable, Codable {
    let dayNumber: Int
    let state: WidgetDayState

    var id: Int {
        dayNumber
    }
}

// MARK: - Widget Universe Data

struct WidgetUniverseData: Codable {
    var syncMessage: String? = nil
    let hasActiveChallenge: Bool
    let title: String
    let galaxyRawValue: String
    let totalDays: Int
    let progress: Double

    // Current challenge day
    let currentDayNumber: Int?

    // Challenge start date
    let startDate: Date?

    // All challenge days
    let days: [WidgetDayData]

    // Calendar presentation advances without changing the app's persisted model.
    func projected(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> Self {
        guard hasActiveChallenge, let startDate, totalDays > 0,
              let offset = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate),
                                                    to: calendar.startOfDay(for: date)).day else { return self }
        let today = offset + 1
        return Self(
            syncMessage: syncMessage,
            hasActiveChallenge: today <= totalDays,
            title: title, galaxyRawValue: galaxyRawValue, totalDays: totalDays, progress: progress,
            currentDayNumber: (1...totalDays).contains(today) ? today : nil,
            startDate: startDate,
            days: days.map { day in
                WidgetDayData(dayNumber: day.dayNumber,
                              state: day.state == .upcoming && day.dayNumber < today ? .missed : day.state)
            }
        )
    }

    // MARK: - Empty

    static let empty = WidgetUniverseData(
        hasActiveChallenge: false,
        title: "",
        galaxyRawValue: "expanding",
        totalDays: 0,
        progress: 0,
        currentDayNumber: nil,
        startDate: nil,
        days: []
    )

    // MARK: - Preview

    static let previewActive = WidgetUniverseData(
        hasActiveChallenge: true,
        title: "Read Every Day",
        galaxyRawValue: "expanding",
        totalDays: 30,
        progress: 5.0 / 30.0,
        currentDayNumber: 6,
        startDate: Date(),
        days: (1...30).map { day in
            WidgetDayData(
                dayNumber: day,
                state: day <= 5
                    ? .completed
                    : .upcoming
            )
        }
    )
}
