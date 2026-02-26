//
//  ContentView.swift
//  The Living Prompt Tree
//
//  3-column iPad layout matching Screenplay Genie:
//  Sidebar (List) | Center (Lesson) | Right (Live Preview / SpriteKit)
//

import SwiftUI
import SpriteKit

struct ContentView: View {

    @StateObject private var appState = AppState()
    @StateObject private var treeScene = TreeScene(size: CGSize(width: 320, height: 600))

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            centerPanel
        } detail: {
            VStack(spacing: 0) {
                Text("Live Preview")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Divider()

                SpriteView(scene: treeScene)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .environmentObject(appState)
        .onChange(of: appState.completedStages) { _, newValue in
            if let latest = newValue.max() {
                treeScene.animateStageCompletion(latest)
            }
        }
    }

    @ViewBuilder
    private var centerPanel: some View {
        switch appState.currentStage {
        case 0:
            IntroStageView()
        case 1:
            Stage1_AirView()
        case 2:
            Stage2_WaterView()
        case 3:
            Stage3_SunlightView()
        case 4:
            Stage4_SoilView()
        case 5:
            Stage5_NutrientsView()
        case 6:
            DashboardView()
        default:
            Text("Unknown stage")
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
