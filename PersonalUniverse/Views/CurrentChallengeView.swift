//
//  CurrentChallengeView.swift
//  PersonalUniverse
//

import SwiftUI
import SwiftData

struct CurrentChallengeView: View {
    // MARK: - Environment

    @Bindable var challenge: UniverseChallenge

    @Environment(\.modelContext)
    private var modelContext

    // MARK: - Input

    let currentDate: Date
    let onDayCompleted: (UniverseEvent) -> Void

    // MARK: - State

    @State private var selectedDay: ChallengeDay?

    // MARK: - Calendar

    private var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SpaceBackground()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // MARK: Challenge Title

                Text(challenge.title)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // MARK: Current Week

                ChallengeProgressView(
                    challenge: challenge,
                    showCurrentWeekOnly: true
                ) { day in
                    handleDayTapped(day)
                }
                .padding(.horizontal, 24)

                Spacer()

                Color.clear
                    .frame(height: 24)
            }
            .frame(maxWidth: .infinity)
        }
        // MARK: Initial / Return Refresh

        .onAppear {
            refreshChallenge()
        }

        // MARK: Refresh when the app becomes active

        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )
        ) { _ in
            refreshChallenge()
        }

        // MARK: Reflection Sheet

        .sheet(item: $selectedDay) { day in
            dayReflectionView(for: day)
                .presentationDetents([.fraction(0.40)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.black)
        }
    }

    // MARK: - Refresh

    private func refreshChallenge() {
        // -------------------------------------------------
        // 1. Update the SwiftData challenge.
        //
        // This checks the current calendar date.
        // If it is a new day, previous unfinished days
        // are marked missed.
        // -------------------------------------------------

        challenge.updateMissedDays(calendar: calendar)

        // -------------------------------------------------
        // 2. Save the changed SwiftData state.
        // -------------------------------------------------

        saveChanges()

        // -------------------------------------------------
        // 3. Sync the EXISTING challenge to the widget.
        //
        // UniverseChallenge + ChallengeDay remain the
        // source of truth.
        // -------------------------------------------------

        if challenge.status == .active {
            WidgetSyncManager.save(challenge: challenge)
        } else {
            WidgetSyncManager.saveEmpty()
        }
    }

    // MARK: - Interaction

    private func handleDayTapped(_ day: ChallengeDay) {
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
        // -------------------------------------------------
        // 1. Make sure there is a current day.
        // -------------------------------------------------

        guard let currentDay = challenge.currentDay else {
            return
        }

        // -------------------------------------------------
        // 2. Make sure the selected day really is the
        //    current challenge day.
        // -------------------------------------------------

        guard day.dayNumber == currentDay.dayNumber else {
            return
        }

        // -------------------------------------------------
        // 3. Make sure this is TODAY.
        //
        // The app day is based on the calendar date.
        // Therefore 00:00 starts a new challenge day.
        // -------------------------------------------------

        guard let today = challenge.today else {
            return
        }

        guard today.dayNumber == day.dayNumber else {
            return
        }

        // -------------------------------------------------
        // 4. Complete the day.
        //
        // IMPORTANT:
        // Once completed, the day becomes .completed and
        // will NOT turn back into .today or .missed.
        // -------------------------------------------------

        challenge.completeDay(day, at: currentDate)

        // -------------------------------------------------
        // 5. Determine whether this was the final day.
        // -------------------------------------------------

        let isFinalDay = challenge.completedDayCount == challenge.days.count

        let event: UniverseEvent = isFinalDay
            ? .completion
            : .growth

        // -------------------------------------------------
        // 6. Update overall challenge status.
        // -------------------------------------------------

        challenge.updateCompletionStatus()

        // -------------------------------------------------
        // 7. Save SwiftData FIRST.
        // -------------------------------------------------

        saveChanges()

        // -------------------------------------------------
        // 8. Reschedule notifications AFTER the challenge
        //    state has been updated and saved.
        //
        //    Day 1 → completed
        //    Day 2 → upcoming
        //
        //    NotificationManager now sees Day 2 as the
        //    current day and schedules Day 2.
        // -------------------------------------------------

        Task { @MainActor in
            await NotificationManager.shared
                .rescheduleAfterCompletion(
                    for: challenge,
                    completedDayNumber: day.dayNumber
                )
        }

        // -------------------------------------------------
        // 9. Sync the UPDATED challenge to the widget.
        //
        // If Day 5 was completed:
        //
        // Day 5 -> completed
        // Day 6 -> today
        //
        // The widget receives the updated state immediately.
        //
        // If this was the final day:
        //
        // active challenge -> none
        // -------------------------------------------------

        if isFinalDay {
            WidgetSyncManager.saveEmpty()
        } else {
            WidgetSyncManager.save(challenge: challenge)
        }

        // -------------------------------------------------
        // 10. Close reflection sheet.
        // -------------------------------------------------

        selectedDay = nil

        // -------------------------------------------------
        // 11. Tell ContentView to show the appropriate
        //     universe event.
        // -------------------------------------------------

        DispatchQueue.main.async {
            onDayCompleted(event)
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

// MARK: - Preview

#Preview("Current Challenge") {
    NavigationStack {
        CurrentChallengeView(
            challenge: UniverseChallenge(
                title: "Draw every day",
                length: .thirty,
                startDate: .now
            ),
            currentDate: .now,
            onDayCompleted: { _ in }
        )
    }
    .modelContainer(
        for: [
            UniverseChallenge.self,
            ChallengeDay.self
        ],
        inMemory: true
    )
}
