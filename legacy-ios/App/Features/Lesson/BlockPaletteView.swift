import SwiftUI
import ForgeCodeEngine

// MARK: - Block types

enum BlockType: String, CaseIterable {
    case move, turnLeft, turnRight, repeatN, ifWall

    var commandKind: CommandKind {
        switch self {
        case .move:      return .move
        case .turnLeft:  return .turnLeft
        case .turnRight: return .turnRight
        case .repeatN:   return .repeatBlock
        case .ifWall:    return .ifWallAhead
        }
    }

    var label: String {
        switch self {
        case .move:      return "move"
        case .turnLeft:  return "turn left"
        case .turnRight: return "turn right"
        case .repeatN:   return "repeat"
        case .ifWall:    return "if wall"
        }
    }

    var icon: String { BlockTheme.icon(for: commandKind) }
    var color: Color { BlockTheme.base(for: commandKind) }

    var category: PaletteCategory {
        switch self {
        case .move, .turnLeft, .turnRight: return .motion
        case .repeatN, .ifWall:            return .control
        }
    }

    func makeCommand() -> Command {
        switch self {
        case .move:      return .move
        case .turnLeft:  return .turnLeft
        case .turnRight: return .turnRight
        case .repeatN:   return .repeatBlock(count: 3, body: [])
        case .ifWall:    return .ifWallAhead(body: [])
        }
    }
}

enum PaletteCategory: String, CaseIterable {
    case motion = "Movement"
    case control = "Control"

    var dotColor: Color {
        switch self {
        case .motion:  return BlockTheme.base(for: .move)
        case .control: return BlockTheme.base(for: .repeatBlock)
        }
    }
}

// MARK: - Palette

struct BlockPaletteView: View {
    @Bindable var vm: SimulatorViewModel

    private var availableBlocks: [BlockType] {
        BlockType.allCases.filter { vm.allowedCommandKinds.contains($0.commandKind) }
    }

    private var categories: [PaletteCategory] {
        PaletteCategory.allCases.filter { cat in
            availableBlocks.contains { $0.category == cat }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            targetBreadcrumb

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.self) { cat in
                        categoryGroup(cat)
                        if cat != categories.last {
                            Rectangle()
                                .fill(Color(.separator).opacity(0.5))
                                .frame(width: 1, height: 40)
                        }
                    }
                }
                .padding(.vertical, 2)
                .padding(.trailing, 8)
            }
        }
    }

    // MARK: Target breadcrumb

    @ViewBuilder private var targetBreadcrumb: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.system(size: 10, weight: .bold))
            Text("Add to")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            if vm.insertionPath.isEmpty {
                Text("Program")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
            } else {
                Text("inside loop")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                Button {
                    vm.insertionPath = []
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 10))
                        Text("top level").font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(BlockTheme.base(for: .repeatBlock)))
                }
            }
            Spacer()
        }
        .foregroundStyle(.secondary)
    }

    // MARK: Category group

    private func categoryGroup(_ cat: PaletteCategory) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle().fill(cat.dotColor).frame(width: 7, height: 7)
                Text(cat.rawValue.uppercased())
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(availableBlocks.filter { $0.category == cat }, id: \.rawValue) { block in
                    PaletteChip(block: block) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.insert(block.makeCommand(), atBody: vm.insertionPath)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Palette chip (mini block)

struct PaletteChip: View {
    let block: BlockType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: block.icon)
                    .font(.system(size: 13, weight: .bold))
                Text(block.label)
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .fixedSize()
            }
            .foregroundStyle(.white)
            .padding(.leading, 11)
            .padding(.trailing, 13)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(BlockTheme.gradient(for: block.commandKind))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                                 startPoint: .top, endPoint: .center))
                    )
                    .shadow(color: block.color.opacity(0.4), radius: 2.5, y: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(block.label) block")
        .accessibilityHint("Adds to your program")
    }
}
