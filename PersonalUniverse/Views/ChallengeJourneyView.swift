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
            SpaceBackground()
                .ignoresSafeArea()

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
        .sheet(item: $selectedDay) { day in
            dayReflectionView(for: day)
                .presentationDetents([.fraction(0.40)])
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
                .frame(width: 340, height: 340)

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
                guard activeEvent == .growth else {
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

    private func completeCurrentDay(_ day: ChallengeDay) {
        guard let currentDay = challenge.currentDay else {
            return
        }

        guard day.dayNumber == currentDay.dayNumber else {
            return
        }

        // -------------------------------------------------
        // Complete the day first.
        // -------------------------------------------------

        day.complete(at: .now)

        // -------------------------------------------------
        // Determine whether this was the final day.
        // -------------------------------------------------

        let isFinalDay = challenge.completedDayCount == challenge.days.count
        let event: UniverseEvent = isFinalDay ? .completion : .growth

        // -------------------------------------------------
        // For a normal day:
        //
        // Update the challenge immediately so that the
        // galaxy/progress is already grown when the
        // GrowthEventView appears.
        //
        // For the final day:
        //
        // Keep the challenge active until the completion
        // event has taken ownership of the screen.
        // -------------------------------------------------

        if !isFinalDay {
            challenge.updateCompletionStatus()
        }

        saveChanges()

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

    private func finalizeCompletedChallenge() {
        if challenge.status != .completed {
            challenge.status = .completed
        }

        saveChanges()
    }

    // MARK: - Completion → My Universe

    private func goToMyUniverse() {
        finalizeCompletedChallenge()

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
        finalizeCompletedChallenge()

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

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save PersonalUniverse changes: \(error)")
        }
    }
}

// MARK: - Navigation Notification

extension Notification.Name {
    static let openNewChallenge = Notification.Name("openNewChallenge")
}

// MARK: - Preview

#Preview("Challenge Journey") {
    let container = try! ModelContainer(
        for: UniverseChallenge.self,
        ChallengeDay.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = ModelContext(container)

    let challenge = UniverseChallenge(
        title: "Draw every day",
        length: .thirty,
        startDate: .now,
        galaxy: .expanding
    )

    context.insert(challenge)

    return NavigationStack {
        ChallengeJourneyView(challenge: challenge)
    }
    .modelContainer(container)
}
