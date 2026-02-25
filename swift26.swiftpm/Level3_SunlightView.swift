//
//  Level3_SunlightView.swift
//  The Living Prompt Tree
//
//  Level 3 — SUNLIGHT (Efficiency): Julie's prompt is bloated with filler words.
//  The user strikes out unnecessary words using PromptChipView, then evaluates
//  the compressed version. Target: ≥25% reduction while preserving meaning.
//

import SwiftUI

struct Level3_SunlightView: View {

    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void

    private let level = LevelDataStore.level(for: 3)!

    private let julieLines: [String] = [
        "I learned the hard way that long prompts waste tokens and confuse the AI…",
        "Every word costs energy. Let's trim away the filler!",
        "Tap any word to strike it out. Keep the meaning, lose the fluff! ☀️"
    ]
    @State private var julieIndex: Int = 0
    @State private var showEditor: Bool = false

    // Word strike state
    @State private var words: [String] = []
    @State private var struckIndices: Set<Int> = []

    // Evaluation
    @State private var isEvaluating: Bool = false
    @State private var result: EvaluationResult? = nil
    @State private var showSuccess: Bool = false

    private var originalWordCount: Int { words.count }
    private var currentWordCount: Int { words.count - struckIndices.count }
    private var reductionPercent: Double {
        guard originalWordCount > 0 else { return 0 }
        return Double(struckIndices.count) / Double(originalWordCount) * 100
    }
    private var compressedPrompt: String {
        words.enumerated()
            .filter { !struckIndices.contains($0.offset) }
            .map { $0.element }
            .joined(separator: " ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                ElementHeaderView(emoji: "☀️", elementName: "Sunlight", principle: "Efficiency", step: 3)

                // Mini tree
                TreeView(appState: appState)
                    .frame(height: 160)
                    .scaleEffect(0.45)
                    .frame(height: 72)
                    .clipped()
                    .opacity(0.5)

                // Dialogue
                DialogueBoxView(
                    characterName: "🌱 Julie",
                    message: julieLines[julieIndex]
                ) {
                    if julieIndex < julieLines.count - 1 {
                        withAnimation(Theme.springAnim) { julieIndex += 1 }
                    } else {
                        withAnimation(Theme.springAnim) { showEditor = true }
                    }
                }

                if showEditor {
                    // Token counter
                    TokenCounterView(originalCount: originalWordCount, currentCount: currentWordCount)

                    // Reduction target
                    HStack(spacing: 6) {
                        Image(systemName: reductionPercent >= 25 ? "checkmark.circle.fill" : "target")
                            .font(.system(size: 13))
                            .foregroundColor(reductionPercent >= 25 ? Theme.safeGreen : Theme.amber)
                        Text("Target: ≥25% reduction")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.cream.opacity(0.7))

                        Spacer()

                        Text("\(String(format: "%.0f", reductionPercent))% removed")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(reductionPercent >= 25 ? Theme.safeGreen : Theme.amber)
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Word chips
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tap words to strike them out", systemImage: "hand.tap.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.amber)

                        WordChipGrid(words: words, struckIndices: struckIndices) { index in
                            withAnimation(Theme.springAnim) {
                                if struckIndices.contains(index) {
                                    struckIndices.remove(index)
                                } else {
                                    struckIndices.insert(index)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.cream)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.warmBrown.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Preview
                    if !struckIndices.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Compressed Preview", systemImage: "doc.text.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.cream.opacity(0.6))

                            Text(compressedPrompt)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Theme.charcoal)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Theme.parchment)
                                )
                        }
                        .padding(.horizontal, 16)
                        .transition(Theme.levelTransition)
                    }

                    // Evaluate
                    Button {
                        Task { await evaluate() }
                    } label: {
                        HStack(spacing: 8) {
                            if isEvaluating {
                                ProgressView().tint(Theme.charcoal)
                            } else {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text(isEvaluating ? "Evaluating…" : "Check Efficiency")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(Theme.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Theme.amber)
                                .shadow(color: Theme.amber.opacity(0.3), radius: 6, y: 3)
                        )
                    }
                    .disabled(struckIndices.isEmpty || isEvaluating)
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)
                }

                if let result = result {
                    ResultPanel(result: result)
                        .transition(Theme.levelTransition)
                }

                if showSuccess {
                    SuccessPanel(elementName: "Sunlight", feedback: level.visualFeedback) {
                        appState.promptHistory.append(compressedPrompt)
                        onComplete()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear { loadWords() }
    }

    private func loadWords() {
        // Use the good (verbose) prompt as the one to compress
        let source = level.examples.first?.goodPrompt ?? level.examples.first?.badPrompt ?? ""
        words = source.components(separatedBy: " ").filter { !$0.isEmpty }
        struckIndices = []
    }

    private func evaluate() async {
        guard !compressedPrompt.isEmpty else { return }
        isEvaluating = true
        result = nil

        let originalPrompt = level.examples.first?.goodPrompt ?? level.examples.first?.badPrompt
        let evalResult = await runEvaluation(
            userPrompt: compressedPrompt,
            originalPrompt: originalPrompt,
            level: level
        )

        await MainActor.run {
            withAnimation(Theme.springAnim) {
                result = evalResult
                isEvaluating = false
                if evalResult.passed {
                    let tokensSaved = struckIndices.count
                    appState.completeLevel(3, tokensSaved: tokensSaved, clarityScore: evalResult.score)
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - Word Chip Grid

/// Grid of tappable word chips using a flow layout.
private struct WordChipGrid: View {
    let words: [String]
    let struckIndices: Set<Int>
    let onTap: (Int) -> Void

    var body: some View {
        // Use a simple VStack + HStack wrapping approach for chip layout
        let rows = buildRows(maxWidth: 300)

        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { index in
                        PromptChipView(
                            word: words[index],
                            isStruck: struckIndices.contains(index)
                        ) {
                            onTap(index)
                        }
                    }
                }
            }
        }
    }

    private func buildRows(maxWidth: CGFloat) -> [[Int]] {
        var rows: [[Int]] = [[]]
        var currentWidth: CGFloat = 0
        let charWidth: CGFloat = 9 // approx char width in monospaced 14pt
        let chipPadding: CGFloat = 26 // horizontal padding per chip

        for i in words.indices {
            let wordWidth = CGFloat(words[i].count) * charWidth + chipPadding
            if currentWidth + wordWidth > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([i])
                currentWidth = wordWidth
            } else {
                rows[rows.count - 1].append(i)
                currentWidth += wordWidth + 6
            }
        }
        return rows
    }
}
