//
//  PhysicsTests.swift
//  FidgetBallTests
//
//  TDD coverage for the pure Verlet physics core.
//

import Testing
import CoreGraphics
@testable import FidgetBall

// MARK: - Vector2

struct Vector2Tests {

    @Test func lengthOfThreeFourIsFive() {
        #expect(Vector2(x: 3, y: 4).length == 5)
    }

    @Test func addSubtractScale() {
        #expect(Vector2(x: 1, y: 2) + Vector2(x: 3, y: 4) == Vector2(x: 4, y: 6))
        #expect(Vector2(x: 5, y: 5) - Vector2(x: 2, y: 1) == Vector2(x: 3, y: 4))
        #expect(Vector2(x: 2, y: 3) * 2 == Vector2(x: 4, y: 6))
    }

    @Test func distanceBetweenPoints() {
        #expect(Vector2(x: 0, y: 0).distance(to: Vector2(x: 0, y: 5)) == 5)
    }

    @Test func normalizedUnitLengthAndZeroIsSafe() {
        let n = Vector2(x: 0, y: 4).normalized()
        #expect(abs(n.x - 0) < 1e-9)
        #expect(abs(n.y - 1) < 1e-9)
        // Normalizing the zero vector must not produce NaN.
        let z = Vector2.zero.normalized()
        #expect(z == Vector2.zero)
    }
}

// MARK: - PhysicsWorld

struct PhysicsWorldTests {

    let dt = 1.0 / 120.0
    let bounds = CGSize(width: 800, height: 600)
    let anchor = Vector2(x: 400, y: 30)

    private func makeWorld() -> PhysicsWorld {
        PhysicsWorld(config: .default, bounds: bounds, anchor: anchor)
    }

    private func advance(_ world: PhysicsWorld, steps: Int) {
        for _ in 0..<steps { world.step(dt: dt) }
    }

    @Test func resetHangsBallStraightBelowAnchorWithinRopeReach() {
        let w = makeWorld()
        let d = w.ballPosition.distance(to: w.anchorPosition)
        #expect(d <= w.config.ropeLength * 1.05)
        #expect(abs(w.ballPosition.x - w.anchorPosition.x) < 1.0)
        #expect(w.ballPosition.y > w.anchorPosition.y) // below the anchor
    }

    @Test func ballSettlesBelowAnchorAtRest() {
        let w = makeWorld()
        advance(w, steps: 1200) // ~10s
        #expect(w.ballPosition.y > w.anchorPosition.y)
        #expect(abs(w.ballPosition.x - w.anchorPosition.x) < 8.0)
        let d = w.ballPosition.distance(to: w.anchorPosition)
        #expect(abs(d - w.config.ropeLength) < w.config.ropeLength * 0.2)
    }

    @Test func ropeKeepsBallWithinReachWhileSwinging() {
        let w = makeWorld()
        // Fling the ball sideways and up, then let it swing.
        let p0 = w.ballPosition
        w.grab(at: p0)
        w.drag(to: Vector2(x: p0.x + 120, y: 80))
        w.step(dt: dt)
        w.drag(to: Vector2(x: p0.x + 220, y: 60))
        w.step(dt: dt)
        w.release()
        var maxDistance = 0.0
        for _ in 0..<400 {
            w.step(dt: dt)
            maxDistance = max(maxDistance, w.ballPosition.distance(to: w.anchorPosition))
        }
        #expect(maxDistance <= w.config.ropeLength * 1.15)
    }

    @Test func cutRopeLetsBallFallOffBottom() {
        let w = makeWorld()
        w.cut()
        #expect(w.isCut)
        advance(w, steps: 500) // plenty of time to fall past the bottom
        // The floor no longer catches a cut ball; it falls off-screen and is gone.
        #expect(w.isBallGone)
        #expect(w.ballPosition.y > bounds.height)
    }

