//
//  PromptJourneySummaryView.swift
//  The Living Prompt Tree
//
//  End-of-journey summary showing the fully restored tree, all 5 prompt
//  snapshots from the user's journey, and environmental impact stats.
//

import SwiftUI

struct PromptJourneySummaryView: View {

    @EnvironmentObject var appState: AppState

    private let elements: [(emoji: String, name: String, principle: String)] = [
        ("💨", "Air",       "Clarity"),
        ("💧", "Water",     "Structure"),
        ("☀️", "Sunlight",  "Efficiency"),
        ("🌱", "Soil",      "Context"),
        ("🛡️", "Nutrients", "Safety")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Restored tree (full size)
                VStack(spacing: 8) {
                    Text("🌳")
                        .font(.system(size: 48))
                    Text("The Tree Lives!")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(Theme.cream)
                    Text("You restored all 5 elements")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.cream.opacity(0.6))
                }

                TreeView(appState: appState)
                    .frame(height: 280)

                // Prompt journey
                VStack(alignment: .leading, spacing: 16) {
                    Label("Your Prompt Journey", systemImage: "book.fill")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(Theme.charcoal)

                    ForEach(Array(zip(elements, appState.promptHistory.prefix(5))), id: \.0.name) { element, prompt in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(element.emoji)
                                    .font(.system(size: 16))
                                Text("\(element.name) — \(element.principle)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.charcoal)
                            }

                            Text(prompt)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Theme.charcoal.opacity(0.7))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.cream)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Theme.warmBrown.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.parchment)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.warmBrown.opacity(0.3), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 16)

                // Environmental impact stats
                VStack(spacing: 14) {
                    Label("Environmental Impact", systemImage: "leaf.fill")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(Theme.cream)

                    HStack(spacing: 20) {
                        ImpactStat(
                            icon: "bolt.fill",
                            value: "\(appState.totalTokensSaved)",
                            label: "Tokens Saved"
                        )
                        ImpactStat(
                            icon: "battery.100.bolt",
                            value: String(format: "%.4f", appState.totalEnergySaved),
                            label: "kWh Saved"
                        )
                        ImpactStat(
                            icon: "carbon.dioxide.cloud.fill",
                            value: String(format: "%.6f", appState.estimatedCarbonSaved),
                            label: "kg CO₂"
                        )
                    }

                    Text("Every token saved reduces AI energy consumption. You're making a difference!")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(Theme.cream.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.forestGreen.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.amber.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)

                // Julie's final message
                DialogueBoxView(
                    characterName: "🌱 Julie",
                    message: "Thank you for teaching me! Now I know how to write prompts that are clear, structured, efficient, contextual, and safe. The tree is alive again because of you! 🌳✨"
                ) { }

                // Reset button
                Button {
                    appState.resetProgress()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                        Text("Start New Journey")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.cream.opacity(0.5))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .stroke(Theme.cream.opacity(0.2), lineWidth: 1)
                    )
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Impact Stat

private struct ImpactStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.amber)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.cream)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.cream.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
