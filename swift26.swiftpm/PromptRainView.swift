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

    @StateObject private var scene: PromptRainScene = {
        let s = PromptRainScene(size: CGSize(width: 400, height: 700))
        s.scaleMode = .aspectFill
        return s
    }()

    @State private var hasStarted = false
    @State private var isEvaluating = false

    var body: some View {
        ZStack {
            // Game scene
            SpriteView(scene: scene)
                .ignoresSafeArea()

            // Overlay UI
            VStack {
                Spacer()

                if !hasStarted {
                    startOverlay
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

            Text("Catch good prompt fragments falling from the tree.\nDodge toxic ones — PII, filler words, vague phrases.")
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
                hasStarted = true
                scene.startGame()
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

    // MARK: - Results Overlay

    private var resultsOverlay: some View {
        VStack(spacing: 14) {
            Text("⏱ Round Over!")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("Score: \(scene.score)")
                .font(.title.weight(.bold).monospaced())
                .foregroundStyle(.green)

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
            }

            // Missed categories
            if !scene.missedCategories.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missed Categories").font(.caption.weight(.bold)).foregroundStyle(.orange)
                    Text(scene.missedCategories.map { $0.capitalized }.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.orange)
                }
            }

            // FM Evaluation
            if let eval = scene.fmEvaluation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🧠 AI Evaluation").font(.caption.weight(.bold)).foregroundStyle(.cyan)
                    Text(eval)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(10)
                .background(.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            } else if isEvaluating {
                HStack(spacing: 8) {
                    ProgressView().tint(.white)
                    Text("AI evaluating your catch…").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
            }

            HStack(spacing: 12) {
                Button {
                    Task { await evaluateWithFM() }
                } label: {
                    Label("AI Evaluate", systemImage: "brain")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
                .disabled(isEvaluating || scene.fmEvaluation != nil)

                Button {
                    scene.fmEvaluation = nil
                    scene.startGame()
                } label: {
                    Text("Play Again")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - FM Evaluation

    private func evaluateWithFM() async {
        isEvaluating = true
        let caught = scene.caughtFragments.filter { $0.category.isGood }
        let caughtText = caught.map { "[\($0.category.rawValue)] \($0.text)" }.joined(separator: ", ")
        let missed = scene.missedCategories

        var evalText = ""

        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let prompt = """
                The player caught these prompt fragments: \(caughtText.isEmpty ? "none" : caughtText).
                They missed these prompt categories: \(missed.isEmpty ? "none" : missed.joined(separator: ", ")).

                Assemble the caught fragments into a prompt. Rate the assembled prompt from 1-5 stars.
                Format: Start with the assembled prompt in quotes, then the rating as "Rating: X/5",
                then one sentence about what was missed or what made it good.
                Keep response under 60 words.
                """
                let response = try await session.respond(to: prompt)
                evalText = String(response.content).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } catch {
                evalText = buildFallbackEval(caught: caught, missed: missed)
            }
        } else {
            evalText = buildFallbackEval(caught: caught, missed: missed)
        }

        await MainActor.run {
            scene.fmEvaluation = evalText
            isEvaluating = false
        }
    }

    private func buildFallbackEval(caught: [PromptFragment], missed: [String]) -> String {
        let count = caught.count
        let total = 6 // role, task, audience, context, constraint, output
        let stars = max(1, min(5, count * 5 / max(1, total)))
        let assembled = caught.map { $0.text }.joined(separator: " ")

        var result = "\"\(assembled.isEmpty ? "(empty)" : assembled)\"\n"
        result += "Rating: \(stars)/5\n"
        if missed.isEmpty {
            result += "Excellent — you caught all prompt building blocks!"
        } else {
            result += "You missed the \(missed.first ?? "unknown") block."
        }
        return result
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
