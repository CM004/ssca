//
//  SidebarView.swift
//  The Living Prompt Tree
//
//  Clean iOS-native sidebar: List with sections, SF Symbols, green checkmarks.
//  Matches the Screenplay Genie layout.
//

import SwiftUI

struct SidebarView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            // Introduction
            Button {
                appState.goToStage(0)
            } label: {
                Label("Introduction", systemImage: "info.circle")
            }
            .listRowBackground(appState.currentStage == 0 ? Color.accentColor.opacity(0.1) : Color.clear)

            // Stages
            Section("Stages") {
                stageRow(id: 1, icon: "wind", title: "Air (Clarity)")
                stageRow(id: 2, icon: "drop.fill", title: "Water (Structure)")
                stageRow(id: 3, icon: "sun.max.fill", title: "Sunlight (Efficiency)")
                stageRow(id: 4, icon: "leaf.fill", title: "Soil (Context)")
                stageRow(id: 5, icon: "shield.fill", title: "Nutrients (Safety)")
            }

            // Dashboard
            Section("Results") {
                Button {
                    if appState.isAllComplete { appState.goToStage(6) }
                } label: {
                    HStack {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                        Spacer()
                        if !appState.isAllComplete {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .disabled(!appState.isAllComplete)
                .listRowBackground(appState.currentStage == 6 ? Color.accentColor.opacity(0.1) : Color.clear)
            }

            // Current prompt
            Section("Current Prompt") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)

                    Text("\(appState.currentTokenCount) tokens")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(.orange)
                }
            }

            // Domain
            Section("Domain") {
                ForEach(["Education", "Health", "Legal", "Finance", "Support"], id: \.self) { (domain: String) in
                    Button {
                        appState.selectedDomain = domain
                    } label: {
                        HStack {
                            Text(domain)
                                .foregroundStyle(appState.selectedDomain == domain ? Color.accentColor : .primary)
                            Spacer()
                            if appState.selectedDomain == domain {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("SamvaadFlow")
        .listStyle(.sidebar)
    }

    // MARK: - Stage Row

    private func stageRow(id: Int, icon: String, title: String) -> some View {
        let isCompleted = appState.completedStages.contains(id)
        let isActive = appState.currentStage == id
        let isUnlocked = appState.isStageUnlocked(id)

        return Button {
            if isUnlocked { appState.goToStage(id) }
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(isUnlocked ? .primary : .tertiary)
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(!isUnlocked)
        .listRowBackground(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
