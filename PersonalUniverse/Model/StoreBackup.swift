import Foundation
import SQLite3

// SQLite's online backup includes committed WAL contents. Never copy a live .store alone.
nonisolated struct StoreBackup: Sendable {
    let storeURL: URL
    var backupURL: URL { storeURL.deletingLastPathComponent().appendingPathComponent("UniverseRecovery/last-good.store") }

    enum Failure: LocalizedError {
        case database(String), missingBackup
        var errorDescription: String? {
            switch self {
            case .database: "The database backup could not be verified. Your existing files have been kept."
            case .missingBackup: "No verified backup is available yet. Your existing files have been kept."
            }
        }
    }

    var backupDate: Date? {
        (try? FileManager.default.attributesOfItem(atPath: backupURL.path)[.modificationDate]) as? Date
    }

    func create() throws {
        let files = FileManager.default
        guard files.fileExists(atPath: storeURL.path) else { return }
        try files.createDirectory(at: backupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let temporary = backupURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString + ".store")
        defer { removeTemporaryFiles(at: temporary) }
        try snapshot(from: storeURL, to: temporary)
        try validate(temporary)
        if files.fileExists(atPath: backupURL.path) {
            _ = try files.replaceItemAt(backupURL, withItemAt: temporary, options: .usingNewMetadataOnly)
        } else {
            try files.moveItem(at: temporary, to: backupURL)
        }
    }

    // Only call before a ModelContainer has opened. Preserve the failed store AND sidecars.
    func restore() throws -> URL {
        let files = FileManager.default
        guard backupDate != nil else { throw Failure.missingBackup }
        try validate(backupURL)
        let archive = backupURL.deletingLastPathComponent().appendingPathComponent("BeforeRestore-" + UUID().uuidString)
        try files.createDirectory(at: archive, withIntermediateDirectories: true)
        let staged = archive.appendingPathComponent("restored.store")
        defer { removeTemporaryFiles(at: staged) }
        try snapshot(from: backupURL, to: staged)
        var originals: [(URL, URL)] = []
        do {
            for suffix in ["", "-wal", "-shm"] {
                let original = URL(fileURLWithPath: storeURL.path + suffix)
                guard files.fileExists(atPath: original.path) else { continue }
                let saved = archive.appendingPathComponent(original.lastPathComponent)
                // Copy all originals before replacing anything, including on disk-full failure.
                try files.copyItem(at: original, to: saved)
                originals.append((original, saved))
            }
            for (original, _) in originals where original != storeURL {
                try files.removeItem(at: original)
            }
            // Atomic replacement avoids a crash window with no primary store at all.
            if files.fileExists(atPath: storeURL.path) {
                _ = try files.replaceItemAt(storeURL, withItemAt: staged, options: .usingNewMetadataOnly)
            } else {
                try files.moveItem(at: staged, to: storeURL)
            }
        } catch {
            // Keep the archive even if rollback itself fails; never discard the only copy.
            for (original, saved) in originals where !files.fileExists(atPath: original.path) {
                try? files.copyItem(at: saved, to: original)
            }
            throw error
        }
        return archive
    }

    // SQLite can leave an empty shared-memory sidecar after changing journal mode.
    // Only clean our unique temporary paths, never a live store's files.
    private func removeTemporaryFiles(at url: URL) {
        for suffix in ["", "-wal", "-shm", "-journal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    func validate(_ url: URL) throws {
        var database: OpaquePointer?
        guard sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            let reason = database.map { String(cString: sqlite3_errmsg($0)) } ?? "open failed"
            sqlite3_close(database); throw Failure.database("validate open \(url.path): \(reason)")
        }
        defer { sqlite3_close(database) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, "PRAGMA quick_check", -1, &statement, nil) == SQLITE_OK else { throw Failure.database("validate prepare: " + (database.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown")) }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW,
              let text = sqlite3_column_text(statement, 0), String(cString: text) == "ok" else { throw Failure.database("quick_check failed: " + String(cString: sqlite3_errmsg(database))) }
    }

    private func snapshot(from sourceURL: URL, to destinationURL: URL) throws {
        var source: OpaquePointer?
        var destination: OpaquePointer?
        defer { sqlite3_close(source); sqlite3_close(destination) }
        guard sqlite3_open_v2(sourceURL.path, &source, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              sqlite3_open_v2(destinationURL.path, &destination, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else { throw Failure.database("source: \(String(cString: sqlite3_errmsg(source))); destination: \(String(cString: sqlite3_errmsg(destination)))") }
        sqlite3_busy_timeout(source, 1000)
        sqlite3_busy_timeout(destination, 1000)
        guard let operation = sqlite3_backup_init(destination, "main", source, "main") else { throw Failure.database(String(cString: sqlite3_errmsg(destination))) }
        let step = sqlite3_backup_step(operation, -1)
        let finish = sqlite3_backup_finish(operation)
        guard step == SQLITE_DONE, finish == SQLITE_OK else { throw Failure.database("step \(step), finish \(finish): \(String(cString: sqlite3_errmsg(destination)))") }
        // Make a standalone backup: do not leave the source's WAL journal mode in its header.
        guard sqlite3_exec(destination, "PRAGMA journal_mode=DELETE", nil, nil, nil) == SQLITE_OK else {
            throw Failure.database(String(cString: sqlite3_errmsg(destination)))
        }
    }
}
