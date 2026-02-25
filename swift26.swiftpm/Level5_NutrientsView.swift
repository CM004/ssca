//
//  Level5_NutrientsView.swift
//  The Living Prompt Tree
//
//  Level 5 — NUTRIENTS (Safety/Privacy): Julie's prompt contains PII —
//  phone numbers, emails, API keys, names. The user must identify and
//  redact them using placeholder tokens before sending to AI.
//

import SwiftUI

struct Level5_NutrientsView: View {

    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void

    private let level = LevelDataStore.level(for: 5)!

    private let julieLines: [String] = [
        "I almost sent my phone number and API key to an AI chatbot! 😱",
        "Personal data (PII) should NEVER go into a prompt. Replace it with placeholders!",
        "Find and redact all sensitive data below. Replace real values with [REDACTED] tags. 🛡️"
    ]
    @State private var julieIndex: Int = 0
    @State private var showEditor: Bool = false

    // Editor
    @State private var userPrompt: String = ""
    @State private var isEvaluating: Bool = false
    @State private var result: EvaluationResult? = nil
    @State private var showSuccess: Bool = false

    // Live PII detection
    @State private var detectedPII: [PIIItem] = []

    private struct PIIItem: Identifiable, Hashable {
        let id = UUID()
        let type: String
        let value: String
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                ElementHeaderView(emoji: "🛡️", elementName: "Nutrients", principle: "Safety", step: 5)

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

                // Unsafe prompt display
                VStack(alignment: .leading, spacing: 8) {
                    Label("⚠️ Unsafe Prompt (Contains PII)", systemImage: "exclamationmark.shield.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.dangerRed)

                    Text(level.examples.first?.badPrompt ?? "")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.charcoal)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.dangerRed.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.dangerRed.opacity(0.4), lineWidth: 1.5)
                                )
                        )
                }
                .padding(.horizontal, 16)

                if showEditor {
                    // Live privacy scanner
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            detectedPII.isEmpty ? "✅ No PII Detected" : "🚨 PII Found (\(detectedPII.count))",
                            systemImage: detectedPII.isEmpty ? "shield.checkered" : "exclamationmark.shield.fill"
                        )
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(detectedPII.isEmpty ? Theme.safeGreen : Theme.dangerRed)

                        if !detectedPII.isEmpty {
                            ForEach(detectedPII) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Theme.dangerRed)
                                    Text("\(item.type): \(item.value)")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(Theme.charcoal.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(detectedPII.isEmpty ? Theme.safeGreen.opacity(0.08) : Theme.dangerRed.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        detectedPII.isEmpty ? Theme.safeGreen.opacity(0.3) : Theme.dangerRed.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Tag chips
                    HStack(spacing: 6) {
                        TagChipView(label: "No Phone", isComplete: !hasPII(type: "phone"))
                        TagChipView(label: "No Email", isComplete: !hasPII(type: "email"))
                        TagChipView(label: "No API Key", isComplete: !hasPII(type: "api"))
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Your Safe Prompt", systemImage: "pencil.line")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.amber)

                        TextEditor(text: $userPrompt)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(Theme.charcoal)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.cream)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.warmBrown.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                            .onChange(of: userPrompt) { _, _ in
                                scanForPII()
                            }
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

                    // Quick redact buttons
                    HStack(spacing: 8) {
                        QuickRedactButton(label: "[REDACTED]") { insertRedaction("[REDACTED]") }
                        QuickRedactButton(label: "[API removed]") { insertRedaction("[API key removed]") }
                        QuickRedactButton(label: "[Phone removed]") { insertRedaction("[Phone removed]") }
                    }
                    .padding(.horizontal, 16)
                    .transition(Theme.levelTransition)

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
                            Text(isEvaluating ? "Evaluating…" : "Check Safety")
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

                if let result = result {
                    ResultPanel(result: result)
                        .transition(Theme.levelTransition)
                }

                if showSuccess {
                    SuccessPanel(elementName: "Nutrients", feedback: level.visualFeedback) {
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
            scanForPII()
        }
    }

    // MARK: - PII Scanner

    private func hasPII(type: String) -> Bool {
        detectedPII.contains { $0.type.lowercased().contains(type) }
    }

    private func scanForPII() {
        var items: [PIIItem] = []
        let text = userPrompt

        // Phone numbers
        let phonePatterns = [#"\b\d{10}\b"#, #"\+\d{1,3}[\s-]\d{10}"#, #"\b\d{3}[\s-]\d{3}[\s-]\d{4}\b"#]
        for pattern in phonePatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                items.append(PIIItem(type: "Phone", value: String(text[range])))
                break
            }
        }

        // Emails
        if let range = text.range(of: #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#, options: .regularExpression) {
            items.append(PIIItem(type: "Email", value: String(text[range])))
        }

        // API keys
        let apiPatterns = [#"sk-[a-zA-Z0-9]{20,}"#, #"Bearer [a-zA-Z0-9]{20,}"#]
        for pattern in apiPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                items.append(PIIItem(type: "API Key", value: String(text[range].prefix(20)) + "…"))
                break
            }
        }

        // Credit cards
        if let range = text.range(of: #"\b\d{4}[\s-]\d{4}[\s-]\d{4}[\s-]\d{4}\b"#, options: .regularExpression) {
            items.append(PIIItem(type: "Credit Card", value: String(text[range])))
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            detectedPII = items
        }
    }

    private func insertRedaction(_ placeholder: String) {
        userPrompt += " " + placeholder
    }

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
                    appState.recordPrivacyRisksRemoved(detectedPII.count)
                    appState.completeLevel(5, tokensSaved: 0, clarityScore: evalResult.score)
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - Quick Redact Button

private struct QuickRedactButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.charcoal)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.parchment)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.warmBrown.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
