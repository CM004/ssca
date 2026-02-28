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
                    .foregroundStyle(.white.opacity(0.9))
            }
            .listRowBackground(rowBG(active: appState.currentStage == 0))

            // Stages
            Section {
                stageRow(id: 1, icon: "wind", title: "Air (Clarity)")
                stageRow(id: 2, icon: "drop.fill", title: "Water (Structure)")
                stageRow(id: 3, icon: "sun.max.fill", title: "Sunlight (Efficiency)")
                stageRow(id: 4, icon: "leaf.fill", title: "Soil (Context)")
                stageRow(id: 5, icon: "shield.fill", title: "Nutrients (Safety)")
            } header: {
                Text("Stages").foregroundStyle(.green.opacity(0.7))
            }

            // Dashboard
            Section {
                Button {
                    if appState.isAllComplete { appState.goToStage(6) }
                } label: {
                    HStack {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        if !appState.isAllComplete {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.green.opacity(0.3))
                        }
                    }
                }
                .disabled(!appState.isAllComplete)
                .listRowBackground(rowBG(active: appState.currentStage == 6))
            } header: {
                Text("Results").foregroundStyle(.green.opacity(0.7))
            }

            // Domain
            Section {
                Picker("Select Domain :", selection: $appState.selectedDomain) {
                    ForEach(["Education", "Health", "Legal", "Finance", "Support"], id: \.self) { (domain: String) in
                        Text(domain).tag(domain)
                    }
                }
                .pickerStyle(.menu)
                .tint(.green)
            } header: {
                Text("Domain").foregroundStyle(.green.opacity(0.7))
            }

            // About
            Section {
                Button {
                    appState.goToStage(7)
                } label: {
                    Label("About This App", systemImage: "info.circle.fill")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .listRowBackground(rowBG(active: appState.currentStage == 7))
            } header: {
                Text("Info").foregroundStyle(.green.opacity(0.7))
            }
        }
        .navigationTitle("SamvaadFlow")
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.04),
                    Color(red: 0.04, green: 0.10, blue: 0.05),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Active row background (light blue capsule)

    @ViewBuilder
    private func rowBG(active: Bool) -> some View {
        if active {
            Capsule().fill(Color.green.opacity(0.15))
                .overlay(Capsule().stroke(Color.green.opacity(0.25), lineWidth: 0.5))
        } else {
            Color.clear
        }
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
        .listRowBackground(rowBG(active: isActive))
    }
}
