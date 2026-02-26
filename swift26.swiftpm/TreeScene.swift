//
//  TreeScene.swift
//  The Living Prompt Tree
//
//  SpriteKit scene: a living tree with 5 element layers
//  that animate progressively as stages are completed.
//

import SpriteKit

class TreeScene: SKScene, ObservableObject {

    // Tree components
    private var trunk: SKShapeNode!
    private var canopy: SKShapeNode!
    private var roots: SKShapeNode!
    private var fogOverlay: SKShapeNode!
    private var skyNode: SKSpriteNode!

    // Element layers
    private var airParticles: SKEmitterNode?
    private var waterDroplets: SKEmitterNode?
    private var sunRays: SKShapeNode?
    private var soilGlow: SKShapeNode?
    private var protectionGlow: SKShapeNode?

    private var completedStages: Set<Int> = []

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.96, alpha: 1.0)
        buildTree()
        addFog()
    }

    // MARK: - Build Tree

    private func buildTree() {
        let centerX = size.width / 2

        // Ground
        let ground = SKShapeNode(rectOf: CGSize(width: size.width, height: 80))
        ground.position = CGPoint(x: centerX, y: 40)
        ground.fillColor = SKColor(red: 0.75, green: 0.65, blue: 0.50, alpha: 1.0)
        ground.strokeColor = .clear
        addChild(ground)

        // Roots (initially faint)
        let rootPath = CGMutablePath()
        rootPath.move(to: CGPoint(x: -40, y: 0))
        rootPath.addCurve(to: CGPoint(x: -80, y: -30),
                         control1: CGPoint(x: -50, y: -10),
                         control2: CGPoint(x: -70, y: -25))
        rootPath.move(to: CGPoint(x: 40, y: 0))
        rootPath.addCurve(to: CGPoint(x: 80, y: -25),
                         control1: CGPoint(x: 50, y: -8),
                         control2: CGPoint(x: 70, y: -20))
        rootPath.move(to: CGPoint(x: 0, y: 0))
        rootPath.addCurve(to: CGPoint(x: -20, y: -35),
                         control1: CGPoint(x: -5, y: -15),
                         control2: CGPoint(x: -15, y: -28))

        roots = SKShapeNode(path: rootPath)
        roots.position = CGPoint(x: centerX, y: 100)
        roots.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.3)
        roots.lineWidth = 3.0
        roots.lineCap = .round
        addChild(roots)

        // Trunk
        let trunkPath = CGMutablePath()
        trunkPath.move(to: CGPoint(x: -16, y: 0))
        trunkPath.addLine(to: CGPoint(x: -12, y: 200))
        trunkPath.addLine(to: CGPoint(x: 12, y: 200))
        trunkPath.addLine(to: CGPoint(x: 16, y: 0))
        trunkPath.closeSubpath()

        trunk = SKShapeNode(path: trunkPath)
        trunk.position = CGPoint(x: centerX, y: 100)
        trunk.fillColor = SKColor(red: 0.25, green: 0.15, blue: 0.08, alpha: 1.0)
        trunk.strokeColor = SKColor(red: 0.18, green: 0.10, blue: 0.05, alpha: 1.0)
        trunk.lineWidth = 1.5
        addChild(trunk)

        // Canopy (initially grey/wilted)
        canopy = SKShapeNode(ellipseOf: CGSize(width: 160, height: 140))
        canopy.position = CGPoint(x: centerX, y: 340)
        canopy.fillColor = SKColor(red: 0.25, green: 0.28, blue: 0.20, alpha: 0.7)
        canopy.strokeColor = SKColor(red: 0.20, green: 0.22, blue: 0.15, alpha: 0.5)
        canopy.lineWidth = 1
        addChild(canopy)

        // Small branches
        for angle in stride(from: -60.0, through: 60.0, by: 30.0) {
            let branchLength: CGFloat = 35
            let rad = angle * .pi / 180.0
            let branch = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: cos(rad) * branchLength, y: sin(rad) * branchLength + 20))
            branch.path = path
            branch.position = CGPoint(x: centerX, y: 290)
            branch.strokeColor = SKColor(red: 0.22, green: 0.13, blue: 0.06, alpha: 0.6)
            branch.lineWidth = 2
            branch.lineCap = .round
            addChild(branch)
        }

        // Tree label
        let label = SKLabelNode(text: "🌳")
        label.fontSize = 24
        label.position = CGPoint(x: centerX, y: 420)
        label.alpha = 0.3
        addChild(label)
    }

    // MARK: - Fog

    private func addFog() {
        fogOverlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        fogOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        fogOverlay.fillColor = SKColor(white: 0.85, alpha: 0.5)
        fogOverlay.strokeColor = .clear
        fogOverlay.zPosition = 50
        addChild(fogOverlay)
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

    // Stage 1: Air — fog clears, leaves lift
    private func animateAir() {
        // Clear fog
        fogOverlay.run(SKAction.fadeAlpha(to: 0.15, duration: 1.2))

        // Lighten canopy
        canopy.run(SKAction.customAction(withDuration: 1.0) { node, t in
            let ratio = t / 1.0
            (node as? SKShapeNode)?.fillColor = SKColor(
                red: 0.25 + ratio * 0.1,
                green: 0.28 + ratio * 0.2,
                blue: 0.20,
                alpha: 0.7 + ratio * 0.2
            )
        })

        // Gentle sway
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.015, duration: 2.0),
            SKAction.rotate(byAngle: -0.03, duration: 4.0),
            SKAction.rotate(byAngle: 0.015, duration: 2.0),
        ])
        canopy.run(SKAction.repeatForever(sway))
    }

    // Stage 2: Water — droplets flow down trunk
    private func animateWater() {
        let centerX = size.width / 2

        // Water flow effect (simple dots moving down)
        let emitter = SKAction.run { [weak self] in
            guard let self else { return }
            let drop = SKShapeNode(circleOfRadius: 2)
            drop.fillColor = SKColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 0.8)
            drop.strokeColor = .clear
            drop.position = CGPoint(x: centerX + CGFloat.random(in: -8...8), y: 340)
            drop.zPosition = 10
            self.addChild(drop)

            let fall = SKAction.moveTo(y: 80, duration: 2.0)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            drop.run(SKAction.sequence([fall, fade, SKAction.removeFromParent()]))
        }
        run(SKAction.repeatForever(SKAction.sequence([emitter, SKAction.wait(forDuration: 0.4)])))

        // Deepen canopy green
        canopy.run(SKAction.customAction(withDuration: 1.5) { node, t in
            let ratio = t / 1.5
            (node as? SKShapeNode)?.fillColor = SKColor(
                red: 0.15,
                green: 0.38 + ratio * 0.15,
                blue: 0.12,
                alpha: 0.85 + ratio * 0.1
            )
        })
    }

    // Stage 3: Sunlight — sun rays, golden pulse
    private func animateSunlight() {
        // Remove remaining fog
        fogOverlay.run(SKAction.fadeOut(withDuration: 0.8))

        // Sun rays
        let centerX = size.width / 2
        for i in 0..<5 {
            let ray = SKShapeNode(rectOf: CGSize(width: 3, height: 120))
            ray.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.0)
            ray.strokeColor = .clear
            ray.zPosition = 5
            let angle = Double(i - 2) * 15.0 * .pi / 180.0
            ray.position = CGPoint(x: centerX + sin(angle) * 60, y: 480)
            ray.zRotation = CGFloat(-angle)
            addChild(ray)

            ray.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.15),
                SKAction.fadeAlpha(to: 0.4, duration: 0.6),
            ]))
        }

        // Golden pulse on canopy
        let glow = SKAction.sequence([
            SKAction.customAction(withDuration: 0.5) { node, t in
                let ratio = t / 0.5
                (node as? SKShapeNode)?.fillColor = SKColor(
                    red: 0.2 + ratio * 0.3,
                    green: 0.5 + ratio * 0.2,
                    blue: 0.1,
                    alpha: 0.95
                )
            },
            SKAction.customAction(withDuration: 0.5) { node, t in
                let ratio = t / 0.5
                (node as? SKShapeNode)?.fillColor = SKColor(
                    red: 0.5 - ratio * 0.3,
                    green: 0.7 - ratio * 0.15,
                    blue: 0.1,
                    alpha: 0.95
                )
            },
        ])
        canopy.run(glow)
    }

    // Stage 4: Soil — roots extend, soil darkens
    private func animateSoil() {
        // Roots become visible
        roots.run(SKAction.customAction(withDuration: 1.2) { node, t in
            let ratio = t / 1.2
            (node as? SKShapeNode)?.strokeColor = SKColor(
                red: 0.3 + ratio * 0.15,
                green: 0.2 + ratio * 0.1,
                blue: 0.1,
                alpha: 0.3 + ratio * 0.6
            )
        })
        roots.run(SKAction.sequence([
            SKAction.scaleX(to: 1.3, duration: 1.0),
        ]))

        // Leaf buds — small circles on canopy edges
        let centerX = size.width / 2
        for i in 0..<6 {
            let bud = SKShapeNode(circleOfRadius: 3)
            bud.fillColor = SKColor(red: 0.4, green: 0.7, blue: 0.2, alpha: 0.0)
            bud.strokeColor = .clear
            let angle = Double(i) * 60.0 * .pi / 180.0
            bud.position = CGPoint(
                x: centerX + cos(angle) * 70,
                y: 340 + sin(angle) * 60
            )
            bud.zPosition = 15
            addChild(bud)
            bud.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.2),
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.8, duration: 0.5),
                    SKAction.scale(to: 1.5, duration: 0.5),
                ]),
            ]))
        }
    }

    // Stage 5: Nutrients — golden glow, full bloom, sparkle burst
    private func animateNutrients() {
        let centerX = size.width / 2

        // Full green canopy
        canopy.run(SKAction.customAction(withDuration: 1.0) { node, t in
            let ratio = t / 1.0
            (node as? SKShapeNode)?.fillColor = SKColor(
                red: 0.1,
                green: 0.55 + ratio * 0.1,
                blue: 0.15,
                alpha: 1.0
            )
        })

        // Protective golden glow ring
        let glow = SKShapeNode(ellipseOf: CGSize(width: 180, height: 160))
        glow.position = CGPoint(x: centerX, y: 340)
        glow.fillColor = .clear
        glow.strokeColor = SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 0.0)
        glow.lineWidth = 3
        glow.zPosition = 20
        addChild(glow)

        let pulse = SKAction.sequence([
            SKAction.customAction(withDuration: 0.8) { node, t in
                (node as? SKShapeNode)?.strokeColor = SKColor(
                    red: 1.0, green: 0.7, blue: 0.2, alpha: Double(t / 0.8) * 0.6
                )
            },
            SKAction.customAction(withDuration: 0.8) { node, t in
                (node as? SKShapeNode)?.strokeColor = SKColor(
                    red: 1.0, green: 0.7, blue: 0.2, alpha: 0.6 - Double(t / 0.8) * 0.4
                )
            },
        ])
        glow.run(SKAction.repeatForever(pulse))

        // Sparkle burst
        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: 2)
            spark.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.9)
            spark.strokeColor = .clear
            spark.position = CGPoint(x: centerX, y: 380)
            spark.zPosition = 30
            addChild(spark)

            let dx = CGFloat.random(in: -80...80)
            let dy = CGFloat.random(in: -60...80)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 1.2),
                    SKAction.fadeOut(withDuration: 1.2),
                ]),
                SKAction.removeFromParent(),
            ]))
        }

        // Banner
        let banner = SKLabelNode(text: "🌳 Restored")
        banner.fontSize = 16
        banner.fontName = "Georgia-Bold"
        banner.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        banner.position = CGPoint(x: centerX, y: 460)
        banner.alpha = 0
        banner.zPosition = 40
        addChild(banner)
        banner.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeIn(withDuration: 0.5),
        ]))
    }
}
