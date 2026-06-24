//
//  HotKey.swift
//  FidgetBall
//
//  A thin wrapper over the Carbon RegisterEventHotKey API. Carbon hot keys work
//  without the Accessibility / Input Monitoring permission a global NSEvent
//  monitor would require — ideal for a sandboxed menu-bar toy.
//

import AppKit
import Carbon.HIToolbox

nonisolated final class HotKey {

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let identifier: UInt32
    private let action: () -> Void

    private static var nextID: UInt32 = 1
    private static var registry: [UInt32: HotKey] = [:]
    private static let signature: OSType = 0x4644_4754 // 'FDGT'

    /// - Parameters:
    ///   - keyCode: a virtual key code, e.g. `kVK_ANSI_F`.
    ///   - modifiers: Carbon modifier flags, e.g. `optionKey`.
    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action
        self.identifier = HotKey.nextID
        HotKey.nextID += 1
        HotKey.registry[identifier] = self

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            guard let event else { return OSStatus(eventNotHandledErr) }
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if let target = HotKey.registry[hkID.id] {
                target.action()
            }
            return noErr
        }

        let installStatus = InstallEventHandler(GetApplicationEventTarget(), handler,
                                                1, &eventType, nil, &eventHandlerRef)
        guard installStatus == noErr else { HotKey.registry[identifier] = nil; return nil }

        let hotKeyID = EventHotKeyID(signature: HotKey.signature, id: identifier)
        let registerStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                                 GetApplicationEventTarget(), 0, &hotKeyRef)
        guard registerStatus == noErr else {
            if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
            HotKey.registry[identifier] = nil
            return nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
        HotKey.registry[identifier] = nil
    }
}
