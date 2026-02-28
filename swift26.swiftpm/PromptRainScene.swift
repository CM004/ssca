//
//  PromptRainScene.swift
//  The Living Prompt Tree — Prompt Rain Mini-Game
//
//  SpriteKit scene: fruits/flowers fall from the tree, player catches good
//  prompt fragments and dodges toxic ones with a basket.
//

import SpriteKit

// MARK: - Data Types

struct PromptFragment {
    let text: String
    let category: FragmentCategory
    let emoji: String
}

struct GameScenario {
    let title: String
    let targetPrompt: String
    let goodFragments: [PromptFragment]
    let toxicFragments: [PromptFragment]
    let requiredParts: Int
}

enum FragmentCategory: String {
    case role, task, audience, context, constraint, output
    case pii, filler, vague

    var isGood: Bool {
        switch self {
        case .role, .task, .audience, .context, .constraint, .output: return true
        case .pii, .filler, .vague: return false
        }
    }

    var color: SKColor {
        switch self {
        case .role:       return SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1)
        case .task:       return SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
        case .audience:   return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1)
        case .context:    return SKColor(red: 0.5, green: 0.8, blue: 0.5, alpha: 1)
        case .constraint: return SKColor(red: 0.6, green: 0.5, blue: 0.9, alpha: 1)
        case .output:     return SKColor(red: 0.3, green: 0.9, blue: 0.8, alpha: 1)
        case .pii:        return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
        case .filler:     return SKColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1)
        case .vague:      return SKColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1)
        }
    }
}

// MARK: - Scene

class PromptRainScene: SKScene, ObservableObject {

    // Categories for physics
    private let fruitCategory:  UInt32 = 0x1 << 0
    private let basketCategory: UInt32 = 0x1 << 1
    private let floorCategory:  UInt32 = 0x1 << 2

    // Game state
    @Published var score: Int = 0
    @Published var caughtFragments: [PromptFragment] = []
    @Published var missedCategories: [String] = []
    @Published var uniquePartsCaught: Int = 0
    @Published var isGameOver = false
    @Published var goodCaughtCount: Int = 0
    @Published var badCaughtCount: Int = 0
    @Published var totalGoodSpawned: Int = 0
    @Published var timeRemaining: Double = 45
    @Published var fmEvaluation: String? = nil
    @Published var currentTargetPrompt: String = ""

    private var basket: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var countsLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var lastSpawnTime: TimeInterval = 0
    private var gameTime: TimeInterval = 0
    private var spawnInterval: Double = 1.2
    private var totalDuration: Double = 45
    private var toxicMultiplier: Double = 1.0
    private var gameStarted = false

    struct TargetScenario {
        let title: String
        let promptText: String
        let goodFragments: [PromptFragment]
    }

