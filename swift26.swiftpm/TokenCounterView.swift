//
//  TokenCounterView.swift
//  The Living Prompt Tree
//
//  Animated word/token counter bar showing original count, current count,
//  and percentage change.
//

import SwiftUI

/// Animated token counter showing original vs. current word count and percentage change.
struct TokenCounterView: View {
    let originalCount: Int
    let currentCount: Int

    private var changePercent: Double {
        guard originalCount > 0 else { return 0 }
        return Double(currentCount - originalCount) / Double(originalCount) * 100
    }

    private var isReduced: Bool { currentCount < originalCount }

    var body: some View {
        HStack(spacing: 16) {
            // Original
            VStack(spacing: 2) {
                Text("Original")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.charcoal.opacity(0.5))
                Text("\(originalCount)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.charcoal)
                    .contentTransition(.numericText())
            }

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.charcoal.opacity(0.3))

            // Current
            VStack(spacing: 2) {
                Text("Current")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.charcoal.opacity(0.5))
                Text("\(currentCount)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(isReduced ? Theme.safeGreen : Theme.amber)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Percentage badge
            HStack(spacing: 3) {
                Image(systemName: isReduced ? "arrow.down" : "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                Text("\(abs(Int(changePercent)))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .foregroundColor(isReduced ? Theme.safeGreen : Theme.dangerRed)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        isReduced
                            ? Theme.safeGreen.opacity(0.15)
                            : Theme.dangerRed.opacity(0.15)
                    )
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.parchment)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.warmBrown.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .animation(Theme.springAnim, value: currentCount)
    }
}

//
//  EvaluationHelper.swift
//  Shared evaluation helper used by all level views.
//

/// Runs evaluation using FoundationModelEvaluator first, falling back to HeuristicEvaluator.
func runEvaluation(
    userPrompt: String,
    originalPrompt: String?,
    level: LevelData
) async -> EvaluationResult {
    if #available(iOS 26, *) {
        let fmEvaluator = FoundationModelEvaluator()
        do {
            return try await fmEvaluator.evaluate(
                userPrompt: userPrompt,
                originalPrompt: originalPrompt,
                level: level
            )
        } catch {
            // Fall through to heuristic
        }
    }

    let heuristic = HeuristicEvaluator()
    do {
        return try await heuristic.evaluate(
            userPrompt: userPrompt,
            originalPrompt: originalPrompt,
            level: level
        )
    } catch {
        return EvaluationResult(
            score: 0, passed: false,
            feedback: "Evaluation failed. Please try again.",
            detectedIssues: ["Evaluation error"],
            suggestions: ["Edit your prompt and retry"]
        )
    }
}
