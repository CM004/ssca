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

    @State private var struckIndices: Set<Int> = []
    @State private var compressedText: String = ""
    @State private var showSymbolRef = false
    @State private var isEvaluating = false
    @State private var result: StageScore? = nil
    @State private var showConfetti = false
    @StateObject private var speech = SpeechManager()

    private var speakText: String {
        var text = "Stage 3: Sunlight, Efficiency. \(config.conceptText) Phase 1: Tap redundant words to remove them. Your bloated prompt is: \(appState.currentPrompt). It currently has \(originalTokenCount) tokens. Remove at least 5 tokens to unlock Phase 2."
        if phase1Done {
            text += " Phase 2 is unlocked. Use symbols to replace verbose phrases, like using an ampersand or an arrow symbol. Your final compressed prompt will be evaluated for efficiency."
        }
        return text
    }

    // Phase tracking
    private var tokensRemoved: Int { originalTokenCount - phase1TokenCount }
    private var phase1Done: Bool { tokensRemoved >= 5 }

    private var keptWords: [String] {
        words.enumerated().compactMap { idx, word in struckIndices.contains(idx) ? nil : word }
    }

    /// Joins words, attaching punctuation to previous word without space
    private func smartJoin(_ wordList: [String]) -> String {
        let punctuation: Set<String> = [".", ",", ";", ":", "!", "?"]
        var result = ""
        for word in wordList {
            if punctuation.contains(word) {
                result += word
            } else {
                if !result.isEmpty { result += " " }
                result += word
            }
        }
        return result
    }

    private var phase1Prompt: String { smartJoin(keptWords) }

    // Use a consistent token counting function everywhere
    private func countTokens(_ text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    private var originalTokenCount: Int { countTokens(appState.currentPrompt) }
    private var phase1TokenCount: Int { countTokens(phase1Prompt) }

    // Phase 2: user edits the prompt further with symbols
    private var finalPrompt: String {
        compressedText.isEmpty ? phase1Prompt : compressedText
    }
    private var finalTokenCount: Int { countTokens(finalPrompt) }
    private var reductionPercent: Int {
        guard originalTokenCount > 0 else { return 0 }
        return Int(Double(originalTokenCount - finalTokenCount) / Double(originalTokenCount) * 100)
    }
    private var usesSymbols: Bool {
        let symbols: [Character] = ["→", "&", "@", "|", "~", "!", "[", "]", "{", "}", ":", "=", "+", "-"]
        return symbols.contains(where: { finalPrompt.contains($0) })
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
                    Text("Bloated Prompt Preview").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
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
                            .font(.title3.weight(.bold))
                        Spacer()
                        if phase1Done {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    Text("Tap those words which you think are making your prompt bloated.")
                        .font(.callout).foregroundStyle(.secondary)
                }

                wordGrid

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
                        Text("Phase 2 : Compress with Symbols")
                            .font(.title3.weight(.bold))
                        Text("Use symbols to replace verbose phrases. LLMs understand code-like syntax.")
                            .font(.callout).foregroundStyle(.secondary)
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
                    }
                }

                if phase1Done && usesSymbols { evaluateButton }

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
        .overlay {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: result != nil) { _, hasResult in
            if hasResult {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation { showConfetti = false }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Sunlight — Efficiency")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SpeakerButton(speech: speech, text: speakText)
            }
        }
        .onDisappear { speech.stop() }
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

        return Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                if struckIndices.contains(idx) { struckIndices.remove(idx) }
                else { struckIndices.insert(idx) }
                compressedText = smartJoin(keptWords)
            }
        } label: {
            Text(word)
                .font(.caption)
                .strikethrough(isStruck, color: .red)
                .foregroundStyle(isStruck ? .secondary : .primary)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(isStruck ? Color.red.opacity(0.06) : Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(isStruck ? Color.red.opacity(0.3) : .clear, lineWidth: 1))
        }
    }

    private var tokenCounter: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemFill))
                    let progress = min(CGFloat(tokensRemoved) / 5.0, 1.0)
                    RoundedRectangle(cornerRadius: 4).fill(phase1Done ? Color.green : Color.orange)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)

            if !phase1Done {
                Text("Remove at least 5 tokens to unlock Phase 2")
                    .font(.callout).foregroundStyle(.secondary)
            }
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

//            compressionExample(
//                verbose: "You are a science educator",
//                tokens: 5,
//                compact: "@science-educator",
//                compactTokens: 1
//            )
//
//            Divider()

            compressionExample(
                verbose: "Explain the main causes and effects of",
                tokens: 8,
                compact: "Explain causes & effects:",
                compactTokens: 4
            )

            Divider()

//            30

            compressionExample(
                verbose: "Use bullet points.",
                tokens: 3,
                compact: "→ bullets",
                compactTokens: 2
            )

            Divider()

            compressionExample(
                verbose: "for a high school student",
                tokens: 5,
                compact: "for: high-schooler",
                compactTokens: 2
            )
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func compressionExample(verbose: String, tokens: Int, compact: String, compactTokens: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("Verbose:").font(.caption2.weight(.bold)).foregroundStyle(.red)
                Spacer()
                Text("\(tokens) tokens").font(.caption2.monospaced()).foregroundStyle(.red)
            }
            Text("\"\(verbose)\"")
                .font(.caption.monospaced()).foregroundStyle(.secondary)

            HStack {
                Text("Compact:").font(.caption2.weight(.bold)).foregroundStyle(.green)
                Spacer()
                Text("\(compactTokens) tokens").font(.caption2.monospaced()).foregroundStyle(.green)
            }
            Text("\"\(compact)\"")
                .font(.caption.monospaced()).foregroundStyle(.green)
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
        let tokensReduced = originalTokenCount - finalTokenCount
        let goodReduction = tokensReduced >= 5
        let symbolsUsed = usesSymbols

        var checks: [(String, Bool)] = [
            ("At least 5 tokens reduced (reduced \(tokensReduced))", goodReduction),
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
