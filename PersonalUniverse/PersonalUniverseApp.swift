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
    @State private var confirmRestore = false
    @Environment(\.openURL) private var openURL
    @State private var ambientScene = AmbientSpaceScene()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var animateAmbience: Bool {
        store.container != nil && scenePhase == .active && !reduceMotion
    }

    var body: some View {
        VStack(spacing: 0) {
            databaseContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if store.container != nil { recoveryNotice }
        }
        .confirmationDialog("Restore the last verified backup?", isPresented: $confirmRestore, titleVisibility: .visible) {
            Button("Restore backup", role: .destructive) { Task { await store.restoreBackup() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Changes after the backup date may be missing. The current database files will be preserved separately before restoring. This does not repair an incompatible app version.")
        }
        .environment(\.ambientSpaceScene, ambientScene)
        .preferredColorScheme(.dark)
        .task(id: animateAmbience) {
            await ambientScene.run(enabled: animateAmbience)
        }
        .onReceive(NotificationCenter.default.publisher(for: .universeDidSave)) { _ in
            Task { await store.updateBackup() }
        }
        .task { store.open(); await store.updateBackup() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { Task { await store.updateBackup() } }
        }
    }

    @ViewBuilder
    private var databaseContent: some View {
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
                        if store.errorMessage != nil && store.backupDate == nil {
                            Text("No recovery backup is available yet. Your existing database has not been reset.")
                                .font(.footnote)
                        }
                        if let date = store.backupDate {
                            Button("Restore backup from \(date.formatted(date: .abbreviated, time: .shortened))") {
                                confirmRestore = true
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var recoveryNotice: some View {
        let notifications = NotificationManager.shared
        let widget = WidgetSyncManager.status
        let messages = [store.backupError, notifications.errorMessage, widget.errorMessage].compactMap { $0 }
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(messages, id: \.self) { Text($0).font(.footnote) }
                HStack {
                    Button("Try again") {
                        Task {
                            if store.backupError != nil { await store.updateBackup() }
                            if notifications.errorMessage != nil { await notifications.retry() }
                            if widget.errorMessage != nil { WidgetSyncManager.retry() }
                        }
                    }
                    if notifications.permissionDenied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .accessibilityElement(children: .contain)
        }
    }

}
