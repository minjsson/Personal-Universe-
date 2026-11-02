import SwiftUI

// 장식 이벤트는 챌린지 완료 이벤트나 저장 데이터와 분리합니다.
struct AmbientSpaceEvent {
    enum Kind: CaseIterable { case meteor, satellite, station }
    let kind: Kind
    let startedAt = Date()
    let duration: TimeInterval = 6
    let height = CGFloat.random(in: 0.15...0.65)

    var symbolScale: CGFloat { kind == .station ? 1.2 : 0.8 }
}

struct AmbientSpaceEventView: View {
    let event: AmbientSpaceEvent
    let date: Date

    var body: some View {
        GeometryReader { geometry in
            let elapsed = date.timeIntervalSince(event.startedAt)
            let progress = min(max(elapsed / event.duration, 0), 1)
            Group {
                if event.kind == .meteor {
                    Capsule()
                        .fill(LinearGradient(colors: [.clear, .white.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 90, height: 2)
                        .shadow(color: .white.opacity(0.8), radius: 6)
                        .rotationEffect(.degrees(25))
                } else {
                    HStack(spacing: 3) {
                        solarPanel
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.85))
                            .frame(width: 8, height: 16)
                        solarPanel
                    }
                    .scaleEffect(event.symbolScale)
                    .rotationEffect(.degrees(progress * 40 - 20))
                    .shadow(color: .white.opacity(0.6), radius: 5)
                }
            }
            .opacity(min(progress * 8, (1 - progress) * 8))
            .position(
                x: -100 + (geometry.size.width + 200) * progress,
                y: geometry.size.height * event.height + (event.kind == .meteor ? 100 * progress : sin(progress * .pi) * 25)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var solarPanel: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.cyan.opacity(0.65))
            .frame(width: event.kind == .station ? 20 : 12, height: 10)
            .overlay {
                Rectangle().stroke(.white.opacity(0.5), lineWidth: 0.5)
            }
    }
}