    private let scenarios: [TargetScenario] = [
        TargetScenario(
            title: "Climate Change",
            promptText: "Role: scientist.\nExplain causes for high schoolers\n→ bullet points.",
            goodFragments: [
                PromptFragment(text: "Role: scientist", category: .role, emoji: "🍎"),
                PromptFragment(text: "Explain causes", category: .task, emoji: "🍊"),
                PromptFragment(text: "for high schoolers", category: .audience, emoji: "🍋"),
                PromptFragment(text: "→ bullet points", category: .output, emoji: "🍇")
            ]
        ),
        TargetScenario(
            title: "Mental Health",
            promptText: "Role: therapist.\nSummarize coping strategies for teens\nunder 100 words → numbered list.",
            goodFragments: [
                PromptFragment(text: "Role: therapist", category: .role, emoji: "🍎"),
                PromptFragment(text: "Summarize coping strategies", category: .task, emoji: "🍊"),
                PromptFragment(text: "for teens", category: .audience, emoji: "🍋"),
                PromptFragment(text: "under 100 words", category: .constraint, emoji: "🫐"),
                PromptFragment(text: "→ numbered list", category: .output, emoji: "🍇")
            ]
        ),
        TargetScenario(
            title: "Legal Advice",
            promptText: "Role: legal advisor.\nDraft a summary for a small business owner.\nIndia jurisdiction only. plain English.",
            goodFragments: [
                PromptFragment(text: "Role: legal advisor", category: .role, emoji: "🍎"),
                PromptFragment(text: "Draft a summary", category: .task, emoji: "🍊"),
                PromptFragment(text: "for a small business owner", category: .audience, emoji: "🍋"),
                PromptFragment(text: "India jurisdiction only", category: .constraint, emoji: "🫐"),
                PromptFragment(text: "plain English", category: .output, emoji: "🍇")
            ]
        ),
        TargetScenario(
            title: "UX Research",
            promptText: "Role: UX Researcher.\nDesign a survey for mobile users\nfocus on accessibility → tabular format.",
            goodFragments: [
                PromptFragment(text: "Role: UX Researcher", category: .role, emoji: "🍎"),
                PromptFragment(text: "Design a survey", category: .task, emoji: "🍊"),
                PromptFragment(text: "for mobile users", category: .audience, emoji: "🍋"),
                PromptFragment(text: "focus on accessibility", category: .constraint, emoji: "🫐"),
                PromptFragment(text: "→ tabular format", category: .output, emoji: "🍇")
            ]
        ),
        TargetScenario(
            title: "Data Analysis",
            promptText: "Role: Senior Data Analyst.\nSummarize Q3 earnings report for executives\nunder 150 words → JSON format.",
            goodFragments: [
                PromptFragment(text: "Role: Senior Data Analyst", category: .role, emoji: "🍎"),
                PromptFragment(text: "Summarize Q3 earnings report", category: .task, emoji: "🍊"),
                PromptFragment(text: "for executives", category: .audience, emoji: "🍋"),
                PromptFragment(text: "under 150 words", category: .constraint, emoji: "🫐"),
                PromptFragment(text: "→ JSON format", category: .output, emoji: "🍇")
            ]
        )
    ]

    private var currentTargetScenario: TargetScenario?

    private let toxicFragments: [PromptFragment] = [
        PromptFragment(text: "John Smith", category: .pii, emoji: "🥀"),
        PromptFragment(text: "SSN: 123-45", category: .pii, emoji: "🥀"),
        PromptFragment(text: "email@test.com", category: .pii, emoji: "🥀"),
        PromptFragment(text: "basically", category: .filler, emoji: "🍂"),
        PromptFragment(text: "kind of", category: .filler, emoji: "🍂"),
        PromptFragment(text: "you know", category: .filler, emoji: "🍂"),
        PromptFragment(text: "do something", category: .vague, emoji: "🍂"),
        PromptFragment(text: "help me", category: .vague, emoji: "🍂"),
        PromptFragment(text: "tell me stuff", category: .vague, emoji: "🍂"),
    ]

