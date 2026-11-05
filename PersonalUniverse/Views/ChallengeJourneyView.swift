//
//  ChallengeJourneyView.swift
//  PersonalUniverse
//

import SwiftUI
import SwiftData

struct ChallengeJourneyView: View {
    @Bindable var challenge: UniverseChallenge

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Reflection

    @State private var selectedDay: ChallengeDay?
    @State private var showSettings = false
    @State private var saveErrorMessage: String?

    // MARK: - Event State

    @State private var activeEvent: UniverseEvent = .none
    @State private var showCompletionActions = false

    // MARK: - Navigation

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Layout

    private let galaxyToProgressSpacing: CGFloat = 12
    private let contentTopPadding: CGFloat = 12
    private let contentBottomPadding: CGFloat = 40

    // MARK: - Body

    var body: some View {
        ZStack {
            SpaceSceneBackground()
                .ignoresSafeArea()
                .zIndex(-1)

            // -------------------------------------------------
            // Events belong to this ChallengeJourneyView when
            // the user is completing a reflection from
            // My Universe.
            //
            // This prevents ContentView from appearing as an
            // overlay behind the event.
            // -------------------------------------------------

            if activeEvent != .none {
                eventView
                    .transition(.opacity)
                    .zIndex(10)
            } else {
                journeyContent
                    .zIndex(0)
            }
        }
        .navigationTitle(challenge.title)
        .navigationBarTitleDisplayMode(.inline)
        // MARK: Lifecycle
        .onAppear {
            challenge.updateMissedDays()
            saveChanges()
        }
        // MARK: Reflection Sheet
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if activeEvent == .none {
                    Button("Edit") { showSettings = true }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit challenge")
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .sheet(isPresented: $showSettings) {
            ChallengeSettingsView(challenge: challenge)
        }
        .saveErrorNotice($saveErrorMessage)
        .sheet(item: $selectedDay) { day in
            dayReflectionView(for: day)
                .presentationDetents([.height(420), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.black)
        }
    }

    // MARK: - Journey Content

    @ViewBuilder
    private var journeyContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Galaxy

                GalaxyView(
                    style: challenge.galaxy,
                    progress: challenge.progress,
                    isCurrent: challenge.status == .active,
                    isAnimated: true,
                    revealProgress: challenge.progress
                )
                .frame(maxWidth: 340)
                .frame(maxWidth: .infinity)

                // MARK: Challenge Progress

                ChallengeProgressView(
                    challenge: challenge,
                    showCurrentWeekOnly: false
                ) { day in
                    handleDayTapped(day)
                }
                .padding(.horizontal, 24)
                .padding(.top, galaxyToProgressSpacing)
            }
            .padding(.top, contentTopPadding)
            .padding(.bottom, contentBottomPadding)
        }
    }

    // MARK: - Event View

    @ViewBuilder
    private var eventView: some View {
        switch activeEvent {
        case .none:
            EmptyView()

        case .growth:
            GrowthEventView(
                style: challenge.galaxy,
                progress: challenge.progress
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                finishGrowthEvent()
            }
            .task {
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled, activeEvent == .growth else {
                    return
                }
                await MainActor.run {
                    finishGrowthEvent()
                }
            }

        case .completion:
            CompletionEventView(
                style: challenge.galaxy,
                showActions: showCompletionActions,
                onReveal: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showCompletionActions = true
                    }
                },
                onMyUniverse: {
                    goToMyUniverse()
                },
                onNewChallenge: {
                    goToNewChallenge()
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Interaction

    private func handleDayTapped(_ day: ChallengeDay) {
        HapticManager.shared.light()
        selectedDay = day
    }

    // MARK: - Reflection

    @ViewBuilder
    private func dayReflectionView(for day: ChallengeDay) -> some View {
        let isCurrent = challenge.currentDay?.dayNumber == day.dayNumber

        if isCurrent && day.status == .upcoming {
            ReflectionView(
                reflection: Binding(
                    get: {
                        day.reflection
                    },
                    set: {
                        day.reflection = $0
                    }
                ),
                onComplete: {
                    completeCurrentDay(day)
                }
            )
        } else {
            ReflectionDetailView(day: day)
        }
    }

    // MARK: - Complete Day

    private func completeCurrentDay(_ day: ChallengeDay) -> Bool {
        guard day.status == .upcoming, day.challenge === challenge else { return false }
        guard let currentDay = challenge.currentDay else {
            return false
        }

        guard day.dayNumber == currentDay.dayNumber else {
            return false
        }

        // -------------------------------------------------
        // Complete the day first.
        // -------------------------------------------------

        challenge.completeDay(day, at: .now)

        // -------------------------------------------------
        // Determine whether this was the final day.
        // -------------------------------------------------

        let isFinalDay = challenge.completedDayCount == challenge.days.count
        let event: UniverseEvent = isFinalDay ? .completion : .growth

        // 완료 상태도 함께 저장한 뒤 이벤트를 시작합니다.
        challenge.updateCompletionStatus()

        guard saveChanges(reportError: false) else { return false }

        if isFinalDay {
            WidgetSyncManager.saveEmpty()
        } else {
            WidgetSyncManager.save(challenge: challenge)
        }
        Task { @MainActor in
            await NotificationManager.shared.rescheduleAfterCompletion(
                for: challenge, completedDayNumber: day.dayNumber
            )
        }

        // -------------------------------------------------
        // Close the reflection sheet FIRST.
        //
        // Do not show the event while the sheet is still
        // visible.
        // -------------------------------------------------

        selectedDay = nil

        // -------------------------------------------------
        // Start the event after the sheet has begun
        // dismissing.
        // -------------------------------------------------

        DispatchQueue.main.async {
            startEvent(event)
        }
        return true
    }

    // MARK: - Start Event

    private func startEvent(_ event: UniverseEvent) {
        showCompletionActions = false

        if event == .completion {
            HapticManager.shared.success()
        } else if event == .growth {
            HapticManager.shared.light()
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            activeEvent = event
        }
    }

    // MARK: - Growth Event

    private func finishGrowthEvent() {
        guard activeEvent == .growth else {
            return
        }

        withAnimation(.easeOut(duration: 0.35)) {
            activeEvent = .none
        }
    }

    // MARK: - Completion Event

    private func finalizeCompletedChallenge() -> Bool {
        if challenge.status != .completed {
            challenge.status = .completed
        }

        return saveChanges()
    }

    // MARK: - Completion → My Universe

    private func goToMyUniverse() {
        guard finalizeCompletedChallenge() else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            activeEvent = .none
            showCompletionActions = false
        }

        // -------------------------------------------------
        // ChallengeJourneyView is inside MyUniverseView's
        // navigation stack.
        //
        // Dismiss this journey first so the user returns
        // directly to My Universe.
        // -------------------------------------------------

        DispatchQueue.main.async {
            dismiss()
        }
    }

    // MARK: - Completion → New Challenge

    private func goToNewChallenge() {
        guard finalizeCompletedChallenge() else { return }

        withAnimation(.easeOut(duration: 0.25)) {
            activeEvent = .none
            showCompletionActions = false
        }

        // -------------------------------------------------
        // Return from ChallengeJourneyView first.
        //
        // Then open the new challenge screen.
        // -------------------------------------------------

        DispatchQueue.main.async {
            dismiss()

            DispatchQueue.main.async {
                // This notification allows the parent
                // navigation flow to open EnterChallengeView.
                NotificationCenter.default.post(
                    name: .openNewChallenge,
                    object: nil
                )
            }
        }
    }

    // MARK: - Save

    @discardableResult
    private func saveChanges(reportError: Bool = true) -> Bool {
        guard modelContext.hasChanges else { return true }
        do {
            try modelContext.saveWithRecoverySnapshot()
            return true
        } catch {
            modelContext.rollback()
            if reportError {
                saveErrorMessage = "Your changes could not be saved. Please try again."
            }
            return false
        }
    }
}

// MARK: - Navigation Notification

extension Notification.Name {
    static let openNewChallenge = Notification.Name("openNewChallenge")
}

// MARK: - Preview

#Preview("Challenge Journey") {
    if let container = try? ModelContainer(
        for: UniverseChallenge.self, ChallengeDay.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) {
        let context = container.mainContext
        let challenge = UniverseChallenge(
            title: "Draw every day", length: .thirty, startDate: .now, galaxy: .expanding
        )
        let _ = context.insert(challenge)
        NavigationStack { ChallengeJourneyView(challenge: challenge) }
            .modelContainer(container)
    } else {
        ContentUnavailableView("Preview storage unavailable", systemImage: "externaldrive.badge.exclamationmark")
    }
}
