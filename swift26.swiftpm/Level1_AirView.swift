//
//  Level1_AirView.swift
//  The Living Prompt Tree
//
//  Level 1 — AIR (Clarity): Julie shows a vague prompt and challenges the
//  user to add clear intent, audience, and scope. Uses TagChipView to track
//  criteria in real time, DialogueBoxView for Julie's coaching.
//

import SwiftUI

struct Level1_AirView: View {

    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void

    private let level = LevelDataStore.level(for: 1)!

    // Julie's dialogue
    private let julieLines: [String] = [
        "This is the prompt I used. It's so vague the AI gave me three pages of nothing useful!",
        "A clear prompt needs three things: intent (what you want), audience (who it's for), and scope (how much).",
        "Try rewriting my prompt below. I'll check if it has all three! 💨"
    ]
    @State private var julieIndex: Int = 0
    @State private var showEditor: Bool = false

    // Editor
    @State private var userPrompt: String = ""
    @State private var isEvaluating: Bool = false
    @State private var result: EvaluationResult? = nil
    @State private var showSuccess: Bool = false

    // Live tag detection
    private var hasIntent: Bool {
        let lower = userPrompt.lowercased()
        return ["explain", "summarize", "list", "compare", "describe", "analyze", "create", "write", "generate", "tell me about"].contains { lower.contains($0) }
    }
    private var hasAudience: Bool {
        let lower = userPrompt.lowercased()
        return ["beginner", "student", "doctor", "child", "expert", "professional", "teacher", "for a", "for an", "audience"].contains { lower.contains($0) }
    }
    private var hasScope: Bool {
        let lower = userPrompt.lowercased()
        return ["3 ", "5 ", "under ", "brief", "short", "bullet", "paragraph", "point", "sentence", "max", "limit", "specific"].contains { lower.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                ElementHeaderView(emoji: "💨", elementName: "Air", principle: "Clarity", step: 1)

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
                        withAnimation(Theme.springAnim) {
                            julieIndex += 1
                        }
                    } else {
                        withAnimation(Theme.springAnim) {
                            showEditor = true
                        }
                    }
                }

                // Bad prompt card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Julie's Original Prompt", systemImage: "xmark.circle.fill")
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
                    // Tag chips (live criteria tracking)
                    HStack(spacing: 8) {
                        TagChipView(label: "Clear Intent", isComplete: hasIntent)
                        TagChipView(label: "Audience", isComplete: hasAudience)
                        TagChipView(label: "Scope", isComplete: hasScope)
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Text editor
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Improved Prompt", systemImage: "pencil.line")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.amber)

                        TextEditor(text: $userPrompt)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(Theme.charcoal)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 110)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.cream)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.warmBrown.opacity(0.3), lineWidth: 1.5)
                                    )
                            )

                        TokenCounterView(
                            originalCount: level.examples.first?.badPrompt.split(separator: " ").count ?? 0,
                            currentCount: userPrompt.split(separator: " ").count
                        )
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Evaluate button
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
                            Text(isEvaluating ? "Evaluating…" : "Check My Prompt")
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
                    .disabled(userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isEvaluating)
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)
                }

                // Result
                if let result = result {
                    ResultPanel(result: result)
                        .transition(Theme.levelTransition)
                }

                // Success
                if showSuccess {
                    SuccessPanel(elementName: "Air", feedback: level.visualFeedback) {
                        appState.promptHistory.append(userPrompt)
                        onComplete()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .onAppear {
            userPrompt = level.examples.first?.badPrompt ?? ""
        }
    }

    // MARK: - Evaluation

    private func evaluate() async {
        let trimmed = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isEvaluating = true
        result = nil

        let evalResult = await runEvaluation(
            userPrompt: trimmed,
            originalPrompt: level.examples.first?.badPrompt,
            level: level
        )

        await MainActor.run {
            withAnimation(Theme.springAnim) {
                result = evalResult
                isEvaluating = false
                if evalResult.passed {
                    appState.completeLevel(1, tokensSaved: 0, clarityScore: evalResult.score)
                    showSuccess = true
                }
            }
        }
    }
}
