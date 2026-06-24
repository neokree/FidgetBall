//
//  PhysicsConfig.swift
//  FidgetBall
//
//  Tunable parameters for the fidget-ball simulation. These back the sliders in
//  the settings window.
//

import Foundation

nonisolated struct PhysicsConfig: Equatable {
    /// Downward acceleration in scene units / second² (scene y grows downward).
    var gravity: Double
    /// Air damping applied to velocity each step (0 = none, 1 = frozen).
    var drag: Double
    /// Wall/floor bounciness (0 = dead stop, 1 = perfectly elastic).
    var restitution: Double
    /// Tangential energy lost on a wall hit (0 = frictionless, 1 = sticky).
    var wallFriction: Double
    /// Ball radius in scene units (collision + hit-test + render size).
    var ballRadius: Double
    /// Resting length of the whole rope in scene units.
    var ropeLength: Double
    /// Number of rope segments (points = segments + 1, last point is the ball).
    var ropeSegments: Int
    /// Release velocity multiplier — how hard a throw flings the ball.
    var throwMultiplier: Double
    /// Constraint relaxation iterations per step (higher = stiffer rope).
    var constraintIterations: Int
    /// Visual spin multiplier — how much the skin rotates as it moves.
    var spin: Double
    /// Upward kick (scene units / step) when you tap a cut ball — volleyball bump.
    var bumpStrength: Double

    static let `default` = PhysicsConfig(
        gravity: 2200,
        drag: 0.012,
        restitution: 0.62,
        wallFriction: 0.08,
        ballRadius: 30,
        ropeLength: 230,
        ropeSegments: 14,
        throwMultiplier: 1.15,
        constraintIterations: 18,
        spin: 1.0,
        bumpStrength: 12.0
    )
}