    @Test func bumpedCutBallRisesThenFallsOff() {
        let w = makeWorld()
        w.cut()
        let startY = w.ballPosition.y
        // Hit it from below — volleyball bump.
        w.bump(from: Vector2(x: w.ballPosition.x, y: w.ballPosition.y + 40))
        #expect(w.ballVelocity.y < 0) // moving up immediately

        var minY = startY
        for _ in 0..<800 {
            w.step(dt: dt)
            minY = min(minY, w.ballPosition.y)
            if w.isBallGone { break }
        }
        #expect(minY < startY)  // it rose above where it started
        #expect(w.isBallGone)   // then eventually fell off the bottom
    }

    @Test func impactSpeedRecordedWhenRopeSnapsTaut() {
        let w = makeWorld()
        // Fling the ball outward so the rope yanks taut.
        let p0 = w.ballPosition
        w.grab(at: p0)
        w.drag(to: Vector2(x: p0.x + 150, y: p0.y - 100))
        w.step(dt: dt)
        w.drag(to: Vector2(x: p0.x + 300, y: p0.y - 180))
        w.step(dt: dt)
        w.release()
        var maxImpact = 0.0
        for _ in 0..<150 {
            w.step(dt: dt)
            maxImpact = max(maxImpact, w.lastImpactSpeed)
        }
        #expect(maxImpact > 0)
    }

    @Test func releaseThrowsBallInDragDirection() {
        let w = makeWorld()
        w.cut()
        let p0 = w.ballPosition
        w.grab(at: p0)
        w.drag(to: Vector2(x: p0.x + 40, y: p0.y))
        w.step(dt: dt)
        w.drag(to: Vector2(x: p0.x + 80, y: p0.y))
        w.step(dt: dt)
        w.release()
        #expect(w.ballVelocity.x > 0)
        w.step(dt: dt)
        #expect(w.ballPosition.x > p0.x)
    }

    @Test func resetRestoresHangingStateAfterCut() {
        let w = makeWorld()
        w.cut()
        advance(w, steps: 300)
        #expect(w.isCut)
        w.reset()
        #expect(!w.isCut)
        #expect(w.ballPosition.distance(to: w.anchorPosition) <= w.config.ropeLength * 1.05)
        advance(w, steps: 60)
        #expect(w.ballPosition.distance(to: w.anchorPosition) <= w.config.ropeLength * 1.1)
    }

    @Test func setAnchorMovesPinnedTopPoint() {
        let w = makeWorld()
        let p = Vector2(x: 123, y: 45)
        w.setAnchor(p)
        #expect(w.anchorPosition == p)
        #expect(w.points.first?.position == p)
    }

    @Test func cutBallBouncesOffSideWalls() {
        let w = makeWorld()
        w.cut()
        let p0 = w.ballPosition
        w.grab(at: p0)
        w.drag(to: Vector2(x: p0.x + 120, y: p0.y))
        w.step(dt: dt)
        w.drag(to: Vector2(x: p0.x + 240, y: p0.y))
        w.step(dt: dt)
        w.release()
        let r = w.config.ballRadius
        for _ in 0..<400 {
            w.step(dt: dt)
            if w.isBallGone { break } // fell off the open bottom
            #expect(w.ballPosition.x >= r - 1.5)
            #expect(w.ballPosition.x <= bounds.width - r + 1.5)
        }
    }

    @Test func ballContainsHitTest() {
        let w = makeWorld()
        #expect(w.ballContains(w.ballPosition))
        let far = w.ballPosition + Vector2(x: w.config.ballRadius * 3, y: 0)
        #expect(!w.ballContains(far))
    }

    @Test func spinAccumulatesWithHorizontalMotion() {
        let w = makeWorld()
        w.cut()
        let p0 = w.ballPosition
        w.grab(at: p0)
        w.drag(to: Vector2(x: p0.x + 40, y: p0.y))
        w.step(dt: dt)
        w.drag(to: Vector2(x: p0.x + 80, y: p0.y))
        w.step(dt: dt)
        w.release()
        let before = w.ballAngle
        advance(w, steps: 10)
        #expect(w.ballAngle != before) // rolling to the right changes spin
    }
}
