//
//  SmallWidgetView.swift
//  PersonalUniverseWidget
//

import SwiftUI

struct SmallWidgetView: View {
    let universe: WidgetUniverseData

    var body: some View {
        ZStack {
            if universe.hasActiveChallenge {
                WidgetGalaxyView(universe: universe)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(2)

                if let currentDayNumber = universe.currentDayNumber {
                    VStack {
                        Spacer()

                        Text("DAY \(String(format: "%02d", currentDayNumber))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.8), radius: 4)
                    }
                    .padding(.bottom, 6)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Start a Challenge")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}

#Preview("Small - Active") {
    SmallWidgetView(universe: .previewActive)
        .frame(width: 155, height: 155)
        .background(.black)
}

#Preview("Small - Empty") {
    SmallWidgetView(universe: .empty)
        .frame(width: 155, height: 155)
        .background(.black)
}
