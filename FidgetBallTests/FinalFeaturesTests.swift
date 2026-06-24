//
//  FinalFeaturesTests.swift
//  FidgetBallTests
//
//  Coverage for the final-version mechanics: slash-to-cut geometry, the
//  volleyball bump, and the cut ball falling off the bottom.
//

import Testing
import CoreGraphics
@testable import FidgetBall

struct GeometryTests {

    @Test func crossingSegmentsIntersect() {
        #expect(Geometry.segmentsIntersect(
            Vector2(x: 0, y: 0), Vector2(x: 10, y: 10),
            Vector2(x: 0, y: 10), Vector2(x: 10, y: 0)))
    }

    @Test func parallelSegmentsDoNotIntersect() {
        #expect(!Geometry.segmentsIntersect(
            Vector2(x: 0, y: 0), Vector2(x: 10, y: 0),
            Vector2(x: 0, y: 5), Vector2(x: 10, y: 5)))
    }

    @Test func separatedSegmentsDoNotIntersect() {
        #expect(!Geometry.segmentsIntersect(
            Vector2(x: 0, y: 0), Vector2(x: 1, y: 1),
            Vector2(x: 5, y: 5), Vector2(x: 6, y: 6)))
    }

    @Test func distancePointToSegmentPerpendicular() {
        let d = Geometry.distancePointToSegment(
            Vector2(x: 5, y: 3), Vector2(x: 0, y: 0), Vector2(x: 10, y: 0))
        #expect(abs(d - 3) < 1e-9)
    }

    @Test func distancePointToSegmentBeyondEndpoint() {
        let d = Geometry.distancePointToSegment(
            Vector2(x: -3, y: 0), Vector2(x: 0, y: 0), Vector2(x: 10, y: 0))
        #expect(abs(d - 3) < 1e-9)
    }
}

struct CutAndBumpTests {

    let dt = 1.0 / 120.0
    let bounds = CGSize(width: 800, height: 600)
    let anchor = Vector2(x: 400, y: 30)

    private func makeWorld() -> PhysicsWorld {
        PhysicsWorld(config: .default, bounds: bounds, anchor: anchor)
    }

    @Test func bumpSendsCutBallUpward() {
        let w = makeWorld()
        w.cut()
        w.bump(from: Vector2(x: w.ballPosition.x, y: w.ballPosition.y + 30))
        #expect(w.ballVelocity.y < 0)
    }

    @Test func bumpHorizontalFollowsClickSide() {
        let w = makeWorld()
        w.cut()
        // Hitting the LEFT of the ball pushes it to the right.
        w.bump(from: Vector2(x: w.ballPosition.x - 20, y: w.ballPosition.y))
        #expect(w.ballVelocity.x > 0)
    }

    @Test func bumpIgnoredWhileRoped() {
        let w = makeWorld() // not cut
        w.bump(from: Vector2(x: w.ballPosition.x, y: w.ballPosition.y + 30))
        #expect(w.ballVelocity.y > -1.0) // not launched
        #expect(!w.isBallGone)
    }

    @Test func perpendicularSlashCrossesRope() {
        let w = makeWorld()
        let y = anchor.y + w.config.ropeLength * 0.4
        #expect(w.ropeIsCrossed(from: Vector2(x: anchor.x - 40, y: y),
                                to: Vector2(x: anchor.x + 40, y: y)))
    }

    @Test func slashFarFromRopeDoesNotCross() {
        let w = makeWorld()
        let y = anchor.y + w.config.ropeLength * 0.4
        #expect(!w.ropeIsCrossed(from: Vector2(x: anchor.x + 200, y: y),
                                 to: Vector2(x: anchor.x + 280, y: y)))
    }

    @Test func cutRopeCannotBeCrossedAgain() {
        let w = makeWorld()
        w.cut()
        let y = anchor.y + w.config.ropeLength * 0.4
        #expect(!w.ropeIsCrossed(from: Vector2(x: anchor.x - 40, y: y),
                                 to: Vector2(x: anchor.x + 40, y: y)))
    }

    @Test func resetClearsGoneAndCut() {
        let w = makeWorld()
        w.cut()
        for _ in 0..<500 { w.step(dt: dt) }
        #expect(w.isBallGone)
        w.reset()
        #expect(!w.isBallGone)
        #expect(!w.isCut)
        #expect(w.ballPosition.distance(to: w.anchorPosition) <= w.config.ropeLength * 1.05)
    }
}
