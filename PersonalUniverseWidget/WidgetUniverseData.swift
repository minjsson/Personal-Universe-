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
