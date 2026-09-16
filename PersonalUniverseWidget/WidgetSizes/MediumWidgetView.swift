//
//  MediumWidgetView.swift
//  PersonalUniverseWidget
//

import SwiftUI

struct MediumWidgetView: View {
    let universe: WidgetUniverseData

    var body: some View {
        if universe.hasActiveChallenge {
            HStack(spacing: 8) {
                // 은하
                WidgetGalaxyView(universe: universe)
                    .frame(width: 140, height: 140)

                // 정보
                VStack(alignment: .leading, spacing: 10) {
                    Text(universe.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if let currentDayNumber = universe.currentDayNumber {
                        Text("DAY \(String(format: "%02d", currentDayNumber))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    // 현재 주
                    WidgetProgressSymbols(
                        universe: universe,
                        showCurrentWeekOnly: true
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(12)
        } else {
            VStack(alignment: .center, spacing: 6) {
                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Your universe is waiting.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("Start a challenge to begin.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(14)
        }
    }
}

#Preview("Medium - Active") {
    MediumWidgetView(universe: .previewActive)
        .frame(width: 329, height: 155)
        .background(.black)
}

#Preview("Medium - Empty") {
    MediumWidgetView(universe: .empty)
        .frame(width: 329, height: 155)
        .background(.black)
}
