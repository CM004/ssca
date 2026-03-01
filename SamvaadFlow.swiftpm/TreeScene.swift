//
//  TreeScene.swift
//  The Living Prompt Tree
//
//  SpriteKit scene: a pixelated tile-based tree that grows
//  progressively as stages are completed. Each tile is a small
//  colored square, giving a retro pixel-art aesthetic.
//

import SpriteKit

class TreeScene: SKScene, ObservableObject {

    private var completedStages: Set<Int> = []
    private let tileSize: CGFloat = 8.0

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        // Forest background image
        if let path = Bundle.main.path(forResource: "forest_bg", ofType: "png"),
           let uiImage = UIImage(contentsOfFile: path) {
            let texture = SKTexture(image: uiImage)
            let bg = SKSpriteNode(texture: texture)
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.size = size
            bg.zPosition = -1
            addChild(bg)
        }

        drawGround()
        drawTrunk()
        drawInitialCanopy()
        run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 30), SKAction.run { [weak self] in self?.resetFogOverlay() }])), withKey: "fog_reset_timer")
    }

    // MARK: - Pixel tile helper

    private func tile(x: CGFloat, y: CGFloat, color: SKColor, z: CGFloat = 10) -> SKSpriteNode {
        let node = SKSpriteNode(color: color, size: CGSize(width: tileSize, height: tileSize))
        node.position = CGPoint(x: x, y: y)
        node.zPosition = z
        return node
    }

    // MARK: - Ground

    private func drawGround() {
        let groundColors: [SKColor] = [
            SKColor(red: 0.38, green: 0.55, blue: 0.22, alpha: 1.0),
            SKColor(red: 0.42, green: 0.58, blue: 0.25, alpha: 1.0),
            SKColor(red: 0.35, green: 0.52, blue: 0.20, alpha: 1.0),
            SKColor(red: 0.45, green: 0.60, blue: 0.28, alpha: 1.0),
        ]
        // Grass layer
        for col in stride(from: CGFloat(0), to: size.width, by: tileSize) {
            let grassHeight = 80 + CGFloat.random(in: -8...8)
            for row in stride(from: CGFloat(0), to: grassHeight, by: tileSize) {
                let ci = Int.random(in: 0..<groundColors.count)
                addChild(tile(x: col, y: row, color: groundColors[ci], z: 2))
            }
        }

        // Soil layer under grass
        let soilColors: [SKColor] = [
            SKColor(red: 0.45, green: 0.32, blue: 0.18, alpha: 1.0),
            SKColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1.0),
        ]
        for col in stride(from: CGFloat(0), to: size.width, by: tileSize) {
            for row in stride(from: CGFloat(0), to: 30, by: tileSize) {
                let ci = Int.random(in: 0..<soilColors.count)
                addChild(tile(x: col, y: row, color: soilColors[ci], z: 1))
            }
        }
    }

    // MARK: - Trunk (pixel tiles)

    private func drawTrunk() {
        let centerX = size.width / 2
        let trunkColors: [SKColor] = [
            SKColor(red: 0.38, green: 0.25, blue: 0.14, alpha: 1.0),
            SKColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1.0),
            SKColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1.0),
        ]

        // Main trunk — 4 tiles wide, grows up from ground
        for row in stride(from: CGFloat(75), to: CGFloat(280), by: tileSize) {
            let trunkWidth: CGFloat = row > 240 ? 2 : row > 200 ? 3 : 4
            let startX = centerX - (trunkWidth * tileSize / 2)
            for i in 0..<Int(trunkWidth) {
                let ci = Int.random(in: 0..<trunkColors.count)
                addChild(tile(x: startX + CGFloat(i) * tileSize, y: row, color: trunkColors[ci], z: 5))
            }
        }

        // Left branch
        let branchColor = trunkColors[1]
        for i in 0..<5 {
            addChild(tile(x: centerX - CGFloat(i + 1) * tileSize, y: 240 + CGFloat(i) * tileSize, color: branchColor, z: 5))
        }
        // Right branch
        for i in 0..<5 {
            addChild(tile(x: centerX + CGFloat(i + 1) * tileSize, y: 250 + CGFloat(i) * tileSize, color: branchColor, z: 5))
        }
        // Second left branch
        for i in 0..<3 {
            addChild(tile(x: centerX - CGFloat(i + 1) * tileSize, y: 200 + CGFloat(i) * tileSize, color: branchColor, z: 5))
        }
    }

    // MARK: - Canopy (initial wilted/grey)

    private func drawInitialCanopy() {
        let centerX = size.width / 2
        let centerY: CGFloat = 350

        // Draw a large oval canopy with grey-green (wilted)
        let wiltedColors: [SKColor] = [
            SKColor(red: 0.30, green: 0.35, blue: 0.25, alpha: 0.7),
            SKColor(red: 0.28, green: 0.33, blue: 0.23, alpha: 0.6),
            SKColor(red: 0.32, green: 0.37, blue: 0.27, alpha: 0.65),
        ]

        drawCanopyTiles(centerX: centerX, centerY: centerY, colors: wiltedColors, name: "canopy_tile")

        // Fog overlay — oscillating multi-grey fog
        addFogOverlay()

        // Golden shimmer tracing tree outline
        let shimCenterX = size.width / 2
        var outlinePoints: [CGPoint] = []
        // Left trunk edge
        for row in stride(from: CGFloat(75), to: CGFloat(280), by: tileSize) {
            let trunkW: CGFloat = row > 240 ? 2 : row > 200 ? 3 : 4
            outlinePoints.append(CGPoint(x: shimCenterX - (trunkW * tileSize / 2), y: row))
        }
        // Canopy outline — clockwise from bottom
        let canopySteps = 50
        for i in 0..<canopySteps {
            let angle = (-.pi / 2) - (CGFloat(i) / CGFloat(canopySteps)) * 2 * .pi
            let r: CGFloat = 105
            outlinePoints.append(CGPoint(
                x: shimCenterX + cos(angle) * r,
                y: 350 + sin(angle) * r * 0.8
            ))
        }
        // Right trunk edge
        for row in stride(from: CGFloat(275), through: CGFloat(75), by: -tileSize) {
            let trunkW: CGFloat = row > 240 ? 2 : row > 200 ? 3 : 4
            outlinePoints.append(CGPoint(x: shimCenterX + (trunkW * tileSize / 2), y: row))
        }

        let goldenColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.9)
        let totalPts = outlinePoints.count
        let lineLen = 10
        var shimmerStep = 0
        let advanceShimmer = SKAction.run { [weak self] in
            guard let self else { return }
            for j in 0..<lineLen {
                let idx = (shimmerStep + j) % totalPts
                let pt = outlinePoints[idx]
                let brightness = 1.0 - (CGFloat(j) / CGFloat(lineLen)) * 0.7
                let tile = SKSpriteNode(
                    color: goldenColor,
                    size: CGSize(width: self.tileSize * 0.7, height: self.tileSize * 0.7)
                )
                tile.position = pt
                tile.zPosition = 55
                tile.alpha = brightness
                self.addChild(tile)
                tile.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.12),
                    SKAction.removeFromParent(),
                ]))
            }
            shimmerStep = (shimmerStep + 1) % totalPts
        }
        run(SKAction.repeatForever(SKAction.sequence([advanceShimmer, SKAction.wait(forDuration: 0.04)])), withKey: "intro_shimmer")
    }

    // MARK: - Fog Overlay Helpers

    private func addFogOverlay() {
        let greys: [CGFloat] = [0.65, 0.72, 0.78, 0.85, 0.90, 0.95]
        // Layer 1: small scattered fog tiles
        for _ in 0..<80 {
            let g = greys[Int.random(in: 0..<greys.count)]
            let fogTile = SKSpriteNode(
                color: SKColor(white: g, alpha: CGFloat.random(in: 0.3...0.5)),
                size: CGSize(width: tileSize * 2, height: tileSize * 2)
            )
            fogTile.position = CGPoint(
                x: CGFloat.random(in: 20...(size.width - 20)),
                y: CGFloat.random(in: 100...(size.height - 20))
            )
            fogTile.zPosition = 50
            fogTile.name = "fog_tile"
            addChild(fogTile)
            let drift = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -10...10), duration: Double.random(in: 2...4)),
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -10...10), duration: Double.random(in: 2...4)),
            ])
            fogTile.run(SKAction.repeatForever(drift))
        }
        // Layer 2: larger, denser fog patches
        for _ in 0..<50 {
            let g = greys[Int.random(in: 0..<greys.count)]
            let fogTile = SKSpriteNode(
                color: SKColor(white: g, alpha: CGFloat.random(in: 0.4...0.6)),
                size: CGSize(width: tileSize * CGFloat.random(in: 3...5), height: tileSize * CGFloat.random(in: 3...4))
            )
            fogTile.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 80...(size.height - 10))
            )
            fogTile.zPosition = 51
            fogTile.name = "fog_tile"
            addChild(fogTile)
            let drift = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -15...15), duration: Double.random(in: 3...5)),
                SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -15...15), duration: Double.random(in: 3...5)),
            ])
            fogTile.run(SKAction.repeatForever(drift))
        }
        // Layer 3: thick fog band across the middle
        for _ in 0..<40 {
            let g = greys[Int.random(in: 0..<greys.count)]
            let fogTile = SKSpriteNode(
                color: SKColor(white: g, alpha: CGFloat.random(in: 0.5...0.7)),
                size: CGSize(width: tileSize * CGFloat.random(in: 4...8), height: tileSize * CGFloat.random(in: 2...4))
            )
            fogTile.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 200...400)
            )
            fogTile.zPosition = 52
            fogTile.name = "fog_tile"
            addChild(fogTile)
            let drift = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -25...25), y: CGFloat.random(in: -12...12), duration: Double.random(in: 2.5...4.5)),
                SKAction.moveBy(x: CGFloat.random(in: -25...25), y: CGFloat.random(in: -12...12), duration: Double.random(in: 2.5...4.5)),
            ])
            fogTile.run(SKAction.repeatForever(drift))
        }
    }

    /// Removes existing fog tiles and rebuilds them. Only runs while the intro shimmer is active (intro state).
    func resetFogOverlay() {
        // Only reset fog during the intro state (shimmer active)
        guard action(forKey: "intro_shimmer") != nil else { return }
        enumerateChildNodes(withName: "fog_tile") { node, _ in
            node.removeFromParent()
        }
        addFogOverlay()
    }

    private func drawCanopyTiles(centerX: CGFloat, centerY: CGFloat, colors: [SKColor], name: String) {
        // Create oval canopy shape with random edge variation
        let radiusX: CGFloat = 110
        let radiusY: CGFloat = 90

        for col in stride(from: -radiusX, to: radiusX, by: tileSize) {
            for row in stride(from: -radiusY, to: radiusY, by: tileSize) {
                let nx = col / radiusX
                let ny = row / radiusY
                let dist = nx * nx + ny * ny

                // Inside ellipse with irregular edges
                let edgeNoise = CGFloat.random(in: -0.15...0.15)
                if dist < 1.0 + edgeNoise {
                    let ci = Int.random(in: 0..<colors.count)
                    let t = tile(x: centerX + col, y: centerY + row, color: colors[ci], z: 15)
                    t.name = name
                    addChild(t)
                }
            }
        }
    }

    // MARK: - Stage Animations

    func animateStageCompletion(_ stage: Int) {
        guard !completedStages.contains(stage) else { return }
        completedStages.insert(stage)

        switch stage {
        case 1: animateAir()
        case 2: animateWater()
        case 3: animateSunlight()
        case 4: animateSoil()
        case 5: animateNutrients()
        default: break
        }
    }

    // Stage 1: Air — fog clears, shimmer stops, canopy begins to lighten
    private func animateAir() {
        // Stop intro shimmer
        removeAction(forKey: "intro_shimmer")

        // Fade out fog tiles
        enumerateChildNodes(withName: "fog_tile") { node, _ in
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0...0.8)),
                SKAction.fadeOut(withDuration: 0.8),
                SKAction.removeFromParent(),
            ]))
        }

        // Lighten canopy tiles slightly
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.colorize(
                    with: SKColor(red: 0.25, green: 0.50, blue: 0.20, alpha: 1.0),
                    colorBlendFactor: 0.4, duration: 1.5
                ))
            }
        }
    }

    // Stage 2: Water — water absorbed by roots, xylem carries it up to canopy
    private func animateWater() {
        let centerX = size.width / 2
        let dropColors: [SKColor] = [
            SKColor(red: 0.30, green: 0.60, blue: 0.90, alpha: 0.8),
            SKColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 0.7),
            SKColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 0.75),
        ]

        // Water droplets rising UP from roots through trunk to canopy (xylem)
        let emitter = SKAction.run { [weak self] in
            guard let self else { return }
            let ci = Int.random(in: 0..<dropColors.count)
            let drop = SKSpriteNode(
                color: dropColors[ci],
                size: CGSize(width: self.tileSize, height: self.tileSize)
            )
            // Start from root area (soil level)
            drop.position = CGPoint(
                x: centerX + CGFloat.random(in: -12...12),
                y: 70
            )
            drop.zPosition = 12
            drop.alpha = 0.6
            self.addChild(drop)

            // Rise up through trunk to canopy
            drop.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveTo(y: 380, duration: 2.0),
                    SKAction.fadeAlpha(to: 0.3, duration: 2.0),
                ]),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent(),
            ]))
        }
        run(SKAction.repeatForever(SKAction.sequence([emitter, SKAction.wait(forDuration: 0.25)])), withKey: "water_xylem")

        // Water droplets moving toward roots (absorption)
        let absorbTargets: [(CGFloat, CGFloat)] = [
            (-80, 30), (-50, 20), (-30, 40),   // left root tips
            (80, 30), (50, 20), (30, 40),       // right root tips
            (0, 10),                             // taproot tip
        ]
        let absorbEmitter = SKAction.run { [weak self] in
            guard let self else { return }
            let target = absorbTargets[Int.random(in: 0..<absorbTargets.count)]
            let startX = centerX + target.0 + CGFloat.random(in: -20...20)
            let startY = target.1 + CGFloat.random(in: -15...15)
            let drop = SKSpriteNode(
                color: SKColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 0.7),
                size: CGSize(width: self.tileSize, height: self.tileSize)
            )
            drop.position = CGPoint(x: startX, y: startY)
            drop.zPosition = 11
            self.addChild(drop)
            // Move toward root and fade (absorbed)
            let rootX = centerX + target.0 * 0.5
            let rootY = target.1 + 30
            drop.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: CGPoint(x: rootX, y: rootY), duration: 0.8),
                    SKAction.fadeOut(withDuration: 0.8),
                    SKAction.scale(to: 0.5, duration: 0.8),
                ]),
                SKAction.removeFromParent(),
            ]))
        }
        run(SKAction.repeatForever(SKAction.sequence([absorbEmitter, SKAction.wait(forDuration: 0.4)])), withKey: "water_absorb")

        // Deepen canopy green as water reaches leaves
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5), // wait for water to rise
                    SKAction.colorize(
                        with: SKColor(red: 0.15, green: 0.55, blue: 0.18, alpha: 1.0),
                        colorBlendFactor: 0.6, duration: 1.0
                    ),
                ]))
            }
        }
    }

    // Stage 3: Sunlight — golden ray tiles, canopy brightens
    private func animateSunlight() {
        let centerX = size.width / 2

        // Golden ray tiles falling diagonally
        for i in 0..<5 {
            let startX = centerX + CGFloat(i - 2) * 25
            for j in 0..<12 {
                let ray = SKSpriteNode(
                    color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.0),
                    size: CGSize(width: tileSize, height: tileSize)
                )
                ray.position = CGPoint(x: startX, y: 550 - CGFloat(j) * tileSize * 1.5)
                ray.zPosition = 8
                addChild(ray)
                ray.run(SKAction.sequence([
                    SKAction.wait(forDuration: Double(j) * 0.05 + Double(i) * 0.15),
                    SKAction.fadeAlpha(to: 0.5, duration: 0.3),
                ]))
            }
        }

        // Brighten canopy and add continuous glitter
        let greens: [SKColor] = [
            SKColor(red: 0.18, green: 0.62, blue: 0.15, alpha: 1.0),  // bright green
            SKColor(red: 0.22, green: 0.58, blue: 0.20, alpha: 1.0),  // warm green
            SKColor(red: 0.15, green: 0.65, blue: 0.12, alpha: 1.0),  // vivid green
            SKColor(red: 0.28, green: 0.55, blue: 0.18, alpha: 1.0),  // sun-kissed green
            SKColor(red: 0.12, green: 0.52, blue: 0.14, alpha: 1.0),  // deeper forest
            SKColor(red: 0.30, green: 0.65, blue: 0.25, alpha: 1.0),  // light lime
        ]
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                // Initial colorize
                let initialDelay = Double.random(in: 0...0.5)
                sprite.run(SKAction.sequence([
                    SKAction.wait(forDuration: initialDelay),
                    SKAction.colorize(with: greens.randomElement()!, colorBlendFactor: 0.8, duration: 0.8),
                ]))

                // Continuous glitter — keep cycling through greens
                let glitterDelay = initialDelay + 1.0
                let glitter = SKAction.sequence([
                    SKAction.colorize(with: greens.randomElement()!, colorBlendFactor: 0.9, duration: Double.random(in: 0.6...1.2)),
                    SKAction.colorize(with: greens.randomElement()!, colorBlendFactor: 0.85, duration: Double.random(in: 0.6...1.2)),
                    SKAction.colorize(with: greens.randomElement()!, colorBlendFactor: 0.9, duration: Double.random(in: 0.6...1.2)),
                ])
                sprite.run(SKAction.sequence([
                    SKAction.wait(forDuration: glitterDelay),
                    SKAction.repeatForever(glitter),
                ]))
            }
        }
    }

    // Stage 4: Soil — root tiles extend, leaf buds appear
    private func animateSoil() {
        let centerX = size.width / 2

        // Yellowish-orange root colors
        let rootColors: [SKColor] = [
            SKColor(red: 0.85, green: 0.70, blue: 0.35, alpha: 1.0),
            SKColor(red: 0.80, green: 0.65, blue: 0.30, alpha: 0.95),
            SKColor(red: 0.90, green: 0.75, blue: 0.40, alpha: 1.0),
        ]
        let trunkBaseY: CGFloat = 75
        let s = tileSize

        // Helper to draw a smooth root line
        func drawRoot(points: [(CGFloat, CGFloat)], delay: Double) {
            for (i, pt) in points.enumerated() {
                let ci = Int.random(in: 0..<rootColors.count)
                let r = tile(x: centerX + pt.0, y: trunkBaseY + pt.1, color: rootColors[ci], z: 4)
                r.alpha = 0
                r.name = "root_tile"
                addChild(r)
                r.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay + Double(i) * 0.04),
                    SKAction.fadeIn(withDuration: 0.25),
                ]))
            }
        }

        // Pre-compute root point arrays
        var taproot: [(CGFloat, CGFloat)] = []
        for i in 0..<12 { taproot.append((0, -CGFloat(i) * s)) }

        var leftA: [(CGFloat, CGFloat)] = []
        for i in 0..<10 { let f = CGFloat(i); leftA.append((-f * s, -2 * s - f * s * 0.4)) }
        var leftB: [(CGFloat, CGFloat)] = []
        for i in 0..<8 { let f = CGFloat(i); leftB.append((-f * s * 0.8, -5 * s - f * s * 0.5)) }
        var leftC: [(CGFloat, CGFloat)] = []
        for i in 0..<6 { let f = CGFloat(i); leftC.append((-f * s * 0.6, -8 * s - f * s * 0.3)) }

        var rightA: [(CGFloat, CGFloat)] = []
        for i in 0..<10 { let f = CGFloat(i); rightA.append((f * s, -2 * s - f * s * 0.4)) }
        var rightB: [(CGFloat, CGFloat)] = []
        for i in 0..<8 { let f = CGFloat(i); rightB.append((f * s * 0.8, -5 * s - f * s * 0.5)) }
        var rightC: [(CGFloat, CGFloat)] = []
        for i in 0..<6 { let f = CGFloat(i); rightC.append((f * s * 0.6, -8 * s - f * s * 0.3)) }

        // Central taproot
        drawRoot(points: taproot, delay: 0)
        // Left laterals
        drawRoot(points: leftA, delay: 0.3)
        drawRoot(points: leftB, delay: 0.5)
        drawRoot(points: leftC, delay: 0.7)
        // Right laterals
        drawRoot(points: rightA, delay: 0.4)
        drawRoot(points: rightB, delay: 0.6)
        drawRoot(points: rightC, delay: 0.8)

        // Fine hair roots at tips
        let hairColor = SKColor(red: 0.90, green: 0.78, blue: 0.45, alpha: 0.7)
        let hairTips: [(CGFloat, CGFloat)] = [
            (-10 * s, -2 * s - 10 * s * 0.4),
            (-8 * s * 0.8, -5 * s - 8 * s * 0.5),
            (-6 * s * 0.6, -8 * s - 6 * s * 0.3),
            (10 * s, -2 * s - 10 * s * 0.4),
            (8 * s * 0.8, -5 * s - 8 * s * 0.5),
            (6 * s * 0.6, -8 * s - 6 * s * 0.3),
            (0, -12 * s),
        ]
        for (hi, tip) in hairTips.enumerated() {
            for j in 0..<3 {
                let hx = tip.0 + CGFloat.random(in: -6...6)
                let hy = tip.1 - CGFloat(j) * s * 0.5
                let hair = tile(x: centerX + hx, y: trunkBaseY + hy, color: hairColor, z: 4)
                hair.alpha = 0
                hair.name = "root_tile"
                addChild(hair)
                hair.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.0 + Double(hi) * 0.1 + Double(j) * 0.05),
                    SKAction.fadeIn(withDuration: 0.2),
                ]))
            }
        }

        // Add bright leaf bud tiles on canopy edges
        let budColors: [SKColor] = [
            SKColor(red: 0.50, green: 0.75, blue: 0.25, alpha: 1.0),
            SKColor(red: 0.55, green: 0.80, blue: 0.30, alpha: 1.0),
        ]
        for _ in 0..<20 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let r = CGFloat.random(in: 85...115)
            let bud = SKSpriteNode(
                color: budColors.randomElement()!,
                size: CGSize(width: tileSize, height: tileSize)
            )
            bud.position = CGPoint(x: centerX + cos(angle) * r, y: 350 + sin(angle) * r * 0.8)
            bud.zPosition = 16
            bud.alpha = 0
            bud.name = "canopy_tile"
            addChild(bud)
            bud.run(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0.3...1.2)),
                SKAction.fadeIn(withDuration: 0.4),
            ]))
        }
    }

    // Stage 5: Nutrients — golden glow, full bloom, sparkle tiles
    private func animateNutrients() {
        let centerX = size.width / 2

        // Nutrient colors
        let nutrientColors: [SKColor] = [
            SKColor(red: 0.90, green: 0.20, blue: 0.25, alpha: 0.8),  // red
            SKColor(red: 0.30, green: 0.45, blue: 0.90, alpha: 0.8),  // blue
            SKColor(red: 0.60, green: 0.25, blue: 0.80, alpha: 0.8),  // purple
            SKColor(red: 0.90, green: 0.40, blue: 0.65, alpha: 0.8),  // pink
        ]

        // Fruit / flower colors for canopy
        let fruitColors: [SKColor] = [
            SKColor(red: 0.95, green: 0.25, blue: 0.20, alpha: 1.0),  // red fruit
            SKColor(red: 0.95, green: 0.55, blue: 0.75, alpha: 1.0),  // pink flower
            SKColor(red: 0.70, green: 0.30, blue: 0.85, alpha: 1.0),  // purple flower
            SKColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1.0),  // yellow fruit
            SKColor(red: 1.00, green: 0.55, blue: 0.30, alpha: 1.0),  // orange fruit
        ]

        // Nutrient drops absorbed at root tips, travel up, become fruits
        let rootTips: [(CGFloat, CGFloat)] = [
            (-80, 30), (-50, 20), (-30, 40),
            (80, 30), (50, 20), (30, 40),
            (0, 10),
        ]

        let nutrientEmitter = SKAction.run { [weak self] in
            guard let self else { return }
            let tip = rootTips[Int.random(in: 0..<rootTips.count)]
            let color = nutrientColors[Int.random(in: 0..<nutrientColors.count)]

            // Nutrient drop appears near root
            let drop = SKSpriteNode(color: color, size: CGSize(width: self.tileSize, height: self.tileSize))
            drop.position = CGPoint(
                x: centerX + tip.0 + CGFloat.random(in: -15...15),
                y: tip.1 + CGFloat.random(in: -10...10)
            )
            drop.zPosition = 12
            self.addChild(drop)

            // Move to trunk base, then rise up to canopy
            let trunkX = centerX + CGFloat.random(in: -8...8)
            drop.run(SKAction.sequence([
                // Move toward trunk base
                SKAction.move(to: CGPoint(x: trunkX, y: 75), duration: 0.6),
                // Rise up through trunk
                SKAction.moveTo(y: 350, duration: 1.2),
                SKAction.fadeOut(withDuration: 0.1),
                SKAction.removeFromParent(),
            ]))

            // Spawn a fruit/flower in canopy after nutrient arrives
            let fruitDelay = 1.8 + Double.random(in: 0...0.3)
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: fruitDelay),
                SKAction.run {
                    let fruitSize = self.tileSize * CGFloat.random(in: 0.5...1.0)
                    let fruit = SKSpriteNode(
                        color: fruitColors[Int.random(in: 0..<fruitColors.count)],
                        size: CGSize(width: fruitSize, height: fruitSize)
                    )
                    let angle = CGFloat.random(in: 0...(2 * .pi))
                    let r = CGFloat.random(in: 30...100)
                    fruit.position = CGPoint(
                        x: centerX + cos(angle) * r,
                        y: 350 + sin(angle) * r * 0.75
                    )
                    fruit.zPosition = 18
                    fruit.alpha = 0
                    fruit.setScale(0.3)
                    self.addChild(fruit)
                    fruit.run(SKAction.group([
                        SKAction.fadeIn(withDuration: 0.3),
                        SKAction.scale(to: 1.0, duration: 0.3),
                    ]))
                },
            ]))
        }
        let nutrientAction = SKAction.repeatForever(SKAction.sequence([nutrientEmitter, SKAction.wait(forDuration: 0.5)]))
        let emitterNode = SKNode()
        addChild(emitterNode)
        emitterNode.run(nutrientAction)

        // Stop all flows (water + nutrients) after 1.5 minutes
        run(SKAction.sequence([
            SKAction.wait(forDuration: 90),
            SKAction.run { [weak self] in
                self?.removeAction(forKey: "water_xylem")
                self?.removeAction(forKey: "water_absorb")
                emitterNode.removeFromParent()
            },
        ]))

        // Full vibrant canopy
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.colorize(
                    with: [
                        SKColor(red: 0.12, green: 0.65, blue: 0.10, alpha: 1.0),
                        SKColor(red: 0.18, green: 0.70, blue: 0.15, alpha: 1.0),
                        SKColor(red: 0.10, green: 0.60, blue: 0.08, alpha: 1.0),
                    ].randomElement()!,
                    colorBlendFactor: 1.0, duration: 0.8
                ))
            }
        }

        // Golden glow ring
        for angle in stride(from: 0.0, to: 360.0, by: 8.0) {
            let rad = angle * .pi / 180.0
            let glowTile = SKSpriteNode(
                color: SKColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 0.0),
                size: CGSize(width: tileSize, height: tileSize)
            )
            glowTile.position = CGPoint(
                x: centerX + cos(rad) * 120,
                y: 350 + sin(rad) * 95
            )
            glowTile.zPosition = 20
            addChild(glowTile)
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.8 + Double.random(in: 0...0.3)),
                SKAction.fadeAlpha(to: 0.2, duration: 0.8 + Double.random(in: 0...0.3)),
            ])
            glowTile.run(SKAction.repeatForever(pulse))
        }

        // Full tree glow — small bright golden pixels
        let goldenGlow = SKColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0)
        let canopyGlowSize = CGSize(width: tileSize * 2, height: tileSize * 2)
        let trunkGlowSize = CGSize(width: tileSize, height: tileSize)

        // Elliptical golden glow around canopy — 45 tiles (2× trunk size)
        for i in 0..<45 {
            let angle = (CGFloat(i) / 45.0) * 2 * .pi
            let rx: CGFloat = 130
            let ry: CGFloat = 105
            let glowSpot = SKSpriteNode(color: goldenGlow, size: canopyGlowSize)
            glowSpot.position = CGPoint(
                x: centerX + cos(angle) * rx,
                y: 350 + sin(angle) * ry * 0.8
            )
            glowSpot.zPosition = 3
            glowSpot.alpha = 0
            addChild(glowSpot)
            glowSpot.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0 + Double(i) * 0.02),
                SKAction.fadeAlpha(to: 0.35, duration: 0.8),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.55, duration: 1.5),
                    SKAction.fadeAlpha(to: 0.2, duration: 1.5),
                ])),
            ]))
        }
        // Inner golden fill
        for i in 0..<12 {
            let angle = (CGFloat(i) / 12.0) * 2 * .pi
            let innerGlow = SKSpriteNode(color: goldenGlow, size: canopyGlowSize)
            innerGlow.position = CGPoint(
                x: centerX + cos(angle) * 65,
                y: 350 + sin(angle) * 50
            )
            innerGlow.zPosition = 3
            innerGlow.alpha = 0
            addChild(innerGlow)
            innerGlow.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.3),
                SKAction.fadeAlpha(to: 0.3, duration: 0.8),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.45, duration: 1.2),
                    SKAction.fadeAlpha(to: 0.15, duration: 1.2),
                ])),
            ]))
        }

        // Trunk golden glow — tiles along edges, offset outward so fully visible
        for row in stride(from: CGFloat(75), to: CGFloat(280), by: tileSize) {
            for side in [-1.0, 1.0] as [CGFloat] {
                let trunkW: CGFloat = row > 240 ? 2 : row > 200 ? 3 : 4
                let tGlow = SKSpriteNode(color: goldenGlow, size: trunkGlowSize)
                tGlow.position = CGPoint(
                    x: centerX + side * (trunkW * tileSize / 2 + tileSize),
                    y: row
                )
                tGlow.zPosition = 3
                tGlow.alpha = 0
                addChild(tGlow)
                tGlow.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.0),
                    SKAction.fadeAlpha(to: 0.3, duration: 0.8),
                    SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.45, duration: 1.5),
                        SKAction.fadeAlpha(to: 0.12, duration: 1.5),
                    ])),
                ]))
            }
        }

        // Brighten all canopy tiles with a visible pulse
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5 + Double.random(in: 0...0.5)),
                    SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to: 1.0, duration: 0.8),
                        SKAction.fadeAlpha(to: 0.7, duration: 0.8),
                    ])),
                ]))
            }
        }

        // Root glow pulse
        enumerateChildNodes(withName: "root_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.sequence([
                    SKAction.wait(forDuration: 2.0),
                    SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to: 1.0, duration: 1.2),
                        SKAction.fadeAlpha(to: 0.6, duration: 1.2),
                    ])),
                ]))
            }
        }
        // Banner
        let banner = SKLabelNode(text: "Prompt Tree Restored")
        banner.fontSize = 20
        banner.fontName = "Menlo-Bold"
        banner.fontColor = SKColor(red: 0.85, green: 0.45, blue: 0.0, alpha: 1.0)
        banner.position = CGPoint(x: centerX, y: 480)
        banner.alpha = 0
        banner.zPosition = 40
        addChild(banner)
        banner.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeIn(withDuration: 0.5),
        ]))
    }
}

