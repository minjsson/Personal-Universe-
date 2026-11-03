//
//  WidgetDataManager.swift
//  PersonalUniverseWidget
//

import Foundation

enum WidgetDataManager {
    private static let appGroupID = "group.com.victoria.PersonalUniverse"
    private static let dataKey = "widgetUniverseData"

    static func load() -> WidgetUniverseData {
        if let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            if let snapshot = WidgetSnapshotStore(directory: directory).load() { return snapshot }
        }
        // Upgrade compatibility: use the previous app's snapshot until the next app sync.
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: dataKey),
              var legacy = try? JSONDecoder().decode(WidgetUniverseData.self, from: data) else {
            var unavailable = WidgetUniverseData.empty
            unavailable.syncMessage = "Open app to refresh widget"
            return unavailable
        }
        legacy.syncMessage = "Older progress · Open app"
        return legacy
    }
}
