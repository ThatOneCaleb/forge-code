import SwiftUI

/// A modal card overlaying the simulator screen for success or failure states.
struct ResultOverlayView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let message: String
    let primaryLabel: String
    let primaryAction: () -> Void
    let secondaryLabel: String
    let secondaryAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    Button(action: primaryAction) {
                        Text(primaryLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(iconColor)
                    .accessibilityLabel(primaryLabel)

                    Button(action: secondaryAction) {
                        Text(secondaryLabel)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(secondaryLabel)
                }
            }
            .padding(28)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 28)
            .shadow(radius: 16)
        }
        .accessibilityElement(children: .contain)
    }
}

/// A hint banner shown below the run controls.
struct HintBannerView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.yellow.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Hint: \(text)")
    }
}
