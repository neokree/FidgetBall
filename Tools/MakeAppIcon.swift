import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

func drawSmiley(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ cs: CGColorSpace) {
    // Contact shadow under the ball.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -r * 0.10), blur: r * 0.35, color: rgb(0, 0, 0, 0.28))
    ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.setFillColor(rgb(0, 0, 0, 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to the ball.
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.clip()

    // Golden radial body.
    let body = CGGradient(colorsSpace: cs,
                          colors: [rgb(1.0, 0.86, 0.27), rgb(0.95, 0.66, 0.10)] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(body,
                           startCenter: CGPoint(x: c.x - r * 0.35, y: c.y + r * 0.35), startRadius: 0,
                           endCenter: c, endRadius: r * 1.25, options: [.drawsAfterEndLocation])

    // Eyes.
    let eyeR = r * 0.12
    let eyeY = c.y + r * 0.20
    ctx.setFillColor(rgb(0.12, 0.10, 0.06, 1))
    for dx in [-r * 0.34, r * 0.34] {
        ctx.addEllipse(in: CGRect(x: c.x + dx - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2))
    }
    ctx.fillPath()

    // Smile (lower arc, opening upward).
    ctx.setStrokeColor(rgb(0.12, 0.10, 0.06, 1))
    ctx.setLineWidth(r * 0.12)
    ctx.setLineCap(.round)
    let smile = CGMutablePath()
    smile.addArc(center: CGPoint(x: c.x, y: c.y + r * 0.04), radius: r * 0.5,
                 startAngle: .pi * 1.18, endAngle: .pi * 1.82, clockwise: false)
    ctx.addPath(smile)
    ctx.strokePath()

    // Glossy highlight.
    let gloss = CGGradient(colorsSpace: cs,
                           colors: [rgb(1, 1, 1, 0.55), rgb(1, 1, 1, 0)] as CFArray,
                           locations: [0, 1])!
    let hl = CGPoint(x: c.x - r * 0.34, y: c.y + r * 0.42)
    ctx.drawRadialGradient(gloss, startCenter: hl, startRadius: 0, endCenter: hl, endRadius: r * 0.85, options: [])
    ctx.restoreGState()
}

func makeIcon(_ n: CGFloat) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(n), height: Int(n), bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.clear(CGRect(x: 0, y: 0, width: n, height: n))

    // Rounded app tile.
    let margin = n * 0.085
    let tile = CGRect(x: margin, y: margin, width: n - 2 * margin, height: n - 2 * margin)
    let corner = tile.width * 0.225
    let tilePath = CGPath(roundedRect: tile, cornerWidth: corner, cornerHeight: corner, transform: nil)

    // Tile drop shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -n * 0.012), blur: n * 0.03, color: rgb(0.4, 0.25, 0, 0.22))
    ctx.addPath(tilePath); ctx.setFillColor(rgb(1, 1, 1, 1)); ctx.fillPath()
    ctx.restoreGState()

    // Warm cream→gold tile gradient.
    ctx.saveGState()
    ctx.addPath(tilePath); ctx.clip()
    let tileGrad = CGGradient(colorsSpace: cs,
                              colors: [rgb(1.0, 0.96, 0.83), rgb(1.0, 0.80, 0.36)] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(tileGrad, start: CGPoint(x: 0, y: n), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()

    // Smiley ball centered on the tile.
    drawSmiley(ctx, CGPoint(x: n / 2, y: n / 2), n * 0.295, cs)
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let outDir = CommandLine.arguments[1]
for size in [16, 32, 64, 128, 256, 512, 1024] {
    writePNG(makeIcon(CGFloat(size)), "\(outDir)/icon_\(size).png")
    print("wrote icon_\(size).png")
}
