import SwiftUI

/// A buildable piece of the academy. Built by spending stars; the base visibly
/// grows as more are added.
struct AcademyModule: Identifiable {
    let id: String
    let name: String
    let cost: Int
    let pos: CGPoint       // relative position in the scene (0…1)
    let size: CGFloat      // relative size (fraction of scene width)
    let tint: Color
    let blurb: String
}

enum AcademyCatalog {
    static let modules: [AcademyModule] = [
        .init(id: "dome",   name: "Habitat Dome", cost: 1,  pos: CGPoint(x: 0.20, y: 0.70), size: 0.22,
              tint: Color(hue: 0.55, saturation: 0.55, brightness: 0.95),
              blurb: "Home sweet dome. Somewhere to sleep between missions."),
        .init(id: "comms",  name: "Comms Tower",  cost: 2,  pos: CGPoint(x: 0.80, y: 0.60), size: 0.16,
              tint: Color(hue: 0.02, saturation: 0.60, brightness: 0.95),
              blurb: "Call the crew — and pick up strange signals from far away."),
        .init(id: "green",  name: "Greenhouse",   cost: 4,  pos: CGPoint(x: 0.44, y: 0.76), size: 0.20,
              tint: Color(hue: 0.33, saturation: 0.55, brightness: 0.85),
              blurb: "Grow space veggies. Spark keeps eating them."),
        .init(id: "solar",  name: "Solar Array",  cost: 6,  pos: CGPoint(x: 0.64, y: 0.78), size: 0.18,
              tint: Color(hue: 0.60, saturation: 0.50, brightness: 0.85),
              blurb: "Soak up starlight to power the whole base."),
        .init(id: "obs",    name: "Observatory",  cost: 9,  pos: CGPoint(x: 0.34, y: 0.55), size: 0.20,
              tint: Color(hue: 0.72, saturation: 0.45, brightness: 0.92),
              blurb: "Spot new worlds — and maybe where the lost cadets went."),
        .init(id: "launch", name: "Launch Pad",   cost: 12, pos: CGPoint(x: 0.86, y: 0.80), size: 0.18,
              tint: Color(hue: 0.09, saturation: 0.75, brightness: 1.0),
              blurb: "Blast off to the next planet. Almost ready…"),
    ]

    static func module(_ id: String) -> AcademyModule? { modules.first { $0.id == id } }
    static var totalCost: Int { modules.reduce(0) { $0 + $1.cost } }
}

// MARK: - Cute shape-art per module

struct ModuleArt: View {
    let id: String
    let tint: Color
    let size: CGFloat

    var body: some View {
        switch id {
        case "dome":   dome
        case "comms":  comms
        case "green":  greenhouse
        case "solar":  solar
        case "obs":    observatory
        case "launch": launch
        default:       dome
        }
    }

    private var s: CGFloat { size }

    // Habitat dome: half-circle + door + window
    private var dome: some View {
        ZStack(alignment: .bottom) {
            Circle().fill(grad).frame(width: s, height: s)
                .clipShape(Rectangle().offset(y: -s * 0.25)).offset(y: s * 0.25)
            Circle().trim(from: 0.5, to: 1.0).fill(grad).frame(width: s, height: s)
            RoundedRectangle(cornerRadius: s * 0.05).fill(.white.opacity(0.85))
                .frame(width: s * 0.18, height: s * 0.26).offset(x: 0, y: 0)
            Circle().fill(.white.opacity(0.9)).frame(width: s * 0.16, height: s * 0.16)
                .offset(x: -s * 0.22, y: -s * 0.18)
        }
        .frame(width: s, height: s * 0.6, alignment: .bottom)
    }

    // Comms tower: tapered mast + dish
    private var comms: some View {
        ZStack(alignment: .bottom) {
            Trapezoid(topRatio: 0.4).fill(grad).frame(width: s * 0.5, height: s)
            Circle().fill(.white.opacity(0.9)).frame(width: s * 0.4, height: s * 0.4)
                .overlay(Circle().fill(tint).frame(width: s * 0.16, height: s * 0.16))
                .offset(x: s * 0.16, y: -s * 0.7).rotationEffect(.degrees(-20))
            Capsule().fill(.white).frame(width: s * 0.05, height: s * 0.28).offset(y: -s * 0.9)
        }
        .frame(width: s, height: s, alignment: .bottom)
    }

    private var greenhouse: some View {
        ZStack(alignment: .bottom) {
            Circle().trim(from: 0.5, to: 1.0).fill(grad.opacity(0.85)).frame(width: s, height: s)
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color(hue: 0.33, saturation: 0.7, brightness: 0.7))
                    .frame(width: s * 0.06, height: s * 0.22)
                    .offset(x: CGFloat(i - 1) * s * 0.18, y: -s * 0.02)
            }
        }
        .frame(width: s, height: s * 0.55, alignment: .bottom)
    }

    private var solar: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(.gray).frame(width: s * 0.06, height: s * 0.5).offset(y: -s * 0.1)
            RoundedRectangle(cornerRadius: s * 0.04)
                .fill(grad)
                .overlay(GridLines().stroke(.white.opacity(0.5), lineWidth: 1))
                .frame(width: s * 0.9, height: s * 0.4)
                .rotationEffect(.degrees(-18)).offset(y: -s * 0.35)
        }
        .frame(width: s, height: s * 0.65, alignment: .bottom)
    }

    private var observatory: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: s * 0.06).fill(grad.opacity(0.9))
                .frame(width: s * 0.7, height: s * 0.35)
            Circle().trim(from: 0.5, to: 1.0).fill(grad).frame(width: s * 0.7, height: s * 0.7)
                .offset(y: -s * 0.32)
            Capsule().fill(.white).frame(width: s * 0.4, height: s * 0.1)
                .rotationEffect(.degrees(-30)).offset(x: s * 0.16, y: -s * 0.5)
        }
        .frame(width: s, height: s * 0.7, alignment: .bottom)
    }

    private var launch: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: s * 0.05).fill(.gray.opacity(0.7))
                .frame(width: s * 0.8, height: s * 0.14)
            // rocket
            ZStack(alignment: .bottom) {
                Capsule().fill(grad).frame(width: s * 0.3, height: s * 0.6)
                Triangle().fill(.red).frame(width: s * 0.3, height: s * 0.25).offset(y: -s * 0.55)
                Circle().fill(.white.opacity(0.9)).frame(width: s * 0.12, height: s * 0.12).offset(y: -s * 0.25)
            }
            .offset(y: -s * 0.1)
        }
        .frame(width: s, height: s * 0.8, alignment: .bottom)
    }

    private var grad: LinearGradient {
        LinearGradient(colors: [tint.lighter(0.15), tint], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Small shapes

struct Trapezoid: Shape {
    var topRatio: CGFloat = 0.5
    func path(in r: CGRect) -> Path {
        var p = Path()
        let inset = r.width * (1 - topRatio) / 2
        p.move(to: CGPoint(x: r.minX + inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct GridLines: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 1..<4 { let x = r.width * CGFloat(i) / 4
            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: r.height)) }
        p.move(to: CGPoint(x: 0, y: r.midY)); p.addLine(to: CGPoint(x: r.width, y: r.midY))
        return p
    }
}

extension Color {
    func lighter(_ amount: CGFloat) -> Color {
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: max(0, s - amount * 0.4), brightness: min(1, b + amount))
    }
}
