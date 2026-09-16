//
//  WidgetDataManager.swift
//  PersonalUniverseWidget
//

import Foundation

enum WidgetDataManager {
    private static let appGroupID = "group.com.victoria.PersonalUniverse"
    private static let dataKey = "widgetUniverseData"

    static func load() -> WidgetUniverseData {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("WidgetDataManager: Could not access App Group.")
            return .empty
        }

        guard let data = defaults.data(forKey: dataKey) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(
                WidgetUniverseData.self,
                from: data
            )
        } catch {
            print("WidgetDataManager: Failed to decode widget data: \(error)")
            return .empty
        }
    }
}
