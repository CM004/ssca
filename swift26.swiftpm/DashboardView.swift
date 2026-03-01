//
//  DashboardView.swift
//  The Living Prompt Tree
//
//  Dashboard: real-time token journey, cost comparison, metrics.
//  Foundation Model judges exchange count. Info button on each card.
//

import SwiftUI
import Charts
import FoundationModels

struct DashboardView: View {

    @EnvironmentObject var appState: AppState
    @State private var activeInfo: InfoCard? = nil
    @State private var infoText: String = ""
    @State private var isLoadingInfo = false

    // Foundation Model estimated exchange count for bad prompt
    @State private var badExchanges: Int = 0
    @State private var isEstimating = true

    // MARK: - Real-time computed data

    private var tokenJourney: [(stage: String, tokens: Int)] {
        let labels = ["Start", "Air", "Water", "Sunlight", "Soil", "Nutrients"]
        let data = appState.tokenHistory
        return zip(labels, data).map { ($0, $1) }
    }

    private var startTokens: Int { appState.tokenHistory.first ?? Curriculum.get(domain: appState.selectedDomain).startingTokens }
    private var finalTokens: Int { appState.tokenHistory.last ?? startTokens }

    private var badPromptConversationCost: Int { startTokens * badExchanges * 2 }
    private var goodPromptConversationCost: Int { finalTokens * 2 }

    private var exchangesSaved: Int { max(0, badExchanges - 1) }

    private var costSavings: Int {
        guard badPromptConversationCost > 0 else { return 0 }
        return Int(Double(badPromptConversationCost - goodPromptConversationCost) / Double(badPromptConversationCost) * 100)
    }

    private var totalScore: Int {
        let scores = appState.stageScores.values
        guard !scores.isEmpty else { return 0 }
        let total = scores.reduce(0) { $0 + $1.earned }
        let maxVal = scores.reduce(0) { $0 + $1.total }
        guard maxVal > 0 else { return 0 }
        return Int(Double(total) / Double(maxVal) * 100)
    }

    // Accuracy estimate: based on how many checks passed across all stages
    private var accuracyEstimate: Int {
        let scores = appState.stageScores.values
        guard !scores.isEmpty else { return 0 }
        let total = scores.reduce(0) { $0 + $1.earned }
        let maxVal = scores.reduce(0) { $0 + $1.total }
        guard maxVal > 0 else { return 0 }
        return Int(Double(total) / Double(maxVal) * 100)
    }

    enum InfoCard: String, Identifiable {
        case tokenJourney = "Token Journey"
        case conversationCost = "Conversation Cost"
        case metrics = "Performance Metrics"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Your Prompt's Impact")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Divider().overlay(Color.green.opacity(0.2))

