import DayXeroCore
import SwiftUI

/// The milestone illustrations (CHAR-05, signed off 3 Nov 2026 on the "Milestone illustrations" canvas, round 4,
/// "crew collage"). Each change in the body has its own composition: two or three bold gradient windows from the crew's
/// worlds (an arch of dawn, a slice of sea, a disc of dusk) layered like a collage, one hero object, and one crew member
/// living inside it. Xero keeps the body, Jelli the waves of withdrawal and cravings, Glim the night. Composed to the
/// bottom right on a 200-point grid, so a card can let it bleed off its edge.
///
/// Drawn in three layers: what sits behind the crew member, the crew member (the real `XeroView`, `JelliView` or
/// `GlimView`, with their usual gentle motion), and what sits in front.
struct MilestoneCollage: View {
    let id: String
    var size: CGFloat = 200
    /// The crew's idle motion; off for small badges in long lists and with Reduce Motion (the crew views check that).
    var animate = true

    var body: some View {
        let k = size / 200
        let crew = CollageCrew.of(id)
        ZStack(alignment: .topLeading) {
            Canvas { context, canvas in
                context.scaleBy(x: canvas.width / 200, y: canvas.height / 200)
                CollageDraw.draw(id, front: false, in: &context)
            }
            if let crew {
                crew.view(points: crew.scale * size, animate: animate)
                    .frame(width: crew.scale * size, height: crew.scale * size)
                    .offset(x: crew.x * k, y: crew.y * k)
            }
            Canvas { context, canvas in
                context.scaleBy(x: canvas.width / 200, y: canvas.height / 200)
                CollageDraw.draw(id, front: true, in: &context)
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

/// Who lives in each picture, how they feel, and where they stand on the 200-point grid.
struct CollageCrew {
    enum Who { case xero, jelli, glim }

    let who: Who
    let mood: CrewMood
    var stage = 2
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat

    @ViewBuilder
    func view(points: CGFloat, animate: Bool) -> some View {
        switch who {
        case .xero: XeroView(mood: mood, stage: stage, points: points, animate: animate)
        case .jelli: JelliView(mood: mood, stage: stage, points: points, animate: animate)
        case .glim: GlimView(mood: mood, stage: stage, points: points, animate: animate)
        }
    }

    static func of(_ id: String) -> CollageCrew? {
        switch id {
        case "heart-rate": CollageCrew(who: .xero, mood: .calm, x: 94, y: 114, scale: 0.42)
        case "carbon-monoxide": CollageCrew(who: .xero, mood: .hello, x: 52, y: 108, scale: 0.42)
        case "circulation": CollageCrew(who: .xero, mood: .cheer, x: 64, y: 14, scale: 0.4)
        case "coughing": CollageCrew(who: .xero, mood: .breathe, x: 22, y: 52, scale: 0.5)
        case "heart-attack": CollageCrew(who: .xero, mood: .calm, x: 2, y: 124, scale: 0.38)
        case "mouth-cancer": CollageCrew(who: .xero, mood: .hello, x: 10, y: 112, scale: 0.45)
        case "lung-cancer": CollageCrew(who: .xero, mood: .calm, stage: 4, x: 120, y: 102, scale: 0.36)
        case "heart-disease": CollageCrew(who: .xero, mood: .hello, x: 94, y: 140, scale: 0.3)
        case "taste": CollageCrew(who: .xero, mood: .cheer, x: 6, y: 108, scale: 0.45)
        case "fresh-breath": CollageCrew(who: .xero, mood: .breathe, x: -2, y: 118, scale: 0.4)
        case "lips": CollageCrew(who: .xero, mood: .cheer, x: 118, y: 118, scale: 0.4)
        case "skin-glow": CollageCrew(who: .xero, mood: .hello, x: -6, y: 110, scale: 0.45)
        case "hair": CollageCrew(who: .xero, mood: .hello, x: 70, y: 99, scale: 0.5)
        case "even-tone": CollageCrew(who: .xero, mood: .calm, x: 68, y: 116, scale: 0.42)
        case "withdrawal-start": CollageCrew(who: .jelli, mood: .hello, x: 100, y: 50, scale: 0.42)
        case "nicotine-gone": CollageCrew(who: .jelli, mood: .calm, x: 58, y: 82, scale: 0.45)
        case "withdrawal-peak": CollageCrew(who: .jelli, mood: .calm, x: 102, y: -6, scale: 0.4)
        case "cravings-fade": CollageCrew(who: .jelli, mood: .cheer, x: 70, y: 40, scale: 0.4)
        case "mood": CollageCrew(who: .glim, mood: .cheer, x: 80, y: 54, scale: 0.45)
        case "sleep": CollageCrew(who: .glim, mood: .sleepy, x: 93, y: 52, scale: 0.42)
        case "flat-days": CollageCrew(who: .glim, mood: .calm, x: 78, y: 96, scale: 0.45)
        case "clearer-head": CollageCrew(who: .xero, mood: .hello, x: 20, y: 96, scale: 0.5)
        case "rewards-return": CollageCrew(who: .xero, mood: .cheer, x: 14, y: 104, scale: 0.45)
        default: nil
        }
    }
}

/// The backdrops and hero objects, ported from the canvas's SVG on its 200-point grid.
enum CollageDraw {
    // MARK: Palette (the app's own: grounds, horizon scenes, crew)

    private static let ink = Color(light: 0x24163A, dark: 0xFFF8EE)
    private static let cream = Color(hex: 0xFFF8EE)
    private static let white = Color.white
    private static let sunYellow = Color(hex: 0xFFC93C)
    private static let pinkDot = Color(hex: 0xFF8FA3)
    private static let blueDot = Color(hex: 0x5AA9FF)
    private static let lilacDot = Color(hex: 0xB9A6FF)
    private static let wine = Color(hex: 0xA81D3A)
    private static let blush = Color(hex: 0xFFC2CD)
    private static let leafGreen = Color(hex: 0x3FB37F), leafDeep = Color(hex: 0x2FA262), forest = Color(hex: 0x1E7A4B)
    private static let bark = Color(hex: 0x8A4B2A)
    private static let violet = Color(hex: 0x4A3596)
    private static let smoke = Color(hex: 0xC9C3D9), smokeLine = Color(hex: 0xA9A3BF)

    private enum Fill {
        case dawn, apricot, apricot2, sun, ocean, waterDeep, sky, night, dusk, mint, leaf, shield, pink, lilac, cherry, coral, ribbon, wave

        func shading(_ rect: CGRect) -> GraphicsContext.Shading {
            func vertical(_ stops: [(UInt32, Double)]) -> GraphicsContext.Shading {
                .linearGradient(Gradient(stops: stops.map { .init(color: Color(hex: $0.0), location: $0.1) }),
                                startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY))
            }
            func diagonal(_ a: UInt32, _ b: UInt32) -> GraphicsContext.Shading {
                .linearGradient(Gradient(colors: [Color(hex: a), Color(hex: b)]),
                                startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY))
            }
            switch self {
            case .dawn: return vertical([(0xFF7E5A, 0), (0xFFB877, 0.55), (0xFFE6BF, 1)])
            case .apricot: return vertical([(0xFFE6BF, 0), (0xFFB877, 1)])
            case .apricot2: return diagonal(0xFFC93C, 0xFF9D6E)
            case .sun:
                return .radialGradient(Gradient(colors: [Color(hex: 0xFFF6C8), Color(hex: 0xFFC23A)]),
                                       center: CGPoint(x: rect.minX + 0.38 * rect.width, y: rect.minY + 0.32 * rect.height),
                                       startRadius: 0, endRadius: 0.75 * max(rect.width, rect.height))
            case .ocean: return vertical([(0x5AA9FF, 0), (0x2A52DB, 0.55), (0x1C2FA8, 1)])
            case .waterDeep: return vertical([(0x9CCBFF, 0), (0x2A52DB, 1)])
            case .sky: return vertical([(0x5AA9FF, 0), (0xD3EEFF, 1)])
            case .night: return vertical([(0x180F52, 0), (0x5A3CC4, 1)])
            case .dusk: return vertical([(0x7A5CE0, 0), (0xE58BB8, 0.6), (0xFFC59A, 1)])
            case .mint: return vertical([(0x9FE3AE, 0), (0x2FA262, 1)])
            case .leaf: return diagonal(0x9FE3AE, 0x2FA262)
            case .shield: return vertical([(0x5CC984, 0), (0x0F6E43, 1)])
            case .pink: return diagonal(0xFFD6DE, 0xFF8FA3)
            case .lilac: return diagonal(0xE8E0FF, 0xB9A6FF)
            case .cherry: return diagonal(0xFF6F8E, 0xC2203F)
            case .coral: return diagonal(0xFF9D6E, 0xE23D57)
            case .ribbon:
                return .linearGradient(Gradient(colors: [Color(hex: 0xFF8FA3), Color(hex: 0xFF7155)]),
                                       startPoint: CGPoint(x: rect.minX, y: rect.midY), endPoint: CGPoint(x: rect.maxX, y: rect.midY))
            case .wave: return diagonal(0x9CCBFF, 0x2F72F2)
            }
        }
    }

    // MARK: Shapes

    private static let heart = "M32 54 C15 43 8 33 8 23 C8 15 14 9.5 21.5 9.5 C26.5 9.5 30 12.5 32 16.5 C34 12.5 37.5 9.5 42.5 9.5 C50 9.5 56 15 56 23 C56 33 49 43 32 54 Z"
    private static let lips = "M10 32 C14 24 20 20 26 22 C29 23 31 25 32 26 C33 25 35 23 38 22 C44 20 50 24 54 32 C48 44 40 48 32 48 C24 48 16 44 10 32 Z"

    // MARK: Drawing

    static func draw(_ id: String, front: Bool, in c: inout GraphicsContext) {
        switch id {
        case "heart-rate": heartRate(c, front)
        case "carbon-monoxide": carbonMonoxide(c, front)
        case "circulation": circulation(c, front)
        case "coughing": coughing(c, front)
        case "heart-attack": heartAttack(c, front)
        case "mouth-cancer": mouth(c, front)
        case "lung-cancer": lungTree(c, front)
        case "heart-disease": heartRoad(c, front)
        case "taste": taste(c, front)
        case "fresh-breath": freshBreath(c, front)
        case "lips": lipsArt(c, front)
        case "skin-glow": mirror(c, front)
        case "hair": hair(c, front)
        case "even-tone": evenTone(c, front)
        case "withdrawal-start": withdrawalStart(c, front)
        case "nicotine-gone": nicotineGone(c, front)
        case "withdrawal-peak": withdrawalPeak(c, front)
        case "mood": moodArt(c, front)
        case "cravings-fade": cravingsFade(c, front)
        case "sleep": deeperSleep(c, front)
        case "flat-days": flatDays(c, front)
        case "clearer-head": clearerHead(c, front)
        case "rewards-return": rewardsReturn(c, front)
        default:
            if !front {
                fill(c, circle(100, 100, 60), .pink)
                star(c, 104, 106, scale: 5.6, wine.opacity(0.25))
                star(c, 100, 100, scale: 5.6, sunYellow)
            }
        }
    }

    private static func heartRate(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(56, 64, 56), .pink)
            blurred(c).fill(circle(150, 44, 34), with: .color(sunYellow.opacity(0.45)))
            let a = arch(74, 198, cy: 118, bottom: 214)
            fill(c, a, .dawn)
            var inside = c
            inside.clip(to: a)
            fill(inside, circle(136, 150, 28), .sun)
            inside.fill(p("M60 178 C100 162 140 170 210 158 V220 H60 Z"), with: .color(Color(hex: 0xFF7A55)))
            inside.fill(p("M60 198 C110 186 150 192 210 184 V220 H60 Z"), with: .color(Color(hex: 0xE85A3E)))
        } else {
            c.fill(shape(heart, x: 18, y: 27, scale: 1.3), with: .color(wine.opacity(0.35)))
            fill(c, shape(heart, x: 14, y: 22, scale: 1.3), .cherry)
            c.stroke(p("M30 56 Q31 44 42 40"), with: .color(blush), style: line(5))
            c.stroke(p("M84 70 H98 L104 60 L112 82 L118 66 L124 72 H150"), with: .color(ink), style: line(3))
            plus(c, 28, 146)
            star(c, 182, 26)
            c.fill(circle(44, 172, 4), with: .color(pinkDot))
            c.fill(circle(58, 186, 2.6), with: .color(pinkDot))
        }
    }

