//
//  Vector2.swift
//  FidgetBall
//
//  A tiny 2D vector value type for the physics core. Pure, no UI dependency.
//

import CoreGraphics

nonisolated struct Vector2: Equatable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    static let zero = Vector2(x: 0, y: 0)

    var lengthSquared: Double { x * x + y * y }
    var length: Double { (lengthSquared).squareRoot() }

    func distance(to other: Vector2) -> Double {
        (self - other).length
    }

    /// Unit vector in the same direction. The zero vector normalizes to zero
    /// (never NaN), which keeps constraint math stable when points coincide.
    func normalized() -> Vector2 {
        let len = length
        guard len > 1e-12 else { return .zero }
        return Vector2(x: x / len, y: y / len)
    }

    static func + (a: Vector2, b: Vector2) -> Vector2 {
        Vector2(x: a.x + b.x, y: a.y + b.y)
    }

    static func - (a: Vector2, b: Vector2) -> Vector2 {
        Vector2(x: a.x - b.x, y: a.y - b.y)
    }

    static func * (a: Vector2, s: Double) -> Vector2 {
        Vector2(x: a.x * s, y: a.y * s)
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }

    init(_ point: CGPoint) {
        self.x = Double(point.x)
        self.y = Double(point.y)
    }
}
