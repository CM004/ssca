//
//  Stage3_SunlightView.swift
//  The Living Prompt Tree
//
//  Stage 3 — Sunlight · Efficiency
//  Two-phase compression:
//   Phase 1: Tap redundant words to remove them
//   Phase 2: Replace verbose phrases with compact symbols (& → [] {} | etc.)
//  Foundation Model evaluates the final compressed prompt.
//

import SwiftUI
import FoundationModels

// MARK: - Symbol Reference Data

struct SymbolRule: Identifiable {
    let id = UUID()
    let symbol: String
    let meaning: String
    let example: String
}

private let symbolReference: [SymbolRule] = [
    SymbolRule(symbol: "→", meaning: "Output format / produce", example: "→ bullet list"),
    SymbolRule(symbol: "&", meaning: "AND / combine", example: "causes & effects"),
    SymbolRule(symbol: "[ ]", meaning: "Enumerate items", example: "[people, orgs]"),
    SymbolRule(symbol: "{ }", meaning: "Structured output", example: "{name, role}"),
    SymbolRule(symbol: "|", meaning: "OR / alternatives", example: "formal|casual"),
    SymbolRule(symbol: "@", meaning: "Reference / role", example: "@educator"),
    SymbolRule(symbol: ":", meaning: "Define / specify", example: "topic: climate"),
    SymbolRule(symbol: "~", meaning: "Approximately", example: "~50 words"),
    SymbolRule(symbol: "!", meaning: "Exclude / negate", example: "!filler"),
    SymbolRule(symbol: "+", meaning: "Include / add", example: "+examples"),
    SymbolRule(symbol: "-", meaning: "Remove / subtract", example: "-jargon"),
]

struct Stage3_SunlightView: View {

    @EnvironmentObject var appState: AppState
    private let config = Curriculum.stage(for: 3)!
    private let words = Curriculum.stage3Words
    private let fallbackRedundantIndices = Curriculum.stage3RedundantIndices

    @State private var struckIndices: Set<Int> = []
    @State private var showHints = false
    @State private var compressedText: String = ""
    @State private var showSymbolRef = false
    @State private var isEvaluating = false
    @State private var result: StageScore? = nil
    @State private var isLoadingHints = false
    @State private var fmRedundantIndices: Set<Int> = []

    // Phase tracking
    private var phase1Done: Bool { struckIndices.count >= 5 }

    private var keptWords: [String] {
        words.enumerated().compactMap { idx, word in struckIndices.contains(idx) ? nil : word }
    }
    private var phase1Prompt: String { keptWords.joined(separator: " ") }
    private var phase1TokenCount: Int { keptWords.count }
    private var originalTokenCount: Int { words.count }

