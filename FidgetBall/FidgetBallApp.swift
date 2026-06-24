//
//  FidgetBallApp.swift
//  FidgetBall
//
//  An open-source desktop fidget ball for macOS. The real work happens in
//  AppDelegate (menu-bar accessory app); SwiftUI just hosts the lifecycle.
//

import SwiftUI

@main
struct FidgetBallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // No main window — the ball lives in its own overlay panel. The empty
        // Settings scene keeps SwiftUI happy without opening anything on launch.
        Settings { EmptyView() }
    }
}
