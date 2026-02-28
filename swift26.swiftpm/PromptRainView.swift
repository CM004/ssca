//
//  PromptRainView.swift
//  The Living Prompt Tree — Prompt Rain Mini-Game
//
//  SwiftUI wrapper: SpriteKit game view + score HUD + FM evaluation overlay.
//

import SwiftUI
import SpriteKit
import FoundationModels

struct PromptRainView: View {
    
    @EnvironmentObject var appState: AppState
    
    @StateObject private var scene: PromptRainScene = {
        let s = PromptRainScene(size: CGSize(width: 400, height: 700))
        s.scaleMode = .resizeFill
        return s
    }()
    
    @State private var hasStarted = false
    @State private var isCountingDown = false
    @State private var countdown = 5
    
    var body: some View {
        ZStack {
            // Game scene
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                if !hasStarted && !isCountingDown {
                    startOverlay
                } else if isCountingDown {
                    countdownOverlay
                } else if scene.isGameOver {
                    resultsOverlay
                }
            }
            .padding(24)
        }
        .navigationTitle("Prompt Rain")
    }
    
    // MARK: - Start Overlay
    
    private var startOverlay: some View {
        VStack(spacing: 16) {
            Text("🌧️ Prompt Rain")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
            
            Text("Catch good prompt fragments falling from the tree.\nDodge toxic ones — personal data, filler words, vague phrases.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 6) {
                ruleRow("🍎", "+10", "Good fragment caught")
                ruleRow("🥀", "−5", "Toxic fragment caught")
                ruleRow("⚡", "+50", "Role → Task → Audience sequence")
            }
            .padding(12)
            .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            
            Text("Drag the basket left and right to catch!")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            
            Button {
                scene.pickNewTargetPrompt()
                startCountdown()
            } label: {
                Text("Start Round")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Countdown Overlay
    
    private var countdownOverlay: some View {
        VStack(spacing: 20) {
            Text("Memorize Your Target")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            
            Text(scene.currentTargetPrompt)
                .font(.headline.monospaced())
                .padding(20)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.green.opacity(0.3), lineWidth: 2))
                .multilineTextAlignment(.center)
            
            Text("Game starts in...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("\(countdown)")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(.green)
                .contentTransition(.numericText())
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func startCountdown() {
        isCountingDown = true
        countdown = 5
        Task { @MainActor in
            for _ in 0..<4 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isCountingDown else { return }
                withAnimation { self.countdown -= 1 }
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard isCountingDown else { return }
            withAnimation {
                self.isCountingDown = false
                self.hasStarted = true
                self.scene.startGame()
            }
        }
    }
    
    // MARK: - Results Overlay
    
    private var performanceGrade: (title: String, color: Color) {
        let maxScore = max(1, scene.totalGoodSpawned * 10)
        let percentage = Double(scene.score) / Double(maxScore)
        switch percentage {
        case ..<0.30: return ("Bad", .red)
        case 0.30..<0.60: return ("Average", .orange)
        case 0.60..<0.85: return ("Good", .green)
        default: return ("Best", .cyan)
        }
    }

    private var resultsOverlay: some View {
        VStack(spacing: 16) {
            Text("⏱ Round Over!")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            
            let grade = performanceGrade
            HStack(spacing: 8) {
                Text("Score: \(scene.score)")
                    .font(.title.weight(.bold).monospaced())
                    .foregroundStyle(.white)
                Text("(\(grade.title))")
                    .font(.title2.weight(.bold).monospaced())
                    .foregroundStyle(grade.color)
            }
            
            // Caught fragments
            if !scene.caughtFragments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Caught Fragments").font(.caption.weight(.bold)).foregroundStyle(.green)
                    FlowLayout(spacing: 4) {
                        ForEach(Array(scene.caughtFragments.enumerated()), id: \.offset) { _, frag in
                            Text("\(frag.emoji) \(frag.text)")
                                .font(.caption2.monospaced())
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Color.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            }
            
            // Missed categories
            if !scene.missedCategories.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missed Categories").font(.caption.weight(.bold)).foregroundStyle(.orange)
                    Text(scene.missedCategories.map { $0.capitalized }.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.orange)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            }
            
            HStack(spacing: 12) {
                Button {
                    scene.pickNewTargetPrompt()
                    startCountdown()
                } label: {
                    Text("Play Again")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helpers
    
    private func ruleRow(_ emoji: String, _ points: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
            Text(points)
                .font(.caption.weight(.bold).monospaced())
                .foregroundStyle(points.hasPrefix("+") || points.hasPrefix("⚡") ? .green : .red)
                .frame(width: 35)
            Text(desc).font(.caption).foregroundStyle(.white.opacity(0.8))
        }
    }
    
    
    // MARK: - Flow Layout (for caught fragments display)
    
    struct FlowLayout: Layout {
        var spacing: CGFloat = 4
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = layout(proposal: proposal, subviews: subviews)
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = layout(proposal: proposal, subviews: subviews)
            for (index, origin) in result.origins.enumerated() {
                subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
            }
        }
        
        private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
            let maxWidth = proposal.width ?? .infinity
            var origins: [CGPoint] = []
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                origins.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            return (CGSize(width: maxWidth, height: y + rowHeight), origins)
        }
    }
}