                // Token Journey Chart
                chartCard(title: "Token Journey", infoCard: .tokenJourney) {
                    Chart {
                        ForEach(tokenJourney, id: \.stage) { point in
                            LineMark(
                                x: .value("Stage", point.stage),
                                y: .value("Tokens", startTokens),
                                series: .value("Line", "Bad Prompt")
                            )
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }

                        ForEach(tokenJourney, id: \.stage) { point in
                            LineMark(
                                x: .value("Stage", point.stage),
                                y: .value("Tokens", point.tokens),
                                series: .value("Line", "Your Prompt")
                            )
                            .foregroundStyle(.green)

                            PointMark(
                                x: .value("Stage", point.stage),
                                y: .value("Tokens", point.tokens)
                            )
                            .foregroundStyle(.green)
                            .annotation(position: .top) {
                                Text("\(point.tokens)")
                                    .font(.caption2.weight(.bold).monospaced())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .frame(height: 180)

                    HStack(spacing: 16) {
                        Label("Bad Prompt (\(startTokens) flat)", systemImage: "minus")
                            .font(.caption2).foregroundStyle(.red)
                        Label("Your Prompt", systemImage: "circle.fill")
                            .font(.caption2).foregroundStyle(.green)
                    }
                }

                // Conversation Cost Chart
                chartCard(title: "Total Conversation Cost", infoCard: .conversationCost) {
                    if isEstimating {
                        HStack {
                            ProgressView()
                            Text("Foundation Model estimating exchange count…")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Chart {
                            BarMark(x: .value("Type", "Bad Prompt\n(\(badExchanges) exchanges)"), y: .value("Tokens", badPromptConversationCost))
                                .foregroundStyle(.red.opacity(0.6))
                                .annotation(position: .top) {
                                    Text("~\(badPromptConversationCost)")
                                        .font(.caption2.weight(.bold).monospaced())
                                        .foregroundStyle(.red)
                                }

                            BarMark(x: .value("Type", "Your Prompt\n(1 exchange)"), y: .value("Tokens", goodPromptConversationCost))
                                .foregroundStyle(.green)
                                .annotation(position: .top) {
                                    Text("~\(goodPromptConversationCost)")
                                        .font(.caption2.weight(.bold).monospaced())
                                        .foregroundStyle(.green)
                                }
                        }
                        .frame(height: 140)

                        Text("A vague prompt needs \(badExchanges) exchanges. Yours gets it done in 1.")
                            .font(.caption).foregroundStyle(.secondary).italic()
                    }
                }

                // Real-time Metrics — 2 cards
                chartCard(title: "Performance Metrics", infoCard: .metrics) {
                    HStack(spacing: 12) {
                        MetricCard(icon: "arrow.triangle.2.circlepath", value: "\(badExchanges)→1", label: "Exchanges Reduced")
                        MetricCard(icon: "target", value: "\(accuracyEstimate)%", label: "Prompt Quality")
                    }

                    // Stage scores breakdown
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(1...5, id: \.self) { stage in
                            if let score = appState.stageScores[stage] {
                                HStack {
                                    Text("Stage \(stage)")
                                        .font(.caption.weight(.medium))
                                        .frame(width: 60, alignment: .leading)

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3).fill(Color(.systemFill))
                                            RoundedRectangle(cornerRadius: 3).fill(.green)
                                                .frame(width: geo.size.width * CGFloat(score.earned) / CGFloat(max(score.total, 1)))
                                        }
                                    }
                                    .frame(height: 6)

                                    Text(score.label)
                                        .font(.caption2.weight(.bold).monospaced())
                                        .foregroundStyle(.green)
                                        .frame(width: 30, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                // Final prompt card
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Final Prompt")
                        .font(.subheadline.weight(.medium))
                    Text(appState.currentPrompt)
                        .font(.caption.monospaced())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                    Label("\(appState.currentTokenCount) tokens", systemImage: "number")
                        .font(.caption.weight(.semibold)).foregroundStyle(.green)
                }

                // Banner
                VStack(spacing: 6) {
                    Text("You didn't just write a better prompt.")
                        .font(.headline)
                    Text("You used AI more sustainably.")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))

                // CTAs
                HStack(spacing: 12) {
                    Button {
                        appState.reset()
                    } label: {
                        Text("Try Another Domain Prompt")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Dashboard")
        .task { await estimateExchanges() }
        .sheet(item: $activeInfo) { card in
            infoSheet(card: card)
        }
    }

    // MARK: - Foundation Model: estimate bad prompt exchanges

    private func estimateExchanges() async {
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let prompt = """
                A user sends this vague prompt to an AI: "\(Curriculum.get(domain: appState.selectedDomain).startingPrompt)"
                How many back-and-forth exchanges would typically be needed before the AI produces a satisfactory, complete answer?
                Consider that the prompt lacks: clear role, audience, output format, constraints, context, and examples.
                Respond with ONLY a single integer number between 2 and 8. Nothing else.
                """
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if let n = Int(text), (2...8).contains(n) {
                    await MainActor.run {
                        badExchanges = n
                        isEstimating = false
                    }
                    return
                }
            } catch { }
        }
        // Fallback
        await MainActor.run {
            badExchanges = 4
            isEstimating = false
        }
    }

    // MARK: - Reusable chart card with info button

    private func chartCard<Content: View>(title: String, infoCard: InfoCard, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button {
                    activeInfo = infoCard
                    infoText = ""
                    Task { await loadInfo(for: infoCard) }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
        .padding(16)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Info sheet

    private func infoSheet(card: InfoCard) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if isLoadingInfo {
                        HStack {
                            ProgressView()
                            Text("Generating explanation…")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding()
                    } else if !infoText.isEmpty {
                        Text(infoText)
                            .font(.body)
                            .padding()
                    }
                }
            }
            .navigationTitle(card.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { activeInfo = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Foundation Model info generation

    private func loadInfo(for card: InfoCard) async {
        isLoadingInfo = true
        var explanation = fallbackExplanation(for: card)

        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let context = """
                App: SamvaadFlow — teaches prompt engineering through 5 stages (Air=Clarity, Water=Structure, Sunlight=Efficiency, Soil=Context, Nutrients=Safety).
                Starting prompt: "\(Curriculum.get(domain: appState.selectedDomain).startingPrompt)" (\(startTokens) tokens)
                Final prompt: "\(appState.currentPrompt)" (\(finalTokens) tokens)
                Token history: \(appState.tokenHistory)
                Stages: \(appState.stageScores.sorted(by: { $0.key < $1.key }).map { "Stage \($0.key): \($0.value.earned)/\($0.value.total)" }.joined(separator: ", "))
                Bad prompt estimated exchanges: \(badExchanges)
                Follow-up rounds saved: \(exchangesSaved), Prompt Quality: \(accuracyEstimate)%
                """

                let prompt: String
                switch card {
                case .tokenJourney:
                    prompt = """
                    \(context)
                    Explain what the Token Journey chart shows. Tokens went from \(startTokens) to \(finalTokens) across 5 stages.
                    Why does token count matter (cost per token, speed, environmental impact)? Which stage likely had the biggest impact?
                    Keep under 150 words, conversational, educational.
                    """
                case .conversationCost:
                    prompt = """
                    \(context)
                    Explain the Conversation Cost comparison. You estimated the vague prompt needs \(badExchanges) exchanges = ~\(badPromptConversationCost) tokens total.
                    The optimized prompt gets it done in 1 exchange = ~\(goodPromptConversationCost) tokens.
                    Explain why multiple exchanges happen with vague prompts and the real-world cost implications.
                    Keep under 150 words, educational.
                    """
                case .metrics:
                    prompt = """
                    \(context)
                    Explain these 2 visible metrics:
                    - Follow-up Rounds Saved: \(exchangesSaved)x — the user's optimized prompt eliminates \(exchangesSaved) follow-up exchanges that a vague prompt would need. Explain how each saved round means less energy, less waiting, fewer AI responses generated.
                    - Prompt Quality: \(accuracyEstimate)% — based on evaluation checks passed across all 5 stages. This reflects the overall learning score.
                    Keep under 150 words, conversational.
                    """
                }

                let response = try await session.respond(to: prompt)
                explanation = response.content
            } catch { }
        }

        await MainActor.run {
            infoText = explanation
            isLoadingInfo = false
        }
    }

    private func fallbackExplanation(for card: InfoCard) -> String {
        switch card {
        case .tokenJourney:
            return "Your prompt went from \(startTokens) to \(finalTokens) tokens across 5 stages. Fewer tokens = lower API costs and faster responses. Each token costs real money at scale."
        case .conversationCost:
            return "The vague starting prompt would need ~\(badExchanges) exchanges to get a good answer (~\(badPromptConversationCost) tokens). Your optimized prompt does it in 1 exchange (~\(goodPromptConversationCost) tokens) — a \(costSavings)% saving."
        case .metrics:
            return "You saved \(exchangesSaved) follow-up rounds — that's \(exchangesSaved) fewer AI responses generated, less energy used, less waiting. Your prompt quality score of \(accuracyEstimate)% reflects how many best-practice checks you passed across all 5 stages."
        }
    }
}

private struct MetricCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
            Text(value)
                .font(.headline.monospaced())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }
}
