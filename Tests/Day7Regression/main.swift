import Foundation
import SwiftData
import SQLite3
import UserNotifications

// 앱과 같은 모델/작업 코드를 사용합니다. 별도의 테스트용 구현을 만들지 않습니다.
enum ForcedFailure: Error { case storage }

@MainActor
func runChecks() throws {
    let container = try ModelContainer(
        for: UniverseChallenge.self, ChallengeDay.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    context.autosaveEnabled = false
    let challenge = UniverseChallenge(title: "Original", length: .seven, galaxy: .cluster)
    context.insert(challenge)
    challenge.completeDay(challenge.orderedDays[0])
    try context.save()
    let originalProgress = challenge.progress
    let originalDate = challenge.startDate
    let originalIDs = challenge.orderedDays.map(\.dayNumber)

    try ChallengeMetadataEditor.save(challenge: challenge, title: "  Edited  ", galaxy: .spiral) {
        try context.save()
    }
    precondition(challenge.title == "Edited" && challenge.galaxy == .spiral)
    precondition(challenge.progress == originalProgress && challenge.startDate == originalDate)
    precondition(challenge.orderedDays.map(\.dayNumber) == originalIDs)
    let fetched = try ModelContext(container).fetch(FetchDescriptor<UniverseChallenge>())
    precondition(fetched.count == 1 && fetched[0].title == "Edited")

    do {
        try ChallengeMetadataEditor.save(challenge: challenge, title: "Not saved", galaxy: .expanding) {
            throw ForcedFailure.storage
        }
        preconditionFailure("A failing save must throw")
    } catch ForcedFailure.storage {
        precondition(challenge.title == "Edited" && challenge.galaxy == .spiral)
        precondition(challenge.progress == originalProgress)
    }
    var attemptedSave = false
    do {
        try ChallengeMetadataEditor.save(challenge: challenge, title: " \n ", galaxy: .expanding) {
            attemptedSave = true
        }
        preconditionFailure("An empty title must be rejected")
    } catch ChallengeMetadataEditor.ValidationError.emptyTitle {
        precondition(!attemptedSave && challenge.title == "Edited")
    }

    var attempts = 0
    let loader = PersistentStoreLoader(backup: nil) {
        attempts += 1
        if attempts == 1 { throw ForcedFailure.storage }
        return container
    }
    loader.open()
    precondition(loader.container == nil && loader.errorMessage != nil && !loader.isLoading)
    loader.open()
    precondition(loader.container === container && loader.errorMessage == nil && !loader.isLoading)
    loader.open()
    precondition(attempts == 2)

    // 멤버와이즈 초기화가 0이 아닌 revealAt을 보존해야 합니다.
    let point = GalaxyPoint(x: 1, y: 2, size: 3, opacity: 0.8, revealAt: 0.7)
    precondition(point.revealAt == 0.7)
    // 고정 시드로 경로·속도·간격의 다양성과 안전 범위를 검사합니다.
    var generator = EventTestGenerator()
    var previous: AmbientSpaceEvent.Kind?
    var seenKinds = Set<Int>()
    var seenSpeeds = Set<Int>()
    var leftToRight = false
    var rightToLeft = false
    var shortGap = false
    var longGap = false
    var lowPass = false
    var highPass = false
    for _ in 0..<512 {
        let event = AmbientSpaceEvent.random(after: previous, using: &generator)
        precondition(event.kind != previous)
        precondition((0.04...0.96).contains(event.end.y))
        let middleY = (event.start.y + event.end.y) / 2 + event.arc
        lowPass = lowPass || middleY >= 0.80
        highPass = highPass || middleY <= 0.24
        for step in 0...20 {
            let t = CGFloat(step) / 20
            let y = event.start.y + (event.end.y - event.start.y) * t + sin(t * .pi) * event.arc
            precondition((0.039...0.961).contains(y))
        }
        precondition(event.start.x != event.end.x)
        leftToRight = leftToRight || event.start.x < event.end.x
        rightToLeft = rightToLeft || event.start.x > event.end.x
        switch event.kind {
        case .meteor:
            precondition((0.75...0.90).contains(event.brightness) && (55...90).contains(event.size))
            seenKinds.insert(0)
            precondition((1.3...2.1).contains(event.duration) && event.arc == 0)
        case .satellite:
            precondition((0.55...0.70).contains(event.brightness) && (20...25).contains(event.size))
            seenKinds.insert(1)
            precondition((10...17).contains(event.duration))
        case .station:
            precondition((0.48...0.64).contains(event.brightness) && (44...56).contains(event.size))
            seenKinds.insert(2)
            precondition((18...26).contains(event.duration))
        }
        seenSpeeds.insert(Int(event.duration * 10))
        let gap = AmbientSpaceEvent.quietInterval(using: &generator)
        precondition((10...120).contains(gap))
        shortGap = shortGap || gap <= 28
        longGap = longGap || gap >= 80
        previous = event.kind
    }
    precondition(seenKinds.count == 3 && seenSpeeds.count > 10)
    precondition(leftToRight && rightToLeft && shortGap && longGap && lowPass && highPass)
    print("PASS: storage/edit regressions, revealAt, ambient variety/bounds/no immediate repeats")
}

struct EventTestGenerator: RandomNumberGenerator {
    private var state: UInt64 = 7
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

func check(_ value: Bool) { precondition(value) }

// Use real temporary SQLite/WAL files, never the user's app database.
@MainActor
func runBackupChecks() throws {
    let files = FileManager.default
    let directory = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try files.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? files.removeItem(at: directory) }
    let url = directory.appendingPathComponent("default.store")
    let backup = StoreBackup(storeURL: url)
    do { _ = try backup.restore(); preconditionFailure("Missing backup must fail") }
    catch StoreBackup.Failure.missingBackup {}

    var database: OpaquePointer?
    precondition(sqlite3_open(url.path, &database) == SQLITE_OK)
    precondition(sqlite3_exec(database, "PRAGMA journal_mode=WAL; CREATE TABLE note(value TEXT); INSERT INTO note VALUES('saved in WAL');", nil, nil, nil) == SQLITE_OK)
    // Keep source open: the latest committed content is still in its WAL.
    try backup.create()
    precondition(backup.backupDate != nil)
    // A second, changed backup exercises WAL freshness and atomic replacement.
    precondition(sqlite3_exec(database, "UPDATE note SET value='latest WAL edit'", nil, nil, nil) == SQLITE_OK)
    try backup.create()
    let leftovers = try files.contentsOfDirectory(at: backup.backupURL.deletingLastPathComponent(), includingPropertiesForKeys: nil)
    precondition(leftovers.count == 1 && leftovers[0].lastPathComponent == "last-good.store")
    sqlite3_close(database)
    database = nil
    // Missing primary + existing backup must not silently create a new empty universe.
    try files.moveItem(at: url, to: directory.appendingPathComponent("retained-primary.store"))
    var openAttempts = 0
    let missingLoader = PersistentStoreLoader(backup: backup) {
        openAttempts += 1
        throw ForcedFailure.storage
    }
    missingLoader.open()
    precondition(openAttempts == 0 && missingLoader.container == nil && missingLoader.errorMessage != nil)
    _ = try backup.restore()
    try Data("broken original".utf8).write(to: url)
    let wal = URL(fileURLWithPath: url.path + "-wal")
    let shm = URL(fileURLWithPath: url.path + "-shm")
    try Data("preserved WAL".utf8).write(to: wal)
    try Data("preserved SHM".utf8).write(to: shm)
    let archive = try backup.restore()
    check(try String(contentsOf: archive.appendingPathComponent("default.store-wal"), encoding: .utf8) == "preserved WAL")
    check(try String(contentsOf: archive.appendingPathComponent("default.store-shm"), encoding: .utf8) == "preserved SHM")
    precondition(!files.fileExists(atPath: wal.path) && !files.fileExists(atPath: shm.path))
    check(try String(contentsOf: archive.appendingPathComponent("default.store"), encoding: .utf8) == "broken original")
    precondition(sqlite3_open(url.path, &database) == SQLITE_OK)
    var statement: OpaquePointer?
    precondition(sqlite3_prepare_v2(database, "SELECT value FROM note", -1, &statement, nil) == SQLITE_OK)
    precondition(sqlite3_step(statement) == SQLITE_ROW)
    precondition(String(cString: sqlite3_column_text(statement, 0)) == "latest WAL edit")
    sqlite3_finalize(statement)
    sqlite3_close(database)
    let restoredBytes = try Data(contentsOf: url)
    try Data("broken backup".utf8).write(to: backup.backupURL)
    do { _ = try backup.restore(); preconditionFailure("Corrupt backup must be rejected") }
    catch StoreBackup.Failure.database {}
    check(try Data(contentsOf: url) == restoredBytes)
    // A failed backup must not overwrite the existing backup.
    try Data("bad source".utf8).write(to: url)
    do { try backup.create(); preconditionFailure("Corrupt source must be rejected") }
    catch StoreBackup.Failure.database {}
    check(try String(contentsOf: backup.backupURL, encoding: .utf8) == "broken backup")
    print("PASS: WAL backup, atomic replacement, restoration, original preservation, missing/corrupt backup refusal")
}

@MainActor
func runSwiftDataRecoveryChecks() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("universe.store")
    let schema = Schema([UniverseChallenge.self, ChallengeDay.self])
    let backup = StoreBackup(storeURL: url)
    try autoreleasepool {
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = container.mainContext
        let challenge = UniverseChallenge(title: "Saved universe", length: .seven, galaxy: .spiral)
        context.insert(challenge)
        challenge.completeDay(challenge.orderedDays[0])
        challenge.orderedDays[0].reflection = "Keep this reflection"
        try context.save()
        try backup.create()
    }
    // Reopen a restored copy under a fresh URL to avoid a cached persistent coordinator.
    let restored = directory.appendingPathComponent("recovered.store")
    try FileManager.default.copyItem(at: backup.backupURL, to: restored)
    let reopened = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: restored)])
    let values = try reopened.mainContext.fetch(FetchDescriptor<UniverseChallenge>())
    precondition(values.count == 1 && values[0].title == "Saved universe")
    precondition(values[0].galaxy == .spiral && values[0].orderedDays.count == 7)
    precondition(values[0].completedDayCount == 1 && values[0].orderedDays[0].reflection == "Keep this reflection")
    print("PASS: real SwiftData backup reopens with title, style, relationships, progress and reflection")
}

