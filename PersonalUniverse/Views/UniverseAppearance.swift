import SwiftUI

// Shared treatment for quiet actions and recovery messages, not unrelated layout numbers.
struct UniverseButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(isEnabled ? 0.9 : 0.3))
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(.white.opacity(configuration.isPressed ? 0.13 : (prominent ? 0.08 : 0.025)), in: Capsule())
            .overlay { Capsule().strokeBorder(.white.opacity(isEnabled ? 0.18 : 0.07), lineWidth: 0.7) }
            .contentShape(Capsule())
    }
}

struct UniverseQuietBackground: View {
    var body: some View {
        ZStack {
            Color.black
            SpaceBackground(isAnimated: false)
                .opacity(0.35)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct UniverseNotice<Actions: View>: View {
    let title: String
    let message: String
    var compact = false
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: compact ? 14 : 24) {
            VStack(spacing: 10) {
                Text(title)
                    .font(compact ? .subheadline.weight(.medium) : .title2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            actions()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: 340)
        .accessibilityElement(children: .contain)
    }
}
