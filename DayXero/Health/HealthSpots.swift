import DayXeroCore
import SwiftUI

/// The paper-cut spot for each change in the body (v5, 037), in the mockup's 62 × 62 box: a day palette and a real
/// night palette (navy skies, a low sun or the moon, cream and gold accents), never a dimmed copy of the day art.
enum HealthSpotKind {
    case rise, cloud, peak, lake, mirror, moon, breeze, sparkle

    init(id: String) {
        switch id {
        case "withdrawal-start", "heart-rate", "clearer-head": self = .rise
        case "nicotine-gone", "carbon-monoxide", "flat-days": self = .cloud
        case "withdrawal-peak", "heart-attack", "heart-disease": self = .peak
        case "mood", "mouth-cancer", "lung-cancer": self = .lake
        case "lips": self = .mirror
        case "sleep": self = .moon
        case "cravings-fade", "circulation", "coughing", "fresh-breath": self = .breeze
        default: self = .sparkle
        }
    }
}

struct HealthSpot: View {
    let kind: HealthSpotKind
    @Environment(\.colorScheme) private var scheme

    init(id: String) { kind = HealthSpotKind(id: id) }

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 62, y: size.height / 62)
            if scheme == .dark { Self.night(&ctx, kind) } else { Self.day(&ctx, kind) }
        }
        .accessibilityHidden(true)
    }

    // MARK: Pieces

    private static func bg(_ ctx: inout GraphicsContext, _ hex: UInt32) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 62, height: 62)), with: .color(Color(hex: hex)))
    }

    /// Three paper hills, lifted by a soft shadow above each.
    static func hills(_ ctx: inout GraphicsContext, _ c: [UInt32], peak: Bool = false, dark: Bool) {
        var layer = ctx
        layer.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.5 : 0.22), radius: 1.2, x: 0, y: -1.2))
        CalmPaint.fill(&layer, peak ? "M0 44 L14 34 L22 38 L36 14 L50 32 L62 28 V62 H0z" : "M0 40 C14 32 28 36 40 34 S52 30 62 32 V62 H0z", c[0])
        CalmPaint.fill(&layer, "M0 47 C16 41 34 49 62 43 V62 H0z", c[1])
        CalmPaint.fill(&layer, "M0 55 C20 51 40 57 62 52 V62 H0z", c[2])
    }

    private static func lifted(_ ctx: inout GraphicsContext, _ d: String, _ hex: UInt32, dark: Bool) {
        var layer = ctx
        layer.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.5 : 0.22), radius: 1.2, x: 0, y: -1.2))
        CalmPaint.fill(&layer, d, hex)
    }

    private static func disc(_ ctx: inout GraphicsContext, _ x: Double, _ y: Double, _ r: Double, _ hex: UInt32, glow: (UInt32, Double)? = nil) {
        if let glow { CalmPaint.glow(&ctx, x, y, r * 2.6, glow.0, glow.1, mid: (0.3, glow.1)) }
        ctx.fill(CalmPaint.circle(x, y, r), with: .color(Color(hex: hex)))
    }

    static let cloudD = "M2 12h20a5 5 0 000-10 7 7 0 00-13-1 5 5 0 00-7 4 3.5 3.5 0 000 7z"

    private static func cloud(_ ctx: inout GraphicsContext, _ x: Double, _ y: Double, _ k: Double, _ hex: UInt32, _ opacity: Double = 1) {
        ctx.fill(SVGPath.path(cloudD).applying(CGAffineTransform(translationX: x, y: y).scaledBy(x: k, y: k)),
                 with: .color(Color(hex: hex).opacity(opacity)))
    }

    private static func stars(_ ctx: inout GraphicsContext, _ pts: [(Double, Double)]) {
        for (i, p) in pts.enumerated() {
            ctx.fill(CalmPaint.circle(p.0, p.1, i % 2 == 1 ? 0.8 : 1.1), with: .color(.white.opacity(i % 2 == 1 ? 0.55 : 0.9)))
        }
    }

    private static func lines(_ ctx: inout GraphicsContext, _ ds: [String], _ color: Color, width: Double) {
        for d in ds { ctx.stroke(SVGPath.path(d), with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round)) }
    }

    static func star4(_ x: Double, _ y: Double, _ r: Double) -> Path {
        SVGPath.path("M\(x) \(y - r)Q\(x) \(y) \(x + r) \(y)Q\(x) \(y) \(x) \(y + r)Q\(x) \(y) \(x - r) \(y)Q\(x) \(y) \(x) \(y - r)Z")
    }

    private static func mirror(_ ctx: inout GraphicsContext, frame: UInt32, glass: UInt32, shine: UInt32, spark: UInt32) {
        var g = ctx
        g.translateBy(x: 31, y: 32)
        g.rotate(by: .degrees(-14))
        g.translateBy(x: -31, y: -32)
        g.fill(Path(roundedRect: CGRect(x: 28.5, y: 38, width: 5, height: 17), cornerRadius: 2.5), with: .color(Color(hex: frame)))
        g.fill(CalmPaint.ellipse(31, 27, 13, 15), with: .color(Color(hex: frame)))
        g.fill(CalmPaint.ellipse(31, 27, 9.6, 11.6), with: .color(Color(hex: glass)))
        g.stroke(SVGPath.path("M25 22 C26 18 29 16 32 15.6"), with: .color(Color(hex: shine)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        ctx.fill(SVGPath.path("M47 9l1.6 3.6 3.6 1.6-3.6 1.6L47 19.4l-1.6-3.6-3.6-1.6 3.6-1.6z"), with: .color(Color(hex: spark)))
        ctx.fill(SVGPath.path("M13 14l1 2.2 2.2 1-2.2 1-1 2.2-1-2.2-2.2-1 2.2-1z"), with: .color(Color(hex: spark).opacity(0.8)))
    }

    // MARK: Day

    static func day(_ ctx: inout GraphicsContext, _ kind: HealthSpotKind) {
        switch kind {
        case .rise:
            bg(&ctx, 0xFFE6C8)
            disc(&ctx, 31, 40, 13, 0xFFD25E)
            hills(&ctx, [0xFFAE73, 0xFF8A5E, 0xE8674A], dark: false)
        case .cloud:
            bg(&ctx, 0xDCE8FF)
            lines(&ctx, ["M6 17h16", "M10 24h10"], .white, width: 2.4)
            cloud(&ctx, 26, 11, 1.05, 0xFFFFFF)
            cloud(&ctx, 44, 25, 0.55, 0xFFFFFF, 0.75)
            hills(&ctx, [0xA9C2F2, 0x7FA0EA, 0x5C7FE0], dark: false)
        case .peak:
            bg(&ctx, 0xFFD9C2)
            disc(&ctx, 12, 13, 6, 0xFFD25E)
            hills(&ctx, [0xE8674A, 0xFF8A5E, 0xFFAE73], peak: true, dark: false)
            lines(&ctx, ["M36 14V4"], Color(hex: 0x1E1A3A), width: 1.8)
            CalmPaint.fill(&ctx, "M36 4.5l9 3-9 3z", 0x1E1A3A)
        case .lake:
            bg(&ctx, 0xD3F1E0)
            disc(&ctx, 31, 24, 10, 0xFFD25E)
            lifted(&ctx, "M0 34 C12 28 24 32 34 31 S50 26 62 30 V62 H0z", 0x7FD3A6, dark: false)
            ctx.fill(Path(CGRect(x: 0, y: 40, width: 62, height: 22)), with: .color(Color(hex: 0x8ECDE6)))
            lines(&ctx, ["M22 46h18", "M26 52h10", "M8 57h8", "M46 57h8"], Color(hex: 0xFFF8EE), width: 2)
            ctx.fill(CalmPaint.ellipse(31, 44, 7, 1.6), with: .color(Color(hex: 0xFFD25E).opacity(0.9)))
        case .mirror:
            bg(&ctx, 0xFFE3D6)
            ctx.fill(CalmPaint.circle(31, 30, 24), with: .color(Color(hex: 0xFFF1E8).opacity(0.8)))
            lifted(&ctx, "M0 50 C20 46 40 52 62 47 V62 H0z", 0xFFB9A4, dark: false)
            mirror(&ctx, frame: 0xFF8A6B, glass: 0xCFE1FF, shine: 0xFFFFFF, spark: 0xF5B83D)
        case .moon:
            bg(&ctx, 0xE4E0F8)
            CalmPaint.fill(&ctx, "M38 10 A11 11 0 1 0 48 26 A9 9 0 1 1 38 10Z", 0xFFD25E)
            ctx.fill(star4(16, 14, 3), with: .color(Color(hex: 0xF5B83D)))
            ctx.fill(star4(24, 24, 2), with: .color(Color(hex: 0xF5B83D).opacity(0.8)))
            hills(&ctx, [0xB9ACEA, 0x9C8BDD, 0x7E6CCB], dark: false)
        case .breeze:
            bg(&ctx, 0xDDF2F4)
            lines(&ctx, ["M6 14h20", "M12 21h22", "M8 28h12"], .white, width: 2.4)
            cloud(&ctx, 34, 9, 0.9, 0xFFFFFF)
            hills(&ctx, [0x9ED9B8, 0x7CC8A0, 0x5DB487], dark: false)
        case .sparkle:
            bg(&ctx, 0xFFF0D6)
            disc(&ctx, 31, 34, 11, 0xFFD25E)
            ctx.fill(star4(14, 14, 5), with: .color(Color(hex: 0xF5B83D)))
            ctx.fill(star4(48, 12, 3.5), with: .color(Color(hex: 0xF5B83D).opacity(0.85)))
            ctx.fill(star4(44, 26, 2.4), with: .color(Color(hex: 0xF5B83D).opacity(0.7)))
            hills(&ctx, [0xFFC38A, 0xFFAE73, 0xFF8A5E], dark: false)
        }
    }

    // MARK: Night

    static func night(_ ctx: inout GraphicsContext, _ kind: HealthSpotKind) {
        let sunGlow: (UInt32, Double) = (0xFFB25E, 0.5)
        switch kind {
        case .rise:
            bg(&ctx, 0x1B284A)
            stars(&ctx, [(10, 9), (26, 6), (48, 12)])
            disc(&ctx, 31, 40, 10, 0xFFD27A, glow: sunGlow)
            hills(&ctx, [0x2C3D6A, 0x1E2B4A, 0x16233F], dark: true)
        case .cloud:
            bg(&ctx, 0x172648)
            stars(&ctx, [(8, 8), (54, 10)])
            lines(&ctx, ["M6 17h16", "M10 24h10"], Color(hex: 0x8EA2D6).opacity(0.7), width: 2.2)
            cloud(&ctx, 26, 11, 1.05, 0x4A5D8E)
            cloud(&ctx, 44, 25, 0.55, 0x3A4C7C)
            hills(&ctx, [0x26396A, 0x1C2D55, 0x142343], dark: true)
        case .peak:
            bg(&ctx, 0x1B284A)
            disc(&ctx, 12, 13, 5, 0xF6E7C1)
            stars(&ctx, [(30, 6), (52, 10)])
            hills(&ctx, [0x33446F, 0x22335B, 0x16233F], peak: true, dark: true)
            lines(&ctx, ["M36 14V4"], Color(hex: 0xE6DCCB), width: 1.8)
            CalmPaint.fill(&ctx, "M36 4.5l9 3-9 3z", 0xE9886C)
        case .lake:
            bg(&ctx, 0x16244A)
            stars(&ctx, [(9, 8), (50, 6), (20, 16)])
            disc(&ctx, 42, 18, 7, 0xF6E7C1, glow: (0xF6E7C1, 0.35))
            lifted(&ctx, "M0 34 C12 28 24 32 34 31 S50 26 62 30 V62 H0z", 0x22355F, dark: true)
            ctx.fill(Path(CGRect(x: 0, y: 40, width: 62, height: 22)), with: .color(Color(hex: 0x2A4677)))
            lines(&ctx, ["M34 46h14", "M38 52h8", "M8 56h8"], Color(hex: 0xF6E7C1).opacity(0.75), width: 2)
        case .mirror:
            bg(&ctx, 0x1E2C52)
            stars(&ctx, [(8, 34), (54, 32)])
            lifted(&ctx, "M0 50 C20 46 40 52 62 47 V62 H0z", 0x2C3D6A, dark: true)
            mirror(&ctx, frame: 0xE6DCCB, glass: 0x8FB1E8, shine: 0xF6EFE2, spark: 0xFFD27A)
        case .moon:
            bg(&ctx, 0x16244A)
            stars(&ctx, [(10, 30), (22, 8), (54, 34), (14, 18)])
            CalmPaint.fill(&ctx, "M38 10 A11 11 0 1 0 48 26 A9 9 0 1 1 38 10Z", 0xF6E7C1)
            hills(&ctx, [0x2C3D6A, 0x1E2B4A, 0x16233F], dark: true)
        case .breeze:
            bg(&ctx, 0x172648)
            stars(&ctx, [(52, 30), (6, 8)])
            lines(&ctx, ["M6 14h20", "M12 21h22", "M8 28h12"], Color(hex: 0x8EA2D6).opacity(0.7), width: 2.2)
            cloud(&ctx, 34, 9, 0.9, 0x4A5D8E)
            hills(&ctx, [0x26396A, 0x1C2D55, 0x142343], dark: true)
        case .sparkle:
            bg(&ctx, 0x1B284A)
            disc(&ctx, 31, 36, 9, 0xFFD27A, glow: sunGlow)
            ctx.fill(star4(14, 14, 5), with: .color(Color(hex: 0xFFD27A)))
            ctx.fill(star4(48, 12, 3.5), with: .color(Color(hex: 0xFFD27A).opacity(0.85)))
            ctx.fill(star4(44, 26, 2.4), with: .color(Color(hex: 0xFFD27A).opacity(0.7)))
            hills(&ctx, [0x2C3D6A, 0x1E2B4A, 0x16233F], dark: true)
        }
    }
}

// MARK: - The change's scene (038)

/// The paper-cut scene at the top of a change's story, led by Xero on the hills: for lips and gums he stands
/// smiling beside a little standing mirror, a soft pink glow on his cheeks; the other changes keep their spot's
/// motif in the sky. Day: a warm dawn and a gold sun. Night: a navy sky, a crescent moon and stars.
struct HealthScene: View {
    let id: String
    @Environment(\.colorScheme) private var scheme
    @State private var twinkle = false
    private let motion = MotionPolicy()

    var body: some View {
        let kind = HealthSpotKind(id: id)
        let dark = scheme == .dark
        GeometryReader { proxy in
            let k = proxy.size.width / 346
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    ctx.scaleBy(x: k, y: k)
                    ctx.translateBy(x: 0, y: 16)
                    Self.back(&ctx, kind: kind, dark: dark)
                }
                XeroView(mood: .hello, stage: 0, points: 162 * k)
                    .frame(width: 162 * k, height: 162 * k)
                    .overlay { if kind == .mirror { cheeks.dxFade(delay: 0.9) } }
                    .dxBob()
                    .dxSettle(delay: 0.2)
                    .offset(x: 50 * k, y: 20 * k)
                Canvas { ctx, _ in
                    ctx.scaleBy(x: k, y: k)
                    ctx.translateBy(x: 0, y: 16)
                    Self.front(&ctx, kind: kind, dark: dark)
                }
                .allowsHitTesting(false)
                sparkles(k: k, dark: dark)
            }
        }
        .onAppear {
            guard motion.breathes else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.2)) { twinkle = true }
        }
        .accessibilityHidden(true)
    }

    private var cheeks: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 200
            let gradient = RadialGradient(stops: [
                .init(color: Color(hex: 0xFF5F86).opacity(0.7), location: 0),
                .init(color: Color(hex: 0xFF8FA3).opacity(0.32), location: 0.5),
                .init(color: Color(hex: 0xFF8FA3).opacity(0), location: 1),
            ], center: .center, startRadius: 0, endRadius: 27 * s)
            ZStack(alignment: .topLeading) {
                Circle().fill(gradient).frame(width: 54 * s, height: 54 * s).offset(x: 43 * s, y: 67 * s)
                Circle().fill(gradient).frame(width: 54 * s, height: 54 * s).offset(x: 103 * s, y: 67 * s)
            }
        }
        .allowsHitTesting(false)
    }

    private func sparkles(k: CGFloat, dark: Bool) -> some View {
        let spark = Color(hex: dark ? 0xFFD27A : 0xF5B83D)
        let points: [(Double, Double, Double)] = [(286, 84, 9.5), (218, 50, 6)]
        return ZStack {
            ForEach(Array(points.enumerated()), id: \.offset) { i, p in
                Spark().fill(spark)
                    .frame(width: 2 * p.2 * k, height: 2 * p.2 * k)
                    .scaleEffect(twinkle ? 0.7 : 1)
                    .opacity(twinkle ? 0.6 : 1)
                    .dxPop(delay: 1.0 + Double(i) * 0.15)
                    .position(x: p.0 * k, y: (p.1 + 16) * k)
            }
        }
    }

    /// A four-point sparkle filling its frame.
    private struct Spark: Shape {
        func path(in rect: CGRect) -> Path {
            let r = rect.width / 2
            return HealthSpot.star4(r, r, r).offsetBy(dx: rect.minX, dy: rect.minY)
        }
    }

    private static func back(_ ctx: inout GraphicsContext, kind: HealthSpotKind, dark: Bool) {
        let sky = dark ? CalmPaint.vertical(0x0D1630, 0x1F2D55, 0x3A4672) : CalmPaint.vertical(0xB9D2F0, 0xDDE6F2, 0xFFE2CC)
        ctx.fill(Path(CGRect(x: 0, y: -20, width: 346, height: 198)), with: .linearGradient(sky, startPoint: CGPoint(x: 0, y: -20), endPoint: CGPoint(x: 0, y: 178)))
        let lift = Color(hex: 0x1A0B2E).opacity(dark ? 0.45 : 0.16)
        if dark {
            for (i, p) in [(30.0, 24.0), (92, 14), (166, 30), (214, 12), (256, 46), (60, 66)].enumerated() {
                ctx.fill(CalmPaint.circle(p.0, p.1, i % 2 == 1 ? 1.1 : 1.6), with: .color(.white.opacity(i % 2 == 1 ? 0.5 : 0.85)))
            }
            CalmPaint.glow(&ctx, 300, 40, 40, 0xF6E7C1, 0.16, mid: (0.2, 0.16))
            CalmPaint.fill(&ctx, "M300 24 A16 16 0 1 0 314 48 A13 13 0 1 1 300 24Z", 0xF6E7C1)
        } else {
            CalmPaint.glow(&ctx, 132, 88, 96, 0xFFF6DA, 0.75, mid: (0.2, 0.75))
            CalmPaint.glow(&ctx, 312, 50, 42, 0xFFF6DA, 0.75, mid: (0.2, 0.75))
            ctx.fill(CalmPaint.circle(312, 50, 19), with: .color(Color(hex: 0xFFD25E)))
        }
        // The spot's motif in the sky, for the changes without a prop of their own.
        switch kind {
        case .cloud, .breeze:
            let c: UInt32 = dark ? 0x4A5D8E : 0xFFFFFF
            ctx.fill(SVGPath.path(HealthSpot.cloudD).applying(CGAffineTransform(translationX: 226, y: 34).scaledBy(x: 2.2, y: 2.2)), with: .color(Color(hex: c)))
            ctx.fill(SVGPath.path(HealthSpot.cloudD).applying(CGAffineTransform(translationX: 268, y: 74).scaledBy(x: 1.3, y: 1.3)), with: .color(Color(hex: c).opacity(0.8)))
            for d in ["M214 60h30", "M228 70h22"] {
                ctx.stroke(SVGPath.path(d), with: .color(dark ? Color(hex: 0x8EA2D6).opacity(0.7) : .white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        case .moon where !dark:
            CalmPaint.fill(&ctx, "M262 30 A16 16 0 1 0 276 54 A13 13 0 1 1 262 30Z", 0xFFE7A8)
        default: break
        }
        var hill = ctx
        hill.addFilter(.shadow(color: lift, radius: 2.4, x: 0, y: -2))
        let h: [UInt32] = dark ? [0x22335B, 0x1A2949, 0x121E38] : [0xFFAE86, 0xF2865F, 0xD9654A]
        if !dark { CalmPaint.fill(&hill, "M0 110 C50 96 108 102 160 108 S282 92 346 100 V178 H0z", 0xFFC9A6) }
        if kind == .peak {
            CalmPaint.fill(&hill, "M200 124 L236 92 L252 102 L278 60 L306 98 L346 88 V178 H200z", h[0])
        }
        CalmPaint.fill(&hill, "M0 128 C60 112 120 120 180 124 S300 110 346 116 V178 H0z", h[0])
        CalmPaint.fill(&hill, "M0 158 C50 150 100 152 150 156 C210 161 280 146 346 150 V178 H0z", h[1])
        if kind == .peak {
            ctx.stroke(SVGPath.path("M278 60V40"), with: .color(Color(hex: dark ? 0xE6DCCB : 0x1E1A3A)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            CalmPaint.fill(&ctx, "M278 41l16 5-16 5z", dark ? 0xE9886C : 0x1E1A3A)
        }
        if kind == .lake {
            ctx.fill(Path(CGRect(x: 200, y: 140, width: 146, height: 38)), with: .color(Color(hex: dark ? 0x2A4677 : 0x8ECDE6)))
            for d in ["M236 150h40", "M252 160h22", "M300 168h20"] {
                ctx.stroke(SVGPath.path(d), with: .color(Color(hex: dark ? 0xF6E7C1 : 0xFFF8EE).opacity(dark ? 0.75 : 1)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }

    private static func front(_ ctx: inout GraphicsContext, kind: HealthSpotKind, dark: Bool) {
        if kind == .mirror { mirror(&ctx, dark: dark) }
        var hill = ctx
        hill.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.45 : 0.16), radius: 2.4, x: 0, y: -2))
        CalmPaint.fill(&hill, "M0 166 C70 160 150 170 220 168 C280 166 320 162 346 164 V178 H0z", dark ? 0x121E38 : 0xD9654A)
    }

    /// The standing mirror with a little Xero in the glass.
    private static func mirror(_ ctx: inout GraphicsContext, dark: Bool) {
        let frame: UInt32 = dark ? 0xE6DCCB : 0xF26E4C
        let frame2: UInt32 = dark ? 0xC2B6A2 : 0xD2563A
        let shine = Color(hex: dark ? 0xF6EFE2 : 0xFFFFFF)
        var g = ctx
        g.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.5 : 0.2), radius: 2.5, x: 0, y: 2.5))
        g.translateBy(x: 252, y: 160)
        g.rotate(by: .degrees(-8))
        g.scaleBy(x: 1.16, y: 1.16)
        CalmPaint.fill(&g, "M-14 0 C-14 -6 -6 -8 0 -8 C6 -8 14 -6 14 0Z", frame2)
        g.fill(Path(roundedRect: CGRect(x: -3, y: -30, width: 6, height: 24), cornerRadius: 3), with: .color(Color(hex: frame2)))
        g.fill(CalmPaint.ellipse(0, -58, 25, 31), with: .color(Color(hex: frame)))
        let glass = CalmPaint.ellipse(0, -58, 19, 25)
        g.fill(glass, with: .linearGradient(Gradient(colors: [Color(hex: dark ? 0x9DB8EA : 0xDCEBFF), Color(hex: dark ? 0x5D7BC0 : 0xA9C8FF)]),
                                            startPoint: CGPoint(x: -19, y: -83), endPoint: CGPoint(x: 19, y: -33)))
        var inner = g
        inner.clip(to: glass)
        inner.opacity = 0.92
        inner.fill(CalmPaint.ellipse(-3, -46, 16, 20), with: .color(Color(hex: 0xE85A3E)))
        inner.fill(CalmPaint.ellipse(-5.5, -46.5, 13.8, 19.4), with: .color(Color(hex: 0xFF7155)))
        inner.fill(CalmPaint.circle(-8.5, -52, 2), with: .color(Color(hex: 0x24163A)))
        inner.fill(CalmPaint.circle(1.5, -52, 2), with: .color(Color(hex: 0x24163A)))
        inner.stroke(SVGPath.path("M-7.5 -46.5 q4.5 3.6 9 0"), with: .color(Color(hex: 0x24163A)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        inner.fill(CalmPaint.circle(-12, -47.5, 2.6), with: .color(Color(hex: 0xFF5F86).opacity(0.6)))
        inner.fill(CalmPaint.circle(5.5, -47.5, 2.6), with: .color(Color(hex: 0xFF5F86).opacity(0.6)))
        g.stroke(SVGPath.path("M-11 -66 C-9 -74 -3 -79 4 -80"), with: .color(shine.opacity(0.9)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        g.stroke(SVGPath.path("M4 -68 l8 -8"), with: .color(shine.opacity(0.6)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }
}