    private static func carbonMonoxide(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            var puff = soft(c)
            puff.opacity = 0.55
            for (x, y, r) in [(34.0, 24.0, 12.0), (50, 16, 9), (22, 12, 7)] as [(CGFloat, CGFloat, CGFloat)] {
                puff.fill(circle(x, y, r), with: .color(Color(hex: 0xB9B3C9)))
            }
            let window = rrect(14, 40, 120, 190, 40)
            fill(c, window, .sky)
            var inside = c
            inside.clip(to: window)
            fill(inside, ellipse(74, 214, 74, 40), .mint)
            for (x, y, r, w) in [(104.0, 66.0, 7.0, 3.0), (84, 50, 4.5, 2.5), (40, 84, 5, 2.5)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                inside.stroke(circle(x, y, r), with: .color(white), lineWidth: w)
            }
        } else {
            for (x, y, r, dimple) in [(150.0, 86.0, 34.0, CGSize(width: 17, height: 12)), (172, 150, 26, CGSize(width: 13, height: 9))]
                as [(CGFloat, CGFloat, CGFloat, CGSize)] {
                c.fill(circle(x + 3, y + 5, r), with: .color(wine.opacity(0.3)))
                fill(c, circle(x, y, r), .coral)
                c.fill(ellipse(x, y, dimple.width, dimple.height), with: .color(Color(hex: 0xC2203F).opacity(0.35)))
            }
            c.stroke(p("M126 76 Q130 62 144 58"), with: .color(Color(hex: 0xFFD6DE)), style: line(5))
            star(c, 186, 30)
        }
    }

    private static func circulation(_ c: GraphicsContext, _ front: Bool) {
        let ribbon = p("M-10 156 C40 156 50 92 90 92 C130 92 132 156 172 156 C202 156 212 112 212 82")
        if !front {
            fill(c, circle(120, 112, 74), .dawn)
            var sun = c
            sun.opacity = 0.9
            fill(sun, circle(120, 124, 26), .sun)
            var dot = c
            dot.opacity = 0.8
            fill(dot, circle(30, 40, 22), .pink)
            c.stroke(ribbon.offsetBy(dx: 0, dy: 4), with: .color(Color(hex: 0xC2203F).opacity(0.35)), style: line(16))
            c.stroke(ribbon, with: Fill.ribbon.shading(ribbon.boundingRect), style: line(16))
            var flow = line(3)
            flow.dash = [4, 10]
            c.stroke(ribbon, with: .color(cream), style: flow)
        } else {
            plus(c, 178, 40)
            star(c, 40, 186)
        }
    }

    private static func coughing(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, rrect(88, 26, 140, 200, 40), .sky)
            var cloud = soft(c)
            cloud.opacity = 0.85
            cloud.fill(ellipse(176, 118, 26, 8), with: .color(white))
            cloud.fill(ellipse(190, 110, 14, 7), with: .color(white))
            let lungs = p("M140 52 C130 50 116 62 115 78 C114 90 121 94 128 92 C135 90 140 85 140 78 Z M150 52 C160 50 174 62 175 78 C176 90 169 94 162 92 C155 90 150 85 150 78 Z")
            c.fill(lungs.offsetBy(dx: 2, dy: 3), with: .color(Color(hex: 0x9CCBFF)))
            c.fill(lungs, with: .color(white))
            c.stroke(p("M145 36 V54 M145 53 Q145 58 139 61 M145 53 Q145 58 151 61"), with: .color(ink), style: line(3))
            fill(c, halfDisc(72, 214, 82), .mint)
            c.stroke(p("M96 150 C124 132 156 156 182 140 C200 128 192 108 176 114 C164 120 172 134 184 130"), with: .color(white), style: line(6))
        } else {
            plus(c, 24, 52)
            c.fill(circle(54, 28, 3), with: .color(blueDot))
            c.fill(circle(66, 40, 2), with: .color(blueDot))
        }
    }

    private static func heartAttack(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, arch(86, 200, cy: 100, bottom: 214), .sky)
            fill(c, circle(166, 78, 14), .sun)
            let shield = p("M100 26 C122 34 140 40 152 42 C156 43 158 46 158 50 V96 C158 136 132 162 100 178 C68 162 42 136 42 96 V50 C42 46 44 43 48 42 C60 40 78 34 100 26 Z")
            c.fill(shield.offsetBy(dx: 4, dy: 6), with: .color(Color(hex: 0x0B4F31).opacity(0.35)))
            fill(c, shield, .shield)
            c.stroke(p("M54 92 C54 74 58 62 66 56"), with: .color(cream.opacity(0.5)), style: line(5))
            fill(c, shape(heart, x: 71, y: 68, scale: 0.9), .cherry)
            c.stroke(p("M84 88 Q85 82 90 80"), with: .color(blush), style: line(3.5))
        } else {
            star(c, 30, 40)
            plus(c, 180, 176)
        }
    }

    private static func mouth(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(60, 70, 52), .apricot)
            let bubble = p("M88 34 H180 Q200 34 200 54 V112 Q200 132 180 132 H122 L104 150 Q100 154 100 148 V132 H88 Q68 132 68 112 V54 Q68 34 88 34 Z")
            c.fill(bubble.offsetBy(dx: 3, dy: 5), with: .color(Color(hex: 0x9C87F0).opacity(0.5)))
            fill(c, bubble, .lilac)
            c.stroke(p("M78 66 Q78 50 92 46"), with: .color(white.opacity(0.7)), style: line(5))
            for x in [110.0, 134, 158] as [CGFloat] { c.fill(circle(x, 83, 7), with: .color(violet)) }
        } else {
            star(c, 30, 22)
            c.fill(circle(176, 176, 4), with: .color(lilacDot))
            c.fill(circle(190, 162, 2.6), with: .color(lilacDot))
        }
    }

    private static func lungTree(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, rrect(70, 14, 150, 200, 40), .sky)
            fill(c, circle(182, 44, 14), .sun)
            fill(c, p("M-10 214 C40 170 120 160 214 176 V214 Z"), .mint)
            c.stroke(p("M96 178 V96 M96 120 Q96 104 80 96 M96 120 Q96 104 112 96"), with: .color(bark), style: line(8))
            let canopy = p("M90 40 C72 36 44 58 42 96 C40 122 56 132 70 128 C84 124 90 112 90 96 Z M102 40 C120 36 148 58 150 96 C152 122 136 132 122 128 C108 124 102 112 102 96 Z")
            c.fill(canopy.offsetBy(dx: 3, dy: 5), with: .color(forest.opacity(0.35)))
            fill(c, canopy, .leaf)
            c.stroke(p("M52 92 C52 72 60 58 72 50"), with: .color(cream.opacity(0.6)), style: line(5))
            c.stroke(p("M96 128 V112"), with: .color(bark), style: line(8))
        } else {
            plus(c, 30, 40)
        }
    }

    private static func heartRoad(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(34, 38, 40), .pink)
            let a = arch(30, 190, cy: 110, bottom: 214)
            fill(c, a, .dawn)
            var inside = c
            inside.clip(to: a)
            blurred(inside).fill(circle(110, 80, 44), with: .color(Color(hex: 0xFFF6C8).opacity(0.5)))
            fill(inside, shape(heart, x: 78, y: 44, scale: 1), .sun)
            inside.fill(p("M20 150 C60 136 120 142 200 132 V214 H20 Z"), with: .color(Color(hex: 0xFF9D6E)))
            inside.fill(p("M20 176 C70 166 130 170 200 162 V214 H20 Z"), with: .color(Color(hex: 0xFF7A55)))
            inside.fill(p("M96 214 C100 196 128 184 120 170 C114 160 104 156 108 148 L112 148 C110 156 120 160 126 170 C134 186 112 198 122 214 Z"),
                        with: .color(Color(hex: 0xFFF1D2)))
        } else {
            plus(c, 180, 24)
            star(c, 186, 176)
        }
    }

    private static func taste(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            var glow = blurred(c)
            glow.opacity = 0.6
            glow.fill(circle(54, 56, 30), with: .color(pinkDot))
            fill(c, circle(130, 126, 84), .apricot)
            var ring = c
            ring.opacity = 0.7
            ring.stroke(circle(130, 126, 64), with: .color(cream), lineWidth: 4)
        } else {
            c.stroke(p("M122 34 Q112 64 98 92 M122 34 Q140 70 150 102"), with: .color(leafDeep), style: line(5))
            c.fill(p("M122 34 C136 14 168 16 180 28 C162 46 136 46 122 34 Z"), with: .color(leafGreen))
            c.stroke(p("M128 33 C146 28 162 26 174 28"), with: .color(leafDeep), style: line(2.5))
            for (x, y, r) in [(100.0, 118.0, 27.0), (154, 126, 25)] as [(CGFloat, CGFloat, CGFloat)] {
                c.fill(circle(x + 4, y + 6, r), with: .color(wine.opacity(0.4)))
                fill(c, circle(x, y, r), .cherry)
            }
            c.stroke(p("M84 110 Q86 100 96 97 M140 118 Q142 108 151 105"), with: .color(blush), style: line(5))
            plus(c, 182, 182)
            c.fill(circle(96, 172, 3), with: .color(cream))
            c.fill(circle(182, 84, 3), with: .color(cream))
        }
    }

    private static func freshBreath(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(130, 96, 76), .sky)
            var cloud = soft(c)
            cloud.opacity = 0.85
            cloud.fill(ellipse(160, 54, 22, 7), with: .color(white))
            let leaf = p("M70 190 C60 130 110 74 176 64 C180 120 140 176 70 190 Z")
            c.fill(leaf.offsetBy(dx: 3, dy: 5), with: .color(forest.opacity(0.35)))
            fill(c, leaf, .leaf)
            c.stroke(p("M76 182 C100 150 130 110 170 70"), with: .color(forest.opacity(0.5)), style: line(3))
            c.fill(p("M150 198 C150 162 176 138 206 134 C204 168 184 192 150 198 Z"), with: .color(leafGreen))
        } else {
            c.stroke(p("M44 150 C64 134 86 146 100 132 C110 122 104 108 94 112"), with: .color(white), style: line(5))
            star(c, 98, 100)
            plus(c, 186, 186)
        }
    }

    private static func lipsArt(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, arch(96, 200, cy: 104, bottom: 214), .dawn)
            fill(c, circle(78, 96, 62), .pink)
            var l = c
            l.translateBy(x: 20, y: 32)
            l.scaleBy(x: 1.8, y: 1.8)
            l.fill(p(lips).offsetBy(dx: 1.5, dy: 2.5), with: .color(wine.opacity(0.35)))
            fill(l, p(lips), .cherry)
            l.stroke(p("M14 32 C22 34.5 27 33.5 32 32 C37 33.5 42 34.5 50 32"), with: .color(wine), style: line(1.8))
            l.stroke(p("M25 41.5 Q32 44 39 41.5"), with: .color(blush), style: line(2.6))
        } else {
            plus(c, 28, 172)
            star(c, 184, 26)
        }
    }

    private static func mirror(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            var glow = blurred(c)
            glow.opacity = 0.5
            glow.fill(circle(126, 82, 66), with: .color(sunYellow))
            c.stroke(p("M126 10 V20 M66 36 L73 43 M186 36 L179 43 M50 90 H60"), with: .color(sunYellow), style: line(4.5))
            c.fill(p("M152 126 L190 174 C194 179 192 186 186 189 C180 192 174 190 171 185 L138 134 Z"), with: .color(Color(hex: 0xE85A3E)))
            c.fill(circle(129, 87, 52), with: .color(Color(hex: 0xC9542F).opacity(0.35)))
            fill(c, circle(126, 82, 52), .apricot2)
            fill(c, circle(126, 82, 40), .sky)
            fill(c, circle(112, 70, 12), .sun)
            c.stroke(p("M104 112 L146 58"), with: .color(white.opacity(0.55)), style: line(6))
            c.stroke(p("M118 118 L150 78"), with: .color(white.opacity(0.45)), style: line(3))
        } else {
            star(c, 186, 128)
            plus(c, 30, 30)
        }
    }

    private static func hair(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            var glow = blurred(c)
            glow.opacity = 0.9
            fill(glow, circle(150, 104, 84), .sky)
            fill(c, p("M50 214 C96 168 160 158 214 166 V214 Z"), .mint)
            c.stroke(p("M112 118 C108 96 100 76 96 58 M120 116 C122 90 118 64 122 42 M128 118 C134 96 146 78 150 64"),
                     with: .color(Color(hex: 0xFF7155)), style: line(4.5))
            leafEllipse(c, 103, 86, angle: -30)
            leafEllipse(c, 139, 88, angle: 30)
            for (x, y, r, petal, centre) in [(96.0, 54.0, 11.0, 0xFF7E5A, 0x24163A), (122, 38, 12, 0xFFC93C, 0xE85A3E), (150, 60, 10, 0xFF7E5A, 0x24163A)]
                as [(CGFloat, CGFloat, CGFloat, UInt32, UInt32)] {
                c.fill(circle(x, y, r), with: .color(Color(hex: petal)))
                c.fill(circle(x, y, r * 0.41), with: .color(Color(hex: centre)))
            }
        } else {
            star(c, 54, 42)
            c.fill(circle(36, 70, 2.5), with: .color(blueDot))
        }
    }

    private static func evenTone(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            let disc = circle(110, 104, 78)
            c.fill(disc, with: .color(Color(hex: 0xFFD6B0)))
            var half = c
            half.clip(to: disc)
            half.opacity = 0.85
            fill(half, p("M110 26 C124 52 96 78 110 104 C124 130 96 156 110 182 L20 182 L20 26 Z"), .apricot2)
            c.stroke(p("M110 26 C124 52 96 78 110 104 C124 130 96 156 110 182"), with: .color(cream.opacity(0.7)), style: line(5))
            fill(c, circle(62, 62, 14), .sun)
            crescent(c, center: CGPoint(x: 166, y: 64), radius: 13, cut: CGPoint(x: 172, y: 58), cutRadius: 11, color: cream.opacity(0.9))
        } else {
            star(c, 30, 150)
            plus(c, 186, 176)
        }
    }

    private static func withdrawalStart(_ c: GraphicsContext, _ front: Bool) {
        let window = rrect(40, 96, 190, 140, 40)
        if !front {
            fill(c, circle(60, 60, 54), .sky)
            fill(c, circle(60, 76, 16), .sun)
            fill(c, window, .ocean)
            var inside = c
            inside.clip(to: window)
            inside.fill(p("M40 120 C60 112 80 112 100 120 C120 128 140 128 160 120 C180 112 200 112 230 120 V240 H40 Z"),
                        with: .color(Color(hex: 0x5A9DFF)))
        } else {
            var inside = c
            inside.clip(to: window)
            inside.fill(p("M40 146 C70 136 100 138 130 146 C160 154 190 146 230 142 V240 H40 Z"), with: .color(Color(hex: 0x2F72F2)))
            inside.fill(p("M40 176 C80 170 120 178 230 172 V240 H40 Z"), with: .color(Color(hex: 0x1C4FCC)))
            inside.stroke(p("M64 120 C68 114 76 114 80 120 M176 138 C180 132 188 132 192 138"), with: .color(cream), style: line(3))
            inside.stroke(circle(86, 166, 3), with: .color(white.opacity(0.7)), lineWidth: 2)
            c.fill(circle(180, 40, 3), with: .color(blueDot))
            c.fill(circle(192, 58, 2), with: .color(blueDot))
        }
    }

    private static func nicotineGone(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(40, 170, 44), .pink)
            let window = rrect(60, 10, 160, 210, 40)
            fill(c, window, .waterDeep)
            var inside = c
            inside.clip(to: window)
            inside.fill(circle(100, 190, 70), with: .color(Color(hex: 0x1C4FCC).opacity(0.35)))
            for (x, y, r, o) in [(150.0, 150.0, 5.0, 0.8), (164, 118, 7, 0.8), (150, 86, 4, 0.8), (172, 66, 9, 0.8), (84, 70, 5, 0.6)]
                as [(CGFloat, CGFloat, CGFloat, Double)] {
                inside.stroke(circle(x, y, r), with: .color(white.opacity(o)), lineWidth: 2.5)
            }
            // The last of the nicotine, carried up and out of the frame.
            var molecule = c
            molecule.opacity = 0.9
            molecule.stroke(p("M160 30 L178 18 M160 30 L182 44"), with: .color(smokeLine), style: line(3))
            for (x, y, r) in [(160.0, 30.0, 9.0), (178, 18, 7), (182, 44, 6)] as [(CGFloat, CGFloat, CGFloat)] {
                molecule.fill(circle(x, y, r), with: .color(smoke))
            }
            var fading = c
            fading.opacity = 0.4
            fading.stroke(p("M196 -2 L208 6"), with: .color(smokeLine), style: line(2.5))
            fading.fill(circle(196, -2, 6), with: .color(smoke))
            fading.fill(circle(208, 6, 5), with: .color(smoke))
        } else {
            star(c, 32, 40)
        }
    }

    private static func withdrawalPeak(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(46, 58, 38), .pink)
            let tile = rrect(52, 18, 170, 200, 36)
            fill(c, tile, .ocean)
            var inside = c
            inside.clip(to: tile)
            var sun = inside
            sun.opacity = 0.95
            fill(sun, circle(196, 44, 22), .sun)
            fill(inside, p("M52 220 V150 C80 150 98 120 112 96 C126 72 156 62 176 76 C190 86 188 106 172 110 C162 112 156 104 160 96 C150 98 140 112 140 128 C140 160 170 176 222 176 V220 Z"), .wave)
            inside.fill(p("M112 96 C126 72 156 62 176 76 C190 86 188 106 172 110 C162 112 156 104 160 96 C168 95 172 89 168 84 C158 73 133 77 120 98 Z"),
                        with: .color(cream))
            inside.fill(p("M52 220 V196 C90 186 140 194 222 186 V220 Z"), with: .color(Color(hex: 0x1C4FCC)))
            inside.stroke(circle(90, 170, 4), with: .color(white.opacity(0.7)), lineWidth: 2)
        } else {
            c.fill(circle(30, 140, 3.5), with: .color(blueDot))
            c.fill(circle(20, 156, 2.2), with: .color(blueDot))
        }
    }

    private static func moodArt(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            var glow = blurred(c)
            glow.opacity = 0.5
            glow.fill(circle(24, 60, 26), with: .color(sunYellow))
            let window = rrect(30, 20, 190, 200, 40)
            fill(c, window, .dusk)
            var inside = c
            inside.clip(to: window)
            for (r, color) in [(92.0, 0xFFC59A), (72, 0xFF8FA3), (52, 0xD9CCFF)] as [(CGFloat, UInt32)] {
                inside.stroke(circle(125, 206, r), with: .color(Color(hex: color)), lineWidth: 14)
            }
            fill(inside, circle(125, 206, 32), .sun)
            for (x, y, r) in [(60.0, 44.0, 1.6), (186, 40, 1.4), (200, 80, 1.4)] as [(CGFloat, CGFloat, CGFloat)] {
                inside.fill(circle(x, y, r), with: .color(cream))
            }
        } else {
            star(c, 186, 186, cream)
        }
    }

    private static func cravingsFade(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(186, 186, 34), .pink)
            let a = arch(28, 192, cy: 110, bottom: 214)
            fill(c, a, .sky)
            var inside = c
            inside.clip(to: a)
            fill(inside, circle(110, 116, 24), .sun)
            fill(inside, Path(CGRect(x: 20, y: 118, width: 180, height: 100)), .ocean)
            // Each wave calmer than the last.
            for (d, o) in [("M30 140 C60 132 90 148 120 140 C150 132 170 146 190 140", 1.0), ("M30 160 C70 155 110 165 190 158", 0.7), ("M30 180 H190", 0.5)] {
                inside.stroke(p(d), with: .color(cream.opacity(o)), style: line(3))
            }
        } else {
            plus(c, 36, 60)
            plus(c, 172, 44)
        }
    }

    private static func deeperSleep(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, arch(40, 200, cy: 96, bottom: 214), .night)
            for (x, y, r) in [(80.0, 60.0, 1.6), (108, 36, 1.3), (186, 100, 1.5), (64, 100, 1.3)] as [(CGFloat, CGFloat, CGFloat)] {
                c.fill(circle(x, y, r), with: .color(cream))
            }
            var glow = blurred(c)
            glow.opacity = 0.25
            glow.fill(circle(152, 58, 30), with: .color(Color(hex: 0xFFF1C2)))
            crescent(c, center: CGPoint(x: 154, y: 56), radius: 20, cut: CGPoint(x: 164, y: 48), cutRadius: 16, color: Color(hex: 0xFFF1C2))
            fill(c, circle(34, 172, 48), .dusk)
            c.fill(rrect(64, 158, 126, 30, 15), with: .color(Color(hex: 0xD9CFF0)))
            c.fill(rrect(60, 152, 126, 30, 15), with: .color(cream))
            c.fill(rrect(94, 132, 86, 26, 13), with: .color(white))
        } else {
            c.fill(circle(70, 128, 6), with: .color(Color(hex: 0xFFE27A).opacity(0.25)))
            c.fill(circle(70, 128, 2.4), with: .color(Color(hex: 0xFFE27A)))
        }
    }

    /// Fog drifting across a dusk window, the sun still there behind it: a passing stage (CLIN-01).
    private static func flatDays(_ c: GraphicsContext, _ front: Bool) {
        let window = rrect(40, 22, 180, 200, 40)
        if !front {
            fill(c, circle(36, 176, 40), .lilac)
            fill(c, window, .dusk)
            var inside = c
            inside.clip(to: window)
            var sun = inside
            sun.opacity = 0.5
            fill(sun, circle(150, 70, 22), .sun)
            var fog = soft(inside)
            for (x, y, rx, ry, hex, o) in [(120.0, 88.0, 92.0, 15.0, 0xE9E2F5, 0.85), (96, 128, 100, 17, 0xDCD3EE, 0.9), (150, 168, 92, 16, 0xF1ECF8, 0.9)]
                as [(CGFloat, CGFloat, CGFloat, CGFloat, UInt32, Double)] {
                fog.fill(ellipse(x, y, rx, ry), with: .color(Color(hex: hex).opacity(o)))
            }
        } else {
            star(c, 186, 40, cream)
        }
    }

    /// Clouds parting around the sun, a little sparkle by Xero's head (CLIN-01).
    private static func clearerHead(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, rrect(66, 16, 150, 200, 40), .sky)
            var glow = blurred(c)
            glow.opacity = 0.5
            glow.fill(circle(150, 70, 34), with: .color(Color(hex: 0xFFF6C8)))
            fill(c, circle(150, 70, 20), .sun)
            for (x, y, rx, ry) in [(104.0, 88.0, 30.0, 12.0), (90, 80, 16, 10), (198, 94, 26, 11), (208, 86, 14, 9)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                c.fill(ellipse(x, y, rx, ry), with: .color(white))
            }
            fill(c, p("M-10 214 C40 176 120 168 214 180 V214 Z"), .mint)
        } else {
            star(c, 40, 100)
            star(c, 100, 92, scale: 0.7)
            plus(c, 180, 180)
        }
    }

    /// Small pleasures coming back: a flower, a tune, Xero cheering (CLIN-01).
    private static func rewardsReturn(_ c: GraphicsContext, _ front: Bool) {
        if !front {
            fill(c, circle(124, 112, 80), .apricot)
            c.stroke(p("M146 98 C146 130 138 160 134 214"), with: .color(leafDeep), style: line(5))
            leafEllipse(c, 156, 150, angle: -35)
            for i in 0..<6 {
                let a = Double(i) * .pi / 3
                c.fill(circle(146 + 18 * CGFloat(cos(a)), 80 + 18 * CGFloat(sin(a)), 14), with: .color(Color(hex: 0xFF7E5A)))
            }
            fill(c, circle(146, 80, 13), .sun)
            c.stroke(p("M58 66 V38 L76 33 V60"), with: .color(violet), style: line(4))
            c.fill(ellipse(52, 66, 7, 5), with: .color(violet))
            c.fill(ellipse(70, 60, 7, 5), with: .color(violet))
        } else {
            star(c, 186, 30)
            plus(c, 186, 182)
        }
    }

    // MARK: Parts

    private static func fill(_ c: GraphicsContext, _ path: Path, _ shading: Fill) {
        c.fill(path, with: shading.shading(path.boundingRect))
    }

    /// The kit's four-point sparkle, sun-coloured unless told otherwise.
    private static func star(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, scale s: CGFloat = 1, _ color: Color = Color(hex: 0xFFC93C)) {
        var g = c
        g.translateBy(x: x, y: y)
        g.scaleBy(x: s, y: s)
        g.fill(p("M0 -8 Q0 0 8 0 Q0 0 0 8 Q0 0 -8 0 Q0 0 0 -8 Z"), with: .color(color))
    }

    /// The crew's ink plus, as in a cheer.
    private static func plus(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat) {
        c.stroke(p("M\(x) \(y - 6) V\(y + 6) M\(x - 6) \(y) H\(x + 6)"), with: .color(ink), style: line(3))
    }

    private static func leafEllipse(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, angle: Double) {
        var g = c
        g.translateBy(x: x, y: y)
        g.rotate(by: .degrees(angle))
        g.fill(ellipse(0, 0, 7, 3.5), with: .color(leafGreen))
    }

    private static func crescent(_ c: GraphicsContext, center: CGPoint, radius: CGFloat, cut: CGPoint, cutRadius: CGFloat, color: Color) {
        var g = c
        g.clip(to: circle(cut.x, cut.y, cutRadius), options: .inverse)
        g.fill(circle(center.x, center.y, radius), with: .color(color))
    }

    private static func blurred(_ c: GraphicsContext) -> GraphicsContext {
        var g = c
        g.addFilter(.blur(radius: 10))
        return g
    }

    private static func soft(_ c: GraphicsContext) -> GraphicsContext {
        var g = c
        g.addFilter(.blur(radius: 3))
        return g
    }

    private static func line(_ w: CGFloat) -> StrokeStyle { StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }

    private static func p(_ d: String) -> Path { MilestoneDrawing.svg(d) }

    private static func shape(_ d: String, x: CGFloat, y: CGFloat, scale s: CGFloat) -> Path {
        p(d).applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: x, ty: y))
    }

    private static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }

    private static func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry))
    }

    private static func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .continuous)
    }

    /// The kit's arch: straight sides up to `cy`, a half circle on top, down to `bottom`.
    static func arch(_ x0: CGFloat, _ x1: CGFloat, cy: CGFloat, bottom: CGFloat) -> Path {
        let r = (x1 - x0) / 2, cx = x0 + r, k = 0.5523 * r
        var path = Path()
        path.move(to: CGPoint(x: x0, y: bottom))
        path.addLine(to: CGPoint(x: x0, y: cy))
        path.addCurve(to: CGPoint(x: cx, y: cy - r), control1: CGPoint(x: x0, y: cy - k), control2: CGPoint(x: cx - k, y: cy - r))
        path.addCurve(to: CGPoint(x: x1, y: cy), control1: CGPoint(x: cx + k, y: cy - r), control2: CGPoint(x: x1, y: cy - k))
        path.addLine(to: CGPoint(x: x1, y: bottom))
        path.closeSubpath()
        return path
    }

    /// The top half of a circle standing on `cy`.
    private static func halfDisc(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        arch(cx - r, cx + r, cy: cy, bottom: cy)
    }
}
