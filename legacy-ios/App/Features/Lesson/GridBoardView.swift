import SwiftUI
import ForgeCodeEngine

// Engine uses origin bottom-left (+y up). SwiftUI is top-left (+y down).
// Flip: screenRow = (grid.height - 1) - engineY

// Disambiguate: ForgeCodeEngine.Grid vs SwiftUI.Grid
typealias ForgeGrid = ForgeCodeEngine.Grid

extension Direction {
    /// Screen rotation for the robot sprite (0° = pointing up on screen).
    var screenRotation: Angle {
        switch self {
        case .up:    return .degrees(0)
        case .right: return .degrees(90)
        case .down:  return .degrees(180)
        case .left:  return .degrees(270)
        }
    }
}

/// Pure render of the grid, obstacles, goal, and robot at a given state.
/// No logic lives here — it's driven entirely by engine value types.
struct GridBoardView: View {
    let grid: ForgeGrid
    let goal: Position
    let robot: RobotState

    var body: some View {
        GeometryReader { geo in
            let cell = min(
                geo.size.width / CGFloat(grid.width),
                geo.size.height / CGFloat(grid.height)
            )
            let boardWidth = cell * CGFloat(grid.width)
            let boardHeight = cell * CGFloat(grid.height)
            let offsetX = (geo.size.width - boardWidth) / 2
            let offsetY = (geo.size.height - boardHeight) / 2

            ZStack(alignment: .topLeading) {
                // Grid cells
                ForEach(0..<grid.height, id: \.self) { screenRow in
                    ForEach(0..<grid.width, id: \.self) { col in
                        let engineY = (grid.height - 1) - screenRow
                        let pos = Position(x: col, y: engineY)
                        cellView(for: pos, cell: cell)
                            .offset(
                                x: offsetX + CGFloat(col) * cell,
                                y: offsetY + CGFloat(screenRow) * cell
                            )
                    }
                }

                // Robot sprite
                RobotSpriteView()
                    .frame(width: cell * 0.75, height: cell * 0.75)
                    .rotationEffect(robot.facing.screenRotation)
                    .offset(
                        x: offsetX + CGFloat(robot.position.x) * cell + cell * 0.125,
                        y: offsetY + CGFloat((grid.height - 1) - robot.position.y) * cell + cell * 0.125
                    )
                    .animation(.easeInOut(duration: 0.28), value: robot)
                    .accessibilityHidden(true)
            }
        }
        .aspectRatio(CGFloat(grid.width) / CGFloat(grid.height), contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(
            "Grid \(grid.width) by \(grid.height). Robot at column \(robot.position.x + 1), row \(robot.position.y + 1), facing \(robot.facing.rawValue). Goal at column \(goal.x + 1), row \(goal.y + 1)."
        )
    }

    @ViewBuilder
    private func cellView(for pos: Position, cell: CGFloat) -> some View {
        let isObstacle = grid.isObstacle(pos)
        let isGoal = pos == goal

        ZStack {
            Rectangle()
                .fill(isObstacle ? Color(.systemGray3) : Color(.secondarySystemBackground))
                .frame(width: cell, height: cell)
                .border(Color(.systemGray5), width: 0.5)

            if isGoal {
                Image(systemName: "flag.checkered")
                    .font(.system(size: cell * 0.45))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
            if isObstacle {
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: cell * 0.4))
                    .foregroundStyle(Color(.systemGray))
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Robot sprite: a directional arrow icon. Replace with custom art later.
struct RobotSpriteView: View {
    var body: some View {
        Image(systemName: "arrowtriangle.up.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint)
            .symbolRenderingMode(.hierarchical)
    }
}