    // Phase 2: user edits the prompt further with symbols
    private var finalPrompt: String {
        compressedText.isEmpty ? phase1Prompt : compressedText
    }
    private var finalTokenCount: Int {
        finalPrompt.split(separator: " ").count
    }
    private var reductionPercent: Int {
        guard originalTokenCount > 0 else { return 0 }
        return Int(Double(originalTokenCount - finalTokenCount) / Double(originalTokenCount) * 100)
    }
    private var usesSymbols: Bool {
        let symbols: [Character] = ["→", "&", "@", "|", "~", "!"]
        return symbols.contains(where: { finalPrompt.contains($0) }) ||
               finalPrompt.contains("[]") || finalPrompt.contains("{}")
    }
    private var isInTargetRange: Bool { Curriculum.stage3TargetRange.contains(finalTokenCount) }
    private var isOvercompressed: Bool { finalTokenCount < Curriculum.stage3OvercompressedThreshold }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                techniques
                Text(config.conceptText).font(.body).foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Don't strip so much that meaning disappears from prompt.")
                        .font(.caption).foregroundStyle(.orange)
                }

                Divider()

                // Current prompt
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Prompt").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    Text(appState.currentPrompt)
                        .font(.callout.monospaced())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                    Label("\(originalTokenCount) tokens", systemImage: "number")
                        .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                }

                Divider()

                // PHASE 1: Word removal
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Phase 1: Remove Redundant and Unrequired tokens")
                            .font(.headline)
                        Spacer()
                        if phase1Done {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    Text("Tap unrequired words to remove them.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                wordGrid

                Button {
                    if showHints {
                        withAnimation { showHints = false }
                    } else {
                        Task { await loadFMRedundantWords() }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isLoadingHints { ProgressView().controlSize(.small) }
                        Label(showHints ? "Hide removable tokens" : "Show removable tokens",
                              systemImage: showHints ? "eye.slash" : "eye")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingHints)

                // Token counter
                tokenCounter

                if isOvercompressed && compressedText.isEmpty {
                    Label("Overcompressed — meaning lost.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.medium)).foregroundStyle(.red)
                }

                // Symbol compression (appears after removing some words)
                if phase1Done {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Now Compress with Symbols")
                            .font(.headline)
                        Text("Use symbols to replace verbose phrases. LLMs understand code-like syntax.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    // Symbol reference card
                    symbolReferenceCard

                    // Before / After examples
                    examplesCard
                }

                Divider()

                // Single editable Final Compressed Prompt
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Final Compressed Prompt")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }

                    TextEditor(text: $compressedText)
                        .font(.callout.monospaced())
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )

                    HStack {
                        Label("\(finalTokenCount) tokens (was \(originalTokenCount))", systemImage: "number")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isInTargetRange ? .green : .orange)

                        if usesSymbols {
                            Label("Symbols used", systemImage: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        if reductionPercent > 0 {
                            Text("-\(reductionPercent)%")
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(.green)
                        }
                    }
                }

                if !struckIndices.isEmpty { evaluateButton }

                if let result = result {
                    EvaluationResultView(
                        emoji: "☀️", title: "Sunlight Efficiency Score",
                        score: result, ctaLabel: "Continue to Stage 4 : Soil"
                    ) {
                        appState.completeStage(3, newPrompt: finalPrompt, score: result)
                    }
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Sunlight — Efficiency")
        .onAppear {
            if compressedText.isEmpty {
                compressedText = appState.currentPrompt
            }
        }
        .onChange(of: phase1Done) { _, done in
            if done {
                compressedText = phase1Prompt
            }
        }
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

    private var wordGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 60), spacing: 6)]
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { idx, word in
                wordButton(idx: idx, word: word)
            }
        }
    }

    private func wordButton(idx: Int, word: String) -> some View {
        let isStruck = struckIndices.contains(idx)
        let isRemovable = showHints && fmRedundantIndices.contains(idx)
        let bgColor: Color = isStruck ? .red.opacity(0.06) : isRemovable ? .orange.opacity(0.06) : Color(.secondarySystemFill)
        let borderColor: Color = isStruck ? .red.opacity(0.3) : isRemovable ? .orange.opacity(0.3) : .clear
        let textColor: Color = isStruck ? .secondary : isRemovable ? .orange : .primary

        return Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                if struckIndices.contains(idx) { struckIndices.remove(idx) }
                else { struckIndices.insert(idx) }
                // Sync the final compressed prompt text field
                compressedText = keptWords.joined(separator: " ")
            }
        } label: {
            Text(word)
                .font(.caption)
                .foregroundStyle(textColor)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(bgColor, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderColor, lineWidth: 1))
        }
    }

    private var tokenCounter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Phase 1 Result").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Spacer()
                Text("\(originalTokenCount) → \(phase1TokenCount) tokens")
                    .font(.caption.weight(.bold).monospaced())
                    .foregroundStyle(phase1Done ? .green : .orange)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemFill))
                    let barColor: Color = phase1Done ? .green : .orange
                    RoundedRectangle(cornerRadius: 4).fill(barColor)
                        .frame(width: geo.size.width * CGFloat(phase1TokenCount) / CGFloat(originalTokenCount))
                }
            }
            .frame(height: 8)
        }
    }

    private var symbolReferenceCard: some View {
        DisclosureGroup(isExpanded: $showSymbolRef) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(symbolReference) { rule in
                    HStack(spacing: 8) {
                        Text(rule.symbol)
                            .font(.callout.weight(.bold).monospaced())
                            .frame(width: 30)
                            .foregroundStyle(Color.accentColor)
                        Text(rule.meaning)
                            .font(.caption)
                            .frame(width: 120, alignment: .leading)
                        Text(rule.example)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 6)
        } label: {
            Label("Symbol Reference", systemImage: "character.textbox")
                .font(.subheadline.weight(.medium))
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var examplesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Before / After Examples").font(.subheadline.weight(.medium))

            VStack(alignment: .leading, spacing: 4) {
                Text("Verbose:").font(.caption2.weight(.bold)).foregroundStyle(.red)
                Text("\"Explain the main causes and effects of climate change\"")
                    .font(.caption.monospaced()).foregroundStyle(.secondary)

                Text("Compact:").font(.caption2.weight(.bold)).foregroundStyle(.green)
                Text("\"Explain climate change causes & effects\"")
                    .font(.caption.monospaced()).foregroundStyle(.green)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Verbose:").font(.caption2.weight(.bold)).foregroundStyle(.red)
                Text("\"focusing on environmental and economic impacts. Use bullet points.\"")
                    .font(.caption.monospaced()).foregroundStyle(.secondary)

                Text("Compact:").font(.caption2.weight(.bold)).foregroundStyle(.green)
                Text("\"environmental & economic impacts → bullet points\"")
                    .font(.caption.monospaced()).foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }


    // Foundation Model judges which words are redundant
    private func loadFMRedundantWords() async {
        isLoadingHints = true
        var indices: Set<Int> = []

        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let numberedWords = words.enumerated().map { "\($0.offset):\($0.element)" }.joined(separator: ", ")
                let prompt = """
                Here is a prompt split into numbered words: \(numberedWords)
                
                Task: Identify word indices that can be removed OR rewritten more concisely using symbols. So that prompt tokens given to LLM is minimised.
                Removable: filler words, redundant adjectives, repeated meaning, unnecessary articles/prepositions, ful stops
                Symbol-rewritable: words like "and" (use &), "or" (use |), "produce/output" (use =>), "approximately" (use ~), "include" (use +), "remove/subtract" (use -), "define/specify" (use :), "exclude" (use !), "as a/role of" (use @), enumerated lists (use []), structured data (use {}).
                
                Respond with ONLY a JSON array of integer indices of ALL words that are either removable or could be replaced by symbols, e.g. [2,5,8,12].
                """
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                // Extract JSON array from response
                if let start = text.firstIndex(of: "["),
                   let end = text.lastIndex(of: "]") {
                    let jsonStr = String(text[start...end])
                    if let data = jsonStr.data(using: .utf8),
                       let arr = try? JSONSerialization.jsonObject(with: data) as? [Int] {
                        indices = Set(arr)
                    }
                }
            } catch { }
        }

        // Fallback to static indices if FM returned nothing
        if indices.isEmpty {
            indices = Set(fallbackRedundantIndices)
        }

        await MainActor.run {
            fmRedundantIndices = indices
            withAnimation { showHints = true }
            isLoadingHints = false
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
        let lc = finalPrompt.lowercased()
        let hasRole = lc.contains("educator") || lc.contains("role") || lc.contains("@")
        let hasTask = lc.contains("explain") || lc.contains("summarize")
        let hasAudience = lc.contains("school") || lc.contains("student")
        let hasConstraint = lc.contains("environmental") || lc.contains("economic") || lc.contains("impact")
        let goodReduction = reductionPercent >= 30
        let symbolsUsed = usesSymbols

        var checks: [(String, Bool)] = [
            ("Tokens reduced \u{2265} 30%", goodReduction),
            ("Role preserved", hasRole),
            ("Task verb preserved", hasTask),
            ("Audience preserved", hasAudience),
            ("Constraint preserved", hasConstraint),
            ("Symbols used for compression", symbolsUsed),
            ("No overcompression", !isOvercompressed),
        ]
        var feedback = ""

        // Foundation Model evaluation
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let evalPrompt = """
                Compare these prompts:
                Original (\(originalTokenCount) tokens): "\(appState.currentPrompt)"
                Compressed (\(finalTokenCount) tokens): "\(finalPrompt)"
                
                Evaluate: Does the compressed version preserve meaning? Does it use symbols effectively (& → [] {} | @ : ~ ! +)?
                Respond with JSON: {"meaningPreserved": true/false, "symbolsEffective": true/false, "feedback": "one sentence"}
                """
                let response = try await session.respond(to: evalPrompt)
                let text = response.content
                if let data = text.data(using: String.Encoding.utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let fb = json["feedback"] as? String { feedback = fb }
                    if let mp = json["meaningPreserved"] as? Bool {
                        checks.append(("LLM: Meaning preserved", mp))
                    }
                }
            } catch { }
        }

        if feedback.isEmpty {
            feedback = goodReduction && symbolsUsed
                ? "Sun breaks through. Efficient and symbolic."
                : symbolsUsed ? "Good symbol use. Compress further."
                : "Try using symbols like & → [] to compress more."
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