    // Fragment pools
    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.02, green: 0.06, blue: 0.04, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -2.0)

        setupFloor()
        setupBasket()
        setupHUD()
    }

    private func setupFloor() {
        let floor = SKNode()
        floor.name = "floor"
        floor.position = CGPoint(x: size.width / 2, y: -10)
        floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 2, height: 20))
        floor.physicsBody?.isDynamic = false
        addChild(floor)
    }

    private func setupBasket() {
        basket = SKSpriteNode(color: SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1), size: CGSize(width: 80, height: 30))
        basket.position = CGPoint(x: size.width / 2, y: 50)
        basket.zPosition = 10
        basket.name = "basket"

        // Basket rim decoration
        let rim = SKSpriteNode(color: SKColor(red: 0.7, green: 0.5, blue: 0.25, alpha: 1), size: CGSize(width: 90, height: 6))
        rim.position = CGPoint(x: 0, y: 15)
        basket.addChild(rim)

        // Label
        let label = SKLabelNode(text: "🧺")
        label.fontSize = 28
        label.position = CGPoint(x: 0, y: -8)
        basket.addChild(label)

        basket.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 30))
        basket.physicsBody?.isDynamic = false
        addChild(basket)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Keep HUD and floor nodes anchored correctly when window resizes
        if let floor = childNode(withName: "floor") {
            floor.position = CGPoint(x: size.width / 2, y: -10)
            floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 2, height: 20))
            floor.physicsBody?.isDynamic = false
        }
        if let timer = timerLabel {
            timer.position = CGPoint(x: size.width - 60, y: size.height - 30)
        }

        if let counts = countsLabel {
            counts.position = CGPoint(x: size.width / 2, y: size.height - 35)
        }
        
        if basket != nil {
            basket.position.x = max(45, min(size.width - 45, basket.position.x))
        }
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 14
        scoreLabel.fontName = "Menlo-Bold"
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 20, y: size.height - 30)
        scoreLabel.zPosition = 100
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)

        countsLabel = SKLabelNode(text: "Good: 0 | Bad: 0")
        countsLabel.fontSize = 14
        countsLabel.fontName = "Menlo-Bold"
        countsLabel.fontColor = SKColor(red: 0.8, green: 0.9, blue: 0.8, alpha: 1)
        countsLabel.position = CGPoint(x: size.width / 2, y: size.height - 35)
        countsLabel.zPosition = 100
        countsLabel.horizontalAlignmentMode = .center
        addChild(countsLabel)

        timerLabel = SKLabelNode(text: "⏱ 45s")
        timerLabel.fontSize = 14
        timerLabel.fontName = "Menlo-Bold"
        timerLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
        timerLabel.position = CGPoint(x: size.width - 60, y: size.height - 30)
        timerLabel.zPosition = 100
        timerLabel.horizontalAlignmentMode = .right
        addChild(timerLabel)

    }

    // MARK: - Game Control

    func pickNewTargetPrompt() {
        currentTargetScenario = scenarios.randomElement()
        currentTargetPrompt = currentTargetScenario?.promptText ?? "Loading prompt..."
    }

    func startGame() {
        // Clear previous state
        enumerateChildNodes(withName: "fruit") { node, _ in node.removeFromParent() }
        score = 0
        goodCaughtCount = 0
        badCaughtCount = 0
        totalGoodSpawned = 0
        caughtFragments = []
        missedCategories = []
        uniquePartsCaught = 0
        isGameOver = false
        gameTime = 0
        lastSpawnTime = 0
        timeRemaining = totalDuration
        spawnInterval = 1.2
        toxicMultiplier = 1.0
        fmEvaluation = nil
        gameStarted = true
        updateHUD()
    }

    func endGame() {
        gameStarted = false
        isGameOver = true

        // Compute missed categories
        let caughtCats = Set(caughtFragments.filter { $0.category.isGood }.map { $0.category.rawValue })
        let allGoodCats = Set(["role", "task", "audience", "context", "constraint", "output"])
        missedCategories = Array(allGoodCats.subtracting(caughtCats))
        uniquePartsCaught = caughtCats.count
        
        // Remove complex completion bonuses to keep score simple and consistent
        updateHUD()

        // Show game over banner
        let bannerText = "Caught \(uniquePartsCaught)/6 Parts!"
        let banner = SKLabelNode(text: bannerText)
        banner.fontSize = 20
        banner.fontName = "Menlo-Bold"
        banner.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
        banner.position = CGPoint(x: size.width / 2, y: size.height / 2)
        banner.zPosition = 200
        banner.alpha = 0
        banner.name = "fruit" // so it gets cleared on restart
        addChild(banner)
        banner.run(SKAction.fadeIn(withDuration: 0.3))
    }

    // MARK: - Touch Handling (Basket Movement)

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let clampedX = max(45, min(size.width - 45, location.x))
        basket.position.x = clampedX
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStarted, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let clampedX = max(45, min(size.width - 45, location.x))
        basket.position.x = clampedX
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameStarted else { return }

        if gameTime == 0 { gameTime = currentTime }
        let elapsed = currentTime - gameTime
        timeRemaining = max(0, totalDuration - elapsed)
        timerLabel.text = "⏱ \(Int(timeRemaining))s"

        if timeRemaining <= 0 {
            endGame()
            return
        }

        // Escalate difficulty
        let progress = elapsed / totalDuration
        spawnInterval = max(0.4, 1.2 - progress * 0.8)
        toxicMultiplier = 1.0 + progress * 2.0

        // Spawn fruits
        if currentTime - lastSpawnTime > spawnInterval {
            lastSpawnTime = currentTime
            spawnFragment()
        }

        // Manual collision detection
        checkCollisions()
    }

    private func checkCollisions() {
        let basketFrame = basket.frame.insetBy(dx: -10, dy: -5)
        var toRemove: [SKNode] = []

        enumerateChildNodes(withName: "fruit") { node, _ in
            // Hit floor?
            if node.position.y < 10 {
                toRemove.append(node)
                return
            }
            // Hit basket?
            let fruitFrame = CGRect(x: node.position.x - 25, y: node.position.y - 20, width: 50, height: 40)
            if fruitFrame.intersects(basketFrame) {
                if let data = node.userData {
                    let isGood = data["isGood"] as? Bool ?? false
                    let text = data["text"] as? String ?? ""
                    let catStr = data["category"] as? String ?? ""
                    let emoji = data["emoji"] as? String ?? ""

                    if isGood {
                        self.score += 10
                        self.goodCaughtCount += 1
                        self.catchEffect(at: node.position, color: .green)
                        if let cat = FragmentCategory(rawValue: catStr) {
                            let frag = PromptFragment(text: text, category: cat, emoji: emoji)
                            self.caughtFragments.append(frag)
                        }
                    } else {
                        self.score -= 5
                        self.badCaughtCount += 1
                        self.catchEffect(at: node.position, color: .red)
                    }
                    self.updateHUD()
                }
                toRemove.append(node)
            }
        }

        for node in toRemove {
            node.removeFromParent()
        }
    }

    // MARK: - Spawning

    private func spawnFragment() {
        // Decide good vs toxic based on multiplier
        let toxicChance = min(0.65, 0.3 * toxicMultiplier)
        let isToxic = Double.random(in: 0...1) < toxicChance
        let goodPool = currentTargetScenario?.goodFragments ?? []
        // Fallback to random fragment if pool is empty
        let pool = isToxic ? toxicFragments : goodPool
        guard !pool.isEmpty else { return }
        
        if (!isToxic) {
            totalGoodSpawned += 1
        }
        
        let fragment = pool[Int.random(in: 0..<pool.count)]

        let node = createFruitNode(fragment: fragment)
        let xPos = CGFloat.random(in: 30...(size.width - 30))
        node.position = CGPoint(x: xPos, y: size.height + 20)
        node.zPosition = 8
        addChild(node)

        // Random speed variation - making it more variable
        let speedMultiplier = CGFloat.random(in: 0.6...2.5)
        node.physicsBody?.linearDamping = 0
        node.physicsBody?.velocity = CGVector(dx: CGFloat.random(in: -15...15), dy: -70 * speedMultiplier)
    }

    private func createFruitNode(fragment: PromptFragment) -> SKNode {
        let container = SKNode()
        container.name = "fruit"

        // Fruit/flower sprite
        let emojiLabel = SKLabelNode(text: fragment.emoji)
        emojiLabel.fontSize = 28 // Increased emoji size
        emojiLabel.position = CGPoint(x: 0, y: 12)
        container.addChild(emojiLabel)

        // Text label
        let textLabel = SKLabelNode(text: fragment.text)
        textLabel.fontSize = 16 // Increased from 14 for readability
        textLabel.fontName = "Menlo-Bold"
        textLabel.fontColor = .white
        textLabel.position = CGPoint(x: 0, y: -22)
        textLabel.zPosition = 2
        container.addChild(textLabel)

        // Text background (adjusted for larger text size)
        let textBG = SKSpriteNode(
            color: fragment.category.color.withAlphaComponent(0.85),
            size: CGSize(width: CGFloat(fragment.text.count) * 10 + 20, height: 26) // Slightly wider
        )
        textBG.position = CGPoint(x: 0, y: -16)
        textBG.zPosition = 1
        container.addChild(textBG)

        // Physics
        container.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 60, height: 50)) // Slightly larger hitbox
        container.physicsBody?.collisionBitMask = 0
        container.physicsBody?.affectedByGravity = true
        container.physicsBody?.allowsRotation = false

        // Store fragment data
        container.userData = NSMutableDictionary()
        container.userData?["text"] = fragment.text
        container.userData?["category"] = fragment.category.rawValue
        container.userData?["isGood"] = fragment.category.isGood
        container.userData?["emoji"] = fragment.emoji

        return container
    }

    // MARK: - Handlers

    private func updateHUD() {
        scoreLabel.text = "Score: \(score)"
        countsLabel.text = "Good: \(goodCaughtCount) | Bad: \(badCaughtCount)"
    }

    private func catchEffect(at pos: CGPoint, color: SKColor) {
        for _ in 0..<6 {
            let spark = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            spark.position = pos
            spark.zPosition = 20
            addChild(spark)
            let dx = CGFloat.random(in: -30...30)
            let dy = CGFloat.random(in: 10...40)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                ]),
                SKAction.removeFromParent(),
            ]))
        }
    }
}
