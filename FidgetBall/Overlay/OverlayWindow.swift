//
//  OverlayWindow.swift
//  FidgetBall
//
//  The transparent, always-on-top, full-screen surface the ball lives on.
//  A non-activating panel so clicking the ball never steals focus from the app
//  you're actually working in — you fidget without losing your place.
//

import AppKit

final class OverlayWindow: NSPanel {

    init(frame: NSRect) {
        super.init(contentRect: frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating                                   // above app windows, below the menu bar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        ignoresMouseEvents = true                            // toggled on near the ball
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        worksWhenModal = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
