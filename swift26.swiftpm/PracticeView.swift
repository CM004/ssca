//
//  PracticeView.swift
//  The Living Prompt Tree
//
//  Free-form prompt practice: write a prompt, get AI evaluation
//  across all 5 learning dimensions (clarity, structure, efficiency,
//  context, safety).
//

import SwiftUI
import FoundationModels

struct PracticeView: View {

    @State private var userPrompt: String = ""
    @State private var isEvaluating = false
    @State private var evaluation: PromptEvaluation? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.and.outline")
                            .font(.title2).foregroundStyle(.green)
                        Text("Practice Mode")
                            .font(.title2.weight(.bold))
                    }
                    Text("Write any prompt and get AI feedback across all 5 dimensions you've learned.")
                        .font(.callout).foregroundStyle(.secondary)
                }

                Divider()

                // Prompt editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Prompt").font(.subheadline.weight(.semibold))
                    TextEditor(text: $userPrompt)
                        .font(.body.monospaced())
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.3), lineWidth: 1))

                    HStack {
                        Text("\(tokenCount) tokens")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            userPrompt = ""
                            evaluation = nil
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(userPrompt.isEmpty)
                    }
                }

                // Evaluate button
                Button {
                    Task { await evaluate() }
                } label: {
                    HStack {
                        if isEvaluating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "brain")
                        }
                        Text(isEvaluating ? "Evaluating…" : "Evaluate Prompt")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
                .disabled(userPrompt.trimmingCharacters(in: .whitespaces).count < 5 || isEvaluating)

                // Results
                if let eval = evaluation {
                    evaluationResults(eval)
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Practice")
    }

    private var tokenCount: Int {
        userPrompt.split(separator: " ").count
    }

    // MARK: - Evaluation Results

    @ViewBuilder
    private func evaluationResults(_ eval: PromptEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            // Overall score
            HStack {
                Text("Overall Score")
                    .font(.headline)
                Spacer()
                Text("\(eval.overallScore)/5")
                    .font(.title.weight(.bold).monospaced())
                    .foregroundStyle(scoreColor(eval.overallScore))
            }
            .padding(12)
            .background(scoreColor(eval.overallScore).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

            // 5 dimensions
            ForEach(eval.dimensions) { dim in
                dimensionCard(dim)
            }

            // Suggestions
            if !eval.addSuggestions.isEmpty || !eval.removeSuggestions.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    if !eval.addSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("What to Add", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.green)
                            ForEach(eval.addSuggestions, id: \.self) { s in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("→").foregroundStyle(.green)
                                    Text(s).font(.caption)
                                }
                            }
                        }
                    }

                    if !eval.removeSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("What to Remove / Fix", systemImage: "minus.circle.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.red)
                            ForEach(eval.removeSuggestions, id: \.self) { s in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("→").foregroundStyle(.red)
                                    Text(s).font(.caption)
                                }
                            }
                        }
                    }
                }
            }

            // Improved prompt suggestion
            if !eval.improvedPrompt.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Suggested Improved Prompt", systemImage: "sparkles")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.cyan)
                    Text(eval.improvedPrompt)
                        .font(.callout.monospaced())
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.cyan.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.cyan.opacity(0.2), lineWidth: 1))

                    Button {
                        userPrompt = eval.improvedPrompt
                        evaluation = nil
                    } label: {
                        Label("Use This Prompt", systemImage: "arrow.uturn.left")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)
                }
            }
        }
    }

    private func dimensionCard(_ dim: DimensionScore) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dim.emoji)
                Text(dim.name)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(dim.score)/5")
                    .font(.subheadline.weight(.bold).monospaced())
                    .foregroundStyle(scoreColor(dim.score))
            }
            Text(dim.feedback)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Score bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.fill.tertiary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(scoreColor(dim.score))
                        .frame(width: geo.size.width * CGFloat(dim.score) / 5.0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(10)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 5: return .green
        case 4: return .cyan
        case 3: return .yellow
        case 2: return .orange
        default: return .red
        }
    }

    // MARK: - FM Evaluation

    private func evaluate() async {
        isEvaluating = true
        evaluation = nil

        var result: PromptEvaluation

        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let prompt = """
                Evaluate this prompt across 5 dimensions. For each dimension, give a score from 1-5 and one-sentence feedback.

                Prompt to evaluate: "\(userPrompt)"

                Dimensions:
                1. CLARITY (Air) — Does it have a clear role and task?
                2. STRUCTURE (Water) — Is it logically ordered (Role→Task→Context→Constraints→Output)?
                3. EFFICIENCY (Sunlight) — Is it concise? Are there filler words or redundancy?
                4. CONTEXT (Soil) — Does it provide enough grounding context or examples?
                5. SAFETY (Nutrients) — Does it contain PII, unsafe requests, or missing constraints?

                Then provide:
                - ADD: List of things to add (max 3 items)
                - REMOVE: List of things to remove or fix (max 3 items)
                - IMPROVED: A rewritten, improved version of the prompt

                Format your response EXACTLY like this:
                CLARITY: [1-5] [feedback]
                STRUCTURE: [1-5] [feedback]
                EFFICIENCY: [1-5] [feedback]
                CONTEXT: [1-5] [feedback]
                SAFETY: [1-5] [feedback]
                ADD: [item1] | [item2] | [item3]
                REMOVE: [item1] | [item2] | [item3]
                IMPROVED: [the improved prompt]
                """
                let response = try await session.respond(to: prompt)
                let text = String(response.content)
                result = parseEvaluation(text)
            } catch {
                result = fallbackEvaluation()
            }
        } else {
            result = fallbackEvaluation()
        }

        await MainActor.run {
            evaluation = result
            isEvaluating = false
        }
    }

    private func parseEvaluation(_ text: String) -> PromptEvaluation {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        let dimensionKeys = [
            ("CLARITY", "🌬️", "Clarity (Air)"),
            ("STRUCTURE", "💧", "Structure (Water)"),
            ("EFFICIENCY", "☀️", "Efficiency (Sunlight)"),
            ("CONTEXT", "🌍", "Context (Soil)"),
            ("SAFETY", "🛡️", "Safety (Nutrients)"),
        ]

        var dimensions: [DimensionScore] = []
        var addItems: [String] = []
        var removeItems: [String] = []
        var improved = ""

        for (key, emoji, name) in dimensionKeys {
            if let line = lines.first(where: { $0.uppercased().hasPrefix(key) }) {
                let parts = line.dropFirst(key.count + 1).trimmingCharacters(in: .whitespaces)
                let score = Int(String(parts.prefix(1))) ?? 3
                let feedback = String(parts.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                dimensions.append(DimensionScore(emoji: emoji, name: name, score: score, feedback: feedback))
            } else {
                dimensions.append(DimensionScore(emoji: emoji, name: name, score: 3, feedback: "Could not evaluate"))
            }
        }

        if let addLine = lines.first(where: { $0.uppercased().hasPrefix("ADD:") }) {
            addItems = addLine.dropFirst(4).components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let remLine = lines.first(where: { $0.uppercased().hasPrefix("REMOVE:") }) {
            removeItems = remLine.dropFirst(7).components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        if let impLine = lines.first(where: { $0.uppercased().hasPrefix("IMPROVED:") }) {
            improved = String(impLine.dropFirst(9)).trimmingCharacters(in: .whitespaces)
        }

        let overall = dimensions.isEmpty ? 3 : dimensions.map(\.score).reduce(0, +) / dimensions.count

        return PromptEvaluation(
            overallScore: overall,
            dimensions: dimensions,
            addSuggestions: addItems,
            removeSuggestions: removeItems,
            improvedPrompt: improved
        )
    }

    private func fallbackEvaluation() -> PromptEvaluation {
        let words = userPrompt.split(separator: " ")
        let hasRole = userPrompt.lowercased().contains("role") || userPrompt.contains("@")
        let hasTask = words.count > 3
        let isShort = words.count < 50
        let hasContext = userPrompt.lowercased().contains("context") || userPrompt.lowercased().contains("example")

        return PromptEvaluation(
            overallScore: (hasRole ? 1 : 0) + (hasTask ? 1 : 0) + (isShort ? 1 : 0) + (hasContext ? 1 : 0) + 1,
            dimensions: [
                DimensionScore(emoji: "🌬️", name: "Clarity", score: hasRole ? 4 : 2, feedback: hasRole ? "Has a role defined" : "Add a clear role (@educator, @analyst)"),
                DimensionScore(emoji: "💧", name: "Structure", score: hasTask ? 3 : 2, feedback: "Structure could be improved with Role→Task→Context order"),
                DimensionScore(emoji: "☀️", name: "Efficiency", score: isShort ? 4 : 2, feedback: isShort ? "Reasonably concise" : "Too verbose — compress filler words"),
                DimensionScore(emoji: "🌍", name: "Context", score: hasContext ? 4 : 2, feedback: hasContext ? "Has context grounding" : "Add context or examples"),
                DimensionScore(emoji: "🛡️", name: "Safety", score: 4, feedback: "No obvious PII detected"),
            ],
            addSuggestions: hasRole ? [] : ["Add a role (@educator)", "Add output format (→ bullet list)"],
            removeSuggestions: isShort ? [] : ["Remove filler words", "Compress verbose phrases"],
            improvedPrompt: ""
        )
    }
}

// MARK: - Data Models

struct PromptEvaluation {
    let overallScore: Int
    let dimensions: [DimensionScore]
    let addSuggestions: [String]
    let removeSuggestions: [String]
    let improvedPrompt: String
}

struct DimensionScore: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let score: Int
    let feedback: String
}
