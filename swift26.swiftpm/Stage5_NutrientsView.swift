//
//  Stage5_NutrientsView.swift
//  The Living Prompt Tree
//
//  Stage 5 — Nutrients · Safety & Privacy
//  The "unsafe prompt" = Stage 4 prompt with PII injected by Julie.
//  Items list contains both real PII and safe keywords extracted from the prompt.
//  User must identify which are truly sensitive.
//

import SwiftUI

struct Stage5_NutrientsView: View {

    @EnvironmentObject var appState: AppState
    private let config = Curriculum.stage(for: 5)!
    private var domainConfig: DomainConfig { Curriculum.get(domain: appState.selectedDomain) }

    @State private var originalUnsafePrompt: String = ""
    @State private var shuffledItems: [PIITarget] = []
    @State private var selectedItems: Set<UUID> = []
    @State private var constraints: [(label: String, isOn: Bool)] = []
    @State private var isEvaluating = false
    @State private var result: StageScore? = nil
    @State private var showConfetti = false
    @State private var showConstraintBuilder = false
    @State private var wrongSelections: Set<UUID> = []
    @StateObject private var speech = SpeechManager()

    private var speakText: String {
        "Stage 5: Nutrients, Safety. \(config.conceptText) Oops! Someone added sensitive info to the prompt. The prompt from Stage 4 now contains personal data that should never be sent to an AI. Find and remove it. Tap items that should not be sent to an AI. Be careful, not everything is sensitive! You can also add output constraints."
    }

    // Build the "unsafe" prompt = Stage 4 prompt with PII injected
    private var unsafePrompt: String {
        var p = appState.currentPrompt
        let isHealthcare = appState.selectedDomain.lowercased() == "healthcare"
        let isLegal = appState.selectedDomain.lowercased() == "legal"

        if isHealthcare {
            if p.lowercased().contains("context:") {
                p = p.replacingOccurrences(
                    of: "Context:",
                    with: "Context: Patient: John Mehta, DOB 12/03/1979, ID #MH4521, Ward 3B,"
                )
            } else {
                p = "Patient: John Mehta, DOB 12/03/1979, ID #MH4521, Ward 3B. " + p
            }
            if let lastDot = p.lastIndex(of: ".") {
                p.insert(contentsOf: " Attending: Dr. Priya Nair (priya.nair@apollo.in).", at: p.index(after: lastDot))
            } else {
                p += " Attending: Dr. Priya Nair (priya.nair@apollo.in)."
            }
        } else if isLegal {
            if p.lowercased().contains("context:") {
                p = p.replacingOccurrences(
                    of: "Context:",
                    with: "Context: Client: Arjun Mehta, Founder, NovaPay Pvt. Ltd. (CIN: U72900MH2021PTC123456). Deal value: ₹48L/yr."
                )
            } else {
                p = "Client: Arjun Mehta, Founder, NovaPay Pvt. Ltd. (CIN: U72900MH2021PTC123456). Deal value: ₹48L/yr. " + p
            }
            if let lastDot = p.lastIndex(of: ".") {
                p.insert(contentsOf: " Contract signed by: cfo@novapay.in.", at: p.index(after: lastDot))
            } else {
                p += " Contract signed by: cfo@novapay.in."
            }
        } else {
            // Inject institution + email after "educator" or "Role:"
            if p.lowercased().contains("educator") {
                p = p.replacingOccurrences(
                    of: "educator",
                    with: "educator at Greenfield High School (teacher: mrs.sharma@greenfield.edu)"
                )
            }
            // Inject student ID after "Context:" or before audience
            if p.lowercased().contains("context:") {
                p = p.replacingOccurrences(
                    of: "Context:",
                    with: "Context: for student ID #4521."
                )
            } else if p.lowercased().contains("grade") {
                p = p.replacingOccurrences(
                    of: "Grade",
                    with: "for student ID #4521. Grade"
                )
            } else {
                p += " for student ID #4521."
            }
        }
        return p
    }

    // Build items dynamically from the actual prompt + PII
    private func buildItems() -> [PIITarget] {
        var items: [PIITarget] = []
        let promptText = unsafePrompt.lowercased()

        for target in domainConfig.stage5PIITargets {
            if target.isPII {
                items.append(target)
            } else {
                if promptText.contains(target.text.lowercased()) {
                    items.append(target)
                }
            }
        }

        // Ensure at least a few decoys
        if items.filter({ !$0.isPII }).isEmpty {
            if appState.selectedDomain.lowercased() == "healthcare" {
                items.append(PIITarget(text: "discharge summary", type: "task", isPII: false))
                items.append(PIITarget(text: "structured headers", type: "format", isPII: false))
            } else if appState.selectedDomain.lowercased() == "legal" {
                items.append(PIITarget(text: "SaaS vendor agreement", type: "context", isPII: false))
                items.append(PIITarget(text: "numbered risk list", type: "format", isPII: false))
            } else {
                items.append(PIITarget(text: "explain", type: "task verb", isPII: false))
                items.append(PIITarget(text: "environmental", type: "topic detail", isPII: false))
            }
        }

        return items
    }

    private var piiItems: [PIITarget] { shuffledItems.filter(\.isPII) }
    private var piiCount: Int { piiItems.count }

    private var correctlyRedacted: Int {
        selectedItems.filter { id in piiItems.contains { $0.id == id } }.count
    }
    private var falsePositives: Int {
        selectedItems.filter { id in shuffledItems.first { $0.id == id }?.isPII == false }.count
    }
    private var allPIIFound: Bool { correctlyRedacted >= piiCount && falsePositives == 0 }

