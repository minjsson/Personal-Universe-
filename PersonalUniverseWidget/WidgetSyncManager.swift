//
//  WidgetSyncManager.swift
//  PersonalUniverse
//

import Foundation
import WidgetKit
import Observation

@Observable
@MainActor
final class WidgetSyncStatus {
    var errorMessage: String?
}

@MainActor
enum WidgetSyncManager {
    static let status = WidgetSyncStatus()
    private static var pendingData: WidgetUniverseData?

    static func retry() {
        if let pendingData { save(pendingData) }
    }

    // MARK: - Configuration

    private static let appGroupID = "group.com.victoria.PersonalUniverse"
    private static let widgetKind = "PersonalUniverseWidget"

    // MARK: - Save Active Challenge

    static func save(challenge: UniverseChallenge) {
        let widgetData = makeWidgetData(from: challenge)
        save(widgetData)
    }

    // MARK: - Save Empty State

    static func saveEmpty() {
        save(WidgetUniverseData.empty)
    }

    // MARK: - Save

    private static func save(_ data: WidgetUniverseData) {
        pendingData = data
        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            status.errorMessage = "The widget's shared storage is unavailable. Your saved data is still available in the app. Try again."
            return
        }
        do {
            let changed = try WidgetSnapshotStore(directory: directory).save(data)
            let wasRecovering = status.errorMessage != nil
            status.errorMessage = nil
            if changed || wasRecovering { WidgetCenter.shared.reloadTimelines(ofKind: widgetKind) }
        } catch {
            status.errorMessage = "Your challenge is saved, but the widget could not be updated. It may show older progress. Check available storage and try again."
        }
    }

    // MARK: - Convert UniverseChallenge

    private static func makeWidgetData(
        from challenge: UniverseChallenge
    ) -> WidgetUniverseData {
        // ---------------------------------------------------------
        // 오늘의 챌린지 Day
        // ---------------------------------------------------------

        let currentDayNumber = challenge.currentDay?.dayNumber

        // ---------------------------------------------------------
        // Widget Days
        // ---------------------------------------------------------

        let widgetDays = challenge.orderedDays.map { day in
            let state: WidgetDayState

            switch day.status {
            case .completed:
                state = .completed
            case .missed:
                state = .missed
            case .upcoming:
                state = .upcoming
            }

            return WidgetDayData(
                dayNumber: day.dayNumber,
                state: state
            )
        }

        // ---------------------------------------------------------
        // Progress
        // ---------------------------------------------------------

        let completedDays = widgetDays.filter {
            $0.state == .completed
        }.count

        let totalDays = challenge.length.days
        let progress: Double

        if totalDays > 0 {
            progress = min(
                max(
                    Double(completedDays) / Double(totalDays),
                    0
                ),
                1
            )
        } else {
            progress = 0
        }

        // ---------------------------------------------------------
        // Final Widget Data
        // ---------------------------------------------------------

        return WidgetUniverseData(
            hasActiveChallenge: challenge.status == .active,
            title: challenge.title,
            galaxyRawValue: challenge.galaxyRawValue,
            totalDays: totalDays,
            progress: progress,
            currentDayNumber: currentDayNumber,
            startDate: challenge.startDate,
            days: widgetDays
        )
    }
}
