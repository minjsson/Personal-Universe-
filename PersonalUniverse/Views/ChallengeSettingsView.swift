import SwiftUI
import SwiftData

struct ChallengeSettingsView: View {
    let challenge: UniverseChallenge
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var draftTitle: String
    @State private var draftGalaxy: GalaxyStyle
    @State private var errorMessage: String?
    @FocusState private var editingTitle: Bool
    @ScaledMetric(relativeTo: .footnote) private var styleMinimumWidth: CGFloat = 84
    @State private var contentHeight: CGFloat = 280

    init(challenge: UniverseChallenge) {
        self.challenge = challenge
        _draftTitle = State(initialValue: challenge.title)
        _draftGalaxy = State(initialValue: challenge.galaxy)
    }

    private var cleanTitle: String { draftTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasChanges: Bool { cleanTitle != challenge.title || draftGalaxy != challenge.galaxy }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 8) {
                        sectionLabel("Name")
                        TextField("Challenge name", text: $draftTitle)
                            .lineLimit(1)
                            .focused($editingTitle)
                            .submitLabel(.done)
                            .onSubmit { editingTitle = false }
                            .modifier(UniverseNameFieldStyle(isFocused: editingTitle))
                            .accessibilityLabel("Challenge name")
                    }

                    VStack(spacing: 12) {
                        sectionLabel("Galaxy style")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: styleMinimumWidth), spacing: 10)], spacing: 10) {
                            ForEach(GalaxyStyle.allCases, id: \.self) { style in
                                styleChoice(style)
                            }
                        }
                    }

                    Text("Dates, progress and reflections stay the same.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage {
                        UniverseNotice(title: "Unable to save", message: errorMessage, compact: true) {
                            EmptyView()
                        }
                        .frame(maxWidth: .infinity)
                    }

                    saveButton
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: 430)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: draftTitle) { errorMessage = nil }
        .onChange(of: draftGalaxy) { errorMessage = nil }
        .presentationDetents([.height(max(280, contentHeight))])
        .presentationBackground(.black)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("✦")
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(cleanTitle.isEmpty || !hasChanges ? 0.3 : 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save challenge changes")
        .disabled(cleanTitle.isEmpty || !hasChanges)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.55))
    }

    private func styleChoice(_ style: GalaxyStyle) -> some View {
        let selected = draftGalaxy == style
        return Button {
            editingTitle = false
            draftGalaxy = style
        } label: {
            VStack(spacing: 6) {
                GalaxyView(style: style, progress: 1, isCurrent: selected, isAnimated: false)
                    .frame(width: 76, height: 76)
                    .accessibilityHidden(true)
                Text(style.name)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(selected ? 0.9 : 0.55))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .background(.white.opacity(selected ? 0.025 : 0), in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(selected ? 0.45 : 0.08), lineWidth: selected ? 1 : 0.7) }

        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.name)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func save() {
        editingTitle = false
        do {
            try ChallengeMetadataEditor.save(
                challenge: challenge, title: draftTitle, galaxy: draftGalaxy,
                persist: { try context.saveWithRecoverySnapshot() }
            )
            if challenge.status == .active {
                WidgetSyncManager.save(challenge: challenge)
                Task { @MainActor in
                    await NotificationManager.shared.scheduleCurrentReminder(for: challenge)
                }
            }
            dismiss()
        } catch {
            errorMessage = "Your changes could not be saved. Your draft is still here. Please try again."
        }
    }
}
