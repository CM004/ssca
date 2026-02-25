//
//  LevelConfig.swift
//  The Living Prompt Tree
//
//  Created by Chandramohan on 26/02/26.
//

import Foundation

// MARK: - Domain Enum
/// The professional domain from which a prompt example originates.
enum Domain: String, Sendable, CaseIterable, Codable {
    case healthcare
    case finance
    case customerService
    case general
}

// MARK: - PromptTechnique Enum
/// The 5 core prompt-engineering techniques taught across levels.
enum PromptTechnique: String, Sendable, CaseIterable, Codable {
    /// "You are a senior cardiologist. Analyze the ECG report..."
    case rolePrompting
    /// "Generate a discharge summary including diagnosis, treatment, medications..."
    case taskPrompting
    /// "Given the patient's symptoms (listed below), suggest possible causes."
    case contextPrompting
    /// "Explain asthma management in exactly 5 bullet points."
    case constraintPrompting
    /// "Present results in a table with columns: Metric, Value, Risk Level."
    case outputFormatting
    /// "Help me debug this Python function. [API key removed]"
    case privacySafety
}

// MARK: - PromptExample
/// A single bad → good prompt transformation with explanation.
struct PromptExample: Sendable, Identifiable {
    let id = UUID()
    /// The original, flawed prompt.
    let badPrompt: String
    /// The improved, well-engineered prompt.
    let goodPrompt: String
    /// Why the good version is better.
    let explanation: String
    /// The professional domain this example belongs to.
    let domain: Domain
    /// Which technique the improvement primarily demonstrates.
    let techniqueUsed: PromptTechnique
    /// Optional structural blocks for Level 2 (Structure).
    let structureBlocks: [String]?
}

// MARK: - LevelData
/// Complete configuration for a single level of the Living Prompt Tree.
struct LevelData: Sendable, Identifiable {
    let id: Int
    /// Natural element associated with this level (Air, Water, Sunlight, Soil, Nutrients).
    let elementName: String
    /// The prompt-engineering principle taught.
    let principle: String
    /// Narrative metaphor connecting the element to the principle.
    let metaphor: String
    /// Why the tree element is "broken" at the start of this level.
    let brokenReason: String
    /// What the user must do to repair the tree element.
    let userTask: String
    /// Description of the visual feedback when the level is completed.
    let visualFeedback: String
    /// The exact system prompt sent to Foundation Models for evaluation.
    let systemEvaluationPrompt: String
    /// All prompt examples for this level.
    let examples: [PromptExample]
}

// MARK: - LevelDataStore
/// Static repository of all 5 level configurations with real curriculum data.
enum LevelDataStore {

    /// All levels in order. Access by index (0-based) or use `level(for:)`.
    static let allLevels: [LevelData] = [
        airLevel,
        waterLevel,
        sunlightLevel,
        soilLevel,
        nutrientsLevel
    ]

    /// Retrieve a level by its 1-based ID.
    static func level(for id: Int) -> LevelData? {
        allLevels.first { $0.id == id }
    }

    // MARK: - Level 1 — AIR (Clarity)

    private static let airLevel = LevelData(
        id: 1,
        elementName: "Air",
        principle: "Clarity",
        metaphor: "Like clean air, a clear prompt lets the AI breathe and think without confusion.",
        brokenReason: "Prompt is vague and ambiguous — the AI has no idea what you actually need.",
        userTask: "Add clear intent, define a target audience, and specify the scope of the response.",
        visualFeedback: "Misty haze clears from the tree canopy, revealing crisp blue sky and gently swaying branches.",
        systemEvaluationPrompt: """
            Evaluate if this rewritten prompt has clear intent, a defined target audience, and a specific scope. \
            Respond with JSON: {"score": 0-100, "hasClearIntent": bool, "hasAudience": bool, "hasScope": bool, "feedback": "string"}
            """,
        examples: [
            PromptExample(
                badPrompt: "Summarize the patient file.",
                goodPrompt: "Summarize the patient's medical history, current symptoms, lab results, and recommended treatment plan in bullet points.",
                explanation: "The improved prompt specifies exactly which sections to summarize and what format to use, producing a far more accurate and useful medical summary.",
                domain: .healthcare,
                techniqueUsed: .taskPrompting,
                structureBlocks: nil
            ),
            PromptExample(
                badPrompt: "What should I do for diabetes?",
                goodPrompt: "Explain diabetes management in simple language for a 56-year-old patient. Include diet, exercise, medication, and daily monitoring tips.",
                explanation: "Adding the audience (56-year-old patient), scope (diet, exercise, medication, monitoring), and tone (simple language) transforms a vague question into actionable medical guidance.",
                domain: .healthcare,
                techniqueUsed: .taskPrompting,
                structureBlocks: nil
            ),
            PromptExample(
                badPrompt: "Tell me about climate change.",
                goodPrompt: "Explain the top 3 causes of climate change and their environmental impact in a short paragraph suitable for a high school student.",
                explanation: "The story mode intro prompt from Julie — originally vague, it now has scope (top 3 causes), format (short paragraph), and audience (high school student).",
                domain: .general,
                techniqueUsed: .taskPrompting,
                structureBlocks: nil
            )
        ]
    )

