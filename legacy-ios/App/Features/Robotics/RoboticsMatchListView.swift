import SwiftUI
import ForgeCodeEngine

// MARK: - RoboticsMatchListView

/// Lists all available robotics matches loaded from `RoboticsLibrary`.
/// Tapping a row navigates to `RoboticsMatchView` for that match.
///
/// This replaces the `.robotics` `PlaceholderView` in `RootView`.
struct RoboticsMatchListView: View {
    @State private var loadState: LoadState = .loading

    /// Curated single-mission challenge ladder (the reactive-mechanism +
    /// attachment/precision missions), shown newest-concept first by difficulty.
    private static let challengeMissionIds = [
        // Cargo Command (warehouse) — reactive-mechanism ladder
        "mission_bay_door",           // d2 — bump the roll-up bay door open
        "mission_dock_lift",          // d3 — armPress dock ramp + crate delivery
        "mission_chute_release",      // d4 — armPress lever → freed crate cascade
        "mission_warehouse_gauntlet", // d5 — chute + delivery + door + precision park
        // Mars Outpost (arena) — reactive-mechanism + attachment/precision ladder
        "mission_drill_wakeup",       // d2 — armPress lever
        "mission_storage_nook",       // d3 — bump gate unlocks a lane
        "mission_signal_rocket",      // d3 — launchTool + tight launcher
        "mission_buried_sample",      // d4 — fineHook + gripper-pull excavator
        "mission_precision_gauntlet", // d5 — launcher + 7 cm rock pocket
    ]

    enum LoadState {
        case loading
        case loaded([MatchWithContent], [MissionWithWorld])
        case failed(String)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading:
                    ProgressView("Loading matches\u{2026}")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .failed(let msg):
                    ContentUnavailableView(
                        "Could not load matches",
                        systemImage: "exclamationmark.triangle",
                        description: Text(msg)
                    )

                case .loaded(let items, let missions):
                    matchList(items, missions)
                }
            }
            .navigationTitle("Robotics")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .task { await loadMatches() }
    }

    // MARK: - List

    private func matchList(_ items: [MatchWithContent], _ missions: [MissionWithWorld]) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {

                if !missions.isEmpty {
                    sectionHeader("Challenge Missions — think it through, pick the right tool!")
                    ForEach(missions) { m in
                        NavigationLink {
                            RoboticsMissionView(
                                vm: RoboticsMissionViewModel(mission: m.mission, world: m.world)
                            )
                        } label: {
                            MissionCard(item: m)
                        }
                        .buttonStyle(.plain)
                    }
                }

                sectionHeader("Season Matches — one program, score the whole field!")
                ForEach(items) { item in
                    NavigationLink {
                        RoboticsMatchView(
                            vm: RoboticsMatchViewModel(
                                match: item.match,
                                world: item.world,
                                missions: item.missions
                            )
                        )
                    } label: {
                        MatchCard(item: item)
                    }
                    .buttonStyle(.plain)
                }

                comingSoonCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 2)
    }

    // MARK: - Coming soon card

    private var comingSoonCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.dashed")
                .font(.title2)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            Text("More matches coming soon!")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Data loading

    @MainActor
    private func loadMatches() async {
        do {
            let matches  = try RoboticsLibrary.matches()
            let fields   = try RoboticsLibrary.fields()
            let missions = try RoboticsLibrary.missions()

            let fieldById   = Dictionary(fields.map   { ($0.id, $0) }, uniquingKeysWith: { f, _ in f })
            let missionById = Dictionary(missions.map { ($0.id, $0) }, uniquingKeysWith: { f, _ in f })

            let items: [MatchWithContent] = matches.compactMap { match in
                guard let world = fieldById[match.fieldId] else { return nil }
                let mList = match.missionIds.compactMap { missionById[$0] }
                return MatchWithContent(match: match, world: world, missions: mList)
            }

            // Curated challenge missions (in ladder order), each with its field.
            let challenges: [MissionWithWorld] = Self.challengeMissionIds.compactMap { id in
                guard let mission = missionById[id],
                      let world = fieldById[mission.fieldId] else { return nil }
                return MissionWithWorld(mission: mission, world: world)
            }

            if items.isEmpty && challenges.isEmpty {
                loadState = .failed("No robotics content found in the app bundle. Check the content files.")
            } else {
                loadState = .loaded(items, challenges)
            }
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

// MARK: - MissionWithWorld

/// A single challenge mission bundled with its resolved `FieldWorld`.
struct MissionWithWorld: Identifiable {
    var id: String { mission.id }
    let mission: Mission
    let world:   FieldWorld
}

// MARK: - MissionCard

private struct MissionCard: View {
    let item: MissionWithWorld

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(difficultyColor.opacity(0.18))
                    .frame(width: 58, height: 58)
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(difficultyColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.mission.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(item.mission.brief)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    stars
                    Text("\(item.mission.totalPossiblePoints) pts")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.mission.title). Difficulty \(item.mission.difficulty) of 5. " +
            "\(item.mission.totalPossiblePoints) points."
        )
        .accessibilityHint("Double-tap to open this challenge")
        .accessibilityAddTraits(.isButton)
    }

    private var stars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= item.mission.difficulty ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(i <= item.mission.difficulty ? difficultyColor : Color(.systemGray4))
            }
        }
        .accessibilityHidden(true)
    }

    private var difficultyColor: Color {
        switch item.mission.difficulty {
        case ...2: return .green
        case 3:    return .orange
        default:   return .red
        }
    }
}

// MARK: - MatchWithContent

/// A match bundled with its resolved `FieldWorld` and `[Mission]` (avoids
/// re-loading on every navigation push).
struct MatchWithContent: Identifiable {
    var id:       String { match.id }
    let match:    Match
    let world:    FieldWorld
    let missions: [Mission]
}

// MARK: - MatchCard

private struct MatchCard: View {
    let item: MatchWithContent

    var body: some View {
        HStack(spacing: 14) {
            // Icon column
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 58, height: 58)
                Image(systemName: "cpu.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }

            // Text column
            VStack(alignment: .leading, spacing: 4) {
                Text(item.match.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.world.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(item.match.brief)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Token pips + budget line
                HStack(spacing: 8) {
                    tokenPips(count: item.match.startingTokens)
                    Text("\(item.match.moveBudget) moves")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if let par = item.match.parScore {
                        Text("par \(par)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.match.name). Field: \(item.world.name). " +
            "\(item.match.missions.count) missions. " +
            "\(item.match.moveBudget) moves. " +
            "\(item.match.startingTokens) precision tokens."
        )
        .accessibilityHint("Double-tap to open this match")
        .accessibilityAddTraits(.isButton)
    }

    private func tokenPips(count: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<min(count, 8), id: \.self) { _ in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel("\(count) precision tokens")
    }
}

// MARK: - Match convenience

private extension Match {
    var missions: [String] { missionIds }
}
