import SwiftUI
import ForgeCodeEngine

// MARK: - Metrics (chunkier than the beginner tier, closer to SPIKE)

private enum R {
    static let rowH: CGFloat = 54
    static let headerH: CGFloat = 54
    static let footerH: CGFloat = 18
    static let tileCm: Double = 30      // one grid tile
}

// MARK: - Category styling (SPIKE-authentic palette)

enum RoboticsCategory: String, CaseIterable {
    case motion = "Move"
    case control = "Control"
    case mechanism = "Mechanisms"
    case operations = "Wait"

    var colors: (Color, Color) {
        switch self {
        case .motion:     return (Color(hue: 0.49, saturation: 0.72, brightness: 0.84),
                                  Color(hue: 0.50, saturation: 0.92, brightness: 0.66))
        case .mechanism:  return (Color(hue: 0.545, saturation: 0.70, brightness: 0.95),
                                  Color(hue: 0.555, saturation: 0.92, brightness: 0.82))
        case .control:    return (Color(hue: 0.095, saturation: 0.80, brightness: 1.0),
                                  Color(hue: 0.075, saturation: 0.94, brightness: 0.92))
        case .operations: return (Color(hue: 0.75, saturation: 0.52, brightness: 0.88),
                                  Color(hue: 0.76, saturation: 0.72, brightness: 0.70))
        }
    }
    var gradient: LinearGradient {
        LinearGradient(colors: [colors.0, colors.1], startPoint: .top, endPoint: .bottom)
    }
    var base: Color { colors.1 }
}

enum RoboticsStyle {
    static func category(_ block: RBlock) -> RoboticsCategory {
        switch block {
        case .stepForward, .move, .turn: return .motion
        case .armRaise, .armLower, .armTo, .gripperOpen, .gripperClose: return .mechanism
        case .repeatN, .whileC, .ifC: return .control
        case .wait, .returnHome: return .operations
        }
    }

    static func icon(_ block: RBlock) -> String {
        switch block {
        case .stepForward:   return "arrow.up"
        case .move:          return "arrow.up.arrow.down"
        case .turn:          return "arrow.trianglehead.clockwise"
        case .armRaise:      return "arrow.up.to.line"
        case .armLower:      return "arrow.down.to.line"
        case .armTo:         return "gauge.with.needle"
        case .gripperOpen:   return "hand.open.fill"
        case .gripperClose:  return "hands.clap.fill"
        case .wait:          return "clock.fill"
        case .returnHome:    return "house.fill"
        case .repeatN:       return "arrow.2.circlepath"
        case .whileC:        return "arrow.triangle.2.circlepath"
        case .ifC:           return "arrow.triangle.branch"
        }
    }

    static func label(_ block: RBlock) -> String {
        switch block {
        case .stepForward:   return "move forward"
        case .move:          return "move"
        case .turn:          return "turn"
        case .armRaise:      return "arm up"
        case .armLower:      return "arm down"
        case .armTo:         return "arm to"
        case .gripperOpen:   return "grip open"
        case .gripperClose:  return "grip shut"
        case .wait:          return "wait"
        case .returnHome:    return "go home"
        case .repeatN:       return "repeat"
        case .whileC:        return "while"
        case .ifC:           return "if"
        }
    }

    /// The value bubble text in kid units (tiles / seconds), or nil for none.
    static func valueText(_ block: RBlock) -> String? {
        switch block {
        case let .wait(ms):
            let s = Int((ms / 1000).rounded())
            return "\(s) sec"
        case let .armTo(deg):
            return "\(Int(deg))°"
        default:
            return nil   // move/turn render their own dropdown controls
        }
    }

    /// Engine-unit step for the +/- buttons on a block's value.
    static func step(_ block: RBlock) -> Double {
        switch block {
        case .wait:  return 1000                              // 1 second
        case .armTo: return 15
        default:     return 0
        }
    }
}

// MARK: - Palette catalog

struct RoboticsPaletteItem: Identifiable {
    let make: () -> RBlock
    var id: String { label }
    var category: RoboticsCategory { RoboticsStyle.category(make()) }
    var icon: String { RoboticsStyle.icon(make()) }
    var label: String { RoboticsStyle.label(make()) }
}

