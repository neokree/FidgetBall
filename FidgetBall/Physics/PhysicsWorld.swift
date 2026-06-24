//
//  PhysicsWorld.swift
//  FidgetBall
//
//  Verlet-integration simulation of a ball hanging on a rope from a moving
//  anchor (the menu-bar icon). Pure model: no AppKit, fully unit-testable.
//
//  Scene coordinates: origin top-left, +x right, +y DOWN (gravity is +y).
//  Bounds are [0, width] x [0, height]; the ball collides with all four edges.
//

import CoreGraphics

/// One mass point in the rope chain.
nonisolated struct VerletPoint: Equatable {
    var position: Vector2
    var previous: Vector2
    var pinned: Bool

    init(_ position: Vector2, pinned: Bool = false) {
        self.position = position
        self.previous = position
        self.pinned = pinned
    }
}

nonisolated final class PhysicsWorld {

    var config: PhysicsConfig
    var bounds: CGSize

    /// Rope points, index 0 = anchor (pinned to the menu bar), last = the ball.
    private(set) var points: [VerletPoint] = []
    private(set) var isCut = false
    private(set) var isGrabbed = false
    /// True once a cut ball has fallen off the bottom of the screen.
    private(set) var isBallGone = false
    /// Speed of the most recent impact (wall bounce or rope snapping taut), for haptics.
    private(set) var lastImpactSpeed: Double = 0
    /// Accumulated rotation (radians) used to spin the skin while it rolls/flies.
    private(set) var ballAngle: Double = 0

    private var anchor: Vector2

    init(config: PhysicsConfig, bounds: CGSize, anchor: Vector2) {
        self.config = config
        self.bounds = bounds
        self.anchor = anchor
        reset()
    }

    // MARK: Derived state

    var anchorPosition: Vector2 { anchor }
    private var ballIndex: Int { points.count - 1 }
    var ballPosition: Vector2 { points[ballIndex].position }
    /// Per-step displacement of the ball (Verlet velocity).
    var ballVelocity: Vector2 { points[ballIndex].position - points[ballIndex].previous }

    private var restLength: Double {
        config.ropeLength / Double(max(1, config.ropeSegments))
    }

    func ballContains(_ p: Vector2) -> Bool {
        p.distance(to: ballPosition) <= config.ballRadius
    }

    // MARK: Lifecycle

    /// Rebuild a taut rope hanging straight down from the anchor with the ball at rest.
    func reset() {
        isCut = false
        isGrabbed = false
        isBallGone = false
        lastImpactSpeed = 0
        ballAngle = 0
        let n = max(1, config.ropeSegments)
        let seg = config.ropeLength / Double(n)
        points = (0...n).map { i in
            let p = Vector2(x: anchor.x, y: anchor.y + seg * Double(i))
            return VerletPoint(p, pinned: i == 0)
        }
        points[0] = VerletPoint(anchor, pinned: true)
    }

    func setAnchor(_ p: Vector2) {
        anchor = p
        guard !points.isEmpty else { return }
        if !isCut {
            points[0].position = p
            points[0].previous = p
            points[0].pinned = true
        }
    }

    // MARK: Interaction

    func grab(at p: Vector2) {
        isGrabbed = true
        points[ballIndex].position = p
        points[ballIndex].previous = p
    }

    func drag(to p: Vector2) {
        guard isGrabbed else { return }
        points[ballIndex].previous = points[ballIndex].position
        points[ballIndex].position = p
    }

    func release() {
        guard isGrabbed else { return }
        isGrabbed = false
        let velocity = ballVelocity * config.throwMultiplier
        points[ballIndex].previous = points[ballIndex].position - velocity
    }

    /// Sever the rope: the ball becomes a free particle that keeps its velocity.
    func cut() {
        guard !isCut else { return }
        isCut = true
        for i in points.indices { points[i].pinned = false }
    }

    /// Volleyball bump: kick a cut ball upward. Hitting it off-center adds sideways
    /// momentum (hit the left side → it veers right), so you can rally it.
    func bump(from point: Vector2) {
        bump(offset: ballPosition - point)
    }

    /// Bump using a precomputed hit offset (ball center − hit point).
    func bump(offset: Vector2) {
        guard isCut, !isBallGone else { return }
        let horizontal = max(-7.0, min(7.0, offset.x * 0.18))
        let velocity = Vector2(x: horizontal, y: -config.bumpStrength)
        isGrabbed = false
        points[ballIndex].previous = points[ballIndex].position - velocity
    }

    /// Does the drag segment a→b cross the rope? (False once the rope is cut.)
    func ropeIsCrossed(from a: Vector2, to b: Vector2) -> Bool {
        guard !isCut else { return false }
        for i in 0..<(points.count - 1) {
            if Geometry.segmentsIntersect(a, b, points[i].position, points[i + 1].position) {
                return true
            }
        }
        return false
    }

    /// Shortest distance from a point to the rope (for hover/interactivity). Large when cut.
    func distanceToRope(_ p: Vector2) -> Double {
        guard !isCut, points.count > 1 else { return .greatestFiniteMagnitude }
        var best = Double.greatestFiniteMagnitude
        for i in 0..<(points.count - 1) {
            best = min(best, Geometry.distancePointToSegment(p, points[i].position, points[i + 1].position))
        }
        return best
    }

    // MARK: Simulation

    func step(dt: Double) {
        guard !points.isEmpty else { return }
        lastImpactSpeed = 0

        // Keep the anchor pinned to the (possibly moving) menu bar.
        if !isCut {
            points[0].position = anchor
            points[0].previous = anchor
            points[0].pinned = true
        }

        integrate(dt: dt)

        if !isCut {
            for _ in 0..<max(1, config.constraintIterations) {
                satisfyRopeConstraints()
            }
            if !isGrabbed {
                clampBallToRope()
            }
        }

        if isGrabbed {
            clampGrabbedBall()
        } else {
            collideBallWithWalls()
        }

        ballAngle += ballVelocity.x / config.ballRadius * config.spin
    }

    private func integrate(dt: Double) {
        let damping = 1.0 - config.drag
        let gravityStep = Vector2(x: 0, y: config.gravity * dt * dt)
        for i in points.indices {
            if points[i].pinned { continue }
            if isGrabbed && i == ballIndex { continue } // cursor controls the ball
            let velocity = (points[i].position - points[i].previous) * damping
            points[i].previous = points[i].position
            points[i].position = points[i].position + velocity + gravityStep
        }
    }

    private func satisfyRopeConstraints() {
        let rest = restLength
        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            let delta = b.position - a.position
            let dist = max(delta.length, 1e-6)
            let correction = delta * (0.5 * (dist - rest) / dist)

            let aMovable = !a.pinned
            let bMovable = !b.pinned && !(isGrabbed && i + 1 == ballIndex)

            if aMovable && bMovable {
                points[i].position = a.position + correction
                points[i + 1].position = b.position - correction
            } else if aMovable {
                points[i].position = a.position + correction * 2
            } else if bMovable {
                points[i + 1].position = b.position - correction * 2
            }
        }
    }

    /// Safety cap for fast throws: the ball can never be farther from the anchor
    /// than the fully-extended rope, no matter how violent the motion. When the
    /// rope snaps taut at speed, record the impact so it can buzz the trackpad.
    private func clampBallToRope() {
        let toBall = ballPosition - anchor
        let dist = toBall.length
        guard dist > config.ropeLength else { return }
        lastImpactSpeed = max(lastImpactSpeed, ballVelocity.length)
        points[ballIndex].position = anchor + toBall.normalized() * config.ropeLength
    }

    /// Bounce off the ceiling and side walls. The floor is intentionally open: a
    /// cut ball that isn't kept up falls off the bottom and is removed from play.
    private func collideBallWithWalls() {
        let r = config.ballRadius
        let e = config.restitution
        let keep = 1.0 - config.wallFriction
        var p = points[ballIndex].position
        var prev = points[ballIndex].previous

        // Ceiling
        if p.y < r {
            let vy = p.y - prev.y
            let vx = p.x - prev.x
            p.y = r
            prev.y = p.y + vy * e
            prev.x = p.x - vx * keep
            lastImpactSpeed = max(lastImpactSpeed, abs(vy))
        }
        // Left wall
        if p.x < r {
            let vx = p.x - prev.x
            let vy = p.y - prev.y
            p.x = r
            prev.x = p.x + vx * e
            prev.y = p.y - vy * keep
            lastImpactSpeed = max(lastImpactSpeed, abs(vx))
        }
        // Right wall
        if p.x > bounds.width - r {
            let vx = p.x - prev.x
            let vy = p.y - prev.y
            p.x = bounds.width - r
            prev.x = p.x + vx * e
            prev.y = p.y - vy * keep
            lastImpactSpeed = max(lastImpactSpeed, abs(vx))
        }

        points[ballIndex].position = p
        points[ballIndex].previous = prev

        // Open floor: once fully below the bottom edge, the ball is gone.
        if p.y - r > bounds.height { isBallGone = true }
    }

    private func clampGrabbedBall() {
        let r = config.ballRadius
        points[ballIndex].position.x = min(max(points[ballIndex].position.x, r), bounds.width - r)
        points[ballIndex].position.y = min(max(points[ballIndex].position.y, r), bounds.height - r)
    }
}
