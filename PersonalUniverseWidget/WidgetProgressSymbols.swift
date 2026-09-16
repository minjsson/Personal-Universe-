//
//  WidgetProgressSymbols.swift
//  PersonalUniverseWidget
//

import SwiftUI

struct WidgetProgressSymbols: View {
    let universe: WidgetUniverseData
    let showCurrentWeekOnly: Bool

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 7
    )

    // MARK: - Current Day

    private var currentDayNumber: Int? {
        universe.currentDayNumber
    }

    // MARK: - Displayed Days

    private var displayedDays: [WidgetDayData] {
        let sortedDays = universe.days.sorted { $0.dayNumber < $1.dayNumber }

        guard showCurrentWeekOnly else {
            return sortedDays
        }

        // ---------------------------------------------------------
        // Current Week
        // ---------------------------------------------------------
        //
        // Row selection is based ONLY on the current challenge day.
        //
        // Day 1 ~ 7
        // → Days 1 ~ 7
        //
        // Day 8 ~ 14
        // → Days 8 ~ 14
        //
        // Day 15 ~ 21
        // → Days 15 ~ 21
        //
        // Completion state does NOT decide the row.
        //
        // ---------------------------------------------------------

        if let currentDayNumber {
            let weekStart = ((currentDayNumber - 1) / 7) * 7 + 1
            let weekEnd = weekStart + 6

            return sortedDays.filter {
                $0.dayNumber >= weekStart && $0.dayNumber <= weekEnd
            }
        }

        // ---------------------------------------------------------
        // No Current Day
        // ---------------------------------------------------------
        //
        // This happens when the challenge has no remaining
        // upcoming day, such as after the final day is completed.
        //
        // In that case, show the final row.
        //
        // ---------------------------------------------------------

        guard let finalDay = sortedDays.last else {
            return []
        }

        let weekStart = ((finalDay.dayNumber - 1) / 7) * 7 + 1

        return sortedDays.filter {
            $0.dayNumber >= weekStart && $0.dayNumber <= finalDay.dayNumber
        }
    }

    // MARK: - Body

    var body: some View {
        LazyVGrid(
            columns: columns,
            spacing: showCurrentWeekOnly ? 3 : 5
        ) {
            ForEach(displayedDays) { day in
                Text(symbol(for: day))
                    .font(
                        .system(
                            size: isCurrentDay(day) ? symbolSize * 1.18 : symbolSize,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        isCurrentDay(day)
                            ? .white
                            : color(for: day)
                    )
                    .frame(
                        width: symbolFrame,
                        height: symbolFrame
                    )
                    .shadow(
                        color: isCurrentDay(day)
                            ? .white.opacity(0.95)
                            : .clear,
                        radius: isCurrentDay(day) ? 5 : 0
                    )
                    .shadow(
                        color: isCurrentDay(day)
                            ? .white.opacity(0.55)
                            : .clear,
                        radius: isCurrentDay(day) ? 9 : 0
                    )
            }
        }
    }

    // MARK: - Current Day Check

    private func isCurrentDay(_ day: WidgetDayData) -> Bool {
        guard let currentDayNumber else {
            return false
        }

        return day.dayNumber == currentDayNumber
    }

    // MARK: - Symbol

    private func symbol(for day: WidgetDayData) -> String {
        switch day.state {
        case .completed:
            return "✦"
        case .missed:
            return "●"
        case .upcoming:
            return "○"
        }
    }

    // MARK: - Color

    private func color(for day: WidgetDayData) -> Color {
        switch day.state {
        case .completed:
            return .white
        case .missed:
            return .white.opacity(0.85)
        case .upcoming:
            return .white.opacity(0.55)
        }
    }

    // MARK: - Size

    private var symbolSize: CGFloat {
        if showCurrentWeekOnly {
            return 14
        }

        switch universe.days.count {
        case 0...14:
            return 20
        case 15...30:
            return 17
        case 31...50:
            return 14
        default:
            return 11
        }
    }

    private var symbolFrame: CGFloat {
        if showCurrentWeekOnly {
            return 21
        }

        switch universe.days.count {
        case 0...14:
            return 26
        case 15...30:
            return 23
        case 31...50:
            return 19
        default:
            return 16
        }
    }
}
