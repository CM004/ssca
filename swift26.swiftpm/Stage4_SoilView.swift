//
//  Stage4_SoilView.swift
//  The Living Prompt Tree
//
//  Stage 4 — Soil · Context
//  Features: context field, + button for few-shot examples,
//  thinking style dropdown, token/accuracy tradeoff warning.
//

import SwiftUI
import FoundationModels

// MARK: - Few-Shot Example Model

struct FewShotExample: Identifiable {
    let id = UUID()
    var input: String = ""
    var output: String = ""
}

// MARK: - Thinking Style

enum ThinkingStyle: String, CaseIterable, Identifiable {
    case none = "None"
    case stepByStep = "Step-by-Step"
    case chainOfThought = "Chain of Thought"
    case treeOfThought = "Tree of Thought"
    case reflective = "Reflect then Answer"

    var id: String { rawValue }

    var promptSuffix: String {
        switch self {
        case .none: return ""
        case .stepByStep: return "Think step by step."
        case .chainOfThought: return "Use chain of thought reasoning."
        case .treeOfThought: return "Explore multiple reasoning paths before answering."
        case .reflective: return "Reflect on your reasoning, then provide the final answer."
        }
    }

    var description: String {
        switch self {
        case .none: return "No reasoning instruction"
        case .stepByStep: return "AI breaks the problem into sequential steps"
        case .chainOfThought: return "AI shows its reasoning chain before concluding"
        case .treeOfThought: return "AI explores multiple paths, picks the best"
        case .reflective: return "AI self-checks reasoning before final answer"
        }
    }

    var tokenCost: String {
        switch self {
        case .none: return "0"
        case .stepByStep: return "+4"
        case .chainOfThought: return "+6"
        case .treeOfThought: return "+8"
        case .reflective: return "+7"
        }
    }
}

struct Stage4_SoilView: View {

    @EnvironmentObject var appState: AppState
    private let config = Curriculum.stage(for: 4)!

    @State private var contextSentence: String = ""
    @State private var examples: [FewShotExample] = []
    @State private var thinkingStyle: ThinkingStyle = .none
    @State private var isEvaluating = false
    @State private var result: StageScore? = nil

    private var assembledPrompt: String {
        var p = appState.currentPrompt
        if !contextSentence.isEmpty { p += " Context: \(contextSentence)." }
        let validExamples = examples.filter { !$0.input.isEmpty && !$0.output.isEmpty }
        if !validExamples.isEmpty {
            for (i, ex) in validExamples.enumerated() {
                p += " Example \(i + 1) — Input: \"\(ex.input)\" → Output: \"\(ex.output)\"."
            }
        }
        if thinkingStyle != .none {
            p += " " + thinkingStyle.promptSuffix
        }
        return p
    }
    private var assembledTokens: Int { assembledPrompt.split(separator: " ").count }
    private var canEvaluate: Bool { !contextSentence.isEmpty }
    private var validExampleCount: Int { examples.filter { !$0.input.isEmpty && !$0.output.isEmpty }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                techniques
                Text(config.conceptText).font(.body).foregroundStyle(.secondary)
                Divider()

                Text("Ground your prompt with context and examples.")
                    .font(.headline)

                // Context field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Context Sentence")
                        .font(.subheadline.weight(.medium))
                    TextField("e.g. For a Grade 10 science revision worksheet", text: $contextSentence, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                // Few-shot examples
                fewShotSection

                Divider()

                // Thinking style
                thinkingStyleSection

                Divider()

                // Token warning
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("More context costs more tokens, But brings more accurate responses")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                        Text("Each example and thinking style adds tokens. Balance accuracy with cost.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.orange.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.2), lineWidth: 1))

                promptPreview

                if canEvaluate { evaluateButton }

                if let result = result {
                    EvaluationResultView(
                        emoji: "🌍", title: "Soil Context Score",
                        score: result, ctaLabel: "Continue to Stage 5 : Nutrients"
                    ) {
                        appState.completeStage(4, newPrompt: assembledPrompt, score: result)
                    }
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Soil — Context")
    }

    // MARK: - Subviews

    private var techniques: some View {
        HStack(spacing: 6) {
            ForEach(config.techniqueNames, id: \.self) { (t: String) in
                Text(t).font(.caption.weight(.medium))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
    }

    private var fewShotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Few-Shot Examples (optional)")
                    .font(.subheadline.weight(.medium))
                if examples.count > 0 {
                    Spacer()
                    Text("\(validExampleCount) example\(validExampleCount == 1 ? "" : "s")")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(examples.enumerated()), id: \.element.id) { idx, _ in
                exampleCard(index: idx)
            }

            // Add example button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    examples.append(FewShotExample())
                }
            } label: {
                Label("Add Example", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
    }

    private func exampleCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Example \(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if examples.count > 1 {
                    Button {
                        withAnimation { _ = examples.remove(at: index) }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }

            Text("Input:").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TextField("e.g. What causes global warming?", text: $examples[index].input)
                .textFieldStyle(.roundedBorder)
                .font(.callout)

            Text("Output:").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            TextField("e.g. Greenhouse gas emissions from…", text: $examples[index].output, axis: .vertical)
                .lineLimit(2...3)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
        }
        .padding(10)
        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 8))
    }

    private var thinkingStyleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Thinking Style - For complex problems (optional)")
                .font(.subheadline.weight(.medium))

            Picker("Thinking Style", selection: $thinkingStyle) {
                ForEach(ThinkingStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.menu)

            if thinkingStyle != .none {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thinkingStyle.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("Adds to prompt:")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("\"\(thinkingStyle.promptSuffix)\"")
                            .font(.caption2.monospaced().weight(.medium))
                            .foregroundStyle(.orange)
                    }

                    Text("\(thinkingStyle.tokenCost) tokens")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                }
                .padding(8)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var promptPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Prompt Preview").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Text(assembledPrompt)
                .font(.callout.monospaced())
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
            Label("\(assembledTokens) tokens", systemImage: "number")
                .font(.caption.weight(.semibold)).foregroundStyle(.orange)
        }
    }