enum RoboticsPalette {
    /// Full robotics palette — the same rich set is offered on every challenge;
    /// kids simply use the ones a given puzzle needs.
    static var full: [RoboticsPaletteItem] {[
        .init { .stepForward },
        .init { .move(dir: .forward, amount: 1, unit: .tiles) },
        .init { .turn(dir: .right, degrees: 90) },
        .init { .armRaise },
        .init { .armLower },
        .init { .armTo(90) },
        .init { .gripperOpen },
        .init { .gripperClose },
        .init { .repeatN(count: 3, body: []) },
        .init { .ifC(cond: .distance(op: .less, cm: 30), body: []) },
        .init { .whileC(cond: .distance(op: .greater, cm: 30), body: []) },
        .init { .wait(1000) },
        .init { .returnHome },
    ]}

    static func grouped(_ items: [RoboticsPaletteItem]) -> [(RoboticsCategory, [RoboticsPaletteItem])] {
        RoboticsCategory.allCases.compactMap { cat in
            let matches = items.filter { $0.category == cat }
            return matches.isEmpty ? nil : (cat, matches)
        }
    }
}

// MARK: - Editor shell

struct RoboticsBlockEditorView: View {
    @Bindable var editor: RoboticsBlockEditor
    var disabled: Bool
    var palette: [RoboticsPaletteItem] = RoboticsPalette.full

    var body: some View {
        VStack(spacing: 0) {
            canvas.frame(minHeight: 220)
            Divider().overlay(Color.white.opacity(0.12))
            paletteBar
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color(red: 0.11, green: 0.13, blue: 0.20))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 12)
        .disabled(disabled)
        .opacity(disabled ? 0.75 : 1)
    }

    private var canvas: some View {
        ZStack {
            WorkshopCanvas()
                .contentShape(Rectangle())
                .onTapGesture { editor.insertionPath = [] }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HatBlockView()
                    if editor.blocks.isEmpty {
                        emptyHint
                    } else {
                        RoboticsStack(editor: editor, path: [])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var emptyHint: some View {
        HStack(spacing: 7) {
            Image(systemName: "hand.tap.fill")
            Text("Tap blocks below to program your robot")
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.secondary)
        .padding(.top, 22)
        .padding(.leading, 4)
    }

    // MARK: Palette

    private var paletteBar: some View {
        VStack(alignment: .leading, spacing: 9) {
            targetBreadcrumb
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(RoboticsPalette.grouped(palette), id: \.0) { cat, items in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Circle().fill(cat.base).frame(width: 7, height: 7)
                                Text(cat.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .tracking(0.5)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            HStack(spacing: 9) {
                                ForEach(items) { item in paletteChip(item) }
                            }
                        }
                        if cat != RoboticsPalette.grouped(palette).last?.0 {
                            Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 52)
                        }
                    }
                }
                .padding(.trailing, 8)
            }
        }
    }

    @ViewBuilder private var targetBreadcrumb: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.down.to.line.compact").font(.system(size: 10, weight: .bold))
            Text("Add to").font(.system(size: 11, weight: .semibold, design: .rounded))
            Text(editor.insertionPath.isEmpty ? "Program" : "inside block")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
            if !editor.insertionPath.isEmpty {
                Button { editor.insertionPath = [] } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 10))
                        Text("top").font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(RoboticsCategory.control.base))
                }
            }
            Spacer()
        }
        .foregroundStyle(.white.opacity(0.62))
    }

    private func paletteChip(_ item: RoboticsPaletteItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                editor.insert(item.make(), atBody: editor.insertionPath)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: item.icon).font(.system(size: 14, weight: .bold))
                Text(item.label).font(.system(size: 14, weight: .heavy, design: .rounded)).fixedSize()
            }
            .foregroundStyle(.white)
            .padding(.leading, 11).padding(.trailing, 14)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(item.category.gradient)
                    .overlay(RoundedRectangle(cornerRadius: 11)
                        .fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                             startPoint: .top, endPoint: .center)))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(.white.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: item.category.base.opacity(0.45), radius: 3, y: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(item.label) block")
    }
}

// MARK: - Recursive stack (with drag-to-reorder)

private struct RRowFrameKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}
private let rStackSpace = "rob-block-stack"

struct RoboticsStack: View {
    @Bindable var editor: RoboticsBlockEditor
    let path: [Int]

    @State private var frames: [Int: CGRect] = [:]
    @State private var dragIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0

    private var blocks: [RBlock] {
        RoboticsBlockEditor.body(in: editor.blocks, at: path[...]) ?? []
    }

