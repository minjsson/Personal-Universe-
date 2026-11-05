import SwiftUI
import SwiftData

struct ChallengeSettingsView: View {
    let challenge: UniverseChallenge
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var draftTitle: String
    @State private var draftGalaxy: GalaxyStyle
    @State private var errorMessage: String?
    @State private var confirmDiscard = false
    @FocusState private var editingTitle: Bool
    @ScaledMetric(relativeTo: .footnote) private var styleMinimumWidth: CGFloat = 84
    @State private var contentHeight: CGFloat = 280
    @State private var headerHeight: CGFloat = 64

    init(challenge: UniverseChallenge) {
        self.challenge = challenge
        _draftTitle = State(initialValue: challenge.title)
        _draftGalaxy = State(initialValue: challenge.galaxy)
    }

    private var cleanTitle: String { draftTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasChanges: Bool { cleanTitle != challenge.title || draftGalaxy != challenge.galaxy }

    var body: some View {
        ZStack {
            UniverseQuietBackground()
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        cancelButton
                        Spacer(minLength: 24)
                        saveButton
                    }
                    if let errorMessage {
                        UniverseNotice(title: "Unable to save", message: errorMessage, compact: true) {
                            Button("Try again", action: save)
                                .buttonStyle(UniverseButtonStyle(prominent: true))
                        }
                        .padding(.top, 16)
                    }
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Name")
                            TextField("Challenge name", text: $draftTitle)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                                .tint(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                                .focused($editingTitle)
                                .submitLabel(.done)
                                .onSubmit { editingTitle = false }
                                .padding(.vertical, 14)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(.white.opacity(editingTitle ? 0.5 : 0.2))
                                        .frame(height: 1)
                                }
                                .accessibilityLabel("Challenge name")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Galaxy style")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: styleMinimumWidth), spacing: 10)], spacing: 10) {
                                ForEach(GalaxyStyle.allCases, id: \.self) { style in
                                    styleChoice(style)
                                }
                            }
                        }

                        Text("Dates, progress and reflections stay the same.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)

                    }
                    .frame(maxWidth: 430)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onChange(of: draftTitle) { errorMessage = nil }
        .onChange(of: draftGalaxy) { errorMessage = nil }
        .interactiveDismissDisabled(hasChanges)
        .confirmationDialog("Discard these changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        }
        .presentationDetents([.height(max(300, headerHeight + contentHeight + 12)), .large])
        .presentationBackground(.black)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var cancelButton: some View {
        Button("Cancel") {
            if hasChanges { confirmDiscard = true } else { dismiss() }
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.7))
        .frame(minHeight: 44)
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button("Save", action: save)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(cleanTitle.isEmpty || !hasChanges ? 0.3 : 0.95))
            .frame(minHeight: 44)
            .buttonStyle(.plain)
            .disabled(cleanTitle.isEmpty || !hasChanges)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.7))
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
            .background(.white.opacity(selected ? 0.075 : 0.015), in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(selected ? 0.55 : 0.13), lineWidth: selected ? 1 : 0.7) }

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
