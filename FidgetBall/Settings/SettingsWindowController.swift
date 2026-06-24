//
//  SettingsWindowController.swift
//  FidgetBall
//
//  Hosts the SwiftUI settings UI in a normal window. The app is an accessory
//  (no Dock icon); we briefly activate so the window can take focus, then it
//  drops back to the background when closed.
//

import AppKit
import SwiftUI

final class SettingsWindowController {

    private let store: SettingsStore
    private var window: NSWindow?

    init(store: SettingsStore) {
        self.store = store
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView(store: store))
            let window = NSWindow(contentViewController: hosting)
            window.title = "FidgetBall Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