    // MARK: - Level 2 — WATER (Structure)

    private static let waterLevel = LevelData(
        id: 2,
        elementName: "Water",
        principle: "Structure",
        metaphor: "Like water flowing through channels, a structured prompt guides the AI along a clear path from input to output.",
        brokenReason: "Prompt is an unstructured blob — the AI doesn't know what role to play, what task to do, what constraints to follow, or what format to output.",
        userTask: "Arrange prompt blocks into the correct structure: Role → Task → Constraints → Output Format.",
        visualFeedback: "Crystal-clear streams begin flowing down the tree's trunk, filling the roots with glowing blue water.",
        systemEvaluationPrompt: """
            Does this instruction clearly define a role, a task, constraints, and expected output format? \
            Respond with JSON: {"score": 0-100, "hasRole": bool, "hasTask": bool, "hasConstraints": bool, "hasOutputFormat": bool, "feedback": "string"}
            """,
        examples: [
            PromptExample(
                badPrompt: "Check if customer is eligible.",
                goodPrompt: "Based on the following data—age, income, credit score, existing loans, repayment history—determine if the customer is eligible for a home loan. Present the result in YES/NO format with justification.",
                explanation: "The structured prompt defines the data inputs, the decision task, and the output format, leaving no ambiguity about what the AI should produce.",
                domain: .finance,
                techniqueUsed: .constraintPrompting,
                structureBlocks: [
                    "Role: Senior loan analyst",
                    "Task: Determine home loan eligibility",
                    "Constraints: Use age/income/credit score/loan history",
                    "Output: YES/NO with justification"
                ]
            ),
            PromptExample(
                badPrompt: "Write the report.",
                goodPrompt: "Draft a quarterly financial performance report for ABC Pvt Ltd covering revenue, expenses, profit/loss, key trends, and recommendations. Keep it within 200 words.",
                explanation: "Adding the company context, specific sections to cover, and a word-count constraint transforms a vague instruction into a precise, actionable task.",
                domain: .finance,
                techniqueUsed: .outputFormatting,
                structureBlocks: [
                    "Role: Senior financial analyst",
                    "Task: Draft Q3 financial report",
                    "Constraints: Max 200 words, cover revenue/expenses/profit",
                    "Output: Structured report"
                ]
            )
        ]
    )

    // MARK: - Level 3 — SUNLIGHT (Efficiency)

    private static let sunlightLevel = LevelData(
        id: 3,
        elementName: "Sunlight",
        principle: "Efficiency",
        metaphor: "Like focused sunlight, an efficient prompt delivers maximum energy with minimum waste.",
        brokenReason: "Prompt wastes words and tokens — it's bloated, repetitive, and costs more to process than necessary.",
        userTask: "Trim redundant words while preserving the core meaning. Target at least 25% word reduction.",
        visualFeedback: "Golden sunbeams break through the clouds and illuminate the tree's leaves, making them glow with warm light.",
        systemEvaluationPrompt: """
            Compare the original and compressed prompts. Does the compressed version fully preserve the original meaning? \
            Respond with JSON: {"meaningPreserved": bool, "compressionQuality": 0-100, "feedback": "string"}
            """,
        examples: [
            PromptExample(
                badPrompt: "Write a reply to customer.",
                goodPrompt: "Draft a polite apology email informing the customer that their delivery is delayed due to a logistics issue. Offer a 10% discount coupon and mention the new expected delivery date.",
                explanation: "The original has only 5 words and zero structure. The efficient version is longer but every word carries meaning — tone, reason, compensation, and timeline are all specified. Efficiency means maximum info per token, not fewest words.",
                domain: .customerService,
                techniqueUsed: .taskPrompting,
                structureBlocks: nil
            ),
            PromptExample(
                badPrompt: "Explain the fraud case.",
                goodPrompt: "Summarize the fraud pattern by listing suspicious transactions, time of occurrence, transaction frequency, and unusual device/location information.",
                explanation: "Instead of a vague 'explain', the efficient prompt uses a single verb (summarize) and lists exactly 4 data points to cover, eliminating ambiguity with zero wasted tokens.",
                domain: .customerService,
                techniqueUsed: .constraintPrompting,
                structureBlocks: nil
            ),
            PromptExample(
                badPrompt: "Update the report.",
                goodPrompt: "Update the patient's daily progress report by adding the following details: temperature, blood pressure, sugar level, medications administered, and nurse observations.",
                explanation: "Every additional word in the improved version carries specific, necessary information. The token investment is justified by the precision of the output.",
                domain: .healthcare,
                techniqueUsed: .taskPrompting,
                structureBlocks: nil
            )
        ]
    )

