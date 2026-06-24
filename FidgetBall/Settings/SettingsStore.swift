//
//  SettingsStore.swift
//  FidgetBall
//
//  Observable store backing the settings window. Persists to UserDefaults and
//  notifies the app so changes apply to the live ball immediately.
//

import Combine
import SwiftUI

final class SettingsStore: ObservableObject {

    @Published var settings: BallSettings {
        didSet {
            save()
            onChange?(settings)
        }
    }

    /// Called whenever any setting changes (after persistence).
    var onChange: ((BallSettings) -> Void)?

    private let defaultsKey = "ballSettings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(BallSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    func resetToDefaults() {
        settings = .default
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
