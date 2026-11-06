import SwiftUI

// Acknowledge the failed operation without implying that dismissal retries a save.
struct SaveErrorModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            ZStack {
                UniverseQuietBackground()
                ScrollView {
                    UniverseNotice(title: "Unable to save", message: message ?? "Please try again.") {
                        Button("Got it") { message = nil }
                            .buttonStyle(UniverseButtonStyle(prominent: true))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 40)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.black)
            .preferredColorScheme(.dark)
        }
    }
}

extension View {
    func saveErrorNotice(_ message: Binding<String?>) -> some View {
        modifier(SaveErrorModifier(message: message))
    }
}
