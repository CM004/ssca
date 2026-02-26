//
//  AppState.swift
//  The Living Prompt Tree
//
//  Central state for the stage-based prompt evolution flow.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {

    // MARK: - Stage Navigation

    /// Current stage: 0 = intro, 1–5 = stages, 6 = dashboard
    @Published var currentStage: Int = 0

    /// Stages the user has completed.
    @Published var completedStages: Set<Int> = []

    // MARK: - Prompt Evolution

    /// The prompt that evolves through all 5 stages.
    @Published var currentPrompt: String = "Tell me something about climate change."

    /// Token count snapshot after each stage. Index 0 = starting prompt.
    @Published var tokenHistory: [Int] = [8]

    // MARK: - Domain

    @Published var selectedDomain: String = "Education"

    // MARK: - Stage Scores

    @Published var stageScores: [Int: StageScore] = [:]

    // MARK: - Computed

    var currentTokenCount: Int {
        currentPrompt.split(separator: " ").count
    }

    var isAllComplete: Bool {
        completedStages.count >= 5
    }

    var overallProgress: Double {
        Double(completedStages.count) / 5.0
    }

    // MARK: - Actions

    func completeStage(_ stage: Int, newPrompt: String, score: StageScore) {
        completedStages.insert(stage)
        currentPrompt = newPrompt
        tokenHistory.append(newPrompt.split(separator: " ").count)
        stageScores[stage] = score

        // Auto-advance to next stage
        if stage < 5 {
            currentStage = stage + 1
        } else {
            currentStage = 6 // Dashboard
        }
    }

    func goToStage(_ stage: Int) {
        // Can go to completed stages or the next unlocked one
        let nextUnlocked = (completedStages.max() ?? 0) + 1
        if completedStages.contains(stage) || stage <= nextUnlocked || stage == 0 {
            currentStage = stage
        }
        // Dashboard requires all 5
        if stage == 6 && isAllComplete {
            currentStage = 6
        }
    }

    func isStageUnlocked(_ stage: Int) -> Bool {
        if stage == 0 { return true }
        if stage == 6 { return isAllComplete }
        let nextUnlocked = (completedStages.max() ?? 0) + 1
        return completedStages.contains(stage) || stage <= nextUnlocked
    }

    func reset() {
        currentStage = 0
        completedStages = []
        currentPrompt = "Tell me something about climate change."
        tokenHistory = [8]
        stageScores = [:]
    }
}

// MARK: - StageScore

struct StageScore {
    let checks: [(label: String, passed: Bool)]
    let total: Int
    let earned: Int
    let feedback: String

    var label: String { "\(earned)/\(total)" }
}
