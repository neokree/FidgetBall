//
//  SettingsView.swift
//  FidgetBall
//
//  The configuration UI — skin, haptics, and the full set of physics sliders.
//  Every change flows through SettingsStore and applies to the live ball.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Skin", selection: $store.settings.skinRaw) {
                    ForEach(BallSkin.allCases) { skin in
                        Text(skin.displayName).tag(skin.rawValue)
                    }
                }
                Toggle("Haptic feedback", isOn: $store.settings.hapticsEnabled)
            }

            Section("Physics") {
                slider("Gravity", $store.settings.gravity, 200...5000, "%.0f")
                slider("Bounciness", $store.settings.bounce, 0...0.98, "%.2f")
                slider("Air resistance", $store.settings.airResistance, 0...0.08, "%.3f")
                slider("Throw power", $store.settings.throwPower, 0.5...2.5, "%.2f")
                slider("Spin", $store.settings.spin, 0...2.5, "%.2f")
            }

            Section("Ball & Rope") {
                slider("Ball size", $store.settings.ballSize, 14...60, "%.0f")
                slider("Rope length", $store.settings.ropeLength, 80...520, "%.0f")
                slider("Rope stiffness", $store.settings.stiffness, 4...30, "%.0f")
                slider("Wall friction", $store.settings.wallFriction, 0...0.4, "%.2f")
                slider("Bump power", $store.settings.bumpPower, 4...22, "%.0f")
            }

            Section {
                HStack {
                    Spacer()
                    Button("Reset to Defaults") { store.resetToDefaults() }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 560)
    }

    private func slider(_ title: String, _ value: Binding<Double>,
                        _ range: ClosedRange<Double>, _ format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
    }
}
