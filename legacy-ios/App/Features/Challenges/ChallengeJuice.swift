import SwiftUI
import AudioToolbox

// MARK: - Sound effects (system sounds — no assets needed)

enum SFX {
    static func play(_ id: SystemSoundID) { AudioServicesPlaySystemSound(id) }
    static let collect: SystemSoundID = 1057   // "Tink"
    static let win:     SystemSoundID = 1025   // chime
    static let build:   SystemSoundID = 1109
    static let fail:    SystemSoundID = 1053
}

// MARK: - Confetti

struct Confetti: View {
    var burst: Bool
    private let pieces = 60
    private let colors: [Color] = [.yellow, .orange, .pink, .cyan, .green, .purple, .red]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieces, id: \.self) { i in
                    ConfettiPiece(
                        color: colors[i % colors.count],
                        startX: geo.size.width * 0.5,
                        startY: geo.size.height * 0.32,
                        angle: Double(i) / Double(pieces) * 2 * .pi + Double(i),
                        distance: 120 + Double(i % 7) * 55,
                        burst: burst)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let angle: Double
    let distance: Double
    let burst: Bool
    @State private var go = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 9, height: 13)
            .rotationEffect(.degrees(go ? Double.random(in: 180...540) : 0))
            .position(x: startX + (go ? CGFloat(cos(angle) * distance) : 0),
                      y: startY + (go ? CGFloat(sin(angle) * distance) + 320 : 0))
            .opacity(go ? 0 : 1)
            .onChange(of: burst) { _, b in if b { fire() } }
            .onAppear { if burst { fire() } }
    }
    private func fire() {
        withAnimation(.easeOut(duration: 1.3)) { go = true }
    }
}

// MARK: - Celebration overlay

struct CelebrationOverlay: View {
    let starRating: Int          // 1…3
    let gemsCollected: Int
    let isSuperHard: Bool
    let onNext: () -> Void
    let onReplay: () -> Void

    @State private var shownStars = 0
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            Confetti(burst: true)

            VStack(spacing: 16) {
                Text(isSuperHard ? "CHALLENGE CLEARED!" : "Mission Complete!")
                    .font(.system(size: isSuperHard ? 26 : 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .scaleEffect(pop ? 1 : 0.6)

                // Stars fill in one by one
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < shownStars ? "star.fill" : "star")
                            .font(.system(size: 46))
                            .foregroundStyle(i < shownStars ? .yellow : .white.opacity(0.35))
                            .scaleEffect(i < shownStars ? 1 : 0.7)
                            .shadow(color: i < shownStars ? .orange.opacity(0.7) : .clear, radius: 6)
                    }
                }

                if gemsCollected > 0 {
                    Label("\(gemsCollected) crystals collected", systemImage: "diamond.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                }

                Text("+1 ⭐ for your academy")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 2)

                HStack(spacing: 12) {
                    Button(action: onReplay) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 54)
                            .background(Capsule().fill(.white.opacity(0.2)))
                    }
                    Button(action: onNext) {
                        Text("Next  ▶")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Capsule().fill(LinearGradient(
                                colors: [Color(hue: 0.33, saturation: 0.7, brightness: 0.85),
                                         Color(hue: 0.36, saturation: 0.8, brightness: 0.7)],
                                startPoint: .top, endPoint: .bottom)))
                    }
                }
                .padding(.top, 6)
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12), lineWidth: 1))
            )
            .padding(.horizontal, 30)
            .scaleEffect(pop ? 1 : 0.8)
        }
        .onAppear {
            SFX.play(SFX.win)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { pop = true }
            // Reveal stars one at a time with a pop each.
            for i in 1...max(1, starRating) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.35) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { shownStars = i }
                    SFX.play(SFX.collect)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    }
}
