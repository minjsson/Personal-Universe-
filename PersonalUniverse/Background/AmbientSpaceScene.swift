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
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ambient-demo") {
            await demonstrateEvents()
            return
        }
        #endif
        if nextEventAt == nil {
            nextEventAt = .now.addingTimeInterval(AmbientSpaceEvent.quietInterval(using: &generator))
        }
        do {
            while !Task.isCancelled {
                let delay = max(nextEventAt?.timeIntervalSinceNow ?? 0, 0)
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--ambient-timing-log") {
                    print("AMBIENT wait \(String(format: "%.2f", delay))s at \(Date().timeIntervalSince1970)")
                    fflush(stdout)
                }
                #endif
                try await Task.sleep(for: .seconds(delay))
                try Task.checkCancellation()
                let next = AmbientSpaceEvent.random(after: previousKind, using: &generator)
                previousKind = next.kind
                event = next
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--ambient-timing-log") {
                    print("AMBIENT start \(next.kind) duration \(String(format: "%.2f", next.duration))s at \(Date().timeIntervalSince1970)")
                    fflush(stdout)
                }
                #endif
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
    #if DEBUG
    // 촬영할 때만 종류 순서와 대기 시간을 지정합니다. 배포 빌드에는 포함되지 않습니다.
    private func demonstrateEvents() async {
        var generator = SystemRandomNumberGenerator()
        do {
            let arguments = ProcessInfo.processInfo.arguments
            let kinds = AmbientSpaceEvent.Kind.allCases.filter {
                !arguments.contains("--ambient-station-only") || $0 == .station
            }
            for kind in kinds {
                try await Task.sleep(for: .seconds(2))
                try Task.checkCancellation()
                let next = AmbientSpaceEvent.random(kind: kind, after: nil, using: &generator)
                event = next
                print("AMBIENT DEMO \(kind) duration \(String(format: "%.2f", next.duration))s")
                fflush(stdout)
                try await Task.sleep(for: .seconds(next.duration))
                event = nil
            }
        } catch { event = nil }
    }
    #endif
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
