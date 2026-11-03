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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var contentHeight: CGFloat = 330
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
                VStack(spacing: 0) {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 8) {
                            Text("Edit challenge").font(.headline)
                            HStack { cancelButton; Spacer(); saveButton }
                        }
                    } else {
                        HStack(spacing: 8) {
                            cancelButton.frame(width: 72)
                            Text("Edit challenge")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                            saveButton.frame(width: 72)
                        }
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
                .padding(.top, 20)
                .padding(.bottom, 20)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("Challenge name")
                            TextField("Challenge name", text: $draftTitle, axis: .vertical)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                                .tint(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .lineLimit(1...3)
                                .focused($editingTitle)
                                .submitLabel(.done)
                                .onSubmit { editingTitle = false }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
                                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(editingTitle ? 0.28 : 0.12), lineWidth: 0.7) }
                                .accessibilityLabel("Challenge name")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Universe appearance")
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                                ForEach(GalaxyStyle.allCases, id: \.self) { style in
                                    styleChoice(style)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Only the name and appearance change.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("Your dates, progress and reflections are preserved.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .lineSpacing(3)
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
        .presentationDetents([.height(max(340, headerHeight + contentHeight + 20)), .large])
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
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .background(.white.opacity(selected ? 0.05 : 0.015), in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(selected ? 0.55 : 0.13), lineWidth: selected ? 1 : 0.7) }
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black, .white.opacity(0.9))
                        .padding(8)
                        .accessibilityHidden(true)
                }
            }
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
