//
//  AppDelegate.swift
//  FidgetBall
//
//  Wires the menu-bar app together: an accessory (no Dock icon) process that owns
//  the overlay, the status item, the settings store/window, and the ⌥F hot key.
//

import AppKit
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var overlay: OverlayController?
    private var statusBar: StatusBarController?
    private var settingsWindow: SettingsWindowController?
    private var store: SettingsStore?
    private var hotKey: HotKey?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Menu-bar app: no Dock icon, never steals foreground focus.
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let store = SettingsStore()
        let settings = store.settings
        let overlay = OverlayController(screen: screen, skin: settings.skin, config: settings.physicsConfig)
        overlay.hapticsEnabled = settings.hapticsEnabled
        let statusBar = StatusBarController(skin: settings.skin)
        let settingsWindow = SettingsWindowController(store: store)

        // Live-apply every settings change to the running ball.
        store.onChange = { [weak overlay, weak statusBar] settings in
            overlay?.applyConfig(settings.physicsConfig)
            overlay?.skin = settings.skin
            overlay?.hapticsEnabled = settings.hapticsEnabled
            statusBar?.updateIcon(settings.skin)
        }

        statusBar.onDropNewBall = { [weak overlay] in overlay?.dropNewBall() }
        statusBar.onCut = { [weak overlay] in overlay?.cutRope() }
        statusBar.onToggle = { [weak overlay] in overlay?.toggleVisibility() }
        statusBar.onOpenSettings = { [weak settingsWindow] in settingsWindow?.show() }
        statusBar.onSelectSkin = { [weak store] skin in store?.settings.skinRaw = skin.rawValue }
        overlay.anchorProvider = { [weak statusBar] in statusBar?.anchorPointInScreen() }

        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_F), modifiers: UInt32(optionKey)) { [weak overlay] in
            overlay?.toggleVisibility()
        }

        self.store = store
        self.overlay = overlay
        self.statusBar = statusBar
        self.settingsWindow = settingsWindow
    }

    // MARK: Helpers

    private var isRunningTests: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["XCTestConfigurationFilePath"] != nil
            || env["XCTestBundlePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
}
