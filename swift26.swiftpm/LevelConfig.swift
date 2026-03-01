//
//  LevelConfig.swift
//  The Living Prompt Tree
//
//  Hardcoded Climate Change curriculum data for all 5 stages.
//

import Foundation

// MARK: - Stage Data

/// Configuration for one stage of the prompt tree.
struct StageConfig {
    let id: Int
    let emoji: String
    let element: String
    let principle: String
    let conceptText: String
    let techniqueNames: [String]
    let systemEvaluationPrompt: String
}

/// Backwards-compatible alias for evaluator files.
typealias LevelData = StageConfig

// MARK: - Stage 1 Blocks

struct DragBlock: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: BlockType
    let emoji: String

    enum BlockType: String, Hashable {
        case role
        case task
        case distractor
    }
}

// MARK: - Stage 2 Reorder Items

struct ReorderItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let category: String
    let correctPosition: Int
}

// MARK: - Stage 5 PII Item

struct PIITarget: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: String  // "institution", "email", "identifier", "safe"
    let isPII: Bool   // true = must redact, false = safe keyword (decoy)
}

// MARK: - Domain Config Struct

struct DomainConfig {
    let startingPrompt: String
    var startingTokens: Int {
        startingPrompt.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    // Stage 1
    let stage1Blocks: [DragBlock]
    let stage1ResultPrompt: String

    // Stage 2
    let stage2Items: [ReorderItem]
    let stage2ResultPrompt: String

    // Stage 3
    let stage3Words: [String]
    let stage3RedundantIndices: Set<Int>
    let stage3TargetRange: ClosedRange<Int>
    let stage3OvercompressedThreshold: Int
    let stage3ResultPrompt: String

    // Stage 4
    let stage4ContextPlaceholder: String
    let stage4ExampleInput: String
    let stage4ExampleOutput: String
    let stage4ResultPrompt: String

    // Stage 5
    let stage5UnsafePrompt: String
    let stage5PIITargets: [PIITarget]
    let stage5Constraints: [(label: String, defaultOn: Bool)]
    let stage5FinalPrompt: String
}

// MARK: - Curriculum Data Store

enum Curriculum {

    static let stages: [StageConfig] = [
        StageConfig(
            id: 1, emoji: "🌬️", element: "Air", principle: "Clarity",
            conceptText: "Air allows ideas to breathe.\n\nWhen a prompt has no clear intent, the AI inhales fog. It cannot understand WHO it is and WHAT it must do.",
            techniqueNames: ["Role-Based Prompting", "Task-Based Prompting"],
            systemEvaluationPrompt: "Evaluate if this prompt has clear intent, a defined role, and a specific task verb. Respond with JSON: {\"hasRole\": bool, \"hasTask\": bool, \"hasFillerPhrase\": bool, \"feedback\": \"string\"}"
        ),
        StageConfig(
            id: 2, emoji: "💧", element: "Water", principle: "Structure",
            conceptText: "Water flows — but only if it has a channel.\n\nThe prompt has a role and task now but no structure. You need to organize it so the AI knows the order of operations.",
            techniqueNames: ["Structured Prompting"],
            systemEvaluationPrompt: "Evaluate if this prompt follows Role→Task→Audience→Constraint→OutputFormat structure. Respond with JSON: {\"score\": 0-100, \"hasStructure\": bool, \"feedback\": \"string\"}"
        ),
        StageConfig(
            id: 3, emoji: "☀️", element: "Sunlight", principle: "Efficiency",
            conceptText: "Sunlight is limited energy. The sun is blocked because of too many words.\n\nThe prompt is now correct but bloated. You must trim every redundant word without losing meaning.\n\nRedundant words cost real money and real time — across millions of requests.",
            techniqueNames: ["Keyword Extraction", "Symbol Compression"],
            systemEvaluationPrompt: "Evaluate if this prompt is efficiently compressed using symbols (& → [] {} | @ : ~ ! +) without losing meaning. Respond with JSON: {\"meaningPreserved\": bool, \"symbolsEffective\": bool, \"feedback\": \"string\"}"
        ),
        StageConfig(
            id: 4, emoji: "🌍", element: "Soil", principle: "Context",
            conceptText: "Soil gives grounding.\n\nA prompt with no context asks the AI to grow in mid-air. It needs a real-world anchor: Why is this being asked? In what situation? \n\nYou can also give an example or few and also tell AI how to think (step by step, chain of thought)",
            techniqueNames: ["Context-Based Prompting", "Example as contex", "AI Thinking" ],
            systemEvaluationPrompt: "Evaluate if this prompt has real-world context and a one-shot example. Respond with JSON: {\"score\": 0-100, \"hasContext\": bool, \"hasExample\": bool, \"feedback\": \"string\"}"
        ),
        StageConfig(
            id: 5, emoji: "🛡️", element: "Nutrients", principle: "Safety & Privacy",
            conceptText: "Nutrients are invisible — but without them, the tree becomes weak, disease prone and toxic.\n\nA prompt can look complete but still leak private data or invite unsafe responses.",
            techniqueNames: ["Constraint-Based Prompting", "Output-Scoped Prompting"],
            systemEvaluationPrompt: "Evaluate if this prompt has PII removed and safety constraints added. Respond with JSON: {\"score\": 0-100, \"hasPII\": bool, \"hasConstraints\": bool, \"feedback\": \"string\"}"
        )
    ]

