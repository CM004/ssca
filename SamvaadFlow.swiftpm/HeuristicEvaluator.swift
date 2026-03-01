//
//  HeuristicEvaluator.swift
//  The Living Prompt Tree
//
//  Created by Chandramohan on 26/02/26.
//
//  Offline, rule-based fallback evaluator used when Foundation Models
//  are unavailable (simulator, Apple Intelligence disabled, parse failure).
//  Conforms to the same PromptEvaluatorProtocol as FoundationModelEvaluator.
//

import Foundation

// MARK: - HeuristicEvaluator
/// Rule-based prompt evaluator that works entirely offline.
/// Each level has bespoke heuristics that approximate the Foundation Model's judgment.
final class HeuristicEvaluator: PromptEvaluatorProtocol {

    /// Passing score threshold.
    private let passingScore = 60

    func evaluate(
        userPrompt: String,
        originalPrompt: String?,
        level: LevelData
    ) async throws -> EvaluationResult {
        switch level.id {
        case 1:  return evaluateClarity(userPrompt)
        case 2:  return evaluateStructure(userPrompt)
        case 3:  return evaluateEfficiency(userPrompt, original: originalPrompt)
        case 4:  return evaluateContext(userPrompt, original: originalPrompt)
        case 5:  return evaluateSafety(userPrompt)
        default: return fallbackResult()
        }
    }

    // MARK: - Level 1 — Clarity

