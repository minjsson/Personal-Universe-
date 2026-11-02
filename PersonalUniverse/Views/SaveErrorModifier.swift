import SwiftUI

// 저장 오류 표시를 재사용하되 각 화면이 오류 상태를 소유합니다.
struct SaveErrorModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.alert("Unable to save", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "Please try again.")
        }
    }
}

extension View {
    func saveErrorAlert(_ message: Binding<String?>) -> some View {
        modifier(SaveErrorModifier(message: message))
    }
}
