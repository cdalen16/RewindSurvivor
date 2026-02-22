import SpriteKit

class ElementalStormNode: SKNode {
    private let blastInterval: TimeInterval = 10.0
    private var blastTimer: TimeInterval = 9.0 // First blast after 1 second
    private let blastRadius: CGFloat = 140
    private let blastDamage: CGFloat = 40
    private var orbAngle: CGFloat = 0

    // Element types for visual variety
    private enum Element: CaseIterable {
        case lightning, ice, fire

        var color: SKColor {
            switch self {
            case .lightning: return SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
            case .ice: return SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0)
            case .fire: return SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0)
            }
        }
    }

    override init() {
        super.init()

        self.name = "elementalStorm"
        self.zPosition = 82

        // Ambient elemental orbs orbiting the player
        for i in 0..<3 {
            let element = Element.allCases[i]
            let orb = SKSpriteNode(color: element.color, size: CGSize(width: 6, height: 6))
            orb.name = "elemOrb_\(i)"
            orb.blendMode = .add
            orb.alpha = 0.7
            addChild(orb)

            // Glow around orb
            let glow = SKSpriteNode(color: element.color, size: CGSize(width: 14, height: 14))
            glow.name = "elemGlow_\(i)"
            glow.blendMode = .add
            glow.alpha = 0.2
            addChild(glow)
        }

        // Spawn flash
        let flash = SKSpriteNode(color: ColorPalette.superElementalStorm, size: CGSize(width: 48, height: 48))
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.8
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 3.0, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(deltaTime: TimeInterval, playerPosition: CGPoint, enemies: [EnemyNode], scene: SKScene) {
        // Follow player
        position = playerPosition

        // Orbit elemental orbs
        orbAngle += 2.0 * CGFloat(deltaTime)
        for i in 0..<3 {
            let angle = orbAngle + CGFloat(i) * (.pi * 2 / 3)
            let dist: CGFloat = 35
            let pos = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            childNode(withName: "elemOrb_\(i)")?.position = pos
            childNode(withName: "elemGlow_\(i)")?.position = pos
        }

        // Blast timer
        blastTimer += deltaTime
        if blastTimer >= blastInterval {
            blastTimer -= blastInterval
            let element = Element.allCases.randomElement() ?? .fire
            triggerBlast(element: element, enemies: enemies, scene: scene)
        }
    }

    private func triggerBlast(element: Element, enemies: [EnemyNode], scene: SKScene) {
        switch element {
        case .lightning:
            triggerLightningChain(enemies: enemies, scene: scene)
        case .ice:
            triggerIceNova(enemies: enemies, scene: scene)
        case .fire:
            triggerFireBurst(enemies: enemies, scene: scene)
        }
    }

    // MARK: - Lightning Chain

    private func triggerLightningChain(enemies: [EnemyNode], scene: SKScene) {
        let color = Element.lightning.color

        // Find enemies in range, chain through up to 8
        var chainTargets: [EnemyNode] = []
        var remaining = enemies.filter { $0.parent != nil && $0.hp > 0 }
        var lastPos = position

        for _ in 0..<8 {
            guard let nearest = remaining.min(by: {
                let d1 = hypot($0.position.x - lastPos.x, $0.position.y - lastPos.y)
                let d2 = hypot($1.position.x - lastPos.x, $1.position.y - lastPos.y)
                return d1 < d2
            }) else { break }

            let dist = hypot(nearest.position.x - lastPos.x, nearest.position.y - lastPos.y)
            guard dist < blastRadius else { break }

            chainTargets.append(nearest)
            remaining.removeAll { $0 === nearest }
            lastPos = nearest.position
        }

        // Apply damage and draw bolts
        var prevPos = position
        for target in chainTargets {
            target.takeDamage(blastDamage)
            drawLightningBolt(from: prevPos, to: target.position, color: color, scene: scene)
            prevPos = target.position
        }

        // Flash at origin
        let flash = SKSpriteNode(color: color, size: CGSize(width: 30, height: 30))
        flash.position = position
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.7
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 2.0, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func drawLightningBolt(from start: CGPoint, to end: CGPoint, color: SKColor, scene: SKScene) {
        let path = CGMutablePath()
        path.move(to: start)

        // Jagged segments
        let dx = end.x - start.x
        let dy = end.y - start.y
        let segments = 5
        for i in 1..<segments {
            let t = CGFloat(i) / CGFloat(segments)
            let jitter = CGFloat.random(in: -12...12)
            let perpX = -dy / hypot(dx, dy) * jitter
            let perpY = dx / hypot(dx, dy) * jitter
            path.addLine(to: CGPoint(x: start.x + dx * t + perpX,
                                      y: start.y + dy * t + perpY))
        }
        path.addLine(to: end)

        let bolt = SKShapeNode(path: path)
        bolt.strokeColor = color
        bolt.lineWidth = 2
        bolt.glowWidth = 4
        bolt.blendMode = .add
        bolt.zPosition = 199
        scene.addChild(bolt)
        bolt.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Ice Nova

    private func triggerIceNova(enemies: [EnemyNode], scene: SKScene) {
        let color = Element.ice.color

        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = color
        ring.fillColor = color.withAlphaComponent(0.1)
        ring.lineWidth = 3
        ring.glowWidth = 4
        ring.blendMode = .add
        ring.position = position
        ring.zPosition = 199
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: blastRadius / 20, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))

        // Ice crystal particles
        for _ in 0..<12 {
            let crystal = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            crystal.position = position
            crystal.zPosition = 200
            crystal.blendMode = .add
            crystal.alpha = 0.8
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 60...blastRadius)
            scene.addChild(crystal)
            crystal.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: CGPoint(x: position.x + cos(angle) * dist,
                                               y: position.y + sin(angle) * dist), duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.3, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Damage + slow enemies in range
        for enemy in enemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            let dx = position.x - enemy.position.x
            let dy = position.y - enemy.position.y
            if sqrt(dx * dx + dy * dy) < blastRadius {
                enemy.takeDamage(blastDamage)
                // Brief speed reduction via velocity damping
                if let vel = enemy.physicsBody?.velocity {
                    enemy.physicsBody?.velocity = CGVector(dx: vel.dx * 0.3, dy: vel.dy * 0.3)
                }
            }
        }
    }

    // MARK: - Fire Burst

    private func triggerFireBurst(enemies: [EnemyNode], scene: SKScene) {
        let color = Element.fire.color

        // Central explosion
        let explosion = SKSpriteNode(color: color, size: CGSize(width: 40, height: 40))
        explosion.position = position
        explosion.zPosition = 200
        explosion.blendMode = .add
        explosion.alpha = 0.9
        scene.addChild(explosion)
        explosion.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: blastRadius / 20, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // Fire embers
        for _ in 0..<16 {
            let ember = SKSpriteNode(color: [color, .yellow, .orange].randomElement()!,
                                      size: CGSize(width: CGFloat.random(in: 3...6),
                                                    height: CGFloat.random(in: 3...6)))
            ember.position = position
            ember.zPosition = 201
            ember.blendMode = .add
            ember.alpha = 0.9
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 40...blastRadius * 1.1)
            scene.addChild(ember)
            ember.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: CGPoint(x: position.x + cos(angle) * dist,
                                               y: position.y + sin(angle) * dist), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.2, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Damage enemies in range (slightly higher than other elements)
        let fireDamage = blastDamage * 1.2
        for enemy in enemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            let dx = position.x - enemy.position.x
            let dy = position.y - enemy.position.y
            if sqrt(dx * dx + dy * dy) < blastRadius {
                enemy.takeDamage(fireDamage)
            }
        }
    }
}
