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
            } else {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Create your universe")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Start a challenge")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(12)
            }
        }
    }
}
