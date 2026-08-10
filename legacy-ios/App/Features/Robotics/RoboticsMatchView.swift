import SwiftUI
import ForgeCodeEngine

// MARK: - RoboticsMatchView

/// The playable **multi-launch** match screen (FLL-style).
///
/// The kid programs a launch, taps **Launch** → the rover drives out, scores
/// missions, and must return to base. Precision tokens + move budget are shared
/// across launches; ending a launch stuck / outside base costs a token. Between
/// launches the kid re-places the rover in base (any spot, any heading), can
/// swap an attachment, and edits the program, then launches again until the
/// shared budget runs out or they tap **Finish Match**.
struct RoboticsMatchView: View {
    @State var vm: RoboticsMatchViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.14).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HUDView(vm: vm)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    fieldSection
                    if vm.runState == .launched, let launch = vm.lastLaunch {
                        launchBanner(launch)
                            .padding(.horizontal, 12)
                            .padding(.top, 10)
                    }
                    setupSection
                    editorSection
                }
            }

            if vm.showScoreboard {
                MatchScoreboardOverlay(vm: vm)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(10)
            }
        }
        .navigationTitle(vm.match.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.35), value: vm.runState)
        .animation(.easeInOut(duration: 0.3), value: vm.showScoreboard)
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

    // MARK: - Between-launch banner

    private func launchBanner(_ launch: MatchLaunch) -> some View {
        let home = launch.endedInBase
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: home ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(home ? .green : .orange)
                Text("Launch \(vm.session.launchCount) done" +
                     (vm.lastLaunchPoints > 0 ? " — +\(vm.lastLaunchPoints) pts" : ""))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            Text(home
                 ? "Rover made it home. Set it up and launch again!"
                 : "Rover ended outside base — \u{2212}1 token. Retrieve it to base, then launch again.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background((home ? Color.green : Color.orange).opacity(0.16),
                    in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Setup (attachment + start pose)

    private var setupSection: some View {
        Group {
            if vm.runState == .idle || vm.runState == .launched {
                VStack(spacing: 12) {
                    AttachmentPicker(selected: $vm.selectedAttachment,
                                     disabled: false)
                    if let area = vm.homeArea {
                        StartPoseControl(
                            heading: $vm.startHeading,
                            x: $vm.startX,
                            y: $vm.startY,
                            homeArea: area,
                            isRunning: false,
                            title: "Place Rover in Base",
                            onReset: { vm.resetStartPose() }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Editor

    private var editorSection: some View {
        VStack(spacing: 10) {
            Text(vm.match.brief)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .accessibilityLabel("Match brief: \(vm.match.brief)")

            Text("Tip: end your program back in base so you don't lose a token. returnHome() rescues a stuck rover (spends 1 token).")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            TextEditor(text: $vm.programText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(vm.errorMessage != nil ? Color.orange : Color(.systemGray4), lineWidth: 1)
                )
                .frame(minHeight: 130, maxHeight: 200)
                .padding(.horizontal, 14)
                .accessibilityLabel("Code editor. Write your launch program here.")
                .disabled(vm.runState == .running)

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

    private var controlsRow: some View {
        VStack(spacing: 10) {
            Button {
                Task { await vm.launch(reduceMotion: reduceMotion) }
            } label: {
                Label(launchButtonTitle,
                      systemImage: vm.runState == .running ? "arrow.trianglehead.clockwise" : "paperplane.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(vm.runState == .running || !vm.canLaunch ? Color(.systemGray) : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(vm.runState == .running || !vm.canLaunch)
            .accessibilityLabel(launchButtonTitle)
            .accessibilityHint("Runs your program from base and animates the rover")

            HStack(spacing: 14) {
                Button { vm.finishMatch() } label: {
                    Label("Finish Match", systemImage: "flag.checkered")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(vm.runState == .running || vm.session.launchCount == 0)
                .accessibilityLabel("Finish match and see the final score")

                Button { vm.newAttempt() } label: {
                    Label("New Attempt", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(vm.runState == .running)
                .accessibilityLabel("Start a brand new attempt")
            }
        }
        .padding(.horizontal, 14)
    }

    private var launchButtonTitle: String {
        if vm.runState == .running { return "Launching\u{2026}" }
        if !vm.canLaunch { return "No moves left" }
        return "Launch \(vm.launchNumber)"
    }
}

// MARK: - HUD

/// Shared token pool + move budget + launch counter for the whole attempt.
private struct HUDView: View {
    var vm: RoboticsMatchViewModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "paperplane.fill")
                    .font(.caption2).foregroundStyle(.white.opacity(0.8))
                    .accessibilityHidden(true)
                Text("Launch \(vm.launchNumber)")
                    .font(.caption2.bold()).foregroundStyle(.white)
            }
            tokenRow
            Spacer(minLength: 8)
            budgetBar
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Launch \(vm.launchNumber). \(vm.tokensRemaining) tokens left. \(vm.movesUsed) of \(vm.match.moveBudget) moves used.")
    }

    private var tokenRow: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                .accessibilityHidden(true)
            ForEach(0..<vm.match.startingTokens, id: \.self) { i in
                Circle()
                    .fill(i < vm.tokensRemaining ? Color.yellow : Color(.systemGray4))
                    .frame(width: 11, height: 11)
                    .accessibilityHidden(true)
            }
        }
    }

    private var budgetBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Moves").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("\(vm.movesUsed) / \(vm.match.moveBudget)")
                    .font(.caption2.bold()).foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray4))
                    RoundedRectangle(cornerRadius: 3).fill(budgetColor)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
        .frame(width: 130)
    }

    private var fraction: CGFloat {
        guard vm.match.moveBudget > 0 else { return 0 }
        return min(1, CGFloat(vm.movesUsed) / CGFloat(vm.match.moveBudget))
    }
    private var budgetColor: Color {
        if fraction < 0.6 { return .green }
        if fraction < 0.85 { return .orange }
        return .red
    }
}

// MARK: - Scoreboard overlay

struct MatchScoreboardOverlay: View {
    let vm: RoboticsMatchViewModel

    private var result: MatchResult { vm.aggregate }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().accessibilityHidden(true)

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    launchSummary
                    missionList
                    scoreBreakdown
                    buttons
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

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: headerIcon)
                .font(.system(size: 52))
                .foregroundStyle(headerColor)
                .accessibilityHidden(true)
            Text(headerTitle).font(.title2.bold()).multilineTextAlignment(.center)
            Text(headerSubtitle)
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headerIcon: String {
        if vm.beatPar { return "trophy.fill" }
        if result.totalScore > 0 { return "checkmark.seal.fill" }
        return "arrow.trianglehead.counterclockwise.rotate.90"
    }
    private var headerColor: Color {
        if vm.beatPar { return .yellow }
        if result.totalScore > 0 { return .green }
        return .orange
    }
    private var headerTitle: String {
        if vm.beatPar { return "Amazing Run!" }
        if result.totalScore > 0 { return "Match Complete!" }
        return "Keep Going!"
    }
    private var headerSubtitle: String {
        if vm.beatPar { return "You beat par (\(vm.match.parScore ?? 0) pts) over \(vm.session.launchCount) launches!" }
        if result.totalScore > 0 { return "Nice work across \(vm.session.launchCount) launch\(vm.session.launchCount == 1 ? "" : "es")! Can you score more?" }
        return "No missions scored yet. Plan your launches and try again!"
    }

    private var launchSummary: some View {
        let penalties = vm.session.launches.filter { $0.homePenaltyApplied }.count
        return HStack {
            Label("\(vm.session.launchCount) launches", systemImage: "paperplane")
            Spacer()
            if penalties > 0 {
                Label("\(penalties) missed base", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            } else {
                Label("all returned home", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            }
        }
        .font(.caption)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var missionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MISSIONS").font(.caption.uppercaseSmallCaps()).foregroundStyle(.secondary)
            ForEach(result.perMission, id: \.missionId) { entry in
                HStack {
                    Image(systemName: entry.success ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(entry.success ? .green : .secondary)
                        .accessibilityHidden(true)
                    Text(vm.missionTitle(for: entry.missionId)).font(.subheadline)
                    Spacer()
                    Text(entry.score > 0 ? "+\(entry.score) pts" : "0 pts")
                        .font(.subheadline.bold())
                        .foregroundStyle(entry.score > 0 ? .green : .secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(vm.missionTitle(for: entry.missionId)): \(entry.success ? "completed" : "not completed"), \(entry.score) points")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var scoreBreakdown: some View {
        VStack(spacing: 10) {
            Text("SCORE").font(.caption.uppercaseSmallCaps()).foregroundStyle(.secondary)
            ScoreRow(label: "Mission points", value: result.missionPoints, accent: false)
            ScoreRow(label: "Precision tokens (\(result.tokensRemaining) \u{00D7} \(vm.match.pointsPerToken))",
                     value: result.tokenPoints, accent: false)
            Divider()
            ScoreRow(label: "Total", value: result.totalScore, accent: true)
            if let par = vm.match.parScore {
                Text("Par: \(par) pts").font(.footnote).foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            if vm.canLaunch {
                Button { vm.showScoreboard = false } label: {
                    Text("Keep Launching").font(.headline).frame(maxWidth: .infinity).frame(height: 52)
                }
                .buttonStyle(.borderedProminent).tint(.accentColor)
                .accessibilityHint("Close the scoreboard and run more launches")
            }
            Button { vm.newAttempt() } label: {
                Text("New Attempt").font(.headline).frame(maxWidth: .infinity).frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(vm.canLaunch ? Color.secondary : headerColor)
            .accessibilityHint("Reset everything and start a fresh attempt")
        }
    }
}

private struct ScoreRow: View {
    let label: String
    let value: Int
    let accent: Bool
    var body: some View {
        HStack {
            Text(label).font(accent ? .headline : .subheadline)
            Spacer()
            Text("\(value)")
                .font(accent ? .title3.bold() : .subheadline.bold())
                .foregroundStyle(accent ? Color.accentColor : .primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) points")
    }
}
