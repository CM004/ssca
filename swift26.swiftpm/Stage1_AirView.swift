//
//  Stage1_AirView.swift
//  The Living Prompt Tree
//
//  Stage 1 — Air · Clarity — Clean iOS native design.
//

import SwiftUI
import FoundationModels

struct Stage1_AirView: View {

    @EnvironmentObject var appState: AppState

    private let config = Curriculum.stage(for: 1)!
    private let blocks = Curriculum.stage1Blocks

    @State private var roleSlot: DragBlock? = nil
    @State private var taskSlot: DragBlock? = nil
    @State private var isEvaluating = false
    @State private var result: StageScore? = nil
    @State private var shuffledBlocks: [DragBlock] = []
    @State private var rejectedBlocks: Set<UUID> = []
    @State private var showConfetti = false

    private var assembledPrompt: String {
        var parts: [String] = []
        if let role = roleSlot { parts.append(role.text + ".") }
        if let task = taskSlot { parts.append(task.text + " of climate change.") }
        return parts.isEmpty ? appState.currentPrompt : parts.joined(separator: " ")
    }

    private var assembledTokens: Int {
        assembledPrompt.split(separator: " ").count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                stageHeader

                // Concept
                Text(config.conceptText)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Divider()

                // Broken prompt
                brokenPromptCard

                Divider()

                // Task
                Text("Add a ROLE and a TASK to this prompt.")
                    .font(.headline)

                blockPicker
                dropZones
                promptPreview

                if roleSlot != nil && taskSlot != nil {
                    evaluateButton
                }

                if let result = result {
                    EvaluationResultView(
                        emoji: "🌬️", title: "Air Clarity Score",
                        score: result, ctaLabel: "Continue to Stage 2 : Water"
                    ) {
                        appState.completeStage(1, newPrompt: assembledPrompt, score: result)
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
        .navigationTitle("Air — Clarity")
        .onAppear {
            if shuffledBlocks.isEmpty {
                shuffledBlocks = blocks.shuffled()
            }
        }
    }

    // MARK: - Subviews

    private var stageHeader: some View {
        HStack(spacing: 6) {
            ForEach(config.techniqueNames, id: \.self) { t in
                Text(t)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
    }

    private var brokenPromptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Current prompt", systemImage: "exclamationmark.triangle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)

            Text(Curriculum.startingPrompt)
                .font(.body.monospaced())
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(["No role (who is the AI?)", "No task verb (what should it do?)", "No bounded scope"], id: \.self) { p in
                    Label(p, systemImage: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var blockPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Available blocks (tap to add)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ForEach(shuffledBlocks) { block in
                blockButton(block: block)
            }
        }
    }

    private func blockButton(block: DragBlock) -> some View {
        let isPlaced = (roleSlot?.id == block.id) || (taskSlot?.id == block.id)
        let isRejected = rejectedBlocks.contains(block.id)

        return Button {
            handleBlockTap(block)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isRejected ? "xmark.circle" : "text.quote")
                    .foregroundStyle(isRejected ? .red : .accentColor)

                Text(block.text)
                    .font(.subheadline)
                    .foregroundStyle(isPlaced ? .tertiary : isRejected ? .secondary : .primary)

                Spacer()

                if isRejected {
                    Text("Not a valid block")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                }
            }
            .padding(10)
            .background(
                isRejected ? Color.red.opacity(0.04) : Color(.secondarySystemFill),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isRejected ? Color.red.opacity(0.2) : .clear, lineWidth: 1)
            )
        }
        .disabled(isPlaced || isRejected)
    }

    private var dropZones: some View {
        HStack(spacing: 12) {
            slotView(label: "Role", block: roleSlot) { roleSlot = nil }
            slotView(label: "Task", block: taskSlot) { taskSlot = nil }
        }
    }

    private func slotView(label: String, block: DragBlock?, onRemove: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            if let block = block {
                HStack {
                    Text(block.text)
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.green.opacity(0.3), lineWidth: 1))
            } else {
                Text("Drop \(label) here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(.quaternary)
                    )
            }
        }
        .frame(maxWidth: .infinity)
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

            HStack {
                Label("\(assembledTokens) tokens", systemImage: "number")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)

                if roleSlot != nil || taskSlot != nil {
                    Text("+\(assembledTokens - Curriculum.startingTokens)")
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(.orange.opacity(0.7))
                }
            }
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

    // MARK: - Logic

    private func handleBlockTap(_ block: DragBlock) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if block.type == .distractor {
                rejectedBlocks.insert(block.id)
                return
            }
            if block.type == .role && roleSlot == nil { roleSlot = block }
            else if block.type == .task && taskSlot == nil { taskSlot = block }
        }
    }

    private func evaluate() async {
        isEvaluating = true
        var checks: [(String, Bool)] = heuristicChecks()
        var feedback = "Good start. Audience comes next."

        if #available(iOS 26, *) {
            do {
                let session = LanguageModelSession()
                let prompt = "Evaluate this prompt for clarity. Check if it has: a role, a task verb, and no filler phrases.\nPrompt: \"\(assembledPrompt)\"\nRespond with JSON: {\"hasRole\": true/false, \"hasTask\": true/false, \"hasFillerPhrase\": true/false, \"feedback\": \"one sentence\"}"
                let response = try await session.respond(to: prompt)
                let text = response.content
                if let data = text.data(using: String.Encoding.utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let hasRole = json["hasRole"] as? Bool ?? (roleSlot != nil)
                    let hasTask = json["hasTask"] as? Bool ?? (taskSlot != nil)
                    let noFiller = !(json["hasFillerPhrase"] as? Bool ?? false)
                    feedback = json["feedback"] as? String ?? feedback
                    checks = [("Role defined", hasRole), ("Action verb present", hasTask), ("No filler phrases", noFiller)]
                }
            } catch { }
        }

        let earned = checks.filter(\.1).count
        let score = StageScore(
            checks: checks.map { (label: $0.0, passed: $0.1) },
            total: checks.count, earned: earned,
            feedback: "\(earned >= 3 ? "Air is clearing." : "Keep going.") \(feedback)"
        )
        await MainActor.run {
            withAnimation { result = score }
            isEvaluating = false
        }
    }

    private func heuristicChecks() -> [(String, Bool)] {
        [("Role defined", roleSlot?.type == .role), ("Action verb present", taskSlot?.type == .task), ("No filler phrases", true)]
    }
}
