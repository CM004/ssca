//
//  FoundationModelEvaluator.swift
//  The Living Prompt Tree
//
//  Created by Chandramohan on 26/02/26.
//
//  Uses Apple's on-device Foundation Models (iOS 26+) to evaluate user prompts.
//  Falls back to HeuristicEvaluator when the model is unavailable or parsing fails.
//

import Foundation
import FoundationModels

// MARK: - EvaluationResult
/// The outcome of evaluating a user-written prompt against a level's criteria.
struct EvaluationResult: Sendable {
    /// Score from 0 to 100.
    let score: Int
    /// Whether the user passed this level's threshold (≥ 60).
    let passed: Bool
    /// Human-readable feedback explaining the evaluation.
    let feedback: String
    /// Specific issues detected in the prompt.
    let detectedIssues: [String]
    /// Actionable suggestions for improvement.
    let suggestions: [String]
}

// MARK: - PromptEvaluatorProtocol
/// Shared contract for both on-device model and heuristic evaluators.
protocol PromptEvaluatorProtocol: Sendable {
    /// Evaluate the user's prompt against a level's criteria.
    /// - Parameters:
    ///   - userPrompt: The prompt the user wrote or edited.
    ///   - originalPrompt: The original "bad" prompt (used for comparison in efficiency levels).
    ///   - level: The level configuration containing evaluation criteria.
    /// - Returns: An `EvaluationResult` with score, pass/fail, feedback, and suggestions.
    func evaluate(userPrompt: String, originalPrompt: String?, level: LevelData) async throws -> EvaluationResult
}

// MARK: - FoundationModelEvaluator
/// Evaluator powered by Apple's on-device Foundation Models framework (iOS 26+).
/// Sends the level's system evaluation prompt along with the user's input to the model,
/// parses the JSON response, and produces an `EvaluationResult`.
@available(iOS 26, *)
final class FoundationModelEvaluator: PromptEvaluatorProtocol {

    /// Passing score threshold.
    private let passingScore = 60

    /// Check whether Foundation Models are available on this device.
    /// Returns `false` on simulators or when Apple Intelligence is disabled.
    func checkAvailability() -> Bool {
        let model = SystemLanguageModel.default
        return model.availability == .available
    }

    func evaluate(
        userPrompt: String,
        originalPrompt: String?,
        level: LevelData
    ) async throws -> EvaluationResult {
        guard checkAvailability() else {
            // Fall through to heuristic by throwing
            throw EvaluationError.modelUnavailable
        }

        let session = LanguageModelSession()

        // Build the full instruction
        var instruction = level.systemEvaluationPrompt + "\n\n"
        if let original = originalPrompt {
            instruction += "Original prompt: \"\(original)\"\n"
        }
        instruction += "User's prompt: \"\(userPrompt)\""

        let response = try await session.respond(to: instruction)
        let responseText = response.content

        // Attempt to parse JSON from the model's response
        guard let result = parseResponse(responseText, for: level) else {
            throw EvaluationError.jsonParseFailed(rawResponse: responseText)
        }

        return result
    }

    // MARK: - JSON Parsing

    /// Extracts the JSON object from the model's response text and maps it to an `EvaluationResult`.
    private func parseResponse(_ text: String, for level: LevelData) -> EvaluationResult? {
        // Find JSON in the response (model may include surrounding text)
        guard let jsonString = extractJSON(from: text),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        switch level.id {
        case 1: return parseClarityResponse(json)
        case 2: return parseStructureResponse(json)
        case 3: return parseEfficiencyResponse(json)
        case 4: return parseContextResponse(json)
        case 5: return parseSafetyResponse(json)
        default: return nil
        }
    }

    /// Extracts a JSON substring `{...}` from potentially surrounding text.
    private func extractJSON(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        return String(text[start...end])
    }

    // MARK: Level-Specific Parsers

