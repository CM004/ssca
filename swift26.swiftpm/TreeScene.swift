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
        backgroundColor = SKColor(white: 0.96, alpha: 1.0)
        drawSky()
        drawGround()
        drawTrunk()
        drawInitialCanopy()
    }

    // MARK: - Pixel tile helper

    private func tile(x: CGFloat, y: CGFloat, color: SKColor, z: CGFloat = 10) -> SKSpriteNode {
        let node = SKSpriteNode(color: color, size: CGSize(width: tileSize, height: tileSize))
        node.position = CGPoint(x: x, y: y)
        node.zPosition = z
        return node
    }

    // MARK: - Sky

    private func drawSky() {
        // Gradient sky with pixel bands
        let skyColors: [SKColor] = [
            SKColor(red: 0.78, green: 0.88, blue: 0.93, alpha: 1.0), // light blue top
            SKColor(red: 0.82, green: 0.91, blue: 0.95, alpha: 1.0),
            SKColor(red: 0.86, green: 0.93, blue: 0.96, alpha: 1.0),
            SKColor(red: 0.90, green: 0.95, blue: 0.97, alpha: 1.0), // lighter near horizon
        ]
        let bandHeight = size.height / CGFloat(skyColors.count)
        for (i, color) in skyColors.enumerated() {
            let band = SKSpriteNode(color: color, size: CGSize(width: size.width, height: bandHeight + 2))
            band.position = CGPoint(x: size.width / 2, y: size.height - bandHeight * CGFloat(i) - bandHeight / 2)
            band.zPosition = 0
            addChild(band)
        }

        // Mountain silhouette with tiles
        let mountainColors = [
            SKColor(red: 0.65, green: 0.72, blue: 0.80, alpha: 0.5),
            SKColor(red: 0.60, green: 0.68, blue: 0.76, alpha: 0.4),
        ]
        let mountainY: CGFloat = 150
        for col in stride(from: CGFloat(0), to: size.width, by: tileSize) {
            // Create gentle mountain shapes
            let mountainHeight = 40 + 30 * sin(col * 0.015) + 20 * sin(col * 0.03 + 1)
            for row in stride(from: CGFloat(0), to: mountainHeight, by: tileSize) {
                let ci = Int.random(in: 0..<mountainColors.count)
                addChild(tile(x: col, y: mountainY + row, color: mountainColors[ci], z: 1))
            }
        }
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

        // Fog overlay — scatter grey tiles on top
        for _ in 0..<60 {
            let fogTile = SKSpriteNode(
                color: SKColor(white: 0.85, alpha: 0.4),
                size: CGSize(width: tileSize * 2, height: tileSize * 2)
            )
            fogTile.position = CGPoint(
                x: CGFloat.random(in: 20...(size.width - 20)),
                y: CGFloat.random(in: 100...(size.height - 20))
            )
            fogTile.zPosition = 50
            fogTile.name = "fog_tile"
            addChild(fogTile)
        }
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

    // Stage 1: Air — fog clears, canopy begins to lighten
    private func animateAir() {
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

    // Stage 2: Water — blue droplet tiles fall, canopy greens more
    private func animateWater() {
        let centerX = size.width / 2
        let dropColors: [SKColor] = [
            SKColor(red: 0.30, green: 0.60, blue: 0.90, alpha: 0.8),
            SKColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 0.7),
        ]

        let emitter = SKAction.run { [weak self] in
            guard let self else { return }
            let ci = Int.random(in: 0..<dropColors.count)
            let drop = SKSpriteNode(
                color: dropColors[ci],
                size: CGSize(width: self.tileSize, height: self.tileSize)
            )
            drop.position = CGPoint(
                x: centerX + CGFloat.random(in: -15...15),
                y: 350
            )
            drop.zPosition = 12
            self.addChild(drop)
            drop.run(SKAction.sequence([
                SKAction.moveTo(y: 80, duration: 1.5),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent(),
            ]))
        }
        run(SKAction.repeatForever(SKAction.sequence([emitter, SKAction.wait(forDuration: 0.3)])))

        // Deepen canopy green
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.colorize(
                    with: SKColor(red: 0.15, green: 0.55, blue: 0.18, alpha: 1.0),
                    colorBlendFactor: 0.6, duration: 1.5
                ))
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

        // Brighten canopy to vibrant green
        enumerateChildNodes(withName: "canopy_tile") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.run(SKAction.sequence([
                    SKAction.wait(forDuration: Double.random(in: 0...0.5)),
                    SKAction.colorize(
                        with: [
                            SKColor(red: 0.18, green: 0.62, blue: 0.15, alpha: 1.0),
                            SKColor(red: 0.22, green: 0.58, blue: 0.20, alpha: 1.0),
                            SKColor(red: 0.15, green: 0.65, blue: 0.12, alpha: 1.0),
                        ].randomElement()!,
                        colorBlendFactor: 0.8, duration: 0.8
                    ),
                ]))
            }
        }
    }

    // Stage 4: Soil — root tiles extend, leaf buds appear
    private func animateSoil() {
        let centerX = size.width / 2
        let rootColor = SKColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 1.0)

        // Extend root tiles underground
        let rootPaths: [(dx: CGFloat, dy: CGFloat)] = [
            (-1, -0.5), (-1.2, -0.3), (1, -0.5), (1.1, -0.4), (0, -1),
        ]
        for (pi, path) in rootPaths.enumerated() {
            for i in 0..<8 {
                let root = tile(
                    x: centerX + path.dx * CGFloat(i) * tileSize,
                    y: 75 + path.dy * CGFloat(i) * tileSize,
                    color: rootColor, z: 4
                )
                root.alpha = 0
                addChild(root)
                root.run(SKAction.sequence([
                    SKAction.wait(forDuration: Double(pi) * 0.15 + Double(i) * 0.08),
                    SKAction.fadeIn(withDuration: 0.3),
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

        // Golden glow ring — tile-based
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
            glowTile.name = "glow_tile"
            addChild(glowTile)

            // Pulsing glow
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.8 + Double.random(in: 0...0.3)),
                SKAction.fadeAlpha(to: 0.2, duration: 0.8 + Double.random(in: 0...0.3)),
            ])
            glowTile.run(SKAction.repeatForever(pulse))
        }

        // Sparkle burst tiles
        for _ in 0..<20 {
            let spark = SKSpriteNode(
                color: SKColor(red: 1.0, green: 0.92, blue: 0.5, alpha: 0.9),
                size: CGSize(width: tileSize, height: tileSize)
            )
            spark.position = CGPoint(x: centerX, y: 380)
            spark.zPosition = 30
            addChild(spark)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -60...100), duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0),
                ]),
                SKAction.removeFromParent(),
            ]))
        }

        // Banner
        let banner = SKLabelNode(text: "🌳 Restored")
        banner.fontSize = 16
        banner.fontName = "Menlo-Bold"
        banner.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        banner.position = CGPoint(x: centerX, y: 480)
        banner.alpha = 0
        banner.zPosition = 40
        addChild(banner)
        banner.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeIn(withDuration: 0.5),
        ]))
    }
}
