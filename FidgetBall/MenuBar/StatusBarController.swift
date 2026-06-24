//
//  StatusBarController.swift
//  FidgetBall
//
//  The menu-bar presence — "the ball icon on the status bar." Left-click drops a
//  fresh ball; right-click opens the menu (skins, cut the rope, show/hide, quit).
//  Also reports its on-screen position so the rope can hang from the icon.
//

import AppKit

final class StatusBarController: NSObject {

    private let statusItem: NSStatusItem
    private var currentSkin: BallSkin

    var onDropNewBall: (() -> Void)?
    var onCut: (() -> Void)?
    var onToggle: (() -> Void)?
    var onSelectSkin: ((BallSkin) -> Void)?
    var onOpenSettings: (() -> Void)?

    init(skin: BallSkin) {
        currentSkin = skin
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = icon(for: skin)
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "FidgetBall — click to drop a new ball, right-click for options"
        }
    }

    // MARK: Public

    func updateIcon(_ skin: BallSkin) {
        currentSkin = skin
        statusItem.button?.image = icon(for: skin)
    }

    /// Bottom-center of the status item in screen coordinates — where the rope hangs from.
    func anchorPointInScreen() -> CGPoint? {
        guard let frame = statusItem.button?.window?.frame else { return nil }
        return CGPoint(x: frame.midX, y: frame.minY)
    }

    // MARK: Icon

    private func icon(for skin: BallSkin) -> NSImage {
        let image = skin.image(diameter: 18)
        image.isTemplate = false
        return image
    }

    // MARK: Clicks

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu(from: sender)
        } else {
            onDropNewBall?()
        }
    }

    private func showMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()

        let drop = NSMenuItem(title: "Drop a New Ball", action: #selector(menuDrop), keyEquivalent: "")
        let cut = NSMenuItem(title: "Cut the Rope", action: #selector(menuCut), keyEquivalent: "")
        for item in [drop, cut] { item.target = self; menu.addItem(item) }

        menu.addItem(.separator())

        let skinItem = NSMenuItem(title: "Skin", action: nil, keyEquivalent: "")
        let skinMenu = NSMenu()
        for skin in BallSkin.allCases {
            let item = NSMenuItem(title: skin.displayName, action: #selector(menuSelectSkin(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = skin.rawValue
            item.state = (skin == currentSkin) ? .on : .off
            item.image = skin.image(diameter: 14)
            skinMenu.addItem(item)
        }
        skinItem.submenu = skinMenu
        menu.addItem(skinItem)

        menu.addItem(.separator())

        let toggle = NSMenuItem(title: "Show / Hide", action: #selector(menuToggle), keyEquivalent: "f")
        toggle.keyEquivalentModifierMask = .option
        toggle.target = self
        menu.addItem(toggle)

        let settings = NSMenuItem(title: "Settings…", action: #selector(menuSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit FidgetBall", action: #selector(menuQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    @objc private func menuDrop() { onDropNewBall?() }
    @objc private func menuCut() { onCut?() }
    @objc private func menuToggle() { onToggle?() }
    @objc private func menuSettings() { onOpenSettings?() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    @objc private func menuSelectSkin(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let skin = BallSkin(rawValue: raw) else { return }
        onSelectSkin?(skin)
    }
}