    /// Level 1 — Air (Clarity):  score, hasClearIntent, hasAudience, hasScope
    private func parseClarityResponse(_ json: [String: Any]) -> EvaluationResult {
        let score = json["score"] as? Int ?? 50
        let hasClearIntent = json["hasClearIntent"] as? Bool ?? false
        let hasAudience = json["hasAudience"] as? Bool ?? false
        let hasScope = json["hasScope"] as? Bool ?? false
        let feedback = json["feedback"] as? String ?? "Evaluation complete."

        var issues: [String] = []
        if !hasClearIntent { issues.append("Missing clear intent") }
        if !hasAudience { issues.append("No target audience defined") }
        if !hasScope { issues.append("Scope is too broad or missing") }

        var suggestions: [String] = []
        if !hasClearIntent { suggestions.append("Start with a specific action verb (e.g., 'Explain', 'Summarize', 'List')") }
        if !hasAudience { suggestions.append("Specify who the response is for (e.g., 'for a beginner', 'for a doctor')") }
        if !hasScope { suggestions.append("Define boundaries (e.g., 'in 3 bullet points', 'covering X, Y, Z')") }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    /// Level 2 — Water (Structure): score, hasRole, hasTask, hasConstraints, hasOutputFormat
    private func parseStructureResponse(_ json: [String: Any]) -> EvaluationResult {
        let score = json["score"] as? Int ?? 50
        let hasRole = json["hasRole"] as? Bool ?? false
        let hasTask = json["hasTask"] as? Bool ?? false
        let hasConstraints = json["hasConstraints"] as? Bool ?? false
        let hasOutputFormat = json["hasOutputFormat"] as? Bool ?? false
        let feedback = json["feedback"] as? String ?? "Evaluation complete."

        var issues: [String] = []
        if !hasRole { issues.append("No role defined") }
        if !hasTask { issues.append("Task is unclear") }
        if !hasConstraints { issues.append("Missing constraints") }
        if !hasOutputFormat { issues.append("Output format not specified") }

        var suggestions: [String] = []
        if !hasRole { suggestions.append("Begin with 'You are a [role]' to set expertise") }
        if !hasTask { suggestions.append("State the task clearly with an action verb") }
        if !hasConstraints { suggestions.append("Add limits like word count, scope, or data to use") }
        if !hasOutputFormat { suggestions.append("Specify output format: table, bullet points, JSON, etc.") }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    /// Level 3 — Sunlight (Efficiency): meaningPreserved, compressionQuality
    private func parseEfficiencyResponse(_ json: [String: Any]) -> EvaluationResult {
        let meaningPreserved = json["meaningPreserved"] as? Bool ?? false
        let compressionQuality = json["compressionQuality"] as? Int ?? 50
        let feedback = json["feedback"] as? String ?? "Evaluation complete."

        var issues: [String] = []
        if !meaningPreserved { issues.append("Core meaning was lost during compression") }
        if compressionQuality < 50 { issues.append("Compression quality is low — important details may be missing") }

        var suggestions: [String] = []
        if !meaningPreserved { suggestions.append("Keep all critical keywords and intent; remove only filler words") }
        if compressionQuality < 70 { suggestions.append("Try rephrasing with fewer words while keeping the same specifics") }

        return EvaluationResult(
            score: compressionQuality,
            passed: meaningPreserved && compressionQuality >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    /// Level 4 — Soil (Context): score, isRelevant, isExcessive, isSufficient
    private func parseContextResponse(_ json: [String: Any]) -> EvaluationResult {
        let score = json["score"] as? Int ?? 50
        let isRelevant = json["isRelevant"] as? Bool ?? false
        let isExcessive = json["isExcessive"] as? Bool ?? false
        let isSufficient = json["isSufficient"] as? Bool ?? false
        let feedback = json["feedback"] as? String ?? "Evaluation complete."

        var issues: [String] = []
        if !isRelevant { issues.append("Added context is not relevant to the task") }
        if isExcessive { issues.append("Too much context — the AI may get confused") }
        if !isSufficient { issues.append("Context is still insufficient for an accurate response") }

        var suggestions: [String] = []
        if !isRelevant { suggestions.append("Only include context that directly affects the AI's answer") }
        if isExcessive { suggestions.append("Remove background information that doesn't change the output") }
        if !isSufficient { suggestions.append("Add key details: numbers, dates, audience, or domain specifics") }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    /// Level 5 — Nutrients (Safety/Privacy): containsPII, detectedItems, isSafe
    private func parseSafetyResponse(_ json: [String: Any]) -> EvaluationResult {
        let containsPII = json["containsPII"] as? Bool ?? true
        let detectedItems = json["detectedItems"] as? [String] ?? []
        let isSafe = json["isSafe"] as? Bool ?? false
        let feedback = json["feedback"] as? String ?? "Evaluation complete."

        let score = isSafe ? 100 : max(0, 100 - (detectedItems.count * 25))

        var issues: [String] = []
        if containsPII {
            issues.append("PII detected in prompt")
            issues.append(contentsOf: detectedItems.map { "Found: \($0)" })
        }

        var suggestions: [String] = []
        if containsPII {
            suggestions.append("Replace sensitive data with placeholders like [REDACTED] or [API key removed]")
            suggestions.append("Ask yourself: does the AI need this personal info to answer?")
        }

        return EvaluationResult(
            score: score,
            passed: isSafe && !containsPII,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }
}

// MARK: - EvaluationError
/// Errors that can occur during Foundation Model evaluation.
enum EvaluationError: Error, LocalizedError, Sendable {
    case modelUnavailable
    case jsonParseFailed(rawResponse: String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence is not available on this device. Using offline evaluation."
        case .jsonParseFailed(let raw):
            return "Failed to parse model response. Raw: \(raw.prefix(200))"
        }
    }
}
