//
//  AppState.swift
//  The Living Prompt Tree
//
//  Created by Chandramohan on 26/02/26.
//

import Foundation
import SwiftUI

// MARK: - AppState
/// Central observable state for the Living Prompt Tree app.
/// Tracks level completion, token savings, clarity scores, and environmental impact.
/// All progress is automatically persisted to UserDefaults.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Constants

    /// Energy consumed per token in kWh (industry estimate for on-device inference).
    static let kWhPerToken: Double = 0.0000004
    /// CO₂ emissions per kWh in kg (global average grid intensity).
    static let kgCO2PerKWh: Double = 0.233

    private enum DefaultsKey {
        static let currentLevel       = "lpt_currentLevel"
        static let completedLevels    = "lpt_completedLevels"
        static let totalTokensSaved   = "lpt_totalTokensSaved"
        static let totalEnergySaved   = "lpt_totalEnergySaved"
        static let clarityHistory     = "lpt_clarityScoreHistory"
        static let privacyRisksRemoved = "lpt_privacyRisksRemoved"
        static let promptHistory       = "lpt_promptHistory"
    }

    // MARK: - Published Properties

    /// The level the user is currently working on (1–5).
    @Published var currentLevel: Int {
        didSet { save() }
    }

    /// Set of level IDs the user has successfully completed.
    @Published var completedLevels: Set<Int> {
        didSet { save() }
    }

    /// Cumulative count of tokens saved by writing efficient prompts.
    @Published var totalTokensSaved: Int {
        didSet { save() }
    }

    /// Cumulative energy saved in kWh (derived from token savings).
    @Published var totalEnergySaved: Double {
        didSet { save() }
    }

    /// History of clarity scores achieved across all attempts.
    @Published var clarityScoreHistory: [Int] {
        didSet { save() }
    }

    /// Number of privacy/PII risks the user has successfully removed.
    @Published var privacyRisksRemoved: Int {
        didSet { save() }
    }

    /// Snapshot of user prompts as they progress through levels.
    @Published var promptHistory: [String] {
        didSet { save() }
    }

    /// Scratch prompt the user is currently editing in a level.
    @Published var userPrompt: String = ""

    // MARK: - Computed Properties

    /// Overall completion progress from 0.0 to 1.0 across all 5 levels.
    var overallProgress: Double {
        Double(completedLevels.count) / 5.0
    }

    /// Whether the user has cleared all 5 levels.
    var isAllComplete: Bool {
        completedLevels.count >= 5
    }

    /// Estimated carbon saved in kg CO₂, derived from cumulative token savings.
    /// Formula: tokens × kWh/token × kgCO₂/kWh
    var estimatedCarbonSaved: Double {
        Double(totalTokensSaved) * Self.kWhPerToken * Self.kgCO2PerKWh
    }

    /// Average clarity score across all recorded attempts, or 0 if none.
    var averageClarityScore: Int {
        guard !clarityScoreHistory.isEmpty else { return 0 }
        return clarityScoreHistory.reduce(0, +) / clarityScoreHistory.count
    }

    // MARK: - Initializer

    init() {
        let defaults = UserDefaults.standard
        self.currentLevel        = defaults.integer(forKey: DefaultsKey.currentLevel) == 0
                                   ? 1 : defaults.integer(forKey: DefaultsKey.currentLevel)
        let savedLevels          = defaults.array(forKey: DefaultsKey.completedLevels) as? [Int] ?? []
        self.completedLevels     = Set(savedLevels)
        self.totalTokensSaved    = defaults.integer(forKey: DefaultsKey.totalTokensSaved)
        self.totalEnergySaved    = defaults.double(forKey: DefaultsKey.totalEnergySaved)
        self.clarityScoreHistory = defaults.array(forKey: DefaultsKey.clarityHistory) as? [Int] ?? []
        self.privacyRisksRemoved = defaults.integer(forKey: DefaultsKey.privacyRisksRemoved)
        self.promptHistory       = defaults.stringArray(forKey: DefaultsKey.promptHistory) ?? []
    }

    // MARK: - Public Methods

    /// Record the completion of a level.
    /// - Parameters:
    ///   - level: Level number (1–5) that was completed.
    ///   - tokensSaved: Tokens saved in this level attempt.
    ///   - clarityScore: Clarity score (0–100) achieved.
    func completeLevel(_ level: Int, tokensSaved: Int, clarityScore: Int) {
        completedLevels.insert(level)
        totalTokensSaved += tokensSaved
        totalEnergySaved += Double(tokensSaved) * Self.kWhPerToken
        clarityScoreHistory.append(clarityScore)

        // Advance to the next level if available
        if level >= currentLevel && level < 5 {
            currentLevel = level + 1
        }
    }

    /// Record the removal of privacy risks (Level 5).
    /// - Parameter count: Number of PII items removed.
    func recordPrivacyRisksRemoved(_ count: Int) {
        privacyRisksRemoved += count
    }

    /// Reset all progress to initial state.
    func resetProgress() {
        currentLevel = 1
        completedLevels = []
        totalTokensSaved = 0
        totalEnergySaved = 0.0
        clarityScoreHistory = []
        privacyRisksRemoved = 0
        promptHistory = []
        userPrompt = ""
        clearDefaults()
    }

    // MARK: - Persistence

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(currentLevel, forKey: DefaultsKey.currentLevel)
        defaults.set(Array(completedLevels), forKey: DefaultsKey.completedLevels)
        defaults.set(totalTokensSaved, forKey: DefaultsKey.totalTokensSaved)
        defaults.set(totalEnergySaved, forKey: DefaultsKey.totalEnergySaved)
        defaults.set(clarityScoreHistory, forKey: DefaultsKey.clarityHistory)
        defaults.set(privacyRisksRemoved, forKey: DefaultsKey.privacyRisksRemoved)
        defaults.set(promptHistory, forKey: DefaultsKey.promptHistory)
    }

    private func clearDefaults() {
        let defaults = UserDefaults.standard
        for key in [
            DefaultsKey.currentLevel,
            DefaultsKey.completedLevels,
            DefaultsKey.totalTokensSaved,
            DefaultsKey.totalEnergySaved,
            DefaultsKey.clarityHistory,
            DefaultsKey.privacyRisksRemoved,
            DefaultsKey.promptHistory
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}
