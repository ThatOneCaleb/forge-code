import SwiftUI
import ForgeCodeEngine

// MARK: - Shared layout metrics
//
// One source of truth so puzzle notches/tabs line up across simple blocks,
// C-blocks and the hat block. If a notch inset changes, everything still meshes.

enum BlockMetrics {
    static let corner: CGFloat      = 9      // outer corner radius
    static let notchInset: CGFloat  = 20     // block-left → start of top notch / bottom tab
    static let notchWidth: CGFloat  = 24     // notch/tab width
    static let notchDepth: CGFloat  = 6      // how far the notch dips / the tab protrudes
    static let spine: CGFloat       = 15     // C-block left bar width
    static let bodyInset: CGFloat   = 8      // padding inside the C mouth before inner blocks
    static let headerH: CGFloat     = 46     // C-block header height & simple-block height
    static let footerH: CGFloat     = 16     // C-block bottom arm height
    static let rowH: CGFloat        = 46

    /// X (relative to a C-block's own left edge) where an inner block's notch
    /// lands — so the C ceiling tab can align to it.
    static var ceilingTabX: CGFloat { spine + bodyInset + notchInset }
}

// MARK: - Category theme

/// Visual identity for a command kind: gradient, grip shade, icon, label, verb.
enum BlockTheme {
    static func gradient(for kind: CommandKind) -> LinearGradient {
        let (top, bottom) = colors(for: kind)
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    static func base(for kind: CommandKind) -> Color { colors(for: kind).1 }

    /// (lighter top, base bottom) — tuned to the LEGO SPIKE Prime category
    /// palette: Movement = teal, Motors = azure, Control = amber/gold.
    static func colors(for kind: CommandKind) -> (Color, Color) {
        switch kind {
        case .move:                 // Movement — teal
            return (Color(hue: 0.49, saturation: 0.72, brightness: 0.82),
                    Color(hue: 0.50, saturation: 0.92, brightness: 0.66))
        case .turnLeft, .turnRight: // Motors — azure/cyan
            return (Color(hue: 0.545, saturation: 0.70, brightness: 0.95),
                    Color(hue: 0.555, saturation: 0.92, brightness: 0.82))
        case .repeatBlock, .ifWallAhead: // Control — amber/gold
            return (Color(hue: 0.105, saturation: 0.78, brightness: 1.0),
                    Color(hue: 0.085, saturation: 0.92, brightness: 0.94))
        }
    }

    /// Sensing category — light blue, used for boolean/hexagon reporters.
    static let sensing = Color(hue: 0.565, saturation: 0.62, brightness: 0.90)

    /// Events category — yellow/gold, used for the hat block.
    static let events = (Color(hue: 0.135, saturation: 0.70, brightness: 1.0),
                         Color(hue: 0.120, saturation: 0.95, brightness: 0.97))

    static func icon(for kind: CommandKind) -> String {
        switch kind {
        case .move:        return "arrow.up"
        case .turnLeft:    return "arrow.uturn.left"
        case .turnRight:   return "arrow.uturn.right"
        case .repeatBlock: return "arrow.2.circlepath"
        case .ifWallAhead: return "arrow.triangle.branch"
        }
    }

    static func label(for kind: CommandKind) -> String {
        switch kind {
        case .move:        return "move"
        case .turnLeft:    return "turn"
        case .turnRight:   return "turn"
        case .repeatBlock: return "repeat"
        case .ifWallAhead: return "if"
        }
    }
}

// MARK: - Puzzle connector shape (simple stack block)

/// A stack block outline with a concave top notch and a convex bottom tab.
/// The tab draws *below* the frame; stack blocks flush (spacing 0) with the
/// upper block on top so its tab fills the lower block's notch.
struct StackBlockShape: Shape {
    var topNotch: Bool = true
    var bottomTab: Bool = true

