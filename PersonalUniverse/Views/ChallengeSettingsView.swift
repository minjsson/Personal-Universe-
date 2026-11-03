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
                HStack {
                    Button("Cancel") {
                        if hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(.plain)
                    Spacer()
                    Button("Save", action: save)
                        .buttonStyle(UniverseButtonStyle(prominent: true))
                        .disabled(cleanTitle.isEmpty || !hasChanges)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                if let errorMessage {
                    UniverseNotice(title: "Unable to save", message: errorMessage, compact: true) {
                        Button("Try again", action: save)
                            .buttonStyle(UniverseButtonStyle(prominent: true))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }

                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 10) {
                            Text("Your challenge")
                                .font(.title2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("A name. A shape. The same journey.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.top, 22)

                        VStack(spacing: 12) {
                            sectionLabel("NAME")
                            TextField("Challenge name", text: $draftTitle, axis: .vertical)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white)
                                .tint(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineLimit(1...3)
                                .focused($editingTitle)
                                .submitLabel(.done)
                                .onSubmit { editingTitle = false }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
                                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(editingTitle ? 0.28 : 0.12), lineWidth: 0.7) }
                                .accessibilityLabel("Challenge name")
                        }

                        VStack(spacing: 16) {
                            sectionLabel("UNIVERSE")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                                ForEach(GalaxyStyle.allCases, id: \.self) { style in
                                    styleChoice(style)
                                }
                            }
                        }

                        Text("Your dates, progress and reflections stay with you.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .lineSpacing(3)
                            .multilineTextAlignment(.center)

                    }
                    .frame(maxWidth: 430)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
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
        .presentationDetents([.fraction(0.75), .large])
        .presentationBackground(.black)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.5))
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
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .background(.white.opacity(selected ? 0.05 : 0.015), in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(selected ? 0.3 : 0.07), lineWidth: 0.7) }
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
