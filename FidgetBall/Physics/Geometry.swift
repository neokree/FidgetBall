//
//  Geometry.swift
//  FidgetBall
//
//  Pure 2D segment helpers used by the slash-to-cut gesture.
//

import Foundation

nonisolated enum Geometry {

    /// True when segment p1→p2 properly crosses segment p3→p4.
    static func segmentsIntersect(_ p1: Vector2, _ p2: Vector2, _ p3: Vector2, _ p4: Vector2) -> Bool {
        func orientation(_ a: Vector2, _ b: Vector2, _ c: Vector2) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        let d1 = orientation(p3, p4, p1)
        let d2 = orientation(p3, p4, p2)
        let d3 = orientation(p1, p2, p3)
        let d4 = orientation(p1, p2, p4)
        return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0))
            && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))
    }

    /// Shortest distance from point `p` to the segment a→b (clamped to the endpoints).
    static func distancePointToSegment(_ p: Vector2, _ a: Vector2, _ b: Vector2) -> Double {
        let ab = b - a
        let lengthSquared = ab.lengthSquared
        guard lengthSquared > 1e-12 else { return p.distance(to: a) }
        var t = ((p.x - a.x) * ab.x + (p.y - a.y) * ab.y) / lengthSquared
        t = max(0, min(1, t))
        let projection = Vector2(x: a.x + ab.x * t, y: a.y + ab.y * t)
        return p.distance(to: projection)
    }
}
