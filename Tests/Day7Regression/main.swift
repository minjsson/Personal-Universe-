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
    print("PASS: metadata save, failure restoration, validation, progress preservation, startup retry, revealAt")
}

@main
struct RegressionChecks {
    @MainActor
    static func main() throws { try runChecks() }
}
