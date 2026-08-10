import SwiftUI
import ForgeCodeEngine

struct LessonView: View {
    let lesson: Lesson
    let kid: Kid
    let progressService: ProgressService
    let onComplete: () -> Void

    @State private var vm: SimulatorViewModel
    @State private var showAddBuildLog = false
    @State private var activeTab: Tab = .code
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    enum Tab { case grid, code }

    init(lesson: Lesson, kid: Kid, progressService: ProgressService, onComplete: @escaping () -> Void) {
        self.lesson = lesson
        self.kid = kid
        self.progressService = progressService
        self.onComplete = onComplete
        self._vm = State(wrappedValue: SimulatorViewModel(lesson: lesson))
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Main content ────────────────────────────────────────────────
            if activeTab == .grid {
                gridView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                codeView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // ── Control bar — Grid/Code toggle lives here ───────────────────
            controlBar
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                    Text(lesson.goalDescription)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let max = vm.maxBlocks {
                    Text("\(vm.blockCount)/\(max)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(vm.blockCount > max ? .red : .secondary)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay(resultOverlay)
        .sheet(isPresented: $showAddBuildLog) {
            AddBuildLogEntryView(kid: kid, progressService: progressService, isPresented: $showAddBuildLog)
        }
        .onChange(of: vm.showBuildLogPrompt) { _, show in
            if show { try? progressService.completeLesson(lesson, for: kid) }
        }
        .onChange(of: vm.result) { _, result in
            if result == .running { activeTab = .grid }
        }
    }

    // MARK: - Grid tab
    // Grid is top-aligned so it fills the full width; remaining space below
    // uses the grouped background rather than a big white void.

    private var gridView: some View {
        VStack(spacing: 0) {
            GridBoardView(
                grid: lesson.challenge.grid,
                goal: lesson.challenge.goal,
                robot: vm.displayedRobot
            )
            // aspectRatio inside GridBoardView keeps cells square and fills
            // exactly the width, so there are no side margins.
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Code tab

    private var codeView: some View {
        VStack(spacing: 0) {
            // Blocks vs Text sub-toggle
            Picker("Mode", selection: Binding(
                get: { vm.mode },
                set: { newMode in
                    if newMode == .text { vm.syncTextFromBlocks() }
                    else { vm.syncBlocksFromText() }
                    vm.mode = newMode
                }
            )) {
                Text("Blocks").tag(EditorMode.blocks)
                Text("Text").tag(EditorMode.text)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))

            Divider()

            if vm.mode == .blocks {
                // Block program list — fills all remaining space, scrolls internally
                BlockProgramView(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Palette strip — pinned at bottom, always visible
                BlockPaletteView(vm: vm)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
            } else {
                ScrollView {
                    CodeEditorView(vm: vm)
                        .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Control bar

    private var controlBar: some View {
        VStack(spacing: 0) {
            if vm.showHint {
                HintBannerView(text: vm.hintText)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }
            HStack(spacing: 10) {
                // Grid / Code toggle — text labels
                Picker("View", selection: $activeTab) {
                    Text("Grid").tag(Tab.grid)
                    Text("Code").tag(Tab.code)
                }
                .pickerStyle(.segmented)
                .frame(width: 110)

                Button {
                    Task { await vm.run(reduceMotion: reduceMotion) }
                } label: {
                    Label("Run", systemImage: "play.fill")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.result == .running || (vm.mode == .blocks && activeTab == .code && vm.program.commands.isEmpty))

                Button { vm.reset() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.body)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(vm.result == .running)
                .accessibilityLabel("Reset")

                Button { vm.showHint.toggle() } label: {
                    Image(systemName: vm.showHint ? "lightbulb.fill" : "lightbulb")
                        .font(.body)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Hint")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Result overlay

    @ViewBuilder
    private var resultOverlay: some View {
        switch vm.result {
        case .success:
            ResultOverlayView(
                title: "You did it!",
                icon: "checkmark.seal.fill",
                iconColor: .green,
                message: "Great work! You solved the puzzle.",
                primaryLabel: "Add to Build Log",
                primaryAction: { vm.result = .idle; showAddBuildLog = true },
                secondaryLabel: "Next challenge",
                secondaryAction: { vm.result = .idle; onComplete(); dismiss() }
            )
            .task { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        case .failure(let message):
            ResultOverlayView(
                title: "Almost there!",
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                message: message,
                primaryLabel: "Try again",
                primaryAction: { vm.reset() },
                secondaryLabel: "Hint",
                secondaryAction: { vm.result = .idle; vm.showHint = true }
            )
        default:
            EmptyView()
        }
    }
}
