//
//  LargeWidgetView.swift
//  PersonalUniverseWidget
//

import SwiftUI

struct LargeWidgetView: View {
    let universe: WidgetUniverseData

    var body: some View {
        if universe.hasActiveChallenge {
            VStack(spacing: 12) {
                // MARK: - Header

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(universe.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer()
                }

                // MARK: - Progress Symbols

                WidgetProgressSymbols(
                    universe: universe,
                    showCurrentWeekOnly: false
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
        } else {
            VStack(spacing: 12) {
                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Your universe is waiting.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)

                Text("Start a challenge to grow a new galaxy.")
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()
            }
            .padding(20)
        }
    }
}
