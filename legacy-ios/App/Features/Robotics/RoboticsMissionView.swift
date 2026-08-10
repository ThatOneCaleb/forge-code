import SwiftUI
import ForgeCodeEngine

// MARK: - RoboticsMissionView

/// A single-mission challenge screen. Unlike a match, it scores one mission and
/// lets the kid bolt a **tool attachment** onto the rover before running — the
/// "bring the right tool" decision that the precision/mechanism missions demand.
///
/// Layout (portrait):
///   ┌─────────────────────────────┐
///   │  mission header (name/★/pts)│
///   │  3D field (4:3)             │
///   │  attachment picker (chips)  │
///   │  brief + code editor        │
///   │  [Run]  [Reset]             │
///   └─────────────────────────────┘
struct RoboticsMissionView: View {
    @State var vm: RoboticsMissionViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.14).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerBar
                    fieldSection
                    AttachmentPicker(
                        selected: $vm.selectedAttachment,
                        disabled: vm.runState == .running
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    if let area = vm.homeArea {
                        StartPoseControl(
                            heading: $vm.startHeading,
                            x: $vm.startX,
                            y: $vm.startY,
                            homeArea: area,
                            isRunning: vm.runState == .running,
                            onReset: {
                                let hp = vm.world.resolvedHomePose
                                vm.startX = hp.position.x
                                vm.startY = hp.position.y
                                vm.startHeading = hp.headingDegrees
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                    }
                    editorSection
                }
            }

            if vm.runState == .done {
                MissionScoreboardOverlay(vm: vm, onRetry: { vm.reset() })
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(10)
            }
        }
        .navigationTitle(vm.mission.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.35), value: vm.runState)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            DifficultyStars(level: vm.mission.difficulty)
            Spacer()
            Text("\(vm.totalPossible) pts")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Difficulty \(vm.mission.difficulty) of 5. \(vm.totalPossible) points possible.")
    }

    // MARK: - Field

    private var fieldSection: some View {
        RoboticsFieldView(world: vm.world) { scene in
            vm.scene = scene
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .accessibilityElement()
        .accessibilityLabel("3D field: \(vm.world.name)")
    }

    // MARK: - Editor

    private var editorSection: some View {
        VStack(spacing: 10) {
            Text(vm.mission.brief)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .accessibilityLabel("Mission brief: \(vm.mission.brief)")

            modePicker

            if vm.editorMode == .blocks {
                RoboticsBlockEditorView(editor: vm.blockEditor,
                                        disabled: vm.runState == .running)
            } else {
                TextEditor(text: $vm.programText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(vm.errorMessage != nil ? Color.orange : Color(.systemGray4),
                                    lineWidth: 1)
                    )
                    .frame(minHeight: 150, maxHeight: 240)
                    .padding(.horizontal, 14)
                    .accessibilityLabel("Code editor. Write your rover program here.")
                    .disabled(vm.runState == .running)
            }

            if let err = vm.errorMessage {
                Label(err, systemImage: "lightbulb.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 14)
                    .accessibilityLabel("Hint: \(err)")
            }

            controlsRow
            Spacer(minLength: 12)
        }
    }

    private var modePicker: some View {
        Picker("Editor mode", selection: Binding(
            get: { vm.editorMode },
            set: { newMode in
                // Leaving blocks → refresh the text view from the tree.
                if newMode == .text { vm.syncTextFromBlocks() }
                vm.editorMode = newMode
            }
        )) {
            Text("Blocks").tag(RoboticsEditorMode.blocks)
            Text("Text").tag(RoboticsEditorMode.text)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 14)
        .disabled(vm.runState == .running)
    }

    private var controlsRow: some View {
        HStack(spacing: 14) {
            Button {
                Task { await vm.run(reduceMotion: reduceMotion) }
            } label: {
                Label(vm.runState == .running ? "Running\u{2026}" : "Run",
                      systemImage: vm.runState == .running
                        ? "arrow.trianglehead.clockwise" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(vm.runState == .running ? Color(.systemGray) : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(vm.runState == .running)
            .accessibilityLabel(vm.runState == .running ? "Running program" : "Run mission program")

            Button { vm.reset() } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(vm.runState == .running)
            .accessibilityLabel("Reset rover")
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Attachment picker

/// Horizontal chips for choosing the rover's tool before a run.
struct AttachmentPicker: View {
    @Binding var selected: RobotAttachment
    var disabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "wrench.adjustable.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Rover Attachment")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            .padding(.leading, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RobotAttachment.allCases, id: \.self) { att in
                        chip(att)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }

            Text(selected.blurb)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.leading, 2)
                .accessibilityHidden(true)
        }
    }

    private func chip(_ att: RobotAttachment) -> some View {
        let isOn = att == selected
        return Button {
            selected = att
        } label: {
            HStack(spacing: 6) {
                Image(systemName: Self.icon(att))
                    .font(.caption)
                Text(att.displayName)
                    .font(.caption.weight(isOn ? .bold : .regular))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isOn ? AnyShapeStyle(Color.accentColor)
                     : AnyShapeStyle(.ultraThinMaterial),
                in: Capsule()
            )
            .foregroundStyle(isOn ? Color.white : Color.white.opacity(0.85))
            .overlay(
                Capsule().stroke(isOn ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled && !isOn ? 0.5 : 1)
        .accessibilityLabel("\(att.displayName)\(isOn ? ", selected" : "")")
        .accessibilityHint(att.blurb)
    }

    static func icon(_ att: RobotAttachment) -> String {
        switch att {
        case .none:          return "cube.fill"
        case .reachExtender: return "arrow.up.left.and.arrow.down.right"
        case .fineHook:      return "paperclip"
        case .launchTool:    return "bolt.fill"
        }
    }
}

// MARK: - Start pose control

/// Lets the kid place the rover anywhere inside the base area, at any heading —
/// like setting up a real robot in base before a launch. Collapsed by default so
/// beginners can ignore it; a powerful optimisation lever for advanced kids.
///
/// Reusable across the mission and match screens: it takes plain bindings, the
/// base rectangle, a running flag, and a "reset to default" action.
struct StartPoseControl: View {
    @Binding var heading: Double
    @Binding var x: Double
    @Binding var y: Double
    let homeArea: FieldRect
    var isRunning: Bool
    var title: String = "Start Position"
    var onReset: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.north.line.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .rotationEffect(.degrees(heading))
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text("facing \(compass(heading))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) setup, facing \(compass(heading)). Double-tap to \(expanded ? "collapse" : "expand").")

            if expanded {
                sliderRow(title: "Facing", value: $heading,
                          range: 0...360, step: 15, label: compass(heading))
                sliderRow(title: "Left \u{2194} Right", value: $x,
                          range: homeArea.x...(homeArea.x + homeArea.width), step: 1,
                          label: "\(Int(x)) cm")
                sliderRow(title: "Back \u{2194} Front", value: $y,
                          range: homeArea.y...(homeArea.y + homeArea.height), step: 1,
                          label: "\(Int(y)) cm")
                Button(action: onReset) {
                    Label("Reset to default", systemImage: "arrow.counterclockwise")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func sliderRow(title: String, value: Binding<Double>,
                           range: ClosedRange<Double>, step: Double, label: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 78, alignment: .leading)
            Slider(value: value, in: range, step: step)
                .disabled(isRunning)
            Text(label)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 44, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(label)")
    }
}

/// 8-point compass name for a heading (0 = north, clockwise).
func compass(_ deg: Double) -> String {
    let names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    let idx = Int((deg.truncatingRemainder(dividingBy: 360) / 45).rounded()) % 8
    return names[(idx + 8) % 8]
}

// MARK: - Difficulty stars

struct DifficultyStars: View {
    let level: Int   // 1...5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= level ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(i <= level ? .yellow : Color.white.opacity(0.3))
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Mission scoreboard

struct MissionScoreboardOverlay: View {
    let vm: RoboticsMissionViewModel
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().accessibilityHidden(true)

            ScrollView {
                VStack(spacing: 20) {
                    header
                    objectiveList
                    scoreRow
                    if let note = vm.failureNote {
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(headerColor)
                    .accessibilityHint("Reset the field and try again")
                }
                .padding(24)
                .background(.background, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 22)
                .padding(.vertical, 40)
            }
            .shadow(radius: 20)
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: vm.didSucceed ? "checkmark.seal.fill" : "arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 52))
                .foregroundStyle(headerColor)
                .accessibilityHidden(true)
            Text(vm.didSucceed ? "Mission Complete!" : "Keep Going!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(vm.didSucceed
                 ? "Nice problem-solving — you scored \(vm.score) of \(vm.totalPossible) points."
                 : "Not quite. Check the objectives below and adjust your plan.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headerColor: Color { vm.didSucceed ? .green : .orange }

    private var objectiveList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OBJECTIVES")
                .font(.caption.uppercaseSmallCaps())
                .foregroundStyle(.secondary)
            ForEach(vm.objectiveRows(), id: \.objective.id) { row in
                HStack {
                    Image(systemName: row.met ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(row.met ? .green : .secondary)
                        .accessibilityHidden(true)
                    Text(row.objective.description)
                        .font(.subheadline)
                    Spacer()
                    Text(row.met ? "+\(row.objective.points)" : "0")
                        .font(.subheadline.bold())
                        .foregroundStyle(row.met ? .green : .secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.objective.description): \(row.met ? "done, \(row.objective.points) points" : "not done")")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var scoreRow: some View {
        HStack {
            Text("Total")
                .font(.headline)
            Spacer()
            Text("\(vm.score) / \(vm.totalPossible)")
                .font(.title3.bold())
                .foregroundStyle(Color.accentColor)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Total score \(vm.score) of \(vm.totalPossible)")
    }
}
