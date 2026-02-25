//
//  Level2_WaterView.swift
//  The Living Prompt Tree
//
//  Level 2 — WATER (Structure): Julie shows an unstructured prompt and the user
//  arranges blocks into the correct order: Role → Task → Constraints → Output.
//

import SwiftUI

struct Level2_WaterView: View {

    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void

    private let level = LevelDataStore.level(for: 2)!

    private let julieLines: [String] = [
        "The AI ignored half my instructions! It just rambled on…",
        "Structured prompts have four parts: Role, Task, Constraints, and Output Format.",
        "Drag the blocks into the right order below. It's like building a spell! 💧"
    ]
    @State private var julieIndex: Int = 0
    @State private var showEditor: Bool = false

    // Block arrangement
    @State private var arrangedBlocks: [String] = []
    @State private var availableBlocks: [String] = []

    // Evaluation
    @State private var isEvaluating: Bool = false
    @State private var result: EvaluationResult? = nil
    @State private var showSuccess: Bool = false

    // Tag tracking
    private var hasRole: Bool {
        arrangedBlocks.first { $0.lowercased().contains("you are") || $0.lowercased().contains("act as") } != nil
    }
    private var hasTask: Bool {
        arrangedBlocks.count >= 2
    }
    private var hasConstraints: Bool {
        arrangedBlocks.first { $0.lowercased().contains("limit") || $0.lowercased().contains("only") || $0.lowercased().contains("must") || $0.lowercased().contains("under") } != nil
    }
    private var hasOutput: Bool {
        arrangedBlocks.first { $0.lowercased().contains("table") || $0.lowercased().contains("bullet") || $0.lowercased().contains("json") || $0.lowercased().contains("format") || $0.lowercased().contains("list") } != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                ElementHeaderView(emoji: "💧", elementName: "Water", principle: "Structure", step: 2)

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

                // Bad prompt
                VStack(alignment: .leading, spacing: 8) {
                    Label("Julie's Unstructured Prompt", systemImage: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.dangerRed)

                    Text(level.examples.first?.badPrompt ?? "")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Theme.charcoal)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.dangerRed.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.dangerRed.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 16)

                if showEditor {
                    // Tag chips
                    HStack(spacing: 6) {
                        TagChipView(label: "Role", isComplete: hasRole)
                        TagChipView(label: "Task", isComplete: hasTask)
                        TagChipView(label: "Constraints", isComplete: hasConstraints)
                        TagChipView(label: "Output", isComplete: hasOutput)
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Arranged blocks (drop zone)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Structured Prompt", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.amber)

                        VStack(spacing: 6) {
                            if arrangedBlocks.isEmpty {
                                Text("Tap blocks below to build your prompt…")
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundColor(Theme.charcoal.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(Array(arrangedBlocks.enumerated()), id: \.offset) { idx, block in
                                    HStack(spacing: 8) {
                                        Text("\(idx + 1)")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.amber)
                                            .frame(width: 20)

                                        Text(block)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Theme.charcoal)
                                            .lineLimit(2)

                                        Spacer()

                                        Button {
                                            withAnimation(Theme.springAnim) {
                                                let removed = arrangedBlocks.remove(at: idx)
                                                availableBlocks.append(removed)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.charcoal.opacity(0.3))
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Theme.parchment)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Theme.warmBrown.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.cream)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Theme.warmBrown.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Available blocks
                    if !availableBlocks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Available Blocks", systemImage: "square.stack.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.cream.opacity(0.6))

                            WrappingHStack(items: availableBlocks) { block in
                                Button {
                                    withAnimation(Theme.springAnim) {
                                        arrangedBlocks.append(block)
                                        availableBlocks.removeAll { $0 == block }
                                    }
                                } label: {
                                    Text(block)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.charcoal)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Theme.parchment)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Theme.warmBrown.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
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
                            Text(isEvaluating ? "Evaluating…" : "Check Structure")
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
                    .disabled(arrangedBlocks.isEmpty || isEvaluating)
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)
                }

                if let result = result {
                    ResultPanel(result: result)
                        .transition(Theme.levelTransition)
                }

                if showSuccess {
                    SuccessPanel(elementName: "Water", feedback: level.visualFeedback) {
                        let prompt = arrangedBlocks.joined(separator: "\n")
                        appState.promptHistory.append(prompt)
                        onComplete()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear { loadBlocks() }
    }

    private func loadBlocks() {
        if let blocks = level.examples.first?.structureBlocks {
            availableBlocks = blocks.shuffled()
        } else {
            // Fallback: split bad prompt into sentences
            availableBlocks = (level.examples.first?.badPrompt ?? "")
                .components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .shuffled()
        }
        arrangedBlocks = []
    }

    private func evaluate() async {
        let promptText = arrangedBlocks.joined(separator: "\n")
        guard !promptText.isEmpty else { return }
        isEvaluating = true
        result = nil

        let evalResult = await runEvaluation(
            userPrompt: promptText,
            originalPrompt: level.examples.first?.badPrompt,
            level: level
        )

        await MainActor.run {
            withAnimation(Theme.springAnim) {
                result = evalResult
                isEvaluating = false
                if evalResult.passed {
                    appState.completeLevel(2, tokensSaved: 0, clarityScore: evalResult.score)
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - WrappingHStack

/// Simple wrapping horizontal stack for string-based chips.
struct WrappingHStack: View {
    let items: [String]
    let content: (String) -> AnyView

    init(items: [String], @ViewBuilder content: @escaping (String) -> some View) {
        self.items = items
        self.content = { item in AnyView(content(item)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                content(item)
            }
        }
    }
}

