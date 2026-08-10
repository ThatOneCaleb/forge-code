import SwiftUI
import ForgeCodeEngine

// MARK: - Simple stack block (move / turn)

struct SimpleBlockView: View {
    let command: Command
    let onDelete: () -> Void
    var onToggleDirection: (() -> Void)? = nil

    private var kind: CommandKind { command.kind }

    var body: some View {
        ZStack(alignment: .leading) {
            StackBlockShape()
                .fill(BlockTheme.gradient(for: kind))
                .overlay(topSheen)
                .shadow(color: BlockTheme.base(for: kind).opacity(0.35), radius: 3, y: 2.5)

            HStack(spacing: 0) {
                gripStripe
                iconTile
                HStack(spacing: 7) {
                    Text(BlockTheme.label(for: kind))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    valueBubble
                    Spacer(minLength: 0)
                }
                deleteButton
            }
        }
        .frame(height: BlockMetrics.rowH)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var valueBubble: some View {
        switch command {
        case .move:
            bubble("1 step", dropdown: false, action: nil)
        case .turnLeft:
            bubble("left", dropdown: onToggleDirection != nil, action: onToggleDirection)
        case .turnRight:
            bubble("right", dropdown: onToggleDirection != nil, action: onToggleDirection)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func bubble(_ text: String, dropdown: Bool, action: (() -> Void)?) -> some View {
        let content = HStack(spacing: 5) {
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
            if dropdown {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .black))
                    .opacity(0.6)
            }
        }
        .foregroundStyle(BlockTheme.base(for: kind))
        .padding(.leading, 11)
        .padding(.trailing, dropdown ? 8 : 11)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
        )

        if let action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var gripStripe: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.white.opacity(0.45))
            .rotationEffect(.degrees(90))
            .frame(width: 16, height: BlockMetrics.rowH)
            .padding(.leading, 2)
    }

    private var iconTile: some View {
        Image(systemName: BlockTheme.icon(for: kind))
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: BlockMetrics.rowH)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40, height: BlockMetrics.rowH)
        }
        .accessibilityLabel("Delete \(BlockTheme.label(for: kind)) block")
    }

    private var topSheen: some View {
        StackBlockShape()
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.30), .white.opacity(0.0)],
                    startPoint: .top, endPoint: .center)
            )
            .allowsHitTesting(false)
    }
}

// MARK: - C-block (repeat / if)

struct CBlockView: View {
    @Bindable var vm: SimulatorViewModel
    let command: Command
    let path: [Int]           // node path to this block
    let onDelete: () -> Void

    private var kind: CommandKind { command.kind }
    private var bodyPath: [Int] { path }   // the C body lives at this node path

    private var bodyCommands: [Command] {
        SimulatorViewModel.body(in: vm.program.commands, at: bodyPath[...]) ?? []
    }
    private var isTarget: Bool { vm.insertionPath == bodyPath }

    var body: some View {
        VStack(spacing: 0) {
            header
            bodyArea
            Color.clear.frame(height: BlockMetrics.footerH)
        }
        .background(
            CBlockShape(headerHeight: BlockMetrics.headerH, footerHeight: BlockMetrics.footerH)
                .fill(BlockTheme.gradient(for: kind))
                .overlay(
                    CBlockShape(headerHeight: BlockMetrics.headerH, footerHeight: BlockMetrics.footerH)
                        .fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                             startPoint: .top, endPoint: .center))
                        .allowsHitTesting(false)
                )
                .shadow(color: BlockTheme.base(for: kind).opacity(0.35), radius: 4, y: 3)
        )
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.45))
                .rotationEffect(.degrees(90))
                .frame(width: 16, height: BlockMetrics.headerH)
                .padding(.leading, 2)

            Image(systemName: BlockTheme.icon(for: kind))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: BlockMetrics.headerH)

            Text(BlockTheme.label(for: kind))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.trailing, 8)

            if case let .repeatBlock(count, _) = command {
                stepper(count: count)
            } else if case .ifWallAhead = command {
                SensorBooleanView(icon: "arrow.up.to.line.compact", text: "wall ahead?")
            }

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 40, height: BlockMetrics.headerH)
            }
            .accessibilityLabel("Delete \(BlockTheme.label(for: kind)) block")
        }
        .frame(height: BlockMetrics.headerH)
    }

    private func stepper(count: Int) -> some View {
        HStack(spacing: 0) {
            Button { vm.updateRepeatCount(atNode: path, count: count - 1) } label: {
                Image(systemName: "minus").font(.system(size: 12, weight: .black))
                    .foregroundStyle(BlockTheme.base(for: kind))
                    .frame(width: 28, height: 30)
            }
            Text("\(count)")
                .font(.system(size: 15, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(BlockTheme.base(for: kind))
                .frame(minWidth: 22)
            Button { vm.updateRepeatCount(atNode: path, count: count + 1) } label: {
                Image(systemName: "plus").font(.system(size: 12, weight: .black))
                    .foregroundStyle(BlockTheme.base(for: kind))
                    .frame(width: 28, height: 30)
            }
        }
        .background(Capsule().fill(.white).shadow(color: .black.opacity(0.12), radius: 1, y: 1))
    }

    // MARK: Body (inside the mouth)

    private var bodyArea: some View {
        VStack(spacing: 0) {
            if bodyCommands.isEmpty {
                emptySlot
            } else {
                ForgeBlockStack(vm: vm, path: bodyPath)
            }
        }
        .padding(.leading, BlockMetrics.spine + BlockMetrics.bodyInset)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { vm.insertionPath = bodyPath }
    }

    private var emptySlot: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill").font(.system(size: 14, weight: .semibold))
            Text(isTarget ? "pick a block below" : "tap, then pick a block")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(isTarget ? 0.95 : 0.7))
        .padding(.horizontal, 12)
        .frame(height: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(isTarget ? 0.22 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .foregroundStyle(.white.opacity(isTarget ? 0.9 : 0.45))
                )
        )
    }
}

