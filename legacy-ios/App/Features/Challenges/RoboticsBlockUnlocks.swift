import SwiftUI
import ForgeCodeEngine

/// One block introduced at a challenge milestone. Once unlocked it stays in the
/// palette for every later challenge — kids just use the ones a puzzle needs.
struct RoboticsBlockUnlock: Identifiable {
    let unlockOrder: Int
    let make: () -> RBlock
    let blurb: String
    var id: String { RoboticsStyle.label(make()) }
    var icon: String { RoboticsStyle.icon(make()) }
    var title: String { RoboticsStyle.label(make()) }
    var category: RoboticsCategory { RoboticsStyle.category(make()) }
}

enum RoboticsUnlocks {
    /// The introduction schedule across the 100-challenge ladder. Cumulative:
    /// a block unlocked at order N is available for every challenge ≥ N.
    static var schedule: [RoboticsBlockUnlock] {[
        .init(unlockOrder: 1,  make: { .stepForward },
              blurb: "Moves forward one tile — no number needed. Great inside an if block."),
        .init(unlockOrder: 1,  make: { .move(dir: .forward, amount: 1, unit: .tiles) },
              blurb: "Moves the rover. Tap the arrows to choose direction, distance, and unit (tiles or cm)."),
        .init(unlockOrder: 1,  make: { .turn(dir: .right, degrees: 90) },
              blurb: "Turns the rover. Pick left or right and how many degrees."),
        .init(unlockOrder: 4,  make: { .repeatN(count: 3, body: []) },
              blurb: "Does the blocks inside it again and again — set how many times."),
        .init(unlockOrder: 9,  make: { .ifC(cond: .distance(op: .less, cm: 30), body: []) },
              blurb: "Runs the inside blocks only when the sensor is true. Tap the blue sensor to change what it checks — like how close a wall is."),
        .init(unlockOrder: 16, make: { .whileC(cond: .distance(op: .greater, cm: 30), body: []) },
              blurb: "Keeps repeating the inside blocks the whole time the sensor stays true."),
        .init(unlockOrder: 32, make: { .wait(1000) },
              blurb: "Pauses for a moment before the next block."),
        .init(unlockOrder: 44, make: { .armLower },
              blurb: "Lowers the robot's arm to reach something."),
        .init(unlockOrder: 44, make: { .armRaise },
              blurb: "Raises the robot's arm back up."),
        .init(unlockOrder: 44, make: { .armTo(90) },
              blurb: "Moves the arm to an exact angle."),
        .init(unlockOrder: 56, make: { .gripperClose },
              blurb: "Closes the gripper to grab what's in front."),
        .init(unlockOrder: 56, make: { .gripperOpen },
              blurb: "Opens the gripper to let go."),
        .init(unlockOrder: 70, make: { .returnHome },
              blurb: "Sends the robot straight back to its start tile."),
    ]}

    /// All blocks available at a given challenge order (cumulative).
    static func palette(upTo order: Int) -> [RoboticsPaletteItem] {
        schedule.filter { $0.unlockOrder <= order }
            .map { RoboticsPaletteItem(make: $0.make) }
    }

    /// Blocks now available that haven't been explained yet.
    static func newlyAvailable(order: Int, seen: Set<String>) -> [RoboticsBlockUnlock] {
        schedule.filter { $0.unlockOrder <= order && !seen.contains($0.id) }
    }
}

// MARK: - "New blocks unlocked" explainer

struct BlockIntroCard: View {
    let blocks: [RoboticsBlockUnlock]
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text(blocks.count == 1 ? "New block unlocked!" : "New blocks unlocked!")
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.top, 22).padding(.bottom, 14)

                VStack(spacing: 12) {
                    ForEach(blocks) { b in
                        HStack(alignment: .top, spacing: 12) {
                            chip(b)
                            Text(b.blurb)
                                .font(.system(size: 13.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Button(action: onDismiss) {
                    Text("Got it!")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.1), lineWidth: 1))
            )
            .padding(.horizontal, 26)
            .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
        }
        .transition(.opacity)
    }

    private func chip(_ b: RoboticsBlockUnlock) -> some View {
        HStack(spacing: 5) {
            Image(systemName: b.icon).font(.system(size: 12, weight: .bold))
            Text(b.title).font(.system(size: 12.5, weight: .heavy, design: .rounded)).fixedSize()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).frame(height: 34)
        .background(RoundedRectangle(cornerRadius: 9).fill(b.category.gradient)
            .shadow(color: b.category.base.opacity(0.5), radius: 2, y: 1))
    }
}
