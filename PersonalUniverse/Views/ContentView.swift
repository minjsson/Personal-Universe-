//
//  ContentView.swift
//  PersonalUniverse
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.scenePhase)
    private var scenePhase

    // MARK: - Data

    @Query(
        sort: \UniverseChallenge.startDate
    )
    private var challenges: [UniverseChallenge]

    // MARK: - Refresh

    @State private var refreshDate = Date()

    // MARK: - Event State

    @State private var activeEvent: UniverseEvent = .none
    @State private var eventChallenge: UniverseChallenge?
    @State private var showCompletionActions = false

    // MARK: - Navigation

    private enum Route: Hashable {
        case myUniverse
        case newChallenge
    }

    @State private var navigationPath = NavigationPath()

    // MARK: - Current Challenge

    private var currentChallenge: UniverseChallenge? {
        challenges.first {
            $0.status == .active
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(
            path: $navigationPath
        ) {
            ZStack {
                // MARK: Background

                SpaceBackground()
                    .ignoresSafeArea()

                // MARK: Main Content

                if activeEvent != .none {
                    eventView
                        .transition(.opacity)
                        .zIndex(10)
                } else if let challenge = currentChallenge {
                    CurrentChallengeView(
                        challenge: challenge,
                        currentDate: refreshDate,
                        onDayCompleted: { event in
                            eventChallenge = challenge
                            showCompletionActions = false
                            DispatchQueue.main.async {
                                withAnimation(
                                    .easeInOut(duration: 0.35)
                                ) {
                                    activeEvent = event
                                }
                            }
                        }
                    )
                } else {
                    emptyView
                }
            }
            // MARK: Navigation Bar

            .toolbar {
                if activeEvent == .none {
                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        Button {
                            navigationPath.append(
                                Route.myUniverse
                            )
                        } label: {
                            Text("My Universe")
                                .font(.subheadline)
                                .foregroundStyle(
                                    .white.opacity(0.7)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            // MARK: Navigation Destinations

            .navigationDestination(
                for: Route.self
            ) { route in
                switch route {
                case .myUniverse:
                    MyUniverseView()
                case .newChallenge:
                    EnterChallengeView()
                }
            }
        }
        // MARK: Lifecycle

        .onAppear {
            refreshCurrentChallenge()
            refreshNotifications()
        }
        .onChange(
            of: scenePhase
        ) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            // Returning from background may mean
            // that midnight has passed.
            refreshCurrentChallenge()
            refreshNotifications()
        }
        // MARK: Periodic Refresh

        .task {
            while !Task.isCancelled {
                try? await Task.sleep(
                    for: .seconds(60)
                )

                guard !Task.isCancelled else {
                    return
                }

                refreshCurrentChallenge()
                refreshNotifications()
            }
        }
    }

    // MARK: - Event View

    @ViewBuilder
    private var eventView: some View {
        if let challenge = eventChallenge {
            switch activeEvent {
            case .none:
                EmptyView()

            // MARK: Growth

            case .growth:
                GrowthEventView(
                    style: challenge.galaxy,
                    progress: challenge.progress
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    finishGrowthEvent()
                }
                .task {
                    try? await Task.sleep(
                        for: .seconds(2.5)
                    )

                    guard activeEvent == .growth else {
                        return
                    }

                    await MainActor.run {
                        finishGrowthEvent()
                    }
                }

            // MARK: Completion

            case .completion:
                CompletionEventView(
                    style: challenge.galaxy,
                    showActions: showCompletionActions,
                    onReveal: {
                        withAnimation(
                            .easeInOut(duration: 0.45)
                        ) {
                            showCompletionActions = true
                        }
                    },
                    onMyUniverse: {
                        visitMyUniverse()
                    },
                    onNewChallenge: {
                        createNewChallenge()
                    }
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
        }
    }

    // MARK: - Growth Event

    private func finishGrowthEvent() {
        guard activeEvent == .growth else {
            return
        }

        withAnimation(
            .easeOut(duration: 0.35)
        ) {
            activeEvent = .none
        }

        DispatchQueue.main.async {
            eventChallenge = nil
        }
    }

    // MARK: - Completion → My Universe

    private func visitMyUniverse() {
        guard let challenge = eventChallenge else {
            return
        }

        challenge.updateCompletionStatus()

        // Only completed challenges get a permanent
        // galaxy position.
        guard challenge.status == .completed else {
            return
        }

        if challenge.universeX == nil ||
            challenge.universeY == nil {
            assignUniversePosition(
                to: challenge
            )
        }

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to save completed challenge: \(error)"
            )
        }

        // The challenge is no longer active.
        // Clear the widget's active challenge.
        WidgetSyncManager.saveEmpty()

        withAnimation(
            .easeOut(duration: 0.25)
        ) {
            activeEvent = .none
            showCompletionActions = false
        }

        DispatchQueue.main.async {
            eventChallenge = nil
            navigationPath.append(
                Route.myUniverse
            )
        }
    }

    // MARK: - Assign Completed Galaxy Position

    private func assignUniversePosition(
        to challenge: UniverseChallenge
    ) {
        let completedChallenges = challenges.filter {
            $0.status == .completed &&
            $0.id != challenge.id
        }

        var occupied: [(Double, Double)] = []

        for existing in completedChallenges {
            if let x = existing.universeX,
               let y = existing.universeY {
                occupied.append(
                    (x, y)
                )
            }
        }

        let minimumRadius: CGFloat = 230
        let maximumRadius: CGFloat = 430
        let minimumDistance: CGFloat = 175

        for _ in 0..<500 {
            let angle = CGFloat.random(
                in: 0...(2 * .pi)
            )
            let radius = CGFloat.random(
                in: minimumRadius...maximumRadius
            )
            let x = cos(angle) * radius
            let y = sin(angle) * radius

            let isFarEnough = occupied.allSatisfy {
                existingX,
                existingY in
                let dx = x - CGFloat(existingX)
                let dy = y - CGFloat(existingY)
                let distance = sqrt(
                    dx * dx +
                    dy * dy
                )

                return distance >= minimumDistance
            }

            guard isFarEnough else {
                continue
            }

            challenge.universeX = Double(x)
            challenge.universeY = Double(y)
            return
        }

        // MARK: Fallback

        let angle = CGFloat.random(
            in: 0...(2 * .pi)
        )

        challenge.universeX = Double(
            cos(angle) * maximumRadius
        )
        challenge.universeY = Double(
            sin(angle) * maximumRadius
        )
    }

    // MARK: - Completion → New Challenge

    private func createNewChallenge() {
        withAnimation(
            .easeOut(duration: 0.25)
        ) {
            activeEvent = .none
            showCompletionActions = false
        }

        DispatchQueue.main.async {
            eventChallenge = nil
            navigationPath.append(
                Route.newChallenge
            )
        }
    }

    // MARK: - Refresh

    private func refreshCurrentChallenge() {
        refreshDate = Date()

        // -------------------------------------------------
        // Find the EXISTING active challenge.
        // -------------------------------------------------

        guard let challenge = currentChallenge else {
            // There is no active challenge.
            WidgetSyncManager.saveEmpty()
            return
        }

        // -------------------------------------------------
        // 1. Update missed days.
        // -------------------------------------------------

        challenge.updateMissedDays(
            calendar: Calendar.autoupdatingCurrent
        )

        // -------------------------------------------------
        // 2. Save SwiftData.
        // -------------------------------------------------

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to save PersonalUniverse changes: \(error)"
            )
        }

        // -------------------------------------------------
        // 3. IMPORTANT:
        //
        // Sync the EXISTING active challenge to the widget.
        //
        // This happens whenever ContentView appears,
        // becomes active, or refreshes.
        // -------------------------------------------------

        if challenge.status == .active {
            WidgetSyncManager.save(
                challenge: challenge
            )
        } else {
            WidgetSyncManager.saveEmpty()
        }
    }

    private func refreshNotifications() {
        guard let challenge = currentChallenge else {
            return
        }

        guard challenge.reminderEnabled else {
            return
        }

        Task { @MainActor in
            let granted =
                await NotificationManager.shared
                    .requestPermission()

            guard granted else {
                return
            }

            await NotificationManager.shared
                .scheduleCurrentReminder(
                    for: challenge
                )
        }
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text(
                    "Every universe begins somewhere."
                )
                .font(.title2)
                .foregroundStyle(.white)

                Text(
                    "Start with one thing.\nLet time shape the rest."
                )
                .font(.body)
                .foregroundStyle(
                    .white.opacity(0.4)
                )
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .overlay(alignment: .bottom) {
            Button {
                navigationPath.append(
                    Route.newChallenge
                )
            } label: {
                Text("Begin")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(
                        minWidth: 100,
                        minHeight: 44
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Preview

#Preview("Empty") {
    ContentView()
        .modelContainer(
            for: [
                UniverseChallenge.self,
                ChallengeDay.self
            ],
            inMemory: true
        )
}