    func path(in rect: CGRect) -> Path {
        let cr = BlockMetrics.corner
        let ci = BlockMetrics.notchInset
        let cw = BlockMetrics.notchWidth
        let ch = BlockMetrics.notchDepth
        let l = rect.minX, t = rect.minY, r = rect.maxX, b = rect.maxY

        var p = Path()
        p.move(to: CGPoint(x: l + cr, y: t))

        // Top edge + concave notch (trapezoidal)
        if topNotch {
            p.addLine(to: CGPoint(x: l + ci, y: t))
            p.addLine(to: CGPoint(x: l + ci + ch, y: t + ch))
            p.addLine(to: CGPoint(x: l + ci + cw - ch, y: t + ch))
            p.addLine(to: CGPoint(x: l + ci + cw, y: t))
        }
        p.addLine(to: CGPoint(x: r - cr, y: t))
        p.addArc(center: CGPoint(x: r - cr, y: t + cr), radius: cr,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        // Right + bottom-right corner
        p.addLine(to: CGPoint(x: r, y: b - cr))
        p.addArc(center: CGPoint(x: r - cr, y: b - cr), radius: cr,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // Bottom edge + convex tab (protrudes below)
        if bottomTab {
            p.addLine(to: CGPoint(x: l + ci + cw, y: b))
            p.addLine(to: CGPoint(x: l + ci + cw - ch, y: b + ch))
            p.addLine(to: CGPoint(x: l + ci + ch, y: b + ch))
            p.addLine(to: CGPoint(x: l + ci, y: b))
        }
        p.addLine(to: CGPoint(x: l + cr, y: b))
        p.addArc(center: CGPoint(x: l + cr, y: b - cr), radius: cr,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        // Left edge + top-left corner
        p.addLine(to: CGPoint(x: l, y: t + cr))
        p.addArc(center: CGPoint(x: l + cr, y: t + cr), radius: cr,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - C-block wrapper shape (repeat / if)

/// The classic "C" outline: full-width header, a left spine, an open mouth on
/// the right, and a full-width bottom arm. Header top carries a notch; the
/// bottom arm carries a tab; the mouth ceiling carries a small tab so the first
/// inner block visually seats into it.
struct CBlockShape: Shape {
    var headerHeight: CGFloat
    var footerHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let cr = BlockMetrics.corner
        let ci = BlockMetrics.notchInset
        let cw = BlockMetrics.notchWidth
        let ch = BlockMetrics.notchDepth
        let spine = BlockMetrics.spine
        let ir: CGFloat = 6   // inner (mouth) corner radius
        let tabX = BlockMetrics.ceilingTabX

        let l = rect.minX, t = rect.minY, r = rect.maxX, b = rect.maxY
        let mouthTop = t + headerHeight
        let mouthBot = b - footerHeight

        var p = Path()
        p.move(to: CGPoint(x: l + cr, y: t))

        // Header top edge + notch
        p.addLine(to: CGPoint(x: l + ci, y: t))
        p.addLine(to: CGPoint(x: l + ci + ch, y: t + ch))
        p.addLine(to: CGPoint(x: l + ci + cw - ch, y: t + ch))
        p.addLine(to: CGPoint(x: l + ci + cw, y: t))
        p.addLine(to: CGPoint(x: r - cr, y: t))
        p.addArc(center: CGPoint(x: r - cr, y: t + cr), radius: cr,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)

        // Right edge of header down to the mouth
        p.addLine(to: CGPoint(x: r, y: mouthTop))

        // Mouth ceiling: travel left, dropping a small convex tab for the inner block
        p.addLine(to: CGPoint(x: tabX + cw, y: mouthTop))
        p.addLine(to: CGPoint(x: tabX + cw - ch, y: mouthTop + ch))
        p.addLine(to: CGPoint(x: tabX + ch, y: mouthTop + ch))
        p.addLine(to: CGPoint(x: tabX, y: mouthTop))
        p.addLine(to: CGPoint(x: spine + ir, y: mouthTop))
        p.addArc(center: CGPoint(x: spine + ir, y: mouthTop + ir), radius: ir,
                 startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: true)

        // Down the spine inner wall
        p.addLine(to: CGPoint(x: spine, y: mouthBot - ir))
        p.addArc(center: CGPoint(x: spine + ir, y: mouthBot - ir), radius: ir,
                 startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)

        // Footer ceiling back out to the right edge
        p.addLine(to: CGPoint(x: r, y: mouthBot))

        // Right edge of footer + bottom-right corner
        p.addLine(to: CGPoint(x: r, y: b - cr))
        p.addArc(center: CGPoint(x: r - cr, y: b - cr), radius: cr,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)

        // Bottom edge + tab
        p.addLine(to: CGPoint(x: l + ci + cw, y: b))
        p.addLine(to: CGPoint(x: l + ci + cw - ch, y: b + ch))
        p.addLine(to: CGPoint(x: l + ci + ch, y: b + ch))
        p.addLine(to: CGPoint(x: l + ci, y: b))
        p.addLine(to: CGPoint(x: l + cr, y: b))
        p.addArc(center: CGPoint(x: l + cr, y: b - cr), radius: cr,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)

        // Left outer edge + top-left corner
        p.addLine(to: CGPoint(x: l, y: t + cr))
        p.addArc(center: CGPoint(x: l + cr, y: t + cr), radius: cr,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Boolean hexagon reporter (Sensing)

/// A pointed hexagon — the SPIKE/Scratch shape for a boolean sensor value
/// that plugs into an `if` condition slot.
struct HexBooleanShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = min(rect.height * 0.5, 11)
        let l = rect.minX, t = rect.minY, r = rect.maxX, b = rect.maxY
        let midY = rect.midY
        var p = Path()
        p.move(to: CGPoint(x: l + inset, y: t))
        p.addLine(to: CGPoint(x: r - inset, y: t))
        p.addLine(to: CGPoint(x: r, y: midY))
        p.addLine(to: CGPoint(x: r - inset, y: b))
        p.addLine(to: CGPoint(x: l + inset, y: b))
        p.addLine(to: CGPoint(x: l, y: midY))
        p.closeSubpath()
        return p
    }
}

/// A light-blue sensing boolean, e.g. "wall ahead?", for an `if` condition.
struct SensorBooleanView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .fixedSize()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .frame(height: 32)
        .background(
            HexBooleanShape()
                .fill(BlockTheme.sensing)
                .overlay(
                    HexBooleanShape()
                        .fill(LinearGradient(colors: [.white.opacity(0.25), .clear],
                                             startPoint: .top, endPoint: .center))
                )
                .overlay(HexBooleanShape().stroke(.white.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
        )
    }
}

// MARK: - Hat block

/// The rounded "start" cap the whole script hangs from — bottom tab only.
struct HatBlockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cr = BlockMetrics.corner
        let ci = BlockMetrics.notchInset
        let cw = BlockMetrics.notchWidth
        let ch = BlockMetrics.notchDepth
        let l = rect.minX, t = rect.minY, r = rect.maxX, b = rect.maxY
        let dome = min(rect.height * 0.9, 26)

        var p = Path()
        // Rounded dome across the top
        p.move(to: CGPoint(x: l, y: b - cr))
        p.addLine(to: CGPoint(x: l, y: t + dome))
        p.addQuadCurve(to: CGPoint(x: l + dome, y: t),
                       control: CGPoint(x: l, y: t))
        p.addLine(to: CGPoint(x: r - dome, y: t))
        p.addQuadCurve(to: CGPoint(x: r, y: t + dome),
                       control: CGPoint(x: r, y: t))
        p.addLine(to: CGPoint(x: r, y: b - cr))
        p.addArc(center: CGPoint(x: r - cr, y: b - cr), radius: cr,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // Bottom tab
        p.addLine(to: CGPoint(x: l + ci + cw, y: b))
        p.addLine(to: CGPoint(x: l + ci + cw - ch, y: b + ch))
        p.addLine(to: CGPoint(x: l + ci + ch, y: b + ch))
        p.addLine(to: CGPoint(x: l + ci, y: b))
        p.addLine(to: CGPoint(x: l + cr, y: b))
        p.addArc(center: CGPoint(x: l + cr, y: b - cr), radius: cr,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct HatBlockView: View {
    var body: some View {
        ZStack(alignment: .leading) {
            HatBlockShape()
                .fill(LinearGradient(colors: [BlockTheme.events.0, BlockTheme.events.1],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    HatBlockShape()
                        .fill(LinearGradient(colors: [.white.opacity(0.35), .clear],
                                             startPoint: .top, endPoint: .center))
                        .allowsHitTesting(false)
                )
                .shadow(color: Color(hue: 0.10, saturation: 0.9, brightness: 0.8).opacity(0.4),
                        radius: 4, y: 3)

            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hue: 0.34, saturation: 0.85, brightness: 0.72))
                Text("when")
                    .foregroundStyle(.brown.opacity(0.85))
                Text("Run")
                    .foregroundStyle(Color(hue: 0.08, saturation: 0.95, brightness: 0.55))
                Text("pressed")
                    .foregroundStyle(.brown.opacity(0.85))
            }
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .padding(.leading, 18)
        }
        .frame(height: 42)
    }
}

// MARK: - Workshop canvas background

/// A faint dotted grid — the "build surface" behind the script.
struct WorkshopCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 22
            let dot: CGFloat = 1.4
            let color = GraphicsContext.Shading.color(.black.opacity(0.06))
            var y: CGFloat = step / 2
            while y < size.height {
                var x: CGFloat = step / 2
                while x < size.width {
                    let rect = CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot)
                    ctx.fill(Path(ellipseIn: rect), with: color)
                    x += step
                }
                y += step
            }
        }
        .background(Color(hue: 0.62, saturation: 0.05, brightness: 0.97))
    }
}
