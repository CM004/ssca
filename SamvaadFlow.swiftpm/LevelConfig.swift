//
//  LevelConfig.swift
//  The Living Prompt Tree
//
//  Domain-aware curriculum data for all 5 stages across 5 domains.
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
    let type: String
    let isPII: Bool
}

// MARK: - Domain Configuration

/// Holds ALL stage data for a single domain.
struct DomainConfig {
    let name: String
    let icon: String
    let startingPrompt: String

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

    var startingTokens: Int {
        startingPrompt
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

// MARK: - Curriculum (Domain Registry)

enum Curriculum {

    // MARK: - All Domains

    static let allDomains = ["Education", "Healthcare", "Legal", "Finance", "Support"]
    static let freeDomains: Set<String> = ["Education"]

    static func config(for domain: String) -> DomainConfig {
        switch domain.lowercased() {
        case "healthcare": return healthcare
        case "legal":      return legal
        case "finance":    return finance
        case "support":    return support
        default:           return education
        }
    }

    // Convenience for backward compat
    static var startingPrompt: String { education.startingPrompt }
    static var startingTokens: Int { education.startingTokens }

    // Stage configs are the same across all domains (the 5 principles don't change)
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

    // Dashboard data
    static let badPromptTokenCost = 303
    static let goodPromptTokenCost = 136

    // MARK: - 🎓 Education (FREE)

    static let education = DomainConfig(
        name: "Education",
        icon: "graduationcap.fill",
        startingPrompt: "Tell me something about climate change.",

        stage1Blocks: [
            DragBlock(text: "You are a science educator", type: .role, emoji: "🎓"),
            DragBlock(text: "Explain the main causes and effects", type: .task, emoji: "📋"),
            DragBlock(text: "Could you please maybe help me understand", type: .distractor, emoji: "💬"),
            DragBlock(text: "I was wondering if you could possibly", type: .distractor, emoji: "✍️"),
        ],
        stage1ResultPrompt: "You are a science educator. Explain the main causes and effects of climate change.",

        stage2Items: [
            ReorderItem(text: "You are a science educator", category: "Role", correctPosition: 0),
            ReorderItem(text: "Explain the main causes and effects of climate change", category: "Task", correctPosition: 1),
            ReorderItem(text: "for a high school student", category: "Audience", correctPosition: 2),
            ReorderItem(text: "focusing on environmental and economic impacts", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use bullet points", category: "Output Format", correctPosition: 4),
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
            PIITarget(text: "bullet points", type: "format", isPII: false),
        ],
        stage5Constraints: [
            ("Keep response under 150 words", true),
            ("Use only established scientific consensus", true),
            ("Avoid speculation", false),
        ],
        stage5FinalPrompt: """
        Role: science educator. Context: Grade 10 revision worksheet. Explain climate change causes & effects for high schoolers: environmental & economic impacts → bullet points. Keep response under 150 words. Use scientific consensus only.
        Example:
        Input: Explain deforestation causes.
        Output: • Cause 1 / Cause 2 / Effect
        """
    )

    // MARK: - 🏥 Healthcare ($2)

    static let healthcare = DomainConfig(
        name: "Healthcare",
        icon: "cross.case.fill",
        startingPrompt: "What should I do about my headache?",

        stage1Blocks: [
            DragBlock(text: "You are a medical triage assistant", type: .role, emoji: "🩺"),
            DragBlock(text: "List possible causes and recommended next steps", type: .task, emoji: "📋"),
            DragBlock(text: "I've been feeling kinda bad lately you know", type: .distractor, emoji: "💬"),
            DragBlock(text: "Can you maybe look into this for me", type: .distractor, emoji: "✍️"),
        ],
        stage1ResultPrompt: "You are a medical triage assistant. List possible causes and recommended next steps for a headache.",

        stage2Items: [
            ReorderItem(text: "You are a medical triage assistant", category: "Role", correctPosition: 0),
            ReorderItem(text: "List possible causes and recommended next steps for a headache", category: "Task", correctPosition: 1),
            ReorderItem(text: "for an adult patient with no prior conditions", category: "Audience", correctPosition: 2),
            ReorderItem(text: "covering tension, migraine, and dehydration causes", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use a numbered list", category: "Output Format", correctPosition: 4),
        ],
        stage2ResultPrompt: "You are a medical triage assistant. List possible causes and recommended next steps for a headache for an adult patient with no prior conditions, covering tension, migraine, and dehydration causes. Use a numbered list.",

        stage3Words: [
            "You", "are", "a", "medical", "triage", "assistant", ".",
            "List", "possible", "causes", "and", "recommended",
            "next", "steps", "for", "a", "headache", "for",
            "an", "adult", "patient", "with", "no", "prior",
            "conditions", ",", "covering", "tension", ",",
            "migraine", ",", "and", "dehydration", "causes", ".",
            "Use", "a", "numbered", "list", "."
        ],
        stage3RedundantIndices: [0, 1, 2, 8, 11, 12, 18, 21, 22, 23, 35, 36],
        stage3TargetRange: 20...28,
        stage3OvercompressedThreshold: 16,
        stage3ResultPrompt: "Role: medical triage assistant. List headache causes & next steps for adult patient: tension, migraine & dehydration → numbered list.",

        stage4ContextPlaceholder: "For an ER walk-in patient presenting with recurring headaches over 3 days.",
        stage4ExampleInput: "Assess chest pain causes.",
        stage4ExampleOutput: "1. Cardiac: angina, MI\n2. Musculoskeletal: strain\n3. GI: acid reflux\nAction: ECG + vitals",
        stage4ResultPrompt: """
        Role: medical triage assistant. Context: ER walk-in, recurring headaches over 3 days. List headache causes & next steps for adult patient: tension, migraine & dehydration → numbered list.
        Example:
        Input: Assess chest pain causes.
        Output: 1. Cardiac / 2. Musculoskeletal / 3. GI → Action
        """,

        stage5UnsafePrompt: """
        Role: medical triage assistant at City General Hospital (doctor: dr.patel@citygeneral.org). Context: ER walk-in for patient MRN #78432, Rahul Mehta, DOB 1985-03-14. List headache causes & next steps for adult patient: tension, migraine & dehydration → numbered list. Keep under 120 words. Use evidence-based guidelines only.
        """,
        stage5PIITargets: [
            PIITarget(text: "City General Hospital", type: "institution", isPII: true),
            PIITarget(text: "dr.patel@citygeneral.org", type: "email", isPII: true),
            PIITarget(text: "MRN #78432", type: "identifier", isPII: true),
            PIITarget(text: "Rahul Mehta", type: "name", isPII: true),
            PIITarget(text: "DOB 1985-03-14", type: "date", isPII: true),
            PIITarget(text: "triage assistant", type: "role", isPII: false),
            PIITarget(text: "headache", type: "topic", isPII: false),
            PIITarget(text: "120 words", type: "constraint", isPII: false),
        ],
        stage5Constraints: [
            ("Keep response under 120 words", true),
            ("Use evidence-based clinical guidelines only", true),
            ("Include disclaimer: not a substitute for professional diagnosis", false),
        ],
        stage5FinalPrompt: """
        Role: medical triage assistant. Context: ER walk-in, recurring headaches over 3 days. List headache causes & next steps for adult patient: tension, migraine & dehydration → numbered list. Keep under 120 words. Use evidence-based guidelines only.
        Example:
        Input: Assess chest pain causes.
        Output: 1. Cardiac / 2. Musculoskeletal / 3. GI → Action
        """
    )

    // MARK: - ⚖️ Legal ($2)

    static let legal = DomainConfig(
        name: "Legal",
        icon: "scalemass.fill",
        startingPrompt: "Tell me about this contract.",

        stage1Blocks: [
            DragBlock(text: "You are a contract review specialist", type: .role, emoji: "⚖️"),
            DragBlock(text: "Identify key risks and obligations", type: .task, emoji: "📋"),
            DragBlock(text: "So like I got this paper and need some help", type: .distractor, emoji: "💬"),
            DragBlock(text: "If it's not too much trouble could you check", type: .distractor, emoji: "✍️"),
        ],
        stage1ResultPrompt: "You are a contract review specialist. Identify key risks and obligations in this contract.",

        stage2Items: [
            ReorderItem(text: "You are a contract review specialist", category: "Role", correctPosition: 0),
            ReorderItem(text: "Identify key risks and obligations in this contract", category: "Task", correctPosition: 1),
            ReorderItem(text: "for a startup founder with no legal background", category: "Audience", correctPosition: 2),
            ReorderItem(text: "focusing on liability, termination, and IP clauses", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use a risk matrix table", category: "Output Format", correctPosition: 4),
        ],
        stage2ResultPrompt: "You are a contract review specialist. Identify key risks and obligations in this contract for a startup founder with no legal background, focusing on liability, termination, and IP clauses. Use a risk matrix table.",

        stage3Words: [
            "You", "are", "a", "contract", "review", "specialist", ".",
            "Identify", "key", "risks", "and", "obligations",
            "in", "this", "contract", "for", "a", "startup",
            "founder", "with", "no", "legal", "background", ",",
            "focusing", "on", "liability", ",", "termination", ",",
            "and", "IP", "clauses", ".", "Use", "a",
            "risk", "matrix", "table", "."
        ],
        stage3RedundantIndices: [0, 1, 2, 8, 10, 12, 13, 19, 20, 21, 24, 25, 34, 35],
        stage3TargetRange: 18...26,
        stage3OvercompressedThreshold: 14,
        stage3ResultPrompt: "Role: contract review specialist. Identify risks & obligations for startup founder: liability, termination & IP clauses → risk matrix table.",

        stage4ContextPlaceholder: "For a SaaS vendor agreement with a 3-year term being reviewed before signing.",
        stage4ExampleInput: "Review NDA key terms.",
        stage4ExampleOutput: "• Risk: Broad definition of confidential info\n• Obligation: 2-year non-compete\n• Flag: No carve-out for public info",
        stage4ResultPrompt: """
        Role: contract review specialist. Context: SaaS vendor agreement, 3-year term, pre-signing review. Identify risks & obligations for startup founder: liability, termination & IP clauses → risk matrix table.
        Example:
        Input: Review NDA key terms.
        Output: • Risk / Obligation / Flag
        """,

        stage5UnsafePrompt: """
        Role: contract review specialist at Kumar & Associates LLP (attorney: adv.kumar@kumarassociates.in). Context: SaaS agreement for client Priya Sharma, company CIN U72200MH2021PTC123456, deal value ₹45 lakhs. Identify risks & obligations for startup founder: liability, termination & IP clauses → risk matrix table. Keep under 200 words. Cite relevant Indian Contract Act sections.
        """,
        stage5PIITargets: [
            PIITarget(text: "Kumar & Associates LLP", type: "institution", isPII: true),
            PIITarget(text: "adv.kumar@kumarassociates.in", type: "email", isPII: true),
            PIITarget(text: "Priya Sharma", type: "name", isPII: true),
            PIITarget(text: "CIN U72200MH2021PTC123456", type: "identifier", isPII: true),
            PIITarget(text: "₹45 lakhs", type: "financial", isPII: true),
            PIITarget(text: "contract review", type: "role", isPII: false),
            PIITarget(text: "SaaS agreement", type: "topic", isPII: false),
            PIITarget(text: "200 words", type: "constraint", isPII: false),
        ],
        stage5Constraints: [
            ("Keep response under 200 words", true),
            ("Cite relevant Indian Contract Act sections", true),
            ("Flag any one-sided indemnity clauses", false),
        ],
        stage5FinalPrompt: """
        Role: contract review specialist. Context: SaaS vendor agreement, 3-year term, pre-signing review. Identify risks & obligations for startup founder: liability, termination & IP clauses → risk matrix table. Keep under 200 words. Cite relevant Indian Contract Act sections.
        Example:
        Input: Review NDA key terms.
        Output: • Risk / Obligation / Flag
        """
    )

    // MARK: - 💰 Finance ($2)

    static let finance = DomainConfig(
        name: "Finance",
        icon: "indianrupeesign.circle.fill",
        startingPrompt: "Help me invest my money.",

        stage1Blocks: [
            DragBlock(text: "You are a personal finance advisor", type: .role, emoji: "💰"),
            DragBlock(text: "Create a diversified investment plan", type: .task, emoji: "📋"),
            DragBlock(text: "I just want to make some money somehow", type: .distractor, emoji: "💬"),
            DragBlock(text: "Maybe you could suggest something good", type: .distractor, emoji: "✍️"),
        ],
        stage1ResultPrompt: "You are a personal finance advisor. Create a diversified investment plan.",

        stage2Items: [
            ReorderItem(text: "You are a personal finance advisor", category: "Role", correctPosition: 0),
            ReorderItem(text: "Create a diversified investment plan", category: "Task", correctPosition: 1),
            ReorderItem(text: "for a 25-year-old salaried professional", category: "Audience", correctPosition: 2),
            ReorderItem(text: "with monthly SIP of ₹10,000 across equity, debt, and gold", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use a table with allocation percentages", category: "Output Format", correctPosition: 4),
        ],
        stage2ResultPrompt: "You are a personal finance advisor. Create a diversified investment plan for a 25-year-old salaried professional, with monthly SIP of ₹10,000 across equity, debt, and gold. Use a table with allocation percentages.",

        stage3Words: [
            "You", "are", "a", "personal", "finance", "advisor", ".",
            "Create", "a", "diversified", "investment", "plan",
            "for", "a", "25-year-old", "salaried", "professional", ",",
            "with", "monthly", "SIP", "of", "₹10,000",
            "across", "equity", ",", "debt", ",", "and",
            "gold", ".", "Use", "a", "table", "with",
            "allocation", "percentages", "."
        ],
        stage3RedundantIndices: [0, 1, 2, 3, 8, 13, 18, 21, 31, 32, 34],
        stage3TargetRange: 18...26,
        stage3OvercompressedThreshold: 14,
        stage3ResultPrompt: "Role: finance advisor. Diversified investment plan for 25-yr-old professional: ₹10,000 SIP across equity, debt & gold → allocation % table.",

        stage4ContextPlaceholder: "For first-time investor with 5-year horizon and moderate risk appetite.",
        stage4ExampleInput: "Suggest retirement savings plan.",
        stage4ExampleOutput: "• EPF: 12% of salary (mandatory)\n• NPS: ₹50k/yr for tax + growth\n• Mutual Funds: Large-cap index for stability",
        stage4ResultPrompt: """
        Role: finance advisor. Context: First-time investor, 5-year horizon, moderate risk. Diversified investment plan for 25-yr-old: ₹10,000 SIP across equity, debt & gold → allocation % table.
        Example:
        Input: Suggest retirement savings plan.
        Output: • EPF / NPS / Mutual Funds → allocation
        """,

        stage5UnsafePrompt: """
        Role: finance advisor at WealthFirst Securities (advisor: amit.jain@wealthfirst.co.in). Context: Client PAN ABCDE1234F, Demat #IN302201-12345678, portfolio value ₹18,50,000. Diversified investment plan for 25-yr-old: ₹10,000 SIP across equity, debt & gold → allocation % table. Keep under 150 words. Follow SEBI guidelines.
        """,
        stage5PIITargets: [
            PIITarget(text: "WealthFirst Securities", type: "institution", isPII: true),
            PIITarget(text: "amit.jain@wealthfirst.co.in", type: "email", isPII: true),
            PIITarget(text: "PAN ABCDE1234F", type: "identifier", isPII: true),
            PIITarget(text: "Demat #IN302201-12345678", type: "identifier", isPII: true),
            PIITarget(text: "₹18,50,000", type: "financial", isPII: true),
            PIITarget(text: "finance advisor", type: "role", isPII: false),
            PIITarget(text: "investment plan", type: "topic", isPII: false),
            PIITarget(text: "150 words", type: "constraint", isPII: false),
        ],
        stage5Constraints: [
            ("Keep response under 150 words", true),
            ("Follow SEBI investment advisory guidelines", true),
            ("Include disclaimer: past returns don't guarantee future results", false),
        ],
        stage5FinalPrompt: """
        Role: finance advisor. Context: First-time investor, 5-year horizon, moderate risk. Diversified investment plan for 25-yr-old: ₹10,000 SIP across equity, debt & gold → allocation % table. Keep under 150 words. Follow SEBI guidelines.
        Example:
        Input: Suggest retirement savings plan.
        Output: • EPF / NPS / Mutual Funds → allocation
        """
    )

    // MARK: - 🎧 Support ($2)

    static let support = DomainConfig(
        name: "Support",
        icon: "headphones.circle.fill",
        startingPrompt: "My app is not working.",

        stage1Blocks: [
            DragBlock(text: "You are a technical support agent", type: .role, emoji: "🎧"),
            DragBlock(text: "Diagnose the issue and provide troubleshooting steps", type: .task, emoji: "📋"),
            DragBlock(text: "Something is broken and I'm really frustrated", type: .distractor, emoji: "💬"),
            DragBlock(text: "Please just fix it as soon as possible", type: .distractor, emoji: "✍️"),
        ],
        stage1ResultPrompt: "You are a technical support agent. Diagnose the issue and provide troubleshooting steps for the app.",

        stage2Items: [
            ReorderItem(text: "You are a technical support agent", category: "Role", correctPosition: 0),
            ReorderItem(text: "Diagnose the issue and provide troubleshooting steps", category: "Task", correctPosition: 1),
            ReorderItem(text: "for a non-technical end user", category: "Audience", correctPosition: 2),
            ReorderItem(text: "covering login failures, crashes, and slow loading", category: "Constraint", correctPosition: 3),
            ReorderItem(text: "Use step-by-step numbered instructions", category: "Output Format", correctPosition: 4),
        ],
        stage2ResultPrompt: "You are a technical support agent. Diagnose the issue and provide troubleshooting steps for a non-technical end user, covering login failures, crashes, and slow loading. Use step-by-step numbered instructions.",

        stage3Words: [
            "You", "are", "a", "technical", "support", "agent", ".",
            "Diagnose", "the", "issue", "and", "provide",
            "troubleshooting", "steps", "for", "a", "non-technical",
            "end", "user", ",", "covering", "login", "failures", ",",
            "crashes", ",", "and", "slow", "loading", ".",
            "Use", "step-by-step", "numbered", "instructions", "."
        ],
        stage3RedundantIndices: [0, 1, 2, 8, 10, 11, 15, 17, 20, 30],
        stage3TargetRange: 18...26,
        stage3OvercompressedThreshold: 14,
        stage3ResultPrompt: "Role: tech support agent. Diagnose issue & troubleshooting steps for non-technical user: login failures, crashes & slow loading → numbered instructions.",

        stage4ContextPlaceholder: "For an iOS app user who updated to latest version and now faces repeated crashes on launch.",
        stage4ExampleInput: "User reports payment page error.",
        stage4ExampleOutput: "1. Clear app cache → Settings > App > Clear\n2. Check internet connection\n3. Try alternate payment method\n4. Escalate to billing team if unresolved",
        stage4ResultPrompt: """
        Role: tech support agent. Context: iOS app user, post-update crashes on launch. Diagnose issue & troubleshooting for non-technical user: login failures, crashes & slow loading → numbered instructions.
        Example:
        Input: User reports payment page error.
        Output: 1. Clear cache / 2. Check internet / 3. Alternate payment / 4. Escalate
        """,

        stage5UnsafePrompt: """
        Role: tech support agent at QuickServe Inc. (agent: neha.singh@quickserve.io). Context: Ticket #TK-90821 for user@gmail.com, device IMEI 353456789012345, iOS 17.4. Diagnose issue & troubleshooting for non-technical user: login failures, crashes & slow loading → numbered instructions. Keep under 100 words. Follow internal SOP.
        """,
        stage5PIITargets: [
            PIITarget(text: "QuickServe Inc.", type: "institution", isPII: true),
            PIITarget(text: "neha.singh@quickserve.io", type: "email", isPII: true),
            PIITarget(text: "Ticket #TK-90821", type: "identifier", isPII: true),
            PIITarget(text: "user@gmail.com", type: "email", isPII: true),
            PIITarget(text: "IMEI 353456789012345", type: "identifier", isPII: true),
            PIITarget(text: "tech support", type: "role", isPII: false),
            PIITarget(text: "crashes", type: "topic", isPII: false),
            PIITarget(text: "100 words", type: "constraint", isPII: false),
        ],
        stage5Constraints: [
            ("Keep response under 100 words", true),
            ("Follow internal troubleshooting SOP", true),
            ("Offer escalation path if unresolved after 3 steps", false),
        ],
        stage5FinalPrompt: """
        Role: tech support agent. Context: iOS app user, post-update crashes on launch. Diagnose issue & troubleshooting for non-technical user: login failures, crashes & slow loading → numbered instructions. Keep under 100 words. Follow internal SOP.
        Example:
        Input: User reports payment page error.
        Output: 1. Clear cache / 2. Check internet / 3. Alternate payment / 4. Escalate
        """
    )
}