    var body: some View {
        let cmds = blocks
        VStack(spacing: 0) {
            ForEach(cmds.indices, id: \.self) { i in
                row(i, block: cmds[i], count: cmds.count)
            }
        }
        .coordinateSpace(name: rStackSpace)
        .onPreferenceChange(RRowFrameKey.self) { frames = $0 }
    }

    @ViewBuilder
    private func row(_ i: Int, block: RBlock, count: Int) -> some View {
        let nodePath = path + [i]
        let isDragging = dragIndex == i
        Group {
            if block.isContainer {
                RoboticsCBlock(editor: editor, block: block, path: nodePath)
            } else {
                RoboticsSimpleBlock(editor: editor, block: block, path: nodePath)
            }
        }
        .background(GeometryReader { geo in
            Color.clear.preference(key: RRowFrameKey.self,
                                   value: [i: geo.frame(in: .named(rStackSpace))])
        })
        .offset(y: isDragging ? dragOffset : 0)
        .scaleEffect(isDragging ? 1.03 : 1, anchor: .center)
        .opacity(isDragging ? 0.96 : 1)
        .zIndex(isDragging ? 1000 : Double(count - i))
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isDragging)
        .gesture(dragGesture(i, count: count))
    }

    private func dragGesture(_ i: Int, count: Int) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .named(rStackSpace))
            .onChanged { v in
                if dragIndex == nil { dragIndex = i }
                dragOffset = v.translation.height
            }
            .onEnded { v in
                let target = targetIndex(for: i, translationY: v.translation.height)
                if target != i {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        editor.move(inBody: path, from: i, to: target > i ? target + 1 : target)
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

// MARK: - Simple stack block

struct RoboticsSimpleBlock: View {
    @Bindable var editor: RoboticsBlockEditor
    let block: RBlock
    let path: [Int]

    private var cat: RoboticsCategory { RoboticsStyle.category(block) }

    var body: some View {
        ZStack(alignment: .leading) {
            StackBlockShape()
                .fill(cat.gradient)
                .overlay(StackBlockShape()
                    .fill(LinearGradient(colors: [.white.opacity(0.32), .clear],
                                         startPoint: .top, endPoint: .center))
                    .allowsHitTesting(false))
                .overlay(StackBlockShape().stroke(.white.opacity(0.16), lineWidth: 0.5))
                .shadow(color: cat.base.opacity(0.4), radius: 3.5, y: 3)

            HStack(spacing: 0) {
                iconTile
                Text(RoboticsStyle.label(block))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.trailing, 8)
                if let text = RoboticsStyle.valueText(block) {
                    ValuePill(text: text, tint: cat.base) { delta in
                        editor.setNumber(atNode: path, (block.number ?? 0) + delta * RoboticsStyle.step(block))
                    }
                }
                Spacer(minLength: 0)
                deleteButton
            }
            .padding(.leading, 6)
        }
        .frame(height: R.rowH)
    }

    private var iconTile: some View {
        Image(systemName: RoboticsStyle.icon(block))
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 34, height: R.rowH)
    }

    private var deleteButton: some View {
        Button { editor.delete(atNode: path) } label: {
            Image(systemName: "xmark").font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 40, height: R.rowH)
        }
    }
}

// MARK: - C-block (repeat / if / while)

struct RoboticsCBlock: View {
    @Bindable var editor: RoboticsBlockEditor
    let block: RBlock
    let path: [Int]

    private var cat: RoboticsCategory { .control }
    private var bodyBlocks: [RBlock] {
        RoboticsBlockEditor.body(in: editor.blocks, at: path[...]) ?? []
    }
    private var isTarget: Bool { editor.insertionPath == path }

    var body: some View {
        VStack(spacing: 0) {
            header
            bodyArea
            Color.clear.frame(height: R.footerH)
        }
        .background(
            CBlockShape(headerHeight: R.headerH, footerHeight: R.footerH)
                .fill(cat.gradient)
                .overlay(CBlockShape(headerHeight: R.headerH, footerHeight: R.footerH)
                    .fill(LinearGradient(colors: [.white.opacity(0.30), .clear],
                                         startPoint: .top, endPoint: .center))
                    .allowsHitTesting(false))
                .shadow(color: cat.base.opacity(0.4), radius: 4, y: 3)
        )
    }

    private var header: some View {
        HStack(spacing: 0) {
            Image(systemName: RoboticsStyle.icon(block))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: R.headerH)
                .padding(.leading, 6)

            Text(RoboticsStyle.label(block))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.trailing, 8)

