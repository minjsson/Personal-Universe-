import SwiftUI

// Navigation stays flat; selection cards and recovery actions have separate roles.
struct UniverseNavigationButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundStyle(.white.opacity(isEnabled ? 0.8 : 0.3))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct UniverseNavigationArrow: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
    }
}

// Navigation arrows share the setup screen's quiet appearance and full tap area.
struct UniverseBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            UniverseNavigationArrow(symbol: UniverseSymbols.back)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(UniverseNavigationButtonStyle())
        .accessibilityLabel("Back")
    }
}

// The same quiet name-entry treatment is used when creating and editing a challenge.
struct UniverseNameFieldStyle: ViewModifier {
    var isFocused = false

    func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .tint(.white)
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.white.opacity(isFocused ? 0.4 : 0.2))
                    .frame(height: 1)
            }
    }
}

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

// Scale a fixed-coordinate drawing to the available space without clipping its edges.
struct UniverseArtwork<Content: View>: View {
    var designSize: CGFloat = 340
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let side = max(0, min(geometry.size.width, geometry.size.height, designSize))
            content()
                .frame(width: designSize, height: designSize)
                .scaleEffect(side / designSize)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
