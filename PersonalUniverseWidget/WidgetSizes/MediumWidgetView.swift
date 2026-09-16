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
                // MARK: - Galaxy

                WidgetGalaxyView(universe: universe)
                    .frame(width: 170, height: 170)

                // MARK: - Information

                VStack(alignment: .leading, spacing: 10) {
                    Text(universe.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    // MARK: - Current Week

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
