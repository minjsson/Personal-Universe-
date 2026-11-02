import SwiftUI

// 한 번 정한 경로·밝기·속도는 이벤트가 끝날 때까지 유지합니다.
struct AmbientSpaceEvent {
    enum Kind: CaseIterable { case meteor, satellite, station }

    let kind: Kind
    let startedAt: Date
    let duration: TimeInterval
    let start: CGPoint
    let end: CGPoint
    let arc: CGFloat
    let size: CGFloat
    let brightness: Double
    let tilt: Double

    static func random<R: RandomNumberGenerator>(
        after previous: Kind?,
        at date: Date = .now,
        using generator: inout R
    ) -> Self {
        // 유성은 자주, 인공 구조물은 드물게 나타납니다. 같은 종류의 연속은 피합니다.
        let candidates: [Kind] = [.meteor, .meteor, .meteor, .meteor, .satellite, .satellite, .station]
            .filter { $0 != previous }
        let kind = candidates.randomElement(using: &generator) ?? .meteor
        let leftToRight = Bool.random(using: &generator)
        let startY = CGFloat.random(in: 0.12...0.78, using: &generator)
        let endY = min(max(startY + CGFloat.random(in: -0.24...0.24, using: &generator), 0.08), 0.85)

        return Self(
            kind: kind,
            startedAt: date,
            duration: Double.random(in: kind == .meteor ? 0.9...1.8 : (kind == .satellite ? 10...17 : 18...26), using: &generator),
            start: CGPoint(x: leftToRight ? -0.25 : 1.25, y: startY),
            end: CGPoint(x: leftToRight ? 1.25 : -0.25, y: endY),
            arc: kind == .meteor ? 0 : CGFloat.random(in: -0.16...0.16, using: &generator),
            size: CGFloat.random(in: kind == .meteor ? 38...80 : (kind == .satellite ? 12...18 : 22...30), using: &generator),
            brightness: Double.random(in: kind == .meteor ? 0.40...0.65 : 0.24...0.42, using: &generator),
            tilt: Double.random(in: -35...35, using: &generator)
        )
    }

    static func quietInterval<R: RandomNumberGenerator>(using generator: inout R) -> TimeInterval {
        // 짧은 간격과 긴 정적을 섞어 일정한 반복 리듬을 줄입니다.
        switch Int.random(in: 0..<10, using: &generator) {
        case 0...3: return Double.random(in: 10...28, using: &generator)
        case 4...8: return Double.random(in: 35...65, using: &generator)
        default: return Double.random(in: 80...120, using: &generator)
        }
    }
}

struct AmbientSpaceEventView: View {
    let event: AmbientSpaceEvent
    let date: Date

    var body: some View {
        GeometryReader { geometry in
            let progress = min(max(date.timeIntervalSince(event.startedAt) / event.duration, 0), 1)
            let fade = sin(min(progress / 0.12, 1) * .pi / 2)
                * sin(min((1 - progress) / 0.18, 1) * .pi / 2)
            let dx = (event.end.x - event.start.x) * geometry.size.width
            let dy = (event.end.y - event.start.y) * geometry.size.height

            Group {
                if event.kind == .meteor {
                    meteor
                        .rotationEffect(.radians(atan2(dy, dx)))
                } else {
                    spacecraft
                        .rotationEffect(.degrees(event.tilt + sin(progress * .pi) * 10))
                }
            }
            .opacity(fade * event.brightness)
            .position(
                x: (event.start.x + (event.end.x - event.start.x) * progress) * geometry.size.width,
                y: (event.start.y + (event.end.y - event.start.y) * progress
                    + sin(progress * .pi) * event.arc) * geometry.size.height
            )
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var meteor: some View {
        ZStack(alignment: .trailing) {
            Capsule()
                .fill(LinearGradient(
                    colors: [.clear, .white.opacity(0.15), .white.opacity(0.7)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: event.size, height: 0.7)
            Circle()
                .fill(.white)
                .frame(width: 1.8, height: 1.8)
                .shadow(color: .white.opacity(0.45), radius: 3)
        }
    }

    // 기존 별·궤도의 흰색 점과 가는 선을 사용하고 강한 색상이나 채운 패널을 피합니다.
    private var spacecraft: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            var truss = Path()
            truss.move(to: CGPoint(x: size.width * 0.08, y: center.y))
            truss.addLine(to: CGPoint(x: size.width * 0.92, y: center.y))
            context.stroke(truss, with: .color(.white.opacity(0.65)), lineWidth: 0.6)

            for x in [size.width * 0.08, size.width * 0.65] {
                let panel = CGRect(x: x, y: size.height * 0.28, width: size.width * 0.27, height: size.height * 0.44)
                context.stroke(Path(roundedRect: panel, cornerRadius: 0.5), with: .color(.white.opacity(0.65)), lineWidth: 0.5)
                if event.kind == .station {
                    var division = Path()
                    division.move(to: CGPoint(x: panel.midX, y: panel.minY))
                    division.addLine(to: CGPoint(x: panel.midX, y: panel.maxY))
                    context.stroke(division, with: .color(.white.opacity(0.4)), lineWidth: 0.4)
                }
            }
            let body = CGRect(x: center.x - 1.5, y: center.y - 3, width: 3, height: 6)
            context.fill(Path(roundedRect: body, cornerRadius: 1), with: .color(.white.opacity(0.85)))
            if event.kind == .station {
                let orbit = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
                context.stroke(Path(ellipseIn: orbit), with: .color(.white.opacity(0.3)), lineWidth: 0.4)
            }
        }
        .frame(width: event.size, height: event.size * 0.55)
        .shadow(color: .white.opacity(0.12), radius: 2)
    }
}