            switch block {
            case let .repeatN(count, _):
                ValuePill(text: "\(count)", tint: cat.base) { delta in
                    editor.setRepeatCount(atNode: path, count + Int(delta))
                }
                Text("times")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 6)
            case let .whileC(cond, _):
                ConditionHex(cond: cond) { editor.setCondition(atNode: path, $0) }
            case let .ifC(cond, _):
                ConditionHex(cond: cond) { editor.setCondition(atNode: path, $0) }
            default:
                EmptyView()
            }

            Spacer(minLength: 0)

            Button { editor.delete(atNode: path) } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 40, height: R.headerH)
            }
        }
        .frame(height: R.headerH)
    }

    private var bodyArea: some View {
        VStack(spacing: 0) {
            if bodyBlocks.isEmpty {
                emptySlot
            } else {
                RoboticsStack(editor: editor, path: path)
            }
        }
        .padding(.leading, BlockMetrics.spine + BlockMetrics.bodyInset)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { editor.insertionPath = path }
    }

    private var emptySlot: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill").font(.system(size: 14, weight: .semibold))
            Text(isTarget ? "pick a block below" : "tap, then pick a block")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(isTarget ? 0.95 : 0.72))
        .padding(.horizontal, 12)
        .frame(height: 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(.white.opacity(isTarget ? 0.24 : 0.13))
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(.white.opacity(isTarget ? 0.9 : 0.45)))
        )
    }
}

// MARK: - Round white value field (SPIKE-style) with +/- steppers

struct ValuePill: View {
    let text: String
    let tint: Color
    let onStep: (Double) -> Void

    var body: some View {
        HStack(spacing: 3) {
            stepButton("minus") { onStep(-1) }
            Text(text)
                .font(.system(size: 15, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1).fixedSize()
                .padding(.horizontal, 2)
            stepButton("plus") { onStep(1) }
        }
        .padding(.horizontal, 5)
        .frame(height: 38)
        .background(
            Capsule().fill(.white)
                .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(0.14), radius: 1.5, y: 1)
        )
    }

    private func stepButton(_ sys: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: sys)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(tint))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Condition hexagon (the adjustable sensor)

struct ConditionHex: View {
    let cond: RCond
    let onChange: (RCond) -> Void

    var body: some View {
        HStack(spacing: 7) {
            Menu {
                Button("distance to a wall") { onChange(.distance(op: .less, cm: 30)) }
                Button("wall right ahead")   { onChange(.wallAhead) }
                Menu("colour is…") {
                    ForEach(RSenseColor.allCases, id: \.self) { c in
                        Button(c.rawValue.capitalized) { onChange(.colorIs(c)) }
                    }
                }
                Button("line on left")     { onChange(.lineLeft) }
                Button("line on right")    { onChange(.lineRight) }
                Button("gripper holding?") { onChange(.holding) }
            } label: {
                sensorLabel
            }

            if case let .distance(op, cm) = cond {
                Menu {
                    ForEach(RCompareOp.allCases, id: \.self) { o in
                        Button(o.symbol) { onChange(.distance(op: o, cm: cm)) }
                    }
                } label: {
                    Text(op.symbol)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.24)))
                }
                ValuePill(text: tileText(cm), tint: RoboticsCategory.control.base) { delta in
                    onChange(.distance(op: op, cm: max(R.tileCm, cm + delta * R.tileCm)))
                }
            }
        }
    }

    private func tileText(_ cm: Double) -> String {
        let t = Int((cm / R.tileCm).rounded())
        return "\(t) " + (t == 1 ? "tile" : "tiles")
    }

    private var sensorLabel: some View {
        HStack(spacing: 5) {
            Image(systemName: cond.icon).font(.system(size: 12, weight: .bold))
            Text(sensorText).font(.system(size: 14, weight: .heavy, design: .rounded)).fixedSize()
            Image(systemName: "chevron.down").font(.system(size: 8, weight: .black)).opacity(0.7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(
            HexBooleanShape().fill(BlockTheme.sensing)
                .overlay(HexBooleanShape()
                    .fill(LinearGradient(colors: [.white.opacity(0.28), .clear],
                                         startPoint: .top, endPoint: .center)))
                .overlay(HexBooleanShape().stroke(.white.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
        )
    }

    private var sensorText: String {
        if case .distance = cond { return "distance" }
        return cond.label
    }
}