func runWidgetChecks() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = WidgetSnapshotStore(directory: directory)
    precondition(store.load() == nil)
    check(try store.save(.previewActive))
    check(!(try store.save(store.load()!))) // identical snapshot does not request reload
    check(try store.save(.empty))
    try Data("corrupt".utf8).write(to: directory.appendingPathComponent("universe-widget.json"))
    let fallback = store.load()
    precondition(fallback?.hasActiveChallenge == true && fallback?.syncMessage != nil)
    try Data("corrupt".utf8).write(to: directory.appendingPathComponent("universe-widget-previous.json"))
    precondition(store.load() == nil)
    // Repair replaces invalid data and clears the stale warning.
    check(try store.save(.empty))
    precondition(store.load()?.hasActiveChallenge == false && store.load()?.syncMessage == nil)
    let blocked = directory.appendingPathComponent("not-a-directory")
    try Data().write(to: blocked)
    do { _ = try WidgetSnapshotStore(directory: blocked).save(.empty); preconditionFailure("Write failure must throw") }
    catch {}
    print("PASS: widget first write/dedup, corrupt snapshot fallback, recovery, write failure")
}

@MainActor
func runNotificationChecks() async throws {
    var status = UNAuthorizationStatus.denied
    var failAuthorization = false
    var failAdd = true
    var added = 0
    var removed = 0
    let client = NotificationClient(
        authorizationStatus: { status },
        requestAuthorization: {
            if failAuthorization { throw ForcedFailure.storage }
            return true
        },
        add: { _ in added += 1; if failAdd { throw ForcedFailure.storage } },
        remove: { removed += $0.count },
        now: { Calendar.current.startOfDay(for: .now) }
    )
    let manager = NotificationManager(client: client)
    check(!(await manager.requestPermission()))
    precondition(manager.permissionDenied && manager.errorMessage != nil)
    status = .notDetermined
    failAuthorization = true
    check(!(await manager.requestPermission()))
    precondition(!manager.permissionDenied && manager.errorMessage != nil)
    status = .authorized
    check(await manager.requestPermission())
    precondition(manager.errorMessage == nil)
    let challenge = UniverseChallenge(title: "Reminder", length: .seven, reminderEnabled: true, reminderHour: 23, reminderMinute: 59)
    await manager.scheduleCurrentReminder(for: challenge)
    precondition(added == 1 && removed == 0 && manager.errorMessage != nil)
    failAdd = false
    await manager.retry()
    precondition(added == 2 && manager.errorMessage == nil)
    challenge.reminderEnabled = false
    await manager.scheduleCurrentReminder(for: challenge)
    precondition(removed == challenge.days.count && manager.errorMessage == nil)
    print("PASS: permission denial/error recovery, schedule failure/retry without deleting prior reminder, disabled cancellation")
}

