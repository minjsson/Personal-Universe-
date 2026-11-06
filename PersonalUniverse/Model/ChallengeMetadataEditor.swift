import Foundation

// 저장 경계를 분리해 테스트에서 실패 상황을 주입할 수 있습니다.
@MainActor
enum ChallengeMetadataEditor {
    enum ValidationError: LocalizedError {
        case emptyTitle
        var errorDescription: String? { "Please enter a challenge title." }
    }

    static func save(
        challenge: UniverseChallenge,
        title: String,
        galaxy: GalaxyStyle,
        persist: () throws -> Void
    ) throws {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw ValidationError.emptyTitle }
        let originalTitle = challenge.title
        let originalGalaxy = challenge.galaxy
        challenge.title = cleanTitle
        challenge.galaxy = galaxy
        do {
            try persist()
        } catch {
            challenge.title = originalTitle
            challenge.galaxy = originalGalaxy
            throw error
        }
    }
}
