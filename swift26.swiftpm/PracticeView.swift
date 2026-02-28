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
                Evaluate this prompt across 4 dimensions. For each dimension, give a score from 1-5 and one-sentence feedback.

                Prompt to evaluate: "\(userPrompt)"

                Dimensions:
                1. CORE — Does it define Role, Task, Audience, Context, Constraints, and Output Format?
                2. ADVANCED — Does it use advanced techniques like Chain of Thought, Step-by-Step, One/Few-Shot examples, or Tree of Thought?
                3. EFFICIENCY — Is it concise? Does it avoid filler, unrequired pleasantries, and repeating words?
                4. SAFETY — Is it free of PII (phone numbers, emails, names) and sensitive data?

                Then provide:
                - ADD: List of specific techniques to add WITH an example (max 4 items)
                - REMOVE: List of things to remove or fix (max 3 items)
                - IMPROVED: A rewritten, improved version of the prompt that utilizes these advanced techniques

                Format your response EXACTLY like this:
                CORE: [1-5] [feedback]
                ADVANCED: [1-5] [feedback]
                EFFICIENCY: [1-5] [feedback]
                SAFETY: [1-5] [feedback]
                ADD: [technique: example] | [technique: example]
                REMOVE: [item1] | [item2]
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
            ("CORE", "🎯", "Core Elements"),
            ("ADVANCED", "🧠", "Advanced Techniques"),
            ("EFFICIENCY", "⚡", "Efficiency"),
            ("SAFETY", "🛡️", "Safety")
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
        let lower = userPrompt.lowercased()
        
        // Good Heuristics
        let hasRole = lower.contains("role") || lower.contains("act as") || lower.contains("you are")
        let hasTask = lower.contains("write") || lower.contains("solve") || lower.contains("explain") || lower.contains("summarize") || lower.contains("create")
        let hasAudience = lower.contains("for") || lower.contains("audience") || lower.contains("reader") || lower.contains("student")
        let hasContext = lower.contains("context") || lower.contains("given the") || lower.contains("based on")
        let hasConstraint = lower.contains("under") || lower.contains("words") || lower.contains("max") || lower.contains("only") || lower.contains("limit")
        let hasOutput = lower.contains("json") || lower.contains("format") || lower.contains("bullet") || lower.contains("table")
        
        let hasCoT = lower.contains("explain reasoning") || lower.contains("think about") || lower.contains("chain of thought")
        let hasStepByStep = lower.contains("step-by-step") || lower.contains("step by step") || lower.contains("first,")
        let hasExamples = lower.contains("example:") || lower.contains("for instance") || lower.contains("e.g.") || lower.contains("one-shot") || lower.contains("few-shot")
        let hasToT = lower.contains("tree of thought") || lower.contains("paths") || lower.contains("options") || lower.contains("brainstorm")
        
        // Bad Heuristics
        let hasFiller = lower.contains("basically") || lower.contains("umm") || lower.contains("kind of")
        let hasUnrequired = lower.contains("please") || lower.contains("if you don't mind") || lower.contains("wondering if")
        let hasRepeating = lower.contains("again") || lower.contains("as i said")
        let hasPII = lower.contains("ssn") || lower.contains("phone:") || lower.contains("@") || lower.contains("123-")
        
        // Scoring logic
        let coreHits = [hasRole, hasTask, hasAudience, hasContext, hasConstraint, hasOutput].filter { $0 }.count
        let advancedHits = [hasCoT, hasStepByStep, hasExamples, hasToT].filter { $0 }.count
        let efficiencyIssues = [hasFiller, hasUnrequired, hasRepeating].filter { $0 }.count
        let safetyIssues = hasPII ? 1 : 0
        
        let coreScore = max(1, min(5, (coreHits * 5) / 6))
        let advancedScore = max(1, min(5, (advancedHits * 5) / 4 + 1))
        let efficiencyScore = max(1, 5 - (efficiencyIssues * 2))
        let safetyScore = hasPII ? 1 : 5
        
        var missingToImprove: [String] = []
        if !hasRole { missingToImprove.append("Add a Role (e.g. 'Act as a Senior Data Analyst')") }
        if !hasOutput { missingToImprove.append("Define Output Format (e.g. 'Format as a JSON object')") }
        if !hasConstraint { missingToImprove.append("Add Constraints (e.g. 'Keep it under 150 words')") }
        if !hasStepByStep { missingToImprove.append("Use Step-by-Step (e.g. 'Break down the steps')") }
        if !hasCoT { missingToImprove.append("Use Chain of Thought (e.g. 'Explain reasoning before answering')") }
        if !hasExamples { missingToImprove.append("Add One/Few-Shot Examples (e.g. 'Example: 2+2=4')") }
        
        var removes: [String] = []
        if hasFiller { removes.append("Remove filler words ('basically', 'kind of')") }
        if hasUnrequired { removes.append("Remove unrequired pleasantries ('please', 'if you don't mind')") }
        if hasRepeating { removes.append("Remove repeating redundant statements ('as I said before')") }
        if hasPII { removes.append("Remove personal data (phone numbers, emails, SSNs)") }
        
        let overall = (coreScore + advancedScore + efficiencyScore + safetyScore) / 4

        return PromptEvaluation(
            overallScore: overall,
            dimensions: [
                DimensionScore(emoji: "🎯", name: "Core Elements", score: coreScore, feedback: "Found \(coreHits)/6 core elements (Role, Task, Context, Audience, Constraint, Output)"),
                DimensionScore(emoji: "🧠", name: "Advanced Techniques", score: advancedScore, feedback: "Found \(advancedHits)/4 advanced techniques (CoT, One-Shot, Step-by-stp, ToT)"),
                DimensionScore(emoji: "⚡", name: "Efficiency", score: efficiencyScore, feedback: efficiencyIssues == 0 ? "Prompt is concise and efficient" : "Prompt contains filler or unrequired words that waste tokens"),
                DimensionScore(emoji: "🛡️", name: "Safety", score: safetyScore, feedback: hasPII ? "Privacy risk detected! Remove personal information" : "No PII detected"),
            ],
            addSuggestions: Array(missingToImprove.prefix(4)),
            removeSuggestions: removes,
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
