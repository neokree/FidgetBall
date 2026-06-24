//
//  OverlayView.swift
//  FidgetBall
//
//  Draws the rope and ball each frame and turns mouse input into two gestures:
//  grabbing/throwing the ball, or slashing across the rope to cut it.
//  Flipped so its coordinate space matches the physics scene (top-left, +y down).
//

import AppKit

protocol OverlayInteractionDelegate: AnyObject {
    func overlayViewShouldGrab(at scenePoint: Vector2) -> Bool
    func overlayViewShouldStartSlash(at scenePoint: Vector2) -> Bool
    func overlayView(_ view: OverlayView, didGrabAt scenePoint: Vector2)
    func overlayView(_ view: OverlayView, didDragTo scenePoint: Vector2)
    func overlayViewDidRelease(_ view: OverlayView)
    func overlayViewDidBeginSlash(_ view: OverlayView)
    func overlayView(_ view: OverlayView, slashFrom: Vector2, to: Vector2)
    func overlayViewDidEndSlash(_ view: OverlayView)
}

final class OverlayView: NSView {

    var world: PhysicsWorld?
    var skin: BallSkin = .smiley
    weak var interactionDelegate: OverlayInteractionDelegate?

    private enum Gesture { case none, grab, slash }
    private var gesture: Gesture = .none
    private var lastSlashPoint = Vector2.zero

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let world, let ctx = NSGraphicsContext.current?.cgContext else { return }
        guard !world.isBallGone else { return }
        if !world.isCut {
            drawRope(world, in: ctx)
        }
        skin.draw(in: ctx,
                  center: world.ballPosition.cgPoint,
                  radius: CGFloat(world.config.ballRadius),
                  angle: CGFloat(world.ballAngle))
    }

    private func drawRope(_ world: PhysicsWorld, in ctx: CGContext) {
        let points = world.points.map { $0.position.cgPoint }
        guard points.count > 1 else { return }
        let path = CGMutablePath()
        path.move(to: points[0])
        for p in points.dropFirst() { path.addLine(to: p) }
        ctx.addPath(path)
        ctx.setStrokeColor(NSColor(white: 0.18, alpha: 0.9).cgColor)
        ctx.setLineWidth(2.4)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.strokePath()
        // Anchor nub at the menu bar.
        let a = points[0]
        ctx.setFillColor(NSColor(white: 0.12, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: a.x - 3, y: a.y - 3, width: 6, height: 6))
    }

    // MARK: Input

    private func scenePoint(_ event: NSEvent) -> Vector2 {
        Vector2(convert(event.locationInWindow, from: nil))
    }

    override func mouseDown(with event: NSEvent) {
        let p = scenePoint(event)
        if interactionDelegate?.overlayViewShouldGrab(at: p) == true {
            gesture = .grab
            interactionDelegate?.overlayView(self, didGrabAt: p)
        } else if interactionDelegate?.overlayViewShouldStartSlash(at: p) == true {
            gesture = .slash
            lastSlashPoint = p
            interactionDelegate?.overlayViewDidBeginSlash(self)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let p = scenePoint(event)
        switch gesture {
        case .grab:
            interactionDelegate?.overlayView(self, didDragTo: p)
        case .slash:
            interactionDelegate?.overlayView(self, slashFrom: lastSlashPoint, to: p)
            lastSlashPoint = p
        case .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        switch gesture {
        case .grab: interactionDelegate?.overlayViewDidRelease(self)
        case .slash: interactionDelegate?.overlayViewDidEndSlash(self)
        case .none: break
        }
        gesture = .none
    }
}
