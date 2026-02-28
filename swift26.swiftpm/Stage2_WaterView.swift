//
//  Stage2_WaterView.swift
//  The Living Prompt Tree
//
//  Stage 2 — Water · Structure — Clean iOS native.
//  Live preview reflects user's block order. LLM evaluates structure.
//

import SwiftUI
import FoundationModels

struct Stage2_WaterView: View {

    @EnvironmentObject var appState: AppState
    private let config = Curriculum.stage(for: 2)!

    @State private var items: [ReorderItem] = []
    @State private var isEvaluating = false
    @State private var result: StageScore? = nil
    @State private var userHasReordered = false
    @State private var showConfetti = false

    private var assembledPrompt: String {
        items.map(\.text).joined(separator: " ") + "."
    }
    private var assembledTokens: Int {
        assembledPrompt.split(separator: " ").count
    }
    private var isCorrectOrder: Bool {
        items.enumerated().allSatisfy { $0.element.correctPosition == $0.offset }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                techniques
                Text(config.conceptText).font(.body).foregroundStyle(.secondary)
                Divider()

                // Current prompt
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current prompt (from Stage 1)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(appState.currentPrompt)
                        .font(.callout.monospaced())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                    Label("Missing: audience, output format, depth constraint", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Divider()

                Text("Arrange the blocks in the correct structural order.")
                    .font(.headline)

                // Correct order hint
                HStack(spacing: 6) {
                    ForEach(["Role", "Task", "Audience", "Constraint", "Output"], id: \.self) { (cat: String) in
                        Text(cat).font(.caption2.weight(.medium))
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(.fill.tertiary, in: Capsule())
                    }
                }

                // Reorder list
                VStack(spacing: 4) {
                    ForEach(items) { item in
                        reorderRow(item: item)
                    }
                }

                // Preview — shows user's current arrangement
                promptPreview

                if items.count == 5, userHasReordered { evaluateButton }

                if let result = result {
                    EvaluationResultView(
                        emoji: "💧", title: "Water Structure Score",
                        score: result, ctaLabel: "Continue to Stage 3 : Sunlight"
                    ) {
                        appState.completeStage(2, newPrompt: Curriculum.stage2ResultPrompt, score: result)
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
        .navigationTitle("Water — Structure")
        .onAppear { if items.isEmpty { items = Curriculum.stage2Items.shuffled() } }
    }

    // MARK: - Helpers

    private var techniques: some View {
        HStack(spacing: 6) {
            ForEach(config.techniqueNames, id: \.self) { (t: String) in
                Text(t).font(.caption.weight(.medium))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
    }

    private func reorderRow(item: ReorderItem) -> some View {
        let index = items.firstIndex(where: { $0.id == item.id }) ?? 0
        let isCorrectSpot = item.correctPosition == index

        return HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.caption).foregroundStyle(.tertiary)

            Text(item.category)
                .font(.caption.weight(.bold))
                .foregroundStyle(isCorrectSpot ? .green : .orange)
                .frame(width: 70, alignment: .leading)

            Text(item.text)
                .font(.subheadline)
                .lineLimit(2)

            Spacer()

            VStack(spacing: 2) {
                Button {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        moveItem(at: idx, direction: -1)
                    }
                } label: {
                    Image(systemName: "chevron.up").font(.caption2.weight(.bold))
                }
                .disabled(index == 0)
                Button {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        moveItem(at: idx, direction: 1)
                    }
                } label: {
                    Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                }
                .disabled(index == items.count - 1)
            }
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCorrectSpot ? Color.green.opacity(0.06) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCorrectSpot ? Color.green.opacity(0.3) : Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    private var promptPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Prompt Preview")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(assembledPrompt)
                .font(.callout.monospaced())
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))

            Label("\(assembledTokens) tokens", systemImage: "number")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
    }

    private var evaluateButton: some View {
        Button {
            Task { await evaluate() }
        } label: {
            HStack(spacing: 8) {
                if isEvaluating { ProgressView() }
                Text(isEvaluating ? "Evaluating…" : "Confirm for Evaluation")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.green)
        .disabled(isEvaluating)
    }

    private func moveItem(at index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < items.count else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items.swapAt(index, newIndex)
            userHasReordered = true
        }
    }

    private func evaluate() async {
        isEvaluating = true

        // Heuristic checks
        let userCategories = items.map(\.category)
        let correctOrder = ["Role", "Task", "Audience", "Constraint", "Output Format"]
        let orderMatches = userCategories == correctOrder

        let roleIdx = items.firstIndex { $0.category == "Role" }
        let taskIdx = items.firstIndex { $0.category == "Task" }
        let roleBeforeTask: Bool = {
            guard let r = roleIdx, let t = taskIdx else { return false }
            return r < t
        }()

        var checks: [(String, Bool)] = [
            ("Role before Task", roleBeforeTask),
            ("Audience after Task", {
                guard let t = taskIdx, let a = items.firstIndex(where: { $0.category == "Audience" }) else { return false }
                return a > t
            }()),
            ("Output format last", items.last?.category == "Output Format"),
            ("Perfect order", orderMatches),
        ]
        var feedback = orderMatches ? "Structure complete. Now trim it." : "Almost — check the block order."

        // Try Foundation Model evaluation
        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let evalPrompt = """
                Compare these two prompts:
                User's prompt: "\(assembledPrompt)"
                Correct prompt: "\(Curriculum.stage2ResultPrompt)"
                Evaluate if the user's prompt follows Role→Task→Audience→Constraint→OutputFormat structure.
                Respond with JSON: {"orderCorrect": true/false, "feedback": "one sentence"}
                """
                let response = try await session.respond(to: evalPrompt)
                let text = response.content
                if let data = text.data(using: String.Encoding.utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let fb = json["feedback"] as? String { feedback = fb }
                    if let correct = json["orderCorrect"] as? Bool {
                        checks[3] = ("LLM: Order correct", correct)
                    }
                }
            } catch { }
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