    private var evaluateButton: some View {
        Button {
            Task { await evaluate() }
        } label: {
            HStack(spacing: 8) {
                if isEvaluating { ProgressView() }
                Text(isEvaluating ? "Evaluating…" : "Confirm for Evaluation").font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).controlSize(.large).tint(.green).disabled(isEvaluating)
    }

    private func evaluate() async {
        isEvaluating = true
        let hasContext = !contextSentence.trimmingCharacters(in: .whitespaces).isEmpty
        let hasExample = validExampleCount >= 1
        let hasMultipleExamples = validExampleCount >= 2
        let contextQuality = contextSentence.split(separator: " ").count >= 5
        let hasThinking = thinkingStyle != .none

        var checks: [(String, Bool)] = [
            ("Context sentence present", hasContext),
            ("Context is specific enough", contextQuality),
            ("At least 1 example provided", hasExample),
            ("Multiple examples (few-shot)", hasMultipleExamples),
            ("Thinking style selected", hasThinking),
        ]
        var feedback = ""

        // Foundation Model evaluation
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let evalPrompt = """
                Evaluate this prompt for context quality and few-shot examples:
                "\(assembledPrompt)"
                Check: Does it have real-world context? Are examples relevant? Is a thinking style included?
                Respond with JSON: {"hasContext": true/false, "examplesRelevant": true/false, "feedback": "one sentence"}
                """
                let response = try await session.respond(to: evalPrompt)
                let text = response.content
                if let data = text.data(using: String.Encoding.utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let fb = json["feedback"] as? String { feedback = fb }
                    if let er = json["examplesRelevant"] as? Bool {
                        checks.append(("LLM: Examples relevant", er))
                    }
                }
            } catch { }
        }

        if feedback.isEmpty {
            feedback = hasContext && hasExample
                ? "Roots are deepening. The tree has grounding."
                : "Add more context and examples for stronger roots."
        }

        let earned = checks.filter(\.1).count
        let score = StageScore(
            checks: checks.map { (label: $0.0, passed: $0.1) },
            total: checks.count, earned: earned,
            feedback: feedback
        )
        await MainActor.run {
            withAnimation { result = score }
            isEvaluating = false
        }
    }
}