// MARK: - Frame reporting for drag-reorder

private struct RowFrameKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private let stackSpace = "forge-block-stack"

// MARK: - Recursive block stack (one body level)

struct ForgeBlockStack: View {
    @Bindable var vm: SimulatorViewModel
    let path: [Int]   // container/body path this stack renders

    @State private var frames: [Int: CGRect] = [:]
    @State private var dragIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0

    private var commands: [Command] {
        SimulatorViewModel.body(in: vm.program.commands, at: path[...]) ?? []
    }

    var body: some View {
        let cmds = commands
        VStack(spacing: 0) {
            ForEach(cmds.indices, id: \.self) { i in
                row(i, command: cmds[i], count: cmds.count)
            }
        }
        .coordinateSpace(name: stackSpace)
        .onPreferenceChange(RowFrameKey.self) { frames = $0 }
    }

    @ViewBuilder
    private func row(_ i: Int, command: Command, count: Int) -> some View {
        let nodePath = path + [i]
        let isDragging = dragIndex == i
        Group {
            switch command {
            case .repeatBlock, .ifWallAhead:
                CBlockView(vm: vm, command: command, path: nodePath,
                           onDelete: { vm.delete(atNode: nodePath) })
            default:
                SimpleBlockView(
                    command: command,
                    onDelete: { vm.delete(atNode: nodePath) },
                    onToggleDirection: canToggleTurn(command)
                        ? { vm.toggleTurnDirection(atNode: nodePath) } : nil
                )
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: RowFrameKey.self,
                                       value: [i: geo.frame(in: .named(stackSpace))])
            }
        )
        .offset(y: isDragging ? dragOffset : 0)
        .scaleEffect(isDragging ? 1.02 : 1, anchor: .center)
        .opacity(isDragging ? 0.96 : 1)
        .zIndex(isDragging ? 1000 : Double(count - i))
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isDragging)
        .gesture(dragGesture(i, count: count))
    }

    /// A placed turn block gets a direction dropdown only when the lesson
    /// allows both turn directions.
    private func canToggleTurn(_ command: Command) -> Bool {
        guard command.kind == .turnLeft || command.kind == .turnRight else { return false }
        let allowed = vm.allowedCommandKinds
        return allowed.contains(.turnLeft) && allowed.contains(.turnRight)
    }

    private func dragGesture(_ i: Int, count: Int) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named(stackSpace))
            .onChanged { v in
                if dragIndex == nil { dragIndex = i }
                dragOffset = v.translation.height
            }
            .onEnded { v in
                let target = targetIndex(for: i, translationY: v.translation.height)
                if target != i {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        vm.move(inBody: path, from: i,
                                to: target > i ? target + 1 : target)
                    }
                }
                dragIndex = nil
                dragOffset = 0
            }
    }

    private func targetIndex(for i: Int, translationY: CGFloat) -> Int {
        guard let f = frames[i] else { return i }
        let center = f.midY + translationY
        var above = 0
        for (j, rect) in frames where j != i {
            if rect.midY < center { above += 1 }
        }
        return above
    }
}

// MARK: - Program shell

struct BlockProgramView: View {
    @Bindable var vm: SimulatorViewModel

    var body: some View {
        ZStack {
            WorkshopCanvas()
                .contentShape(Rectangle())
                .onTapGesture { vm.insertionPath = [] }

            if vm.program.commands.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HatBlockView()
                        ForgeBlockStack(vm: vm, path: [])
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            HatBlockView()
                .padding(.horizontal, 18)
            VStack(spacing: 10) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hue: 0.6, saturation: 0.2, brightness: 0.6))
                Text("Snap blocks below onto your program")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 34)
            Spacer()
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
