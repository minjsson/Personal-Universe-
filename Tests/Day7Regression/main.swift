import Foundation
import SwiftData

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
    let loader = PersistentStoreLoader {
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
    for _ in 0..<512 {
        let event = AmbientSpaceEvent.random(after: previous, using: &generator)
        precondition(event.kind != previous)
        precondition((0.08...0.85).contains(event.end.y))
        precondition(event.start.x != event.end.x)
        leftToRight = leftToRight || event.start.x < event.end.x
        rightToLeft = rightToLeft || event.start.x > event.end.x
        switch event.kind {
        case .meteor:
            seenKinds.insert(0)
            precondition((0.9...1.8).contains(event.duration) && event.arc == 0)
        case .satellite:
            seenKinds.insert(1)
            precondition((10...17).contains(event.duration))
        case .station:
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
    precondition(leftToRight && rightToLeft && shortGap && longGap)
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

@main
struct RegressionChecks {
    @MainActor
    static func main() throws { try runChecks() }
}