    /// Checks for clear intent, defined audience, and specific scope.
    private func evaluateClarity(_ prompt: String) -> EvaluationResult {
        let lower = prompt.lowercased()
        let words = prompt.split(separator: " ")
        let wordCount = words.count

        var score = 0
        var issues: [String] = []
        var suggestions: [String] = []

        // 1. Word count threshold — prompts under 10 words are almost always vague
        if wordCount > 10 {
            score += 20
        } else {
            issues.append("Prompt is very short (\(wordCount) words)")
            suggestions.append("Expand your prompt to at least 10 words with specific details")
        }

        // 2. Intent keywords — verbs/prepositions that signal a clear ask
        let intentKeywords = ["for", "in", "to", "about", "explain", "summarize",
                              "list", "describe", "compare", "analyze", "create",
                              "generate", "write", "draft", "provide"]
        let intentHits = intentKeywords.filter { lower.contains($0) }
        if intentHits.count >= 2 {
            score += 25
        } else if intentHits.count == 1 {
            score += 15
            suggestions.append("Add more specificity — what exactly should the AI do?")
        } else {
            issues.append("No clear intent detected")
            suggestions.append("Start with an action verb like 'Explain', 'Summarize', or 'List'")
        }

        // 3. Audience indicators
        let audienceKeywords = ["for a", "for the", "aimed at", "suitable for",
                                "targeted at", "designed for", "patient", "student",
                                "beginner", "expert", "doctor", "child", "year-old"]
        let hasAudience = audienceKeywords.contains { lower.contains($0) }
        if hasAudience {
            score += 25
        } else {
            issues.append("No target audience specified")
            suggestions.append("Specify who the response is for (e.g., 'for a beginner', 'for a 56-year-old patient')")
        }

        // 4. Scope indicators — specifics that narrow the output
        let scopeKeywords = ["including", "include", "covering", "such as",
                             "specifically", "bullet", "points", "steps",
                             "top", "main", "key", "within", "between"]
        let hasScope = scopeKeywords.contains { lower.contains($0) }
        if hasScope {
            score += 20
        } else {
            issues.append("Scope is too broad")
            suggestions.append("Define boundaries (e.g., 'in 3 bullet points', 'covering X, Y, Z')")
        }

        // 5. Bonus for question specificity (contains specific nouns/numbers)
        let containsNumbers = prompt.range(of: #"\d+"#, options: .regularExpression) != nil
        if containsNumbers {
            score += 10
        }

        score = min(score, 100)

        let feedback: String
        if score >= passingScore {
            feedback = "Good clarity! Your prompt has a clear intent" +
                       (hasAudience ? ", a defined audience" : "") +
                       (hasScope ? ", and a specific scope." : ".")
        } else {
            feedback = "Your prompt needs more clarity. Try specifying what you want, who it's for, and what it should cover."
        }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    // MARK: - Level 2 — Structure

    /// Checks for role, task, constraints, and output format markers.
    private func evaluateStructure(_ prompt: String) -> EvaluationResult {
        let lower = prompt.lowercased()

        var score = 0
        var issues: [String] = []
        var suggestions: [String] = []

        // Role indicator
        let roleKeywords = ["you are", "as a", "act as", "role:", "your role"]
        let hasRole = roleKeywords.contains { lower.contains($0) }
        if hasRole {
            score += 25
        } else {
            issues.append("No role defined")
            suggestions.append("Begin with 'You are a [role]' to set expertise context")
        }

        // Task verb
        let taskVerbs = ["determine", "draft", "write", "create", "analyze",
                         "evaluate", "generate", "summarize", "calculate",
                         "review", "prepare", "develop", "assess", "check"]
        let hasTask = taskVerbs.contains { lower.contains($0) }
        if hasTask {
            score += 25
        } else {
            issues.append("Task is unclear")
            suggestions.append("State the task clearly with an action verb (e.g., 'Determine...', 'Draft...')")
        }

        // Constraint keywords
        let constraintKeywords = ["only", "exactly", "must", "within", "max",
                                  "minimum", "at most", "at least", "limit",
                                  "no more than", "based on", "using", "following"]
        let hasConstraints = constraintKeywords.contains { lower.contains($0) }
        if hasConstraints {
            score += 25
        } else {
            issues.append("Missing constraints")
            suggestions.append("Add constraints like word count, data inputs, or specific rules to follow")
        }

        // Output format
        let formatKeywords = ["table", "bullet", "list", "json", "format",
                              "yes/no", "structured", "report", "summary",
                              "paragraph", "csv", "columns", "rows"]
        let hasOutputFormat = formatKeywords.contains { lower.contains($0) }
        if hasOutputFormat {
            score += 25
        } else {
            issues.append("Output format not specified")
            suggestions.append("Specify the desired format: table, bullet points, JSON, YES/NO, etc.")
        }

        let partsFound = [hasRole, hasTask, hasConstraints, hasOutputFormat].filter { $0 }.count
        let feedback: String
        if partsFound == 4 {
            feedback = "Excellent structure! Your prompt covers role, task, constraints, and output format."
        } else {
            feedback = "Your prompt has \(partsFound)/4 structural components. Add the missing parts for a complete prompt."
        }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    // MARK: - Level 3 — Efficiency

    /// Compares word count of original vs. edited prompt; passes if reduced ≥25% with core keywords retained.
    private func evaluateEfficiency(_ prompt: String, original: String?) -> EvaluationResult {
        guard let original = original, !original.isEmpty else {
            return EvaluationResult(
                score: 50,
                passed: false,
                feedback: "No original prompt to compare against.",
                detectedIssues: ["Original prompt missing"],
                suggestions: ["Provide an original prompt for efficiency comparison"]
            )
        }

        let originalWords = original.split(separator: " ")
        let editedWords = prompt.split(separator: " ")
        let originalCount = originalWords.count
        let editedCount = editedWords.count

        guard originalCount > 0 else {
            return fallbackResult()
        }

        let reductionPercent = Double(originalCount - editedCount) / Double(originalCount) * 100.0

        // Core keyword retention — check if important nouns/verbs from the original survive
        let coreKeywords = extractCoreKeywords(from: original)
        let retainedKeywords = coreKeywords.filter { prompt.lowercased().contains($0) }
        let retentionRate = coreKeywords.isEmpty ? 1.0 : Double(retainedKeywords.count) / Double(coreKeywords.count)

        var score = 0
        var issues: [String] = []
        var suggestions: [String] = []

        // Word reduction scoring
        if reductionPercent >= 40 {
            score += 50
        } else if reductionPercent >= 25 {
            score += 35
        } else if reductionPercent >= 10 {
            score += 20
            suggestions.append("Try to reduce at least 25% of the words")
        } else {
            issues.append("Word count barely reduced (\(String(format: "%.0f", reductionPercent))%)")
            suggestions.append("Remove filler words, redundant phrases, and unnecessary qualifiers")
        }

        // Keyword retention scoring
        if retentionRate >= 0.8 {
            score += 40
        } else if retentionRate >= 0.5 {
            score += 25
            suggestions.append("Some key terms were lost — make sure the core meaning is preserved")
        } else {
            score += 10
            issues.append("Too many core keywords were removed")
            suggestions.append("Keep essential nouns and verbs from the original prompt")
        }

        // Bonus for conciseness without losing structure
        if editedCount > 5 && editedCount <= originalCount {
            score += 10
        }

        score = min(score, 100)

        let feedback: String
        if score >= passingScore {
            feedback = "Great compression! Reduced by \(String(format: "%.0f", reductionPercent))% while retaining \(String(format: "%.0f", retentionRate * 100))% of core meaning."
        } else {
            feedback = "The prompt needs more trimming — aim for at least 25% word reduction without losing key information."
        }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    /// Extracts lowercase keywords (≥4 chars) from a prompt, excluding common stop words.
    private func extractCoreKeywords(from text: String) -> [String] {
        let stopWords: Set<String> = [
            "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "shall", "can", "this", "that", "these",
            "those", "with", "from", "into", "through", "during", "before",
            "after", "above", "below", "between", "about", "each", "every",
            "some", "any", "most", "other", "more", "also", "than", "then",
            "very", "just", "only", "and", "but", "not", "for", "your", "their"
        ]
        return text.lowercased()
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count >= 4 && !stopWords.contains($0) }
    }

    // MARK: - Level 4 — Context

    /// Detects whether meaningful context was added without excessive bloat.
    private func evaluateContext(_ prompt: String, original: String?) -> EvaluationResult {
        let lower = prompt.lowercased()
        let words = prompt.split(separator: " ")
        let wordCount = words.count

        var score = 0
        var issues: [String] = []
        var suggestions: [String] = []

        // 1. Meaningful nouns/specifics added (numbers, ages, budgets, domains)
        let containsNumbers = prompt.range(of: #"\d+"#, options: .regularExpression) != nil
        let contextIndicators = ["year-old", "years", "budget", "capital", "risk",
                                 "horizon", "income", "salary", "experience",
                                 "history", "symptoms", "data", "report",
                                 "portfolio", "patient", "customer", "client"]
        let contextHits = contextIndicators.filter { lower.contains($0) }

        if containsNumbers {
            score += 20
        }

        if contextHits.count >= 2 {
            score += 25
        } else if contextHits.count == 1 {
            score += 15
            suggestions.append("Add more specific context — numbers, timeframes, or constraints")
        } else {
            issues.append("No meaningful context detected")
            suggestions.append("Include relevant details like age, budget, timeline, or domain")
        }

        // 2. Role context
        let roleKeywords = ["you are", "as a", "act as", "senior", "expert", "specialist"]
        let hasRole = roleKeywords.contains { lower.contains($0) }
        if hasRole {
            score += 20
        }

        // 3. Example indicators (one-shot / few-shot)
        let exampleKeywords = ["for example", "such as", "e.g.", "like", "for instance",
                               "example:", "sample:", "given the following"]
        let hasExamples = exampleKeywords.contains { lower.contains($0) }
        if hasExamples {
            score += 15
        }

        // 4. Penalize excessive prompt size (>3× original)
        if let original = original {
            let originalCount = original.split(separator: " ").count
            if originalCount > 0 && wordCount > originalCount * 3 {
                score -= 15
                issues.append("Prompt grew more than 3× the original — that's excessive")
                suggestions.append("Strip out irrelevant background; keep only what changes the AI's answer")
            }
        }

        // 5. Baseline for having a reasonable length
        if wordCount >= 10 {
            score += 15
        }

        // 6. Bonus for constraint/specificity
        if lower.contains("include") || lower.contains("cover") || lower.contains("mention") {
            score += 5
        }

        score = max(0, min(score, 100))

        let feedback: String
        if score >= passingScore {
            feedback = "Good context! You've added relevant, minimal details that ground the AI's response."
        } else {
            feedback = "Your prompt needs more precise context — think: what specific information would change the AI's answer?"
        }

        return EvaluationResult(
            score: score,
            passed: score >= passingScore,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    // MARK: - Level 5 — Safety / Privacy

    /// Uses regex to detect PII: phone numbers, emails, API keys, credit cards.
    private func evaluateSafety(_ prompt: String) -> EvaluationResult {
        var detectedItems: [String] = []
        var issues: [String] = []

        // Phone numbers: 10 consecutive digits or international format
        let phonePatterns = [
            #"\b\d{10}\b"#,
            #"\+\d{1,3}[\s-]\d{10}"#,
            #"\b\d{3}[\s-]\d{3}[\s-]\d{4}\b"#
        ]
        for pattern in phonePatterns {
            if let _ = prompt.range(of: pattern, options: .regularExpression) {
                detectedItems.append("Phone number")
                issues.append("Phone number detected — replace with [Phone number removed]")
                break
            }
        }

        // Email addresses
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        if let _ = prompt.range(of: emailPattern, options: .regularExpression) {
            detectedItems.append("Email address")
            issues.append("Email address detected — replace with [Email removed]")
        }

        // API keys (sk-..., Bearer tokens)
        let apiKeyPatterns = [
            #"sk-[a-zA-Z0-9]{20,}"#,
            #"Bearer [a-zA-Z0-9]{20,}"#,
            #"api[_-]?key\s*[:=]\s*\S+"#
        ]
        for pattern in apiKeyPatterns {
            if let _ = prompt.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                detectedItems.append("API key or token")
                issues.append("API key/token detected — replace with [API key removed]")
                break
            }
        }

        // Credit card numbers (4 groups of 4 digits)
        let ccPattern = #"\b\d{4}[\s-]\d{4}[\s-]\d{4}[\s-]\d{4}\b"#
        if let _ = prompt.range(of: ccPattern, options: .regularExpression) {
            detectedItems.append("Credit card number")
            issues.append("Credit card number detected — replace with [Card number removed]")
        }

        // Personal names followed by common PII context (heuristic)
        let namePattern = #"\b(customer|user|client|patient)\s+[A-Z][a-z]+\s+[A-Z][a-z]+"#
        if let _ = prompt.range(of: namePattern, options: .regularExpression) {
            detectedItems.append("Personal name")
            issues.append("Personal name detected — remove or anonymize")
        }

        let isSafe = detectedItems.isEmpty
        let score = isSafe ? 100 : max(0, 100 - (detectedItems.count * 25))

        var suggestions: [String] = []
        if !isSafe {
            suggestions.append("Replace all sensitive data with placeholders like [REDACTED]")
            suggestions.append("Ask: does the AI actually need this personal info to help?")
        }

        let feedback: String
        if isSafe {
            feedback = "Prompt is safe! No personally identifiable information detected."
        } else {
            feedback = "Found \(detectedItems.count) privacy risk(s): \(detectedItems.joined(separator: ", ")). Redact before sending to any AI."
        }

        return EvaluationResult(
            score: score,
            passed: isSafe,
            feedback: feedback,
            detectedIssues: issues,
            suggestions: suggestions
        )
    }

    // MARK: - Fallback

    private func fallbackResult() -> EvaluationResult {
        EvaluationResult(
            score: 50,
            passed: false,
            feedback: "Unable to evaluate this prompt with the current rules.",
            detectedIssues: ["Unknown level or insufficient data"],
            suggestions: ["Try editing the prompt and submitting again"]
        )
    }
}
