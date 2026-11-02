import SwiftUI
import Observation

// 화면마다 타이머를 새로 시작하지 않고 한 창의 일정과 진행 상태를 공유합니다.
@Observable
@MainActor
final class AmbientSpaceScene {
    private(set) var event: AmbientSpaceEvent?
    private var previousKind: AmbientSpaceEvent.Kind?
    private var nextEventAt: Date?

    func run(enabled: Bool) async {
        guard enabled else { event = nil; return }
        var generator = SystemRandomNumberGenerator()
        if nextEventAt == nil {
            nextEventAt = .now.addingTimeInterval(AmbientSpaceEvent.quietInterval(using: &generator))
        }
        do {
            while !Task.isCancelled {
                let delay = max(nextEventAt?.timeIntervalSinceNow ?? 0, 0)
                try await Task.sleep(for: .seconds(delay))
                try Task.checkCancellation()
                let next = AmbientSpaceEvent.random(after: previousKind, using: &generator)
                previousKind = next.kind
                event = next
                try await Task.sleep(for: .seconds(next.duration))
                event = nil
                nextEventAt = .now.addingTimeInterval(AmbientSpaceEvent.quietInterval(using: &generator))
            }
        } catch {
            event = nil
            // 복귀 직후 같은 이벤트가 다시 재생되지 않게 다음 시각만 유지합니다.
            nextEventAt = .now.addingTimeInterval(AmbientSpaceEvent.quietInterval(using: &generator))
        }
    }
}

private struct AmbientSpaceSceneKey: EnvironmentKey {
    static let defaultValue: AmbientSpaceScene? = nil
}

extension EnvironmentValues {
    var ambientSpaceScene: AmbientSpaceScene? {
        get { self[AmbientSpaceSceneKey.self] }
        set { self[AmbientSpaceSceneKey.self] = newValue }
    }
}
