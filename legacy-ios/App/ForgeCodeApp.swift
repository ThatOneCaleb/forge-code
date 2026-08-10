import SwiftUI
import SwiftData

@main
struct ForgeCodeApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Kid.self, Badge.self, BuildLogEntry.self)
        } catch {
            fatalError("[ForgeCodeApp] Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
        }
    }
}
