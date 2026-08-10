import SwiftUI
import ForgeCodeEngine

/// Standalone preview screen for Phase 1a of 3D Field Mode.
///
/// Loads the first challenge ("Staircase Sprint") from `LessonStore`,
/// renders it in `Field3DView`, and lets the user run the hardcoded
/// canonical solution so they can watch the robot drive in 3D.
///
/// The hardcoded solution is intentional for Phase 1a — solutions are
/// not stored on `Lesson`; that is a Phase 1b concern.
struct FieldPreviewView: View {
    // MARK: - State

    @State private var fieldScene: Field3DScene?
    @State private var runState: FieldRunState = .idle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Static data

    /// The first challenge ("Staircase Sprint", 8×8).
    private var challenge: Challenge? {
        LessonStore.shared.challengeLessons.first?.challenge
    }

    /// Canonical solution for Staircase Sprint.
    private static let canonicalSolution = "repeat(4){ move(); turnRight(); move(); turnLeft(); }"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep-ocean background behind the 3D field
                Color(red: 0.05, green: 0.12, blue: 0.20)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let challenge {
                        field3DSection(challenge: challenge)
                        controlsSection
                    } else {
                        ContentUnavailableView(
                            "No Challenges Loaded",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Challenge data could not be read from the app bundle.")
                        )
                    }
                }
            }
            .navigationTitle("Field Mission \u{2014} Reef Rescue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func field3DSection(challenge: Challenge) -> some View {
        Field3DView(challenge: challenge) { scene in
            self.fieldScene = scene
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .accessibilityElement()
        .accessibilityLabel(fieldAccessibilityLabel(challenge: challenge))
    }

    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Status label
            Text(runState.statusText)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(minHeight: 44)
                .accessibilityLabel("Status: \(runState.statusText)")

            HStack(spacing: 16) {
                // Run / Running indicator
                Button(action: runProgram) {
                    Label(
                        runState == .running ? "Running\u{2026}" : "Run",
                        systemImage: runState == .running ? "arrow.trianglehead.clockwise" : "play.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(runState == .running ? Color.gray : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(runState == .running)
                .accessibilityLabel(runState == .running ? "Running program" : "Run program")
                .accessibilityHint(runState == .running ? "" : "Animates the robot through the Staircase Sprint solution in 3D")

                // Reset
                Button(action: reset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(white: 0.25))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(runState == .running)
                .accessibilityLabel("Reset robot to start")
                .accessibilityHint("Moves the robot back to its starting position")
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Actions

    @MainActor
    private func runProgram() {
        guard runState != .running, let scene = fieldScene, let challenge else { return }

        let program: Program
        do {
            program = try Parser.parse(Self.canonicalSolution)
        } catch {
            runState = .error("Could not parse the solution. Please reset and try again.")
            return
        }

        let simulator = Simulator()
        let result = simulator.run(program: program, challenge: challenge)
        let frames = result.frames

        guard !frames.isEmpty else {
            runState = .error("No frames were produced by the simulator.")
            return
        }

        runState = .running
        // Capture only Sendable values so the @Sendable closure requirement is met.
        // Hop back to the main actor before mutating @State.
        let outcome = result.outcome
        scene.playFrames(frames) { [outcome] in
            Task { @MainActor [outcome] in
                switch outcome {
                case .success:
                    self.runState = .success
                case .failure(let reason):
                    self.runState = .error(reason.message)
                }
            }
        }
    }

    private func reset() {
        fieldScene?.resetRobot()
        runState = .idle
    }

    // MARK: - Helpers

    private func fieldAccessibilityLabel(challenge: Challenge) -> String {
        "3D field view. \(challenge.grid.width) by \(challenge.grid.height) grid. " +
        "Robot starts at column \(challenge.start.position.x + 1), row \(challenge.start.position.y + 1), " +
        "facing \(challenge.start.facing.rawValue). " +
        "Goal at column \(challenge.goal.x + 1), row \(challenge.goal.y + 1)."
    }
}

// MARK: - Run state

private enum FieldRunState: Equatable {
    case idle
    case running
    case success
    case error(String)

    var statusText: String {
        switch self {
        case .idle:
            return "Staircase Sprint \u{2014} tap Run to watch the robot solve it!"
        case .running:
            return "Robot is driving\u{2026}"
        case .success:
            return "Goal reached! Great work!"
        case .error(let msg):
            return "Something went wrong: \(msg)"
        }
    }
}

// MARK: - Preview

#Preview {
    FieldPreviewView()
}
