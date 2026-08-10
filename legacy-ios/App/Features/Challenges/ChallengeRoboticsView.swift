import SwiftUI
import ForgeCodeEngine

/// A Challenge played on the robotics engine: 3D field + FLL block editor +
/// Run/Reset/Hint, with a success overlay that advances the ladder.
struct ChallengeRoboticsView: View {
    @State var vm: ChallengeRoboticsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("seenRoboticsBlocks") private var seenCSV = ""
    @State private var introBlocks: [RoboticsBlockUnlock] = []

    private var seenSet: Set<String> {
        Set(seenCSV.split(separator: ",").map(String.init))
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.14).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    goalBar
                    fieldSection
                    RoboticsBlockEditorView(editor: vm.blockEditor,
                                            disabled: vm.runState == .running,
                                            palette: RoboticsUnlocks.palette(upTo: vm.lesson.order))
                        .padding(.top, 10)
                    if vm.showHint {
                        hintBanner
                    }
                    if let err = vm.errorMessage, !vm.didWin {
                        errorBanner(err)
                    }
                    controlsRow
                        .padding(.top, 4)
                    Spacer(minLength: 16)
                }
            }

            if vm.runState == .done && vm.didWin {
                CelebrationOverlay(
                    starRating: vm.starRating,
                    gemsCollected: vm.gemsCollected,
                    isSuperHard: vm.isSuperHard,
                    onNext: { vm.finish() },
                    onReplay: { vm.reset() })
                .zIndex(10)
            }

            if !introBlocks.isEmpty {
                BlockIntroCard(blocks: introBlocks) { dismissIntro() }
                    .zIndex(20)
            }
        }
        .navigationTitle(vm.lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.3), value: vm.runState)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: introBlocks.count)
        .onAppear {
            let newly = RoboticsUnlocks.newlyAvailable(order: vm.lesson.order, seen: seenSet)
            if !newly.isEmpty { introBlocks = newly }
        }
    }

    private func dismissIntro() {
        var seen = seenSet
        introBlocks.forEach { seen.insert($0.id) }
        seenCSV = seen.sorted().joined(separator: ",")
        introBlocks = []
    }

    // MARK: Goal

    private var goalBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .foregroundStyle(.green)
            Text(vm.goalDescription)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    // MARK: Field

    private var fieldSection: some View {
        ChallengeBoardView(world: vm.world, pose: vm.displayedPose,
                           collectedGemIds: vm.collectedGemIds)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.13, blue: 0.20))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
            )
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .accessibilityElement()
            .accessibilityLabel("Grid board for \(vm.lesson.title)")
    }

    // MARK: Banners

    private var hintBanner: some View {
        Label(vm.hintText, systemImage: "lightbulb.fill")
            .font(.callout)
            .foregroundStyle(.yellow)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 14)
            .padding(.top, 10)
    }

    private func errorBanner(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.orange)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 14)
            .padding(.top, 10)
    }

    // MARK: Controls

    private var controlsRow: some View {
        HStack(spacing: 12) {
            Button {
                Task { await vm.run(reduceMotion: reduceMotion) }
            } label: {
                Label(vm.runState == .running ? "Running…" : "Run",
                      systemImage: vm.runState == .running ? "arrow.trianglehead.clockwise" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(vm.runState == .running ? Color(.systemGray) : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .disabled(vm.runState == .running || vm.blockEditor.blocks.isEmpty)

            Button { vm.reset() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(width: 52, height: 50)
                    .background(Color(.systemGray5).opacity(0.25))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .disabled(vm.runState == .running)
            .accessibilityLabel("Reset")

            Button { vm.showHint.toggle() } label: {
                Image(systemName: vm.showHint ? "lightbulb.fill" : "lightbulb")
                    .font(.headline)
                    .frame(width: 52, height: 50)
                    .background(Color(.systemGray5).opacity(0.25))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .accessibilityLabel("Hint")
        }
        .padding(.horizontal, 14)
    }
}
