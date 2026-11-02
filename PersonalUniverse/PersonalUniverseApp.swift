import SwiftUI
import SwiftData

@main
struct PersonalUniverseApp: App {
    var body: some Scene {
        WindowGroup {
            DatabaseRootView()
        }
    }
}

// 저장소를 열지 못해도 기존 파일을 지우지 않고 재시도할 수 있습니다.
struct DatabaseRootView: View {
    @State private var store = PersistentStoreLoader()

    var body: some View {
        Group {
            if let container = store.container {
                ContentView()
                    .modelContainer(container)
            } else {
                ContentUnavailableView {
                    Label("Unable to open your universe", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(store.errorMessage ?? "Opening your saved challenges…")
                } actions: {
                    if store.isLoading {
                        ProgressView()
                    } else {
                        Button("Try again", action: store.open)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .task { store.open() }
    }

}
