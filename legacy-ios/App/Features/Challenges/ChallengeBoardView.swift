import SwiftUI
import ForgeCodeEngine

/// A clean 2D tile board for a bridged Challenge. Draws the grid, walls and
/// goal from the `FieldWorld`, and a friendly robot at `pose` (continuous cm,
/// heading 0° = up). The robot animates because `pose` is driven with
/// `withAnimation` from the view-model's playback.
struct ChallengeBoardView: View {
    let world: FieldWorld
    let pose: Pose
    var collectedGemIds: Set<String> = []

    private var cols: Int { Int((world.widthCm  / 30).rounded()) }
    private var rows: Int { Int((world.heightCm / 30).rounded()) }

    var body: some View {
        GeometryReader { geo in
            let tile = geo.size.width / CGFloat(cols)
            let boardH = tile * CGFloat(rows)
            let ppc = tile / 30.0   // points per cm

            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    drawBoard(ctx, size: size, tile: tile)
                }

                // Collectible gems (pop when collected)
                ForEach(world.items, id: \.id) { item in
                    let collected = collectedGemIds.contains(item.id)
                    Image(systemName: "diamond.fill")
                        .font(.system(size: tile * 0.4, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(hue: 0.5, saturation: 0.7, brightness: 1),
                                                    Color(hue: 0.55, saturation: 0.85, brightness: 0.85)],
                                           startPoint: .top, endPoint: .bottom))
                        .shadow(color: Color(hue: 0.55, saturation: 0.8, brightness: 0.9).opacity(0.7),
                                radius: collected ? 10 : 3)
                        .scaleEffect(collected ? 1.9 : 1)
                        .opacity(collected ? 0 : 1)
                        .rotationEffect(.degrees(collected ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: collected)
                        .position(point(item.position, ppc: ppc, boardH: boardH))
                }

                // Goal flag marker
                if let goal = world.zones.first(where: { $0.kind == .goal }) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: tile * 0.42, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        .position(point(goal.rect.centre, ppc: ppc, boardH: boardH))
                }

                // Robot
                RobotSprite(size: tile * 0.82)
                    .rotationEffect(.degrees(pose.headingDegrees))
                    .position(point(pose.position, ppc: ppc, boardH: boardH))
            }
            .frame(width: geo.size.width, height: boardH)
        }
        .aspectRatio(CGFloat(cols) / CGFloat(rows), contentMode: .fit)
    }

    private func point(_ v: Vec2, ppc: CGFloat, boardH: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(v.x) * ppc, y: boardH - CGFloat(v.y) * ppc)
    }

    private func drawBoard(_ ctx: GraphicsContext, size: CGSize, tile: CGFloat) {
        // Base
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(Color(hue: 0.57, saturation: 0.10, brightness: 0.96)))

        // Checkerboard tiles
        for r in 0..<rows {
            for c in 0..<cols where (r + c) % 2 == 1 {
                let rect = CGRect(x: CGFloat(c) * tile, y: CGFloat(r) * tile, width: tile, height: tile)
                ctx.fill(Path(rect), with: .color(Color(hue: 0.57, saturation: 0.14, brightness: 0.90)))
            }
        }

        // Walls (obstacles) — dark rounded blocks
        for obs in world.obstacles {
            let rect = tileRect(obs.rect, tile: tile, size: size)
                .insetBy(dx: tile * 0.06, dy: tile * 0.06)
            let path = Path(roundedRect: rect, cornerRadius: tile * 0.16)
            ctx.fill(path, with: .color(Color(hue: 0.6, saturation: 0.22, brightness: 0.32)))
            ctx.stroke(path, with: .color(.black.opacity(0.25)), lineWidth: 1.5)
        }

        // Goal tile glow
        if let goal = world.zones.first(where: { $0.kind == .goal }) {
            let rect = tileRect(goal.rect, tile: tile, size: size).insetBy(dx: tile * 0.04, dy: tile * 0.04)
            let path = Path(roundedRect: rect, cornerRadius: tile * 0.18)
            ctx.fill(path, with: .color(Color(hue: 0.36, saturation: 0.62, brightness: 0.72)))
            ctx.stroke(path, with: .color(.white.opacity(0.7)), lineWidth: 2)
        }

        // Grid lines
        var grid = Path()
        for c in 0...cols {
            let x = CGFloat(c) * tile
            grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
        }
        for r in 0...rows {
            let y = CGFloat(r) * tile
            grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
        }
        ctx.stroke(grid, with: .color(Color(hue: 0.58, saturation: 0.3, brightness: 0.55).opacity(0.35)),
                   lineWidth: 1)
    }

    /// FieldRect (cm, +y up) → board CGRect (points, +y down).
    private func tileRect(_ r: FieldRect, tile: CGFloat, size: CGSize) -> CGRect {
        let ppc = tile / 30.0
        let x = CGFloat(r.x) * ppc
        let y = size.height - CGFloat(r.y + r.height) * ppc
        return CGRect(x: x, y: y, width: CGFloat(r.width) * ppc, height: CGFloat(r.height) * ppc)
    }
}

// MARK: - Robot sprite (points up at heading 0)

struct RobotSprite: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(.black.opacity(0.18))
                .frame(width: size * 0.7, height: size * 0.22)
                .offset(y: size * 0.42)

            // Body
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hue: 0.09, saturation: 0.85, brightness: 1.0),
                             Color(hue: 0.06, saturation: 0.95, brightness: 0.90)],
                    startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: size * 0.26)
                    .stroke(.white.opacity(0.5), lineWidth: size * 0.03))
                .frame(width: size * 0.72, height: size * 0.72)

            // Direction headlight (points up = forward)
            Capsule()
                .fill(.white.opacity(0.95))
                .frame(width: size * 0.22, height: size * 0.1)
                .offset(y: -size * 0.3)

            // Eyes
            HStack(spacing: size * 0.12) {
                Circle().fill(.white).frame(width: size * 0.16, height: size * 0.16)
                    .overlay(Circle().fill(Color(hue: 0.6, saturation: 0.8, brightness: 0.3))
                        .frame(width: size * 0.08, height: size * 0.08))
                Circle().fill(.white).frame(width: size * 0.16, height: size * 0.16)
                    .overlay(Circle().fill(Color(hue: 0.6, saturation: 0.8, brightness: 0.3))
                        .frame(width: size * 0.08, height: size * 0.08))
            }
            .offset(y: -size * 0.02)
        }
        .frame(width: size, height: size)
    }
}