    // MARK: - Level 4 — SOIL (Context)

    private static let soilLevel = LevelData(
        id: 4,
        elementName: "Soil",
        principle: "Context",
        metaphor: "Like rich soil feeding the roots, the right context nourishes the AI's understanding and grounds its response in reality.",
        brokenReason: "Prompt lacks essential background information, or overshares irrelevant details that confuse the AI.",
        userTask: "Add only essential context — age, goal, budget, domain role — and include one-shot or few-shot examples where appropriate.",
        visualFeedback: "Dark, cracked earth around the roots transforms into rich, glowing soil teeming with nutrients and tiny sparks of life.",
        systemEvaluationPrompt: """
            Is the added context in this prompt relevant and appropriately minimal — not excessive, not missing? \
            Respond with JSON: {"score": 0-100, "isRelevant": bool, "isExcessive": bool, "isSufficient": bool, "feedback": "string"}
            """,
        examples: [
            PromptExample(
                badPrompt: "Suggest investments.",
                goodPrompt: "Suggest a low-risk investment portfolio for a 35-year-old investor with ₹10 lakhs capital and a 5-year horizon. Include stocks, mutual funds, and fixed-income options.",
                explanation: "Adding minimal but essential context — age (35), budget (₹10 lakhs), risk tolerance (low), and horizon (5 years) — lets the AI give a tailored, actionable recommendation instead of generic advice.",
                domain: .finance,
                techniqueUsed: .contextPrompting,
                structureBlocks: nil
            ),
            PromptExample(
                badPrompt: "Analyze the ECG report.",
                goodPrompt: "You are a senior cardiologist. Analyze the ECG report and highlight any abnormalities.",
                explanation: "Adding a role context ('senior cardiologist') makes the AI respond with domain-specific precision and clinical terminology rather than generic observations.",
                domain: .healthcare,
                techniqueUsed: .rolePrompting,
                structureBlocks: nil
            )
        ]
    )

    // MARK: - Level 5 — NUTRIENTS (Safety / Privacy)

    private static let nutrientsLevel = LevelData(
        id: 5,
        elementName: "Nutrients",
        principle: "Safety",
        metaphor: "Like filtering toxins from nutrients, safe prompting removes sensitive data before feeding information to the AI.",
        brokenReason: "Prompt leaks personal data — API keys, phone numbers, emails, or other PII — putting the user at risk.",
        userTask: "Redact all PII (API keys, phone numbers, email addresses, tokens) and reframe the prompt safely without losing its purpose.",
        visualFeedback: "Toxic purple particles dissolve from the tree's roots, replaced by glowing green nutrient streams that pulse with healthy energy.",
        systemEvaluationPrompt: """
            Does this prompt contain any personally identifiable information such as names, phone numbers, email addresses, API keys, or tokens? \
            Respond with JSON: {"containsPII": bool, "detectedItems": ["string"], "isSafe": bool, "feedback": "string"}
            """,
        examples: [
            PromptExample(
                badPrompt: "My API key is sk-abc123xyz, my phone is 9876543210, help me debug this code.",
                goodPrompt: "Help me debug this Python function. [API key removed] [Phone number removed]",
                explanation: "The API key and phone number are stripped and replaced with safe placeholders. The AI can still help debug without ever seeing sensitive credentials.",
                domain: .general,
                techniqueUsed: .privacySafety,
                structureBlocks: nil
            ),
            PromptExample(
                badPrompt: "Check order status for Order ID #45892 for customer John Doe, email john@gmail.com.",
                goodPrompt: "Check order status for Order ID #45892. Provide current location, expected delivery date, and any delay reasons.",
                explanation: "The customer's name and email are unnecessary for checking an order status — removing them protects privacy while preserving the functional query.",
                domain: .customerService,
                techniqueUsed: .privacySafety,
                structureBlocks: nil
            )
        ]
    )
}
