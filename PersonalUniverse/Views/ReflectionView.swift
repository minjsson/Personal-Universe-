//
//  ReflectionView.swift
//  PersonalUniverse
//
//  Created by Minjae Son on 8/12/26.
//

import SwiftUI

struct ReflectionView: View {
    @Binding var reflection: String
    let onComplete: () -> Bool

    @State private var draftReflection: String
    @State private var saveErrorMessage: String?
    @State private var showDiscardConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(reflection: Binding<String>, onComplete: @escaping () -> Bool) {
        _reflection = reflection
        self.onComplete = onComplete
        _draftReflection = State(initialValue: reflection.wrappedValue)
    }

    private let characterLimit = 150

    // MARK: - Shared Layout

    private let horizontalPadding: CGFloat = 24
    private let topPadding: CGFloat = 52
    private let contentHeight: CGFloat = 180
    private let contentCornerRadius: CGFloat = 16
    private let bottomPadding: CGFloat = 18

    // MARK: - Animation State

    @State private var isCompleting = false
    @State private var showCompletionGlow = false

    // MARK: - Confirmation

    @State private var showCompletionConfirmation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top

                Spacer()
                    .frame(height: topPadding)

                // MARK: - Prompt

                Text("What did you discover today?")
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)

                // MARK: - Reflection Box

                TextEditor(text: $draftReflection)
                    .tint(.white.opacity(0.65))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .font(
                        .system(
                            size: 17,
                            weight: .regular
                        )
                    )
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .frame(height: contentHeight)
                    .background(
                        RoundedRectangle(
                            cornerRadius: contentCornerRadius
                        )
                        .fill(.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: contentCornerRadius
                        )
                        .stroke(
                            .white.opacity(0.15),
                            lineWidth: 1
                        )
                    )
                    .onChange(
                        of: draftReflection
                    ) {
                        limitReflection()
                    }

                // MARK: - Character Count

                HStack {
                    Spacer()

                    Text("\(draftReflection.count) / \(characterLimit)")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            draftReflection.count >= characterLimit
                            ? .white
                            : .white.opacity(0.5)
                        )
                }
                .frame(height: 20)
                .padding(.top, 6)

                // MARK: - Space Before Complete

                Spacer()
                    .frame(height: 16)

                // MARK: - Complete

                Button {
                    showCompletionConfirmation = true
                } label: {
                    sparkleView
                }
                .buttonStyle(.plain)
                .disabled(isCompleting)
                .accessibilityLabel("Complete reflection")
                .padding(.bottom, bottomPadding)
            }
            .padding(.horizontal, horizontalPadding)
        }

        .interactiveDismissDisabled(!draftReflection.isEmpty || isCompleting)
        .overlay(alignment: .topTrailing) {
            Button("Close") {
                if draftReflection.isEmpty { dismiss() }
                else { showDiscardConfirmation = true }
            }
            .padding()
            .foregroundStyle(.white)
            .disabled(isCompleting)
        }
        .confirmationDialog("Discard unfinished reflection?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep writing", role: .cancel) {}
        }
        .saveErrorNotice($saveErrorMessage)
        // MARK: - Completion Confirmation

        .alert(
            "Complete reflection?",
            isPresented: $showCompletionConfirmation
        ) {
            Button("Cancel", role: .cancel) {
                // Keep writing.
            }

            Button("Complete") {
                completeReflection()
            }
        } message: {
            Text(
                "Once completed, this reflection will be saved and cannot be edited."
            )
        }
    }

    // MARK: - Sparkle

    private var sparkleView: some View {
        Text("✦")
            .font(.system(size: 22))
            .foregroundStyle(.white)
            .frame(
                width: 44,
                height: 44
            )
            .scaleEffect(
                isCompleting ? 1.15 : 1
            )
            .shadow(
                color: showCompletionGlow
                    ? .white.opacity(0.8)
                    : .clear,
                radius: showCompletionGlow ? 12 : 0
            )
            .shadow(
                color: showCompletionGlow
                    ? .white.opacity(0.4)
                    : .clear,
                radius: showCompletionGlow ? 22 : 0
            )
    }

    // MARK: - Character Limit

    private func limitReflection() {
        guard draftReflection.count > characterLimit else {
            return
        }

        draftReflection = String(
            draftReflection.prefix(characterLimit)
        )
    }

    // MARK: - Complete

    private func completeReflection() {
        guard !isCompleting else {
            return
        }

        HapticManager.shared.light()

        withAnimation(
            .easeOut(duration: 0.18)
        ) {
            isCompleting = true
            showCompletionGlow = true
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.48
        ) {
            withAnimation(
                .easeOut(duration: 0.15)
            ) {
                showCompletionGlow = false
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.63
        ) {
            let original = reflection
            reflection = draftReflection
            if !onComplete() {
                isCompleting = false
                reflection = original
                saveErrorMessage = "Your reflection could not be saved. Your draft is still here. Please try again."
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReflectionView(
        reflection: .constant(""),
        onComplete: { true }
    )
}
