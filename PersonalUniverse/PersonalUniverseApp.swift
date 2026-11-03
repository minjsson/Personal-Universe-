import SwiftUI
import SwiftData

@main
struct PersonalUniverseApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--lighting-review") {
                UniverseLightingReview()
            } else {
                DatabaseRootView()
            }
            #else
            DatabaseRootView()
            #endif
        }
    }
}

// 저장소를 열지 못해도 기존 파일을 지우지 않고 재시도할 수 있습니다.
struct DatabaseRootView: View {
    @State private var store = PersistentStoreLoader()
    @State private var confirmRestore = false
    @State private var isRetryingServices = false
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                ZStack {
                    UniverseQuietBackground()
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 24) {
                                Circle()
                                    .fill(.white.opacity(0.8))
                                    .frame(width: 3, height: 3)
                                    .shadow(color: .white.opacity(0.35), radius: 12)
                                    .accessibilityHidden(true)
                                UniverseNotice(
                                    title: store.errorMessage == nil ? "Opening your universe" : "Unable to open your universe",
                                    message: store.errorMessage ?? "Your saved journey will be here shortly."
                                ) {
                                    if store.isLoading || store.errorMessage == nil {
                                        ProgressView().tint(.white.opacity(0.65))
                                    } else {
                                        VStack(spacing: 16) {
                                            Button("Try again", action: store.open)
                                                .buttonStyle(UniverseButtonStyle(prominent: true))
                                            if let date = store.backupDate {
                                                VStack(spacing: 10) {
                                                    Button("Restore backup") { confirmRestore = true }
                                                        .buttonStyle(UniverseButtonStyle())
                                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.caption)
                                                        .foregroundStyle(.white.opacity(0.5))
                                                }
                                            } else {
                                                Text("No recovery backup is available yet. Your database has not been reset.")
                                                    .font(.footnote)
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 48)
                            .frame(minHeight: geometry.size.height)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recoveryNotice: some View {
        let notifications = NotificationManager.shared
        let widget = WidgetSyncManager.status
        let messages = [store.backupError, notifications.errorMessage, widget.errorMessage].compactMap { $0 }
        let actionsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        if !messages.isEmpty {
            UniverseNotice(title: "Updates need attention", message: messages.joined(separator: "\n\n"), compact: true) {
                actionsLayout {
                    Button {
                        guard !isRetryingServices else { return }
                        isRetryingServices = true
                        Task {
                            defer { isRetryingServices = false }
                            if store.backupError != nil { await store.updateBackup() }
                            if notifications.errorMessage != nil { await notifications.retry() }
                            if widget.errorMessage != nil { WidgetSyncManager.retry() }
                        }
                    } label: {
                        if isRetryingServices { ProgressView().tint(.white) }
                        else { Text("Try again") }
                    }
                    .buttonStyle(UniverseButtonStyle(prominent: true))
                    .disabled(isRetryingServices)
                    if notifications.permissionDenied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        .buttonStyle(UniverseButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(.black)
            .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.1)).frame(height: 0.5) }
        }
    }
}
