import SwiftUI
import SwiftData

struct ChallengeSettingsView: View {
    let challenge: UniverseChallenge
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var draftTitle: String
    @State private var draftGalaxy: GalaxyStyle
    @State private var errorMessage: String?

    init(challenge: UniverseChallenge) {
        self.challenge = challenge
        _draftTitle = State(initialValue: challenge.title)
        _draftGalaxy = State(initialValue: challenge.galaxy)
    }

    private var cleanTitle: String {
        draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Challenge") {
                    TextField("Title", text: $draftTitle)
                    Picker("Universe style", selection: $draftGalaxy) {
                        ForEach(GalaxyStyle.allCases, id: \.self) { style in
                            Text(style.name).tag(style)
                        }
                    }
                }
                Section {
                    GalaxyView(style: draftGalaxy, progress: challenge.progress,
                               isCurrent: challenge.status == .active, isAnimated: false,
                               revealProgress: challenge.progress)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.black)
                } footer: {
                    Text("Editing the title or universe style keeps your dates, progress and reflections.")
                }
            }
            .navigationTitle("Challenge settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(cleanTitle.isEmpty)
                }
            }
            .saveErrorAlert($errorMessage)
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        do {
            try ChallengeMetadataEditor.save(
                challenge: challenge, title: draftTitle, galaxy: draftGalaxy,
                persist: { try context.saveWithRecoverySnapshot() }
            )
            // 저장된 데이터만 위젯과 알림에 반영합니다.
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
