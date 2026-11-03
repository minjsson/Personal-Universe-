import Foundation
import SwiftData

extension Notification.Name {
    static let universeDidSave = Notification.Name("PersonalUniverse.didSave")
}

extension ModelContext {
    // Publish only successful commits. Failed saves must never replace a recovery snapshot.
    func saveWithRecoverySnapshot() throws {
        try save()
        NotificationCenter.default.post(name: .universeDidSave, object: nil)
    }
}
