import SwiftUI

/// A "Coming soon" placeholder screen for Robotics, Mentor, and Parent.
/// No real functionality — just a visually consistent holding page.
struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2.bold())

                    Text("Coming soon")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("This feature is on the way. Keep coding — it'll be worth the wait!")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .accessibilityElement(children: .contain)
    }
}
