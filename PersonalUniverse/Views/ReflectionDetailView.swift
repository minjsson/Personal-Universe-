//
//  ReflectionDetailView.swift
//  PersonalUniverse
//
//  Created by Minjae Son on 8/14/26.
//

import SwiftUI

struct ReflectionDetailView: View {
    let day: ChallengeDay

    // MARK: - Shared Layout

    private let horizontalPadding: CGFloat = 24
    private let topPadding: CGFloat = 24
    private let bottomPadding: CGFloat = 24

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top

                Spacer()
                    .frame(height: topPadding)

                // MARK: - Content

                detailContent
                    .frame(maxWidth: .infinity)

                // MARK: - Bottom

                Spacer(minLength: 0)

                if day.status == .completed {
                    completionDate
                        .padding(.bottom, bottomPadding)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch day.status {
        case .completed:
            if day.hasReflection {
                savedReflectionContent
            } else {
                emptyContent(
                    title: "Day completed.",
                    subtitle: "No reflection was written."
                )
            }

        case .missed:
            emptyContent(
                title: "Nothing was recorded.",
                subtitle: "This day was left behind."
            )

        case .upcoming:
            emptyContent(
                title: "Nothing here yet.",
                subtitle: "This day has not arrived."
            )
        }
    }

    // MARK: - Saved Reflection

    private var savedReflectionContent: some View {
        ScrollView {
            Text(day.reflection)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 320)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty Content

    private func emptyContent(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Completion Date

    private var completionDate: some View {
        Group {
            if let completedAt = day.completedAt {
                Text(
                    completedAt.formatted(
                        .dateTime
                            .month(.abbreviated)
                            .day()
                            .year()
                    )
                )
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - Preview

#Preview("Completed With Reflection") {
    ReflectionDetailView(
        day: ChallengeDay(
            dayNumber: 1,
            status: .completed,
            reflection: "Today I noticed that drawing became easier once I stopped trying to make it perfect."
        )
    )
}

#Preview("Completed Without Reflection") {
    ReflectionDetailView(
        day: ChallengeDay(
            dayNumber: 2,
            status: .completed
        )
    )
}

#Preview("Missed") {
    ReflectionDetailView(
        day: ChallengeDay(
            dayNumber: 3,
            status: .missed
        )
    )
}

#Preview("Upcoming") {
    ReflectionDetailView(
        day: ChallengeDay(
            dayNumber: 4,
            status: .upcoming
        )
    )
}
