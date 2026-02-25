//
//  Level4_SoilView.swift
//  The Living Prompt Tree
//
//  Level 4 — SOIL (Context): Julie's prompt lacks essential background.
//  The user adds context fields (role, numbers, timeframe, examples) to
//  transform a bare prompt into a well-grounded one.
//

import SwiftUI

struct Level4_SoilView: View {

    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void

    private let level = LevelDataStore.level(for: 4)!

    private let julieLines: [String] = [
        "The AI gave me a super generic response. It didn't know anything about my actual situation!",
        "Context is like soil for a tree — it grounds the AI in your specific reality.",
        "Add key details below: your role, specific numbers, timeframe, and a reference example. 🌱"
    ]
    @State private var julieIndex: Int = 0
    @State private var showEditor: Bool = false

    // Context fields
    @State private var userPrompt: String = ""
    @State private var roleField: String = ""
    @State private var numbersField: String = ""
    @State private var timeframeField: String = ""
    @State private var exampleField: String = ""

    // Evaluation
    @State private var isEvaluating: Bool = false
    @State private var result: EvaluationResult? = nil
    @State private var showSuccess: Bool = false

    // Live detection
    private var hasRole: Bool { !roleField.trimmingCharacters(in: .whitespaces).isEmpty }
    private var hasNumbers: Bool { !numbersField.trimmingCharacters(in: .whitespaces).isEmpty }
    private var hasTimeframe: Bool { !timeframeField.trimmingCharacters(in: .whitespaces).isEmpty }
    private var hasExample: Bool { !exampleField.trimmingCharacters(in: .whitespaces).isEmpty }

    private var assembledPrompt: String {
        var parts: [String] = []
        let base = level.examples.first?.badPrompt ?? ""
        if !roleField.isEmpty { parts.append("You are \(roleField).") }
        parts.append(base)
        if !numbersField.isEmpty { parts.append("Specific details: \(numbersField).") }
        if !timeframeField.isEmpty { parts.append("Timeframe: \(timeframeField).") }
        if !exampleField.isEmpty { parts.append("Example: \(exampleField).") }
        return parts.joined(separator: " ")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                ElementHeaderView(emoji: "🌱", elementName: "Soil", principle: "Context", step: 4)

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

                // Original (context-free) prompt
                VStack(alignment: .leading, spacing: 8) {
                    Label("Julie's Bare Prompt", systemImage: "xmark.circle.fill")
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
                        TagChipView(label: "Numbers", isComplete: hasNumbers)
                        TagChipView(label: "Timeframe", isComplete: hasTimeframe)
                        TagChipView(label: "Example", isComplete: hasExample)
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Context fields
                    VStack(spacing: 12) {
                        ContextField(
                            label: "Role / Expertise",
                            placeholder: "e.g., senior cardiologist, 10th-grade student",
                            icon: "person.fill",
                            text: $roleField
                        )
                        ContextField(
                            label: "Specific Numbers",
                            placeholder: "e.g., age 45, budget $2000, 3 options",
                            icon: "number",
                            text: $numbersField
                        )
                        ContextField(
                            label: "Timeframe / Scope",
                            placeholder: "e.g., next 6 months, Q3 2026, short-term",
                            icon: "calendar",
                            text: $timeframeField
                        )
                        ContextField(
                            label: "Example / Reference",
                            placeholder: "e.g., similar to Mediterranean diet, like Python Flask",
                            icon: "doc.text.fill",
                            text: $exampleField
                        )
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Preview
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Assembled Prompt Preview", systemImage: "doc.richtext")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.cream.opacity(0.6))

                        Text(assembledPrompt)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(Theme.charcoal)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.parchment)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Theme.warmBrown.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Token counter
                    TokenCounterView(
                        originalCount: (level.examples.first?.badPrompt ?? "").split(separator: " ").count,
                        currentCount: assembledPrompt.split(separator: " ").count
                    )

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
                            Text(isEvaluating ? "Evaluating…" : "Check Context")
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
                    .disabled((!hasRole && !hasNumbers) || isEvaluating)
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)
                }

                if let result = result {
                    ResultPanel(result: result)
                        .transition(Theme.levelTransition)
                }

                if showSuccess {
                    SuccessPanel(elementName: "Soil", feedback: level.visualFeedback) {
                        appState.promptHistory.append(assembledPrompt)
                        onComplete()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }

    private func evaluate() async {
        isEvaluating = true
        result = nil

        let evalResult = await runEvaluation(
            userPrompt: assembledPrompt,
            originalPrompt: level.examples.first?.badPrompt,
            level: level
        )

        await MainActor.run {
            withAnimation(Theme.springAnim) {
                result = evalResult
                isEvaluating = false
                if evalResult.passed {
                    appState.completeLevel(4, tokensSaved: 0, clarityScore: evalResult.score)
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - Context Field

/// A labeled text input for adding specific context.
private struct ContextField: View {
    let label: String
    let placeholder: String
    let icon: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.charcoal.opacity(0.6))

            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundColor(Theme.charcoal)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.cream)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    text.isEmpty ? Theme.warmBrown.opacity(0.2) : Theme.safeGreen.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
        }
    }
}
