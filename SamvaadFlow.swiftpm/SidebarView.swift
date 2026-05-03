//
//  SidebarView.swift
//  SamvaadFlow
//
//  Sidebar with domain picker, stage list, games, and about.
//

import SwiftUI

struct SidebarView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: StoreManager
    @State private var showPaywall = false

    var body: some View {
        List {
            // Domain Picker
            Section {
                ForEach(Curriculum.allDomains, id: \.self) { domain in
                    domainRow(domain)
                }
            } header: {
                Text("Domain").foregroundStyle(.green.opacity(0.7))
            }

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

            // Game
            Section {
                Button {
                    appState.goToStage(8)
                } label: {
                    Label("Prompt Rain", systemImage: "cloud.rain.fill")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .listRowBackground(rowBG(active: appState.currentStage == 8))
                Button {
                    appState.goToStage(9)
                } label: {
                    Label("Practice", systemImage: "pencil.and.outline")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .listRowBackground(rowBG(active: appState.currentStage == 9))
            } header: {
                Text("Game").foregroundStyle(.green.opacity(0.7))
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
    }

    // MARK: - Domain Row

    private func domainRow(_ domain: String) -> some View {
        let isActive = appState.selectedDomain == domain
        let isFree = Curriculum.freeDomains.contains(domain)
        // TEMP: Bypass paywall for testing — uncomment next line to re-enable
        // let isLocked = !isFree && !store.isPro
        let isLocked = false
        let config = Curriculum.config(for: domain)

        return Button {
            if isLocked {
                showPaywall = true
            } else {
                withAnimation { appState.switchDomain(domain) }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: config.icon)
                    .foregroundStyle(isActive ? .green : .white.opacity(0.7))
                    .frame(width: 24)

                Text(domain)
                    .foregroundStyle(isActive ? .green : .white.opacity(0.9))

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.6))
                } else if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .listRowBackground(rowBG(active: isActive))
    }

    // MARK: - Active row background

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
