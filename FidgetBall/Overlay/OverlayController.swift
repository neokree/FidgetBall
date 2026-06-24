//
//  OverlayController.swift
//  FidgetBall
//
//  Owns the overlay window, the render view, and the display-link loop. Steps the
//  physics on a fixed timestep, keeps the rope anchored to the menu-bar icon,
//  decides when the window should swallow vs. pass through clicks, and fires
//  haptics on impact.
//

import AppKit
import QuartzCore

final class OverlayController: NSObject, OverlayInteractionDelegate {

    let world: PhysicsWorld

    private let window: OverlayWindow
    private let view: OverlayView
    private let screen: NSScreen
    private var displayLink: CADisplayLink?

    /// Returns the menu-bar anchor in screen coordinates (bottom-center of the status item).
    var anchorProvider: (() -> CGPoint?)?

    var hapticsEnabled = true

    private(set) var isVisible = true
    private var isDragging = false
    private var isSlashing = false
    private var accumulator = 0.0
    private var lastHapticTimestamp = 0.0
    private var lastDirty = NSRect.zero

    // Grab tracking, to tell a volleyball tap from a throw.
    private var grabMoved = 0.0
    private var grabLast = Vector2.zero
    private var grabWasCut = false
    private var bumpOffset = Vector2.zero

    private let fixedStep = 1.0 / 120.0

    var skin: BallSkin {
        get { view.skin }
        set { view.skin = newValue; view.needsDisplay = true }
    }

    init(screen: NSScreen, skin: BallSkin, config: PhysicsConfig) {
        self.screen = screen
        let frame = screen.frame
        let anchor = Vector2(x: Double(frame.width) / 2, y: 12)
        world = PhysicsWorld(config: config, bounds: frame.size, anchor: anchor)
        window = OverlayWindow(frame: frame)
        view = OverlayView(frame: NSRect(origin: .zero, size: frame.size))
        super.init()

        view.world = world
        view.skin = skin
        view.interactionDelegate = self
        window.contentView = view
        window.setFrame(frame, display: true)
        window.orderFrontRegardless()
        startDisplayLink()
    }

    // MARK: Display link

    private func startDisplayLink() {
        let link = view.displayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        if let raw = anchorProvider?() {
            let candidate = screenToScene(raw)
            // Only trust a frame that actually sits in the menu-bar strip at the
            // top of the screen — the status item reports a bogus offscreen frame
            // until AppKit lays the menu bar out.
            let valid = candidate.y >= -4 && candidate.y <= 100
                && candidate.x >= 0 && candidate.x <= Double(world.bounds.width)
            if valid { world.setAnchor(candidate) }
        }

        var frameDelta = link.targetTimestamp - link.timestamp
        if !(frameDelta > 0) || frameDelta > 1.0 / 30.0 { frameDelta = 1.0 / 60.0 }
        accumulator += frameDelta
        var steps = 0
        while accumulator >= fixedStep && steps < 8 {
            world.step(dt: fixedStep)
            accumulator -= fixedStep
            steps += 1
        }

        updateMouseState()
        fireHaptics(now: link.timestamp)
        invalidateContent()
    }

    // MARK: Per-frame helpers

    private func updateMouseState() {
        let cursor = screenToScene(NSEvent.mouseLocation)
        let nearBall = !world.isBallGone
            && cursor.distance(to: world.ballPosition) <= world.config.ballRadius + 16
        let nearRope = world.distanceToRope(cursor) <= 18 // large when cut → false
        window.ignoresMouseEvents = !(nearBall || nearRope || isDragging || isSlashing)
        if isDragging {
            NSCursor.closedHand.set()
        } else if nearBall {
            NSCursor.openHand.set()
        } else if nearRope {
            NSCursor.crosshair.set()
        }
    }

    private func fireHaptics(now: CFTimeInterval) {
        guard hapticsEnabled, world.lastImpactSpeed > 5, now - lastHapticTimestamp > 0.07 else { return }
        performHaptic(now: now)
    }

    private func performHaptic(now: CFTimeInterval = 0) {
        guard hapticsEnabled else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        lastHapticTimestamp = now
    }

    private func invalidateContent() {
        if world.isBallGone {
            if lastDirty != .zero { view.setNeedsDisplay(lastDirty); lastDirty = .zero }
            return
        }
        let r = world.config.ballRadius
        var minX = world.ballPosition.x - r, maxX = world.ballPosition.x + r
        var minY = world.ballPosition.y - r, maxY = world.ballPosition.y + r
        if !world.isCut {
            for point in world.points {
                minX = min(minX, point.position.x); maxX = max(maxX, point.position.x)
                minY = min(minY, point.position.y); maxY = max(maxY, point.position.y)
            }
        }
        let pad = 16.0 // covers ball shadow blur + rope stroke
        let rect = NSRect(x: minX - pad, y: minY - pad,
                          width: (maxX - minX) + pad * 2, height: (maxY - minY) + pad * 2)
        view.setNeedsDisplay(lastDirty.union(rect))
        lastDirty = rect
    }

    // MARK: Coordinate mapping

    private func screenToScene(_ p: CGPoint) -> Vector2 {
        Vector2(x: Double(p.x - screen.frame.minX),
                y: Double(screen.frame.maxY - p.y))
    }

    // MARK: Commands

    func toggleVisibility() { isVisible ? hide() : show() }

    func show() {
        isVisible = true
        window.orderFrontRegardless()
        displayLink?.isPaused = false
    }

    func hide() {
        isVisible = false
        window.orderOut(nil)
        displayLink?.isPaused = true
    }

    func dropNewBall() {
        world.reset()
        show()
        view.needsDisplay = true
    }

    func cutRope() { world.cut() }

    /// Apply live physics changes from the settings window. Ball size and rope
    /// length take effect immediately; the rope simply re-settles.
    func applyConfig(_ config: PhysicsConfig) {
        world.config = config
    }

    // MARK: OverlayInteractionDelegate

    func overlayViewShouldGrab(at scenePoint: Vector2) -> Bool {
        guard !world.isBallGone else { return false }
        return scenePoint.distance(to: world.ballPosition) <= world.config.ballRadius + 10
    }

    func overlayViewShouldStartSlash(at scenePoint: Vector2) -> Bool {
        guard !world.isCut, !world.isBallGone else { return false }
        return world.distanceToRope(scenePoint) <= 18
    }

    func overlayView(_ view: OverlayView, didGrabAt scenePoint: Vector2) {
        isDragging = true
        grabWasCut = world.isCut
        bumpOffset = world.ballPosition - scenePoint // captured before the grab moves the ball
        grabMoved = 0
        grabLast = scenePoint
        world.grab(at: scenePoint)
    }

    func overlayView(_ view: OverlayView, didDragTo scenePoint: Vector2) {
        grabMoved += scenePoint.distance(to: grabLast)
        grabLast = scenePoint
        world.drag(to: scenePoint)
    }

    func overlayViewDidRelease(_ view: OverlayView) {
        isDragging = false
        if grabWasCut && grabMoved < 6 {
            world.bump(offset: bumpOffset) // a tap on the free ball = volleyball bump
            performHaptic()
        } else {
            world.release()
        }
    }

    func overlayViewDidBeginSlash(_ view: OverlayView) {
        isSlashing = true
    }

    func overlayView(_ view: OverlayView, slashFrom a: Vector2, to b: Vector2) {
        guard world.ropeIsCrossed(from: a, to: b) else { return }
        world.cut()
        performHaptic()
    }

    func overlayViewDidEndSlash(_ view: OverlayView) {
        isSlashing = false
    }
}