@MainActor
func runNotificationRaceChecks() async {
    for fail in [false, true] {
        var continuation: CheckedContinuation<Void, Never>?
        var removed = 0
        let manager = NotificationManager(client: NotificationClient(
            authorizationStatus: { .authorized }, requestAuthorization: { true },
            add: { _ in
                await withCheckedContinuation { continuation = $0 }
                if fail { throw ForcedFailure.storage }
            },
            remove: { removed += $0.count },
            now: { Calendar.current.startOfDay(for: .now) }
        ))
        let challenge = UniverseChallenge(title: "Pending reminder", length: .seven, reminderEnabled: true, reminderHour: 23, reminderMinute: 59)
        let work = Task { await manager.scheduleCurrentReminder(for: challenge) }
        for _ in 0..<10000 {
            if continuation != nil { break }
            await Task.yield()
        }
        precondition(continuation != nil)
        challenge.completeDay(challenge.currentDay!)
        continuation?.resume()
        await work.value
        precondition(manager.errorMessage == nil && removed == 7)
    }

    // Denial arrives after completion: the obsolete permission error must not remain.
    var permissionContinuation: CheckedContinuation<Void, Never>?
    let permissionManager = NotificationManager(client: NotificationClient(
        authorizationStatus: {
            await withCheckedContinuation { permissionContinuation = $0 }
            return .denied
        }, requestAuthorization: { false }, add: { _ in preconditionFailure("Completed day must not schedule") }, remove: { _ in },
        now: { Calendar.current.startOfDay(for: .now) }
    ))
    let completed = UniverseChallenge(title: "Completed during permission", length: .seven, reminderEnabled: true, reminderHour: 23, reminderMinute: 59)
    let permissionWork = Task { await permissionManager.scheduleCurrentReminder(for: completed) }
    for _ in 0..<10000 {
        if permissionContinuation != nil { break }
        await Task.yield()
    }
    precondition(permissionContinuation != nil)
    completed.completeDay(completed.currentDay!)
    permissionContinuation?.resume()
    await permissionWork.value
    precondition(permissionManager.errorMessage == nil && !permissionManager.permissionDenied)

    // Hold the first platform write while a newer title is queued.
    var firstWrite: CheckedContinuation<Void, Never>?
    var titles: [String] = []
    var overlappingWrites = 0
    var activeWrites = 0
    let manager = NotificationManager(client: NotificationClient(
        authorizationStatus: { .authorized }, requestAuthorization: { true },
        add: { request in
            activeWrites += 1
            overlappingWrites = max(overlappingWrites, activeWrites)
            titles.append(request.content.title)
            if titles.count == 1 { await withCheckedContinuation { firstWrite = $0 } }
            activeWrites -= 1
        }, remove: { _ in }, now: { Calendar.current.startOfDay(for: .now) }
    ))
    let challenge = UniverseChallenge(title: "Old title", length: .seven, reminderEnabled: true, reminderHour: 23, reminderMinute: 59)
    let first = Task { await manager.scheduleCurrentReminder(for: challenge) }
    for _ in 0..<10000 {
        if firstWrite != nil { break }
        await Task.yield()
    }
    precondition(firstWrite != nil)
    challenge.title = "Newest title"
    var queued = false
    let second = Task { queued = true; await manager.scheduleCurrentReminder(for: challenge) }
    for _ in 0..<10000 {
        if queued { break }
        await Task.yield()
    }
    precondition(queued)
    firstWrite?.resume()
    await first.value
    await second.value
    precondition(titles == ["Old title", "Newest title"] && overlappingWrites == 1)
    precondition(manager.errorMessage == nil)
    print("PASS: notification completion during pending add/permission, serialized latest-title scheduling")
}

