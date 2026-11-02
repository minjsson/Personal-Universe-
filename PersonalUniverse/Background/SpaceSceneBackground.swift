import SwiftUI

// 화면의 ZStack에서 내용보다 먼저 배치합니다.
// 별 배경 < 장식 이벤트 < 화면 내용의 순서를 유지합니다.
struct SpaceSceneBackground: View {
    var body: some View {
        ZStack {
            SpaceBackground()
                .zIndex(0)
            AmbientSpaceEventLayer()
                .zIndex(1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct AmbientSpaceEventLayer: View {
    @Environment(\.ambientSpaceScene) private var scene
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if !reduceMotion, scenePhase == .active, let event = scene?.event {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                AmbientSpaceEventView(event: event, date: timeline.date)
            }
        }
    }
}

#Preview {
    ZStack {
        SpaceSceneBackground()
            .ignoresSafeArea()
            .zIndex(-1)
        Text("Your universe")
            .foregroundStyle(.white)
    }
}