    static func stage(for id: Int) -> StageConfig? {
        stages.first { $0.id == id }
    }

    // MARK: - Dashboard Data
    static let badPromptTokenCost = 303 // 4 repair exchanges
    static let goodPromptTokenCost = 136 // 1 clean exchange

    // MARK: - Domains

    static let education = DomainConfig(
        startingPrompt: "Tell me something about climate change.",
        stage1Blocks: [
            DragBlock(text: "You are a science educator", type: .role, emoji: "🎓"),
            DragBlock(text: "Explain the main causes and effects", type: .task, emoji: "📋"),
            DragBlock(text: "Could you please maybe help me understand", type: .distractor, emoji: "💬"),
            DragBlock(text: "I was wondering if you could possibly", type: .distractor, emoji: "✍️")
        ],
        stage1ResultPrompt: "You are a science educator. Explain the main causes and effects of climate change.",
        stage2Items: [
            ReorderItem(text: "You are a science educator", category: "Role", correctPosition: 0),
            ReorderItem(text: "Explain the main causes and effects of climate change", category: "Task", correctPosition: 1),
            ReorderItem(text: "for a high school student", category: "Audience", correctPosition: 2),
            ReorderItem(text: "focusing on environmental and economic impacts", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use bullet points", category: "Output Format", correctPosition: 4)
        ],
        stage2ResultPrompt: "You are a science educator. Explain the main causes and effects of climate change for a high school student, focusing on environmental and economic impacts. Use bullet points.",
        stage3Words: [
            "You", "are", "a", "science", "educator", ".",
            "Explain", "the", "main", "causes", "and",
            "effects", "of", "climate", "change", "for",
            "a", "high", "school", "student", ",",
            "focusing", "on", "environmental", "and",
            "economic", "impacts", ".", "Use", "bullet",
            "points", "."
        ],
        stage3RedundantIndices: [0, 1, 2, 7, 10, 11, 12, 21, 22, 28],
        stage3TargetRange: 20...26,
        stage3OvercompressedThreshold: 16,
        stage3ResultPrompt: "Role: science educator. Explain climate change causes & effects for high schoolers: environmental & economic impacts → bullet points.",
        stage4ContextPlaceholder: "For a Grade 10 science revision worksheet.",
        stage4ExampleInput: "Explain deforestation causes.",
        stage4ExampleOutput: "• Cause 1: Agricultural expansion\n• Cause 2: Logging\n• Effect: Loss of biodiversity",
        stage4ResultPrompt: """
        Role: science educator. Context: Grade 10 revision worksheet. Explain climate change causes & effects for high schoolers: environmental & economic impacts → bullet points.
        Example:
        Input: Explain deforestation causes.
        Output: • Cause 1 / Cause 2 / Effect
        """,
        stage5UnsafePrompt: """
        Role: science educator at Greenfield High School (teacher: mrs.sharma@greenfield.edu). Context: Grade 10 revision for student ID #4521. Explain climate change causes & effects for high schoolers: environmental & economic impacts → bullet points. Keep response under 150 words. Use scientific consensus only.
        """,
        stage5PIITargets: [
            PIITarget(text: "Greenfield High School", type: "institution", isPII: true),
            PIITarget(text: "mrs.sharma@greenfield.edu", type: "email", isPII: true),
            PIITarget(text: "student ID #4521", type: "identifier", isPII: true),
            PIITarget(text: "science educator", type: "role", isPII: false),
            PIITarget(text: "climate change", type: "topic", isPII: false),
            PIITarget(text: "Grade 10", type: "context", isPII: false),
            PIITarget(text: "150 words", type: "constraint", isPII: false),
            PIITarget(text: "bullet points", type: "format", isPII: false)
        ],
        stage5Constraints: [
            ("Keep response under 150 words", true),
            ("Use only established scientific consensus", true),
            ("Avoid speculation", false)
        ],
        stage5FinalPrompt: """
        Role: science educator. Context: Grade 10 revision worksheet. Explain climate change causes & effects for high schoolers: environmental & economic impacts → bullet points. Keep response under 150 words. Use scientific consensus only.
        Example:
        Input: Explain deforestation causes.
        Output: • Cause 1 / Cause 2 / Effect
        """
    )

    static let healthcare = DomainConfig(
        startingPrompt: "Write something about a patient.",
        stage1Blocks: [
            DragBlock(text: "You are a clinical documentation assistant", type: .role, emoji: "🩺"),
            DragBlock(text: "Write a discharge summary", type: .task, emoji: "📝"),
            DragBlock(text: "tell me about what happened with", type: .distractor, emoji: "💬"),
            DragBlock(text: "help me write something", type: .distractor, emoji: "✍️")
        ],
        stage1ResultPrompt: "You are a clinical documentation assistant. Write a discharge summary for a patient.",
        stage2Items: [
            ReorderItem(text: "You are a clinical documentation assistant", category: "Role", correctPosition: 0),
            ReorderItem(text: "Write a discharge summary", category: "Task", correctPosition: 1),
            ReorderItem(text: "for the referring physician", category: "Audience", correctPosition: 2),
            ReorderItem(text: "covering diagnosis, treatment given, and follow-up plan", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use structured sections with headers", category: "Output Format", correctPosition: 4)
        ],
        stage2ResultPrompt: "You are a clinical documentation assistant. Write a discharge summary for the referring physician, covering diagnosis, treatment given, and follow-up plan. Use structured sections with headers.",
        stage3Words: [
            "You", "are", "a", "clinical", "documentation", "assistant", ".", 
            "Write", "a", "discharge", "summary", "for", 
            "the", "referring", "physician", ",", "covering", 
            "diagnosis", ",", "treatment", "given", ",", "and", 
            "follow-up", "plan", ".", "Use", "structured", 
            "sections", "with", "headers", "."
        ],
        stage3RedundantIndices: [0, 1, 2, 8, 12, 16, 20, 22, 26, 29], // Removes "You are a", "a", "the", "covering", "given", "and", "Use", "with"
        stage3TargetRange: 16...24,
        stage3OvercompressedThreshold: 12,
        stage3ResultPrompt: "Role: clinical documentation assistant. Draft discharge summary for referring physician: diagnosis, treatment, follow-up plan → structured headers.",
        stage4ContextPlaceholder: "Patient: 45-year-old, post-appendectomy, 2-day stay",
        stage4ExampleInput: "Knee replacement discharge.",
        stage4ExampleOutput: "## Diagnosis / ## Treatment / ## Follow-up",
        stage4ResultPrompt: """
        Role: clinical documentation assistant.
        Context: 45-year-old patient, post-appendectomy, 2-day stay, no complications.
        Draft discharge summary for referring physician: diagnosis, treatment, follow-up plan → structured headers.
        Example format:
          Input: Knee replacement discharge.
          Output: ## Diagnosis / ## Treatment / ## Follow-up
        """,
        stage5UnsafePrompt: """
        Role: clinical documentation assistant.
        Context: Patient: John Mehta, DOB 12/03/1979, ID #MH4521, Ward 3B, post-appendectomy, 2-day stay, no complications.
        Attending: Dr. Priya Nair (priya.nair@apollo.in).
        Draft discharge summary for referring physician: diagnosis, treatment, follow-up plan → structured headers.
        Example format:
          Input: Knee replacement discharge.
          Output: ## Diagnosis / ## Treatment / ## Follow-up
        """,
        stage5PIITargets: [
            PIITarget(text: "John Mehta", type: "name", isPII: true),
            PIITarget(text: "DOB 12/03/1979", type: "date", isPII: true),
            PIITarget(text: "ID #MH4521", type: "identifier", isPII: true),
            PIITarget(text: "Ward 3B", type: "location", isPII: true),
            PIITarget(text: "priya.nair@apollo.in", type: "email", isPII: true),
            PIITarget(text: "post-appendectomy", type: "context", isPII: false),
            PIITarget(text: "discharge summary", type: "task", isPII: false),
            PIITarget(text: "structured headers", type: "format", isPII: false)
        ],
        stage5Constraints: [
            ("Do not speculate on diagnosis.", true),
            ("Use only provided clinical facts.", true),
            ("Keep summary under 200 words.", true)
        ],
        stage5FinalPrompt: """
        Role: clinical documentation assistant.
        Context: 45-year-old patient, post-appendectomy, 2-day inpatient stay, no complications. Attending: [Attending Physician].
        Draft discharge summary for referring physician: diagnosis, treatment, follow-up plan → structured headers.
        Do not speculate. Use only provided facts. Max 200 words.
        Example format:
          Input: Knee replacement discharge.
          Output: ## Diagnosis / ## Treatment / ## Follow-up
        """
    )
    
    static func get(domain: String) -> DomainConfig {
        return domain.lowercased() == "healthcare" ? healthcare : education
    }
}
