import SwiftUI
import ForgeCodeEngine

/// The home base that visibly grows as the kid earns stars. This is the app's
/// front door: return here after every challenge, spend stars to build cute
/// modules, then launch the next mission.
struct AcademyHomeView: View {
    let kid: Kid
    let progressService: ProgressService
    @Environment(\.modelContext) private var context

    @State private var playing: Lesson?
    @State private var toast: String?
    @State private var burstAt: CGPoint?
    @State private var counterBounce = false

    private var earned: Int { kid.completedLessonIDs.count }
    private var spent: Int {
        kid.builtModuleIDs.compactMap { AcademyCatalog.module($0)?.cost }.reduce(0, +)
    }
    private var balance: Int { max(0, earned - spent) }

    private var nextLesson: Lesson? {
        let all = LessonStore.shared.challengeLessons.sorted { $0.order < $1.order }
        return all.first { !kid.completedLessonIDs.contains($0.id) } ?? all.last
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    sky
                    stars(in: geo.size)
                    hill(in: geo.size)

                    ForEach(AcademyCatalog.modules) { m in
                        moduleNode(m, in: geo.size)
                    }

                    RobotSprite(size: geo.size.width * 0.14)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.66)

                    if let burstAt { BuildBurst().position(burstAt).id(burstAt.debugDescription) }

                    topBar
                    bottomBar

                    if let toast {
                        Text(toast)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(Capsule().fill(.black.opacity(0.7)))
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.42)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
            .navigationDestination(item: $playing) { lesson in
                ChallengeRoboticsView(vm: ChallengeRoboticsViewModel(
                    lesson: lesson, kid: kid, progressService: progressService,
                    onComplete: { playing = nil }))
            }
        }
        .onChange(of: balance) { _, _ in
            counterBounce = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { counterBounce = false }
        }
    }

    // MARK: Scene layers

    private var sky: some View {
        LinearGradient(
            colors: [Color(hue: 0.58, saturation: 0.45, brightness: 1.0),
                     Color(hue: 0.62, saturation: 0.30, brightness: 1.0),
                     Color(hue: 0.08, saturation: 0.22, brightness: 1.0)],
            startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }

    private func stars(in size: CGSize) -> some View {
        Canvas { ctx, sz in
            var seed: UInt64 = 88172645463325252
            func rnd() -> Double { seed ^= seed << 7; seed ^= seed >> 9; return Double(seed % 1000) / 1000 }
            for _ in 0..<60 {
                let x = rnd() * sz.width, y = rnd() * sz.height * 0.55
                let r = 0.6 + rnd() * 1.6
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(.white.opacity(0.5 + rnd() * 0.5)))
            }
        }
        .allowsHitTesting(false)
    }

    private func hill(in size: CGSize) -> some View {
        Ellipse()
            .fill(LinearGradient(colors: [Color(hue: 0.30, saturation: 0.45, brightness: 0.80),
                                          Color(hue: 0.30, saturation: 0.55, brightness: 0.62)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size.width * 1.8, height: size.height * 0.9)
            .position(x: size.width * 0.5, y: size.height * 1.02)
            .allowsHitTesting(false)
    }

    // MARK: Module

    @ViewBuilder
    private func moduleNode(_ m: AcademyModule, in size: CGSize) -> some View {
        let built = kid.builtModuleIDs.contains(m.id)
        let affordable = balance >= m.cost
        let px = size.width * m.pos.x
        let py = size.height * m.pos.y
        let w = size.width * m.size

        Button {
            build(m, at: CGPoint(x: px, y: py - w * 0.3))
        } label: {
            Group {
                if built {
                    ModuleArt(id: m.id, tint: m.tint, size: w)
                        .shadow(color: m.tint.opacity(0.5), radius: 6, y: 3)
                } else {
                    ghost(m, width: w, affordable: affordable)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(built)
        .position(x: px, y: py)
        .modifier(Pulse(active: !built && affordable))
    }

    private func ghost(_ m: AcademyModule, width w: CGFloat, affordable: Bool) -> some View {
        VStack(spacing: 4) {
            ModuleArt(id: m.id, tint: .white, size: w)
                .opacity(0.18)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                        .foregroundStyle(.white.opacity(affordable ? 0.9 : 0.5))
                        .frame(width: w, height: w * 0.6)
                )
            HStack(spacing: 3) {
                Image(systemName: "star.fill").font(.system(size: 11))
                Text("\(m.cost)").font(.system(size: 13, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(affordable ? .yellow : .white.opacity(0.8))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(.black.opacity(0.35)))
        }
    }

    // MARK: Chrome

    private var topBar: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Forge Academy")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Mission \(min(earned + 1, 100)) of 100")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    Text("\(balance)")
                        .font(.system(size: 20, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(.black.opacity(0.28)))
                .scaleEffect(counterBounce ? 1.25 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: counterBounce)
            }
            .padding(.horizontal, 18)
            .padding(.top, 60)
            Spacer()
        }
    }

    private var bottomBar: some View {
        VStack {
            Spacer()
            Button {
                playing = nextLesson
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Play Mission \(min(earned + 1, 100))")
                }
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(
                    Capsule().fill(LinearGradient(
                        colors: [Color(hue: 0.09, saturation: 0.85, brightness: 1),
                                 Color(hue: 0.06, saturation: 0.95, brightness: 0.9)],
                        startPoint: .top, endPoint: .bottom))
                    .shadow(color: .orange.opacity(0.5), radius: 8, y: 4)
                )
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 44)
        }
    }

    // MARK: Build

    private func build(_ m: AcademyModule, at point: CGPoint) {
        guard !kid.builtModuleIDs.contains(m.id) else { return }
        guard balance >= m.cost else {
            showToast("Need \(m.cost - balance) more ⭐")
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            kid.builtModuleIDs.append(m.id)
        }
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        burstAt = point
        showToast("Built \(m.name)!  \(m.blurb)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { burstAt = nil }
    }

    private func showToast(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Juice

/// A gentle pulse for buildable, affordable modules.
private struct Pulse: ViewModifier {
    let active: Bool
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(active && on ? 1.08 : 1)
            .animation(active ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: on)
            .onAppear { if active { on = true } }
            .onChange(of: active) { _, v in on = v }
    }
}

/// A quick particle burst when a module is built.
struct BuildBurst: View {
    @State private var go = false
    private let bits = 10
    var body: some View {
        ZStack {
            ForEach(0..<bits, id: \.self) { i in
                let angle = Double(i) / Double(bits) * 2 * .pi
                Circle()
                    .fill([Color.yellow, .orange, .white, .cyan].randomElement()!)
                    .frame(width: 8, height: 8)
                    .offset(x: go ? cos(angle) * 46 : 0, y: go ? sin(angle) * 46 : 0)
                    .opacity(go ? 0 : 1)
                    .scaleEffect(go ? 0.4 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.7)) { go = true } }
        .allowsHitTesting(false)
    }
}
