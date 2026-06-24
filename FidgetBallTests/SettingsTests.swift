//
//  SettingsTests.swift
//  FidgetBallTests
//
//  Locks in the user settings → physics mapping and persistence round-trip.
//

import Testing
import Foundation
@testable import FidgetBall

struct SettingsTests {

    @Test func mapsSettingsOntoPhysicsConfig() {
        var s = BallSettings.default
        s.gravity = 1800
        s.bounce = 0.5
        s.airResistance = 0.02
        s.throwPower = 1.4
        s.ballSize = 40
        s.ropeLength = 300
        s.stiffness = 22.6
        s.spin = 1.5
        s.bumpPower = 15
        s.wallFriction = 0.2

        let c = s.physicsConfig
        #expect(c.gravity == 1800)
        #expect(c.restitution == 0.5)
        #expect(c.drag == 0.02)
        #expect(c.throwMultiplier == 1.4)
        #expect(c.ballRadius == 40)
        #expect(c.ropeLength == 300)
        #expect(c.constraintIterations == 23) // rounded
        #expect(c.spin == 1.5)
        #expect(c.bumpStrength == 15)
        #expect(c.wallFriction == 0.2)
    }

    @Test func codableRoundTrips() throws {
        var s = BallSettings.default
        s.gravity = 1234
        s.skinRaw = BallSkin.disco.rawValue
        s.hapticsEnabled = false
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(BallSettings.self, from: data)
        #expect(decoded == s)
        #expect(decoded.skin == .disco)
    }

    @Test func defaultsAreSensible() {
        let s = BallSettings.default
        #expect(s.skin == .smiley)
        #expect(s.hapticsEnabled)
        #expect(s.physicsConfig.constraintIterations >= 2)
    }

    @Test func allSixSkinsPresent() {
        #expect(BallSkin.allCases.count == 6)
        #expect(BallSkin.allCases.contains(.football))
        #expect(BallSkin.allCases.contains(.disco))
    }
}
