import Foundation

// Shared by app and extension. Atomic files keep the last readable generation.
struct WidgetSnapshotStore {
    let directory: URL
    private var current: URL { directory.appendingPathComponent("universe-widget.json") }
    private var previous: URL { directory.appendingPathComponent("universe-widget-previous.json") }

    func save(_ data: WidgetUniverseData) throws -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(data)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let existing = try? Data(contentsOf: current), existing == encoded { return false }
        if let existing = try? Data(contentsOf: current),
           (try? JSONDecoder().decode(WidgetUniverseData.self, from: existing)) != nil {
            try existing.write(to: previous, options: .atomic)
        }
        try encoded.write(to: current, options: .atomic)
        return true
    }

    func load() -> WidgetUniverseData? {
        for (index, url) in [current, previous].enumerated() {
            if let bytes = try? Data(contentsOf: url),
               var value = try? JSONDecoder().decode(WidgetUniverseData.self, from: bytes) {
                if index == 1 { value.syncMessage = "Older progress · Open app" }
                return value
            }
        }
        return nil
    }
}