    private var displayPrompt: String {
        var text = unsafePrompt
        for item in piiItems {
            if selectedItems.contains(item.id) {
                let masked = String(repeating: "█", count: item.text.count)
                text = text.replacingOccurrences(of: item.text, with: masked)
            }
        }
        return text
    }

    /// Final safe prompt = Stage 4 prompt (no PII) + constraints
    private var finalSafePrompt: String {
        var p = appState.currentPrompt
        let activeConstraints = constraints.filter(\.isOn).map(\.label)
        if !activeConstraints.isEmpty {
            p += " " + activeConstraints.joined(separator: ". ") + "."
        }
        return p
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                techniques
                Text(config.conceptText).font(.body).foregroundStyle(.secondary)
                Divider()

                // Narrative
                VStack(alignment: .leading, spacing: 6) {
                    Text("Oops! Someone added sensitive info to the prompt.")
                        .font(.headline)
                    Text("The prompt from Stage 4 now contains personal data that should never be sent to an AI. Find and remove it.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                // Unsafe prompt display
                VStack(alignment: .leading, spacing: 8) {
                    Label("Unsafe version detected", systemImage: "exclamationmark.shield.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)

                    Text(displayPrompt)
                        .font(.callout.monospaced())
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.red.opacity(0.2), lineWidth: 1))
                }

                // Tap-to-redact — shuffled mix
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tap items that should NOT be sent to an AI:")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("Be careful — not everything is sensitive!")
                        .font(.caption).foregroundStyle(.orange)

                    ForEach(shuffledItems) { item in
                        itemRow(item: item)
                    }

                    HStack {
                        Text("\(correctlyRedacted)/\(piiCount) personal information items found")
                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        if falsePositives > 0 {
                            Text("• \(falsePositives) false positive\(falsePositives == 1 ? "" : "s")")
                                .font(.caption.weight(.semibold)).foregroundStyle(.red)
                        }
                    }
                }

                // Constraint builder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add output constraints:")
                        .font(.subheadline.weight(.medium))

                    ForEach(Array(constraints.enumerated()), id: \.offset) { idx, constraint in
                        Toggle(constraint.label, isOn: Binding(
                            get: { constraints[idx].isOn },
                            set: { constraints[idx].isOn = $0 }
                        ))
                        .font(.subheadline)
                        .tint(.green)
                    }
                }

                // Final prompt
                if correctlyRedacted >= piiCount {
                    finalPromptPreview
                }

                // Evaluate — shows once PII items are found (constraints optional)
                if correctlyRedacted >= piiCount {
                    evaluateButton
                }

                if let result = result {
                    EvaluationResultView(
                        emoji: "🛡️", title: "Nutrients Safety Score",
                        score: result, ctaLabel: "View Dashboard"
                    ) {
                        appState.completeStage(5, newPrompt: finalSafePrompt, score: result)
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
        .navigationTitle("Nutrients — Safety")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SpeakerButton(speech: speech, text: speakText)
            }
        }
        .onDisappear { speech.stop() }
        .onAppear {
            if originalUnsafePrompt.isEmpty {
                originalUnsafePrompt = domainConfig.stage5UnsafePrompt
                constraints = domainConfig.stage5Constraints.map { ($0.label, $0.defaultOn) }
            }
            if shuffledItems.isEmpty {
                shuffledItems = buildItems().shuffled()
            }
        }
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

    private func itemRow(item: PIITarget) -> some View {
        let isSelected = selectedItems.contains(item.id)
        let isWrong = wrongSelections.contains(item.id)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedItems.remove(item.id)
                    wrongSelections.remove(item.id)
                } else {
                    selectedItems.insert(item.id)
                    if !item.isPII {
                        wrongSelections.insert(item.id)
                    }
                    if allPIIFound { showConstraintBuilder = true }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? (isWrong ? "xmark.circle.fill" : "checkmark.circle.fill") : "circle")
                    .foregroundStyle(isSelected ? (isWrong ? .red : .green) : Color.gray.opacity(0.3))

                VStack(alignment: .leading, spacing: 1) {
                    Text(isSelected && item.isPII ? String(repeating: "█", count: item.text.count) : item.text)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(isSelected && item.isPII ? .secondary : .primary)
                    Text(item.type)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if isWrong {
                    Text("Safe — keep this!")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isWrong ? Color.red.opacity(0.04) : isSelected && item.isPII ? Color.green.opacity(0.04) : Color(.secondarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isWrong ? Color.red.opacity(0.3) : isSelected && item.isPII ? Color.green.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
    }

    private var finalPromptPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Final Safe Prompt", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
            Text(finalSafePrompt)
                .font(.callout.monospaced())
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.green.opacity(0.2), lineWidth: 1))
            Label("\(finalSafePrompt.split(separator: " ").count) tokens", systemImage: "number")
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
        // Start nutrient flow animation immediately
        appState.completedStages.insert(5)
        let hasWordLimit = constraints.first { $0.label.contains("150") }?.isOn ?? false
        let activeConstraints = constraints.filter(\.isOn).count
        let noFalsePositives = falsePositives == 0
        let checks: [(String, Bool)] = [
            ("All Personal info found", correctlyRedacted >= piiCount),
            ("No false positives", noFalsePositives),
            ("At least 1 output constraint", activeConstraints >= 1),
            ("Word limit constraint", hasWordLimit),
        ]
        let earned = checks.filter(\.1).count
        let score = StageScore(
            checks: checks.map { (label: $0.0, passed: $0.1) },
            total: checks.count, earned: earned,
            feedback: earned >= 3 ? "Safe, bounded, responsible. The tree is whole." : "Some safety issues remain."
        )
        await MainActor.run {
            withAnimation { result = score }
            isEvaluating = false
        }
    }
}
