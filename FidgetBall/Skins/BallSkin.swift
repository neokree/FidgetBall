//
//  BallSkin.swift
//  FidgetBall
//
//  Procedural ball skins drawn with Core Graphics — no bitmap assets, so the
//  whole look is reproducible and open. Each skin renders into a CGContext and
//  spins with an angle so throws and rolls look alive.
//
//  Six skins: smiley, basketball, tennis, marble, football, disco. The enum
//  extends cleanly for more.
//

import AppKit

enum BallSkin: String, CaseIterable, Identifiable {
    case smiley
    case basketball
    case tennis
    case marble
    case football
    case disco

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .smiley: return "Smiley"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        case .marble: return "Marble"
        case .football: return "Football"
        case .disco: return "Disco"
        }
    }

    // MARK: Public drawing

    /// Draw the ball centered at `center` with the given `radius`, rotated by `angle` radians.
    /// Assumes a context whose coordinate space matches the view (top-left origin is fine).
    func draw(in ctx: CGContext, center: CGPoint, radius r: CGFloat, angle: CGFloat) {
        ctx.saveGState()

        // Contact/drop shadow for a sense of floating depth.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: r * 0.35,
                      color: NSColor.black.withAlphaComponent(0.28).cgColor)
        ctx.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Clip everything to the ball circle.
        ctx.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        ctx.clip()

        switch self {
        case .smiley: drawSmiley(ctx, center, r, angle)
        case .basketball: drawBasketball(ctx, center, r, angle)
        case .tennis: drawTennis(ctx, center, r, angle)
        case .marble: drawMarble(ctx, center, r, angle)
        case .football: drawFootball(ctx, center, r, angle)
        case .disco: drawDisco(ctx, center, r, angle)
        }

        drawGloss(ctx, center, r)
        ctx.restoreGState()

        // Crisp rim.
        ctx.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.18).cgColor)
        ctx.setLineWidth(max(1, r * 0.04))
        ctx.strokePath()
    }

    /// A standalone image of the skin, used for the menu-bar icon and skin menu.
    func image(diameter: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: diameter, height: diameter), flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let r = diameter / 2 - 1
            self.draw(in: ctx, center: CGPoint(x: diameter / 2, y: diameter / 2), radius: r, angle: 0)
            return true
        }
    }

    // MARK: Skins

    private func drawSmiley(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ angle: CGFloat) {
        fillRadial(ctx, c, r,
                   inner: NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.27, alpha: 1),
                   outer: NSColor(calibratedRed: 0.95, green: 0.66, blue: 0.10, alpha: 1))
        withRotation(ctx, c, angle) {
            let eyeR = r * 0.12
            let eyeY = c.y + r * 0.18
            let eyeDX = r * 0.34
            ctx.setFillColor(NSColor(white: 0.12, alpha: 1).cgColor)
            for dx in [-eyeDX, eyeDX] {
                ctx.addEllipse(in: CGRect(x: c.x + dx - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2))
            }
            ctx.fillPath()
            // Smile.
            ctx.setStrokeColor(NSColor(white: 0.12, alpha: 1).cgColor)
            ctx.setLineWidth(r * 0.11)
            ctx.setLineCap(.round)
            let smile = CGMutablePath()
            let sr = r * 0.5
            smile.addArc(center: CGPoint(x: c.x, y: c.y - r * 0.05), radius: sr,
                         startAngle: .pi * 1.18, endAngle: .pi * 1.82, clockwise: false)
            ctx.addPath(smile)
            ctx.strokePath()
        }
    }

    private func drawBasketball(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ angle: CGFloat) {
        fillRadial(ctx, c, r,
                   inner: NSColor(calibratedRed: 0.93, green: 0.50, blue: 0.18, alpha: 1),
                   outer: NSColor(calibratedRed: 0.78, green: 0.33, blue: 0.08, alpha: 1))
        withRotation(ctx, c, angle) {
            ctx.setStrokeColor(NSColor(white: 0.08, alpha: 0.92).cgColor)
            ctx.setLineWidth(r * 0.055)
            ctx.setLineCap(.round)
            // Vertical + horizontal seams.
            ctx.move(to: CGPoint(x: c.x, y: c.y - r)); ctx.addLine(to: CGPoint(x: c.x, y: c.y + r))
            ctx.move(to: CGPoint(x: c.x - r, y: c.y)); ctx.addLine(to: CGPoint(x: c.x + r, y: c.y))
            ctx.strokePath()
            // Two curved side seams.
            for sign in [CGFloat(-1), 1] {
                let p = CGMutablePath()
                p.addArc(center: CGPoint(x: c.x + sign * r * 1.15, y: c.y), radius: r * 0.95,
                         startAngle: 0, endAngle: .pi * 2, clockwise: false)
                ctx.addPath(p)
            }
            ctx.strokePath()
        }
    }

    private func drawTennis(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ angle: CGFloat) {
        fillRadial(ctx, c, r,
                   inner: NSColor(calibratedRed: 0.85, green: 0.94, blue: 0.36, alpha: 1),
                   outer: NSColor(calibratedRed: 0.66, green: 0.80, blue: 0.16, alpha: 1))
        withRotation(ctx, c, angle) {
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
            ctx.setLineWidth(r * 0.10)
            ctx.setLineCap(.round)
            // Two opposing arcs that read as the classic tennis seam.
            for sign in [CGFloat(-1), 1] {
                let p = CGMutablePath()
                p.addArc(center: CGPoint(x: c.x + sign * r * 1.28, y: c.y), radius: r * 1.05,
                         startAngle: .pi * (sign > 0 ? 0.62 : 1.62),
                         endAngle: .pi * (sign > 0 ? 1.38 : 0.38), clockwise: false)
                ctx.addPath(p)
                ctx.strokePath()
            }
        }
    }

    private func drawMarble(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ angle: CGFloat) {
        fillRadial(ctx, c, r,
                   inner: NSColor(white: 0.98, alpha: 1),
                   outer: NSColor(white: 0.74, alpha: 1))
        withRotation(ctx, c, angle) {
            ctx.setStrokeColor(NSColor(white: 0.55, alpha: 0.35).cgColor)
            ctx.setLineWidth(r * 0.05)
            ctx.setLineCap(.round)
            // A couple of soft veins.
            let v1 = CGMutablePath()
            v1.move(to: CGPoint(x: c.x - r, y: c.y - r * 0.3))
            v1.addCurve(to: CGPoint(x: c.x + r, y: c.y + r * 0.45),
                        control1: CGPoint(x: c.x - r * 0.2, y: c.y - r * 0.9),
                        control2: CGPoint(x: c.x + r * 0.1, y: c.y + r * 0.9))
            ctx.addPath(v1)
            let v2 = CGMutablePath()
            v2.move(to: CGPoint(x: c.x - r * 0.7, y: c.y + r))
            v2.addCurve(to: CGPoint(x: c.x + r * 0.6, y: c.y - r * 0.8),
                        control1: CGPoint(x: c.x - r * 0.9, y: c.y + r * 0.1),
                        control2: CGPoint(x: c.x + r * 0.1, y: c.y - r * 0.2))
            ctx.addPath(v2)
            ctx.strokePath()
        }
    }

    private func drawFootball(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ angle: CGFloat) {
        fillRadial(ctx, c, r,
                   inner: NSColor(white: 0.99, alpha: 1),
                   outer: NSColor(white: 0.84, alpha: 1))
        withRotation(ctx, c, angle) {
            ctx.setFillColor(NSColor(white: 0.10, alpha: 1).cgColor)
            ctx.setStrokeColor(NSColor(white: 0.10, alpha: 0.5).cgColor)
            ctx.setLineWidth(r * 0.04)
            // Central pentagon.
            fillPolygon(ctx, sides: 5, center: c, radius: r * 0.32, rotation: -.pi / 2)
            // Five pentagons around it, pointing inward, partially clipped by the rim.
            for k in 0..<5 {
                let a = -CGFloat.pi / 2 + CGFloat(k) * (2 * .pi / 5)
                let pc = CGPoint(x: c.x + cos(a) * r * 0.78, y: c.y + sin(a) * r * 0.78)
                fillPolygon(ctx, sides: 5, center: pc, radius: r * 0.30, rotation: a + .pi / 2)
            }
        }
    }

    private func drawDisco(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ angle: CGFloat) {
        fillRadial(ctx, c, r,
                   inner: NSColor(calibratedRed: 0.82, green: 0.86, blue: 0.96, alpha: 1),
                   outer: NSColor(calibratedRed: 0.42, green: 0.46, blue: 0.62, alpha: 1))
        withRotation(ctx, c, angle) {
            let tiles = 7
            let step = (r * 2) / CGFloat(tiles)
            for i in 0..<tiles {
                for j in 0..<tiles {
                    let x = c.x - r + CGFloat(i) * step
                    let y = c.y - r + CGFloat(j) * step
                    let shimmer = 0.34 + 0.5 * abs(sin(Double(i) * 1.3 + Double(j) * 0.7))
                    ctx.setFillColor(NSColor(calibratedHue: 0.60, saturation: 0.18,
                                             brightness: CGFloat(shimmer), alpha: 1).cgColor)
                    ctx.fill(CGRect(x: x + 0.6, y: y + 0.6, width: step - 1.2, height: step - 1.2))
                }
            }
            // A couple of sparkles.
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
            for p in [CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.35),
                      CGPoint(x: c.x + r * 0.42, y: c.y - r * 0.1)] {
                ctx.fillEllipse(in: CGRect(x: p.x - r * 0.05, y: p.y - r * 0.05, width: r * 0.1, height: r * 0.1))
            }
        }
    }

    // MARK: Helpers

    private func fillPolygon(_ ctx: CGContext, sides: Int, center: CGPoint, radius: CGFloat, rotation: CGFloat) {
        let path = CGMutablePath()
        for i in 0..<sides {
            let a = rotation + CGFloat(i) * (2 * .pi / CGFloat(sides))
            let p = CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        ctx.addPath(path)
        ctx.fillPath()
    }

    private func fillRadial(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, inner: NSColor, outer: NSColor) {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: space,
                                        colors: [inner.cgColor, outer.cgColor] as CFArray,
                                        locations: [0, 1]) else { return }
        // Light from the upper-left.
        let start = CGPoint(x: c.x - r * 0.35, y: c.y + r * 0.35)
        ctx.drawRadialGradient(gradient, startCenter: start, startRadius: 0,
                               endCenter: c, endRadius: r * 1.25, options: [.drawsAfterEndLocation])
    }

    private func drawGloss(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat) {
        let space = CGColorSpaceCreateDeviceRGB()
        let colors = [NSColor.white.withAlphaComponent(0.55).cgColor,
                      NSColor.white.withAlphaComponent(0.0).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
        let hl = CGPoint(x: c.x - r * 0.34, y: c.y + r * 0.40)
        ctx.drawRadialGradient(gradient, startCenter: hl, startRadius: 0,
                               endCenter: hl, endRadius: r * 0.85, options: [])
    }

    private func withRotation(_ ctx: CGContext, _ c: CGPoint, _ angle: CGFloat, _ body: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: angle)
        ctx.translateBy(x: -c.x, y: -c.y)
        body()
        ctx.restoreGState()
    }
}
