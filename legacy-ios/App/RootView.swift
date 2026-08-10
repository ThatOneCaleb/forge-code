import SwiftUI
import SwiftData

/// App root — no tabs. The game IS the app.
/// Opens directly to BaseCampView (landscape, full-bleed).
struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var kid: Kid?

    var body: some View {
        Group {
            if let kid {
                let service = ProgressService(context: context)
                AcademyHomeView(kid: kid, progressService: service)
                    .task { try? service.recordAppOpen(for: kid) }
            } else {
                Color(red: 0.03, green: 0.02, blue: 0.08)
                    .ignoresSafeArea()
                    .task { await seedKid() }
            }
        }
    }

    @MainActor
    private func seedKid() async {
        let service = ProgressService(context: context)
        kid = try? service.currentKid()
    }
}