@MainActor
func runDailyRolloverChecks() async throws {
    let calendar = Calendar.autoupdatingCurrent
    let start = calendar.startOfDay(for: .now)
    var now = calendar.date(byAdding: .hour, value: 12, to: start)!
    var requests: [UNNotificationRequest] = []
    let manager = NotificationManager(client: NotificationClient(
        authorizationStatus: { .authorized }, requestAuthorization: { true },
        add: { requests.append($0) }, remove: { _ in }, now: { now }
    ))
    let challenge = UniverseChallenge(title: "Daily rollover", length: .seven, startDate: start,
                                     reminderEnabled: true, reminderHour: 13, reminderMinute: 0)
    await manager.scheduleCurrentReminder(for: challenge)
    precondition(requests.last?.content.body == "Day 1 is waiting for you.")
    challenge.completeDay(challenge.orderedDays[0], at: now)
    await manager.rescheduleAfterCompletion(for: challenge, completedDayNumber: 1)
    precondition(requests.last?.content.body == "Day 2 is waiting for you.")
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: start)!
    let trigger = requests.last?.trigger as? UNCalendarNotificationTrigger
    precondition(trigger?.dateComponents.day == calendar.component(.day, from: tomorrow))
    precondition(challenge.currentDay?.dayNumber == 1) // Reminder planning must not advance the UI day.
    challenge.title = "Edited daily rollover"
    await manager.scheduleCurrentReminder(for: challenge)
    precondition(requests.last?.content.title == challenge.title)
    now = calendar.date(byAdding: .hour, value: 14, to: start)!
    let late = UniverseChallenge(title: "After reminder time", length: .seven, startDate: start,
                                reminderEnabled: true, reminderHour: 13, reminderMinute: 0)
    await manager.scheduleCurrentReminder(for: late)
    precondition(requests.last?.content.body == "Day 2 is waiting for you.")
    for day in challenge.orderedDays { challenge.completeDay(day, at: now) }
    let count = requests.count
    await manager.rescheduleAfterCompletion(for: challenge, completedDayNumber: 7)
    precondition(requests.count == count && challenge.status == .completed)

    let snapshot = WidgetUniverseData(hasActiveChallenge: true, title: "Widget rollover",
        galaxyRawValue: "spiral", totalDays: 7, progress: 1.0 / 7,
        currentDayNumber: 1, startDate: start,
        days: (1...7).map { WidgetDayData(dayNumber: $0, state: $0 == 1 ? .completed : .upcoming) })
    let projected = snapshot.projected(at: tomorrow, calendar: calendar)
    precondition(projected.currentDayNumber == 2 && projected.days[0].state == .completed)
    precondition(projected.progress == snapshot.progress && snapshot.currentDayNumber == 1)
    let dayFour = calendar.date(byAdding: .day, value: 3, to: start)!
    let missed = snapshot.projected(at: dayFour, calendar: calendar)
    precondition(missed.currentDayNumber == 4 && missed.days[1].state == .missed && missed.days[2].state == .missed)
    let afterEnd = calendar.date(byAdding: .day, value: 7, to: start)!
    precondition(!snapshot.projected(at: afterEnd, calendar: calendar).hasActiveChallenge)
    print("PASS: next-day reminder after completion/past time, edited title, final cancellation, widget midnight projection")
}

@main
struct RegressionChecks {
    @MainActor
    static func main() async throws {
        try runChecks()
        try runBackupChecks()
        try runSwiftDataRecoveryChecks()
        try runWidgetChecks()
        try await runNotificationChecks()
        await runNotificationRaceChecks()
        try await runDailyRolloverChecks()
    }
}
