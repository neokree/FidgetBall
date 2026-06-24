//
//  BallSettings.swift
//  FidgetBall
//
//  The user-facing, persisted configuration. Maps onto the internal PhysicsConfig
//  plus app-level options (skin, haptics).
//

import Foundation

struct BallSettings: Codable, Equatable {
    var gravity: Double = 2200
    var bounce: Double = 0.62        // restitution
    var airResistance: Double = 0.012 // drag (lower = swings longer)
    var throwPower: Double = 1.15     // throw multiplier
    var ballSize: Double = 30         // ball radius
    var ropeLength: Double = 230
    var stiffness: Double = 18        // constraint iterations (higher = stiffer rope)
    var spin: Double = 1.0
    var bumpPower: Double = 12         // volleyball bump strength
    var wallFriction: Double = 0.08
    var hapticsEnabled: Bool = true
    var skinRaw: String = BallSkin.smiley.rawValue

    static let `default` = BallSettings()

    var skin: BallSkin {
        BallSkin(rawValue: skinRaw) ?? .smiley
    }

    var physicsConfig: PhysicsConfig {
        PhysicsConfig(
            gravity: gravity,
            drag: airResistance,
            restitution: bounce,
            wallFriction: wallFriction,
            ballRadius: ballSize,
            ropeLength: ropeLength,
            ropeSegments: 14,
            throwMultiplier: throwPower,
            constraintIterations: max(2, Int(stiffness.rounded())),
            spin: spin,
            bumpStrength: bumpPower
        )
    }
}
