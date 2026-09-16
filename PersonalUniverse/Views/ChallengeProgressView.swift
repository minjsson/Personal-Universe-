//
//  ChallengeProgressView.swift
//  PersonalUniverse
//

import SwiftUI
import SwiftData

struct ChallengeProgressView: View {
    let challenge: UniverseChallenge
    let showCurrentWeekOnly: Bool
    let onDayTapped: (ChallengeDay) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    // MARK: - Displayed Days

    private var displayedDays: [ChallengeDay] {
        let sortedDays = challenge.orderedDays

        // My Universe:
        // Show every day in the challenge.
        guard showCurrentWeekOnly else {
            return sortedDays
        }

        // Current Challenge:
        // Show only the week containing today.
        if let currentDay = challenge.currentDay {
            let currentDayNumber = currentDay.dayNumber
            let weekStart = ((currentDayNumber - 1) / 7) * 7 + 1
            let weekEnd = min(weekStart + 6, challenge.length.days)

            return sortedDays.filter {
                $0.dayNumber >= weekStart &&
                $0.dayNumber <= weekEnd
            }
        }

        // If the challenge is finished,
        // show its final week.
        let finalDay = challenge.length.days
        let weekStart = ((finalDay - 1) / 7) * 7 + 1

        return sortedDays.filter {
            $0.dayNumber >= weekStart &&
            $0.dayNumber <= finalDay
        }
    }

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(displayedDays) { day in
                Button {
                    onDayTapped(day)
                } label: {
                    Text(symbol(for: day))
                        .font(.system(size: isCurrent(day) ? 23 : 17))
                        .foregroundStyle(color(for: day))
                        .frame(width: 38, height: 38)
                        .scaleEffect(isCurrent(day) ? 1.15 : 1)
                        .shadow(
                            color: isCurrent(day) ? .white.opacity(0.8) : .clear,
                            radius: isCurrent(day) ? 9 : 0
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canTap(day))
            }
        }
    }

    // MARK: - Current

    private func isCurrent(_ day: ChallengeDay) -> Bool {
        challenge.currentDay?.dayNumber == day.dayNumber
    }

    // MARK: - Interaction

    private func canTap(_ day: ChallengeDay) -> Bool {
        // Today can be opened.
        if isCurrent(day) {
            return true
        }
        // Completed and missed days can be inspected.
        if day.status == .completed || day.status == .missed {
            return true
        }
        // Upcoming days can be inspected.
        return day.status == .upcoming
    }

    // MARK: - Symbol

    private func symbol(for day: ChallengeDay) -> String {
        switch day.status {
        case .completed:
            return "✦"
        case .missed:
            return "●"
        case .upcoming:
            return "○"
        }
    }

    // MARK: - Color

    private func color(for day: ChallengeDay) -> Color {
        switch day.status {
        case .completed:
            return .white
        case .missed:
            return .white.opacity(0.85)
        case .upcoming:
            if isCurrent(day) {
                return .white
            }
            return .white.opacity(0.65)
        }
    }
}

// MARK: - Preview

#Preview("Current Challenge") {
    let challenge = UniverseChallenge(
        title: "Draw every day",
        length: .thirty,
        startDate: .now
    )

    ChallengeProgressView(
        challenge: challenge,
        showCurrentWeekOnly: true,
        onDayTapped: { day in
            print("Tapped day: \(day.dayNumber)")
        }
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 40)
    .background(.black)
}

#Preview("Full Challenge") {
    let challenge = UniverseChallenge(
        title: "Draw every day",
        length: .thirty,
        startDate: .now
    )

    ChallengeProgressView(
        challenge: challenge,
        showCurrentWeekOnly: false,
        onDayTapped: { day in
            print("Tapped day: \(day.dayNumber)")
        }
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 40)
    .background(.black)
}
