import SpriteKit

class GravitySingularityNode: SKNode {
    private var remainingTime: TimeInterval
    private let pullRadius: CGFloat = 200
    private let pullForce: CGFloat = 120
    private let damagePerSecond: CGFloat = 5
    private var damageAccumulator: TimeInterval = 0
    private let damageInterval: TimeInterval = 0.5
    private var rotationAngle: CGFloat = 0

    init(duration: TimeInterval) {
        self.remainingTime = duration
        super.init()

        self.name = "gravitySingularity"
        self.zPosition = 80

        // Dark core
        let core = SKShapeNode(circleOfRadius: 12)
        core.fillColor = SKColor(red: 0.05, green: 0.0, blue: 0.1, alpha: 0.95)
        core.strokeColor = ColorPalette.superGravitySingularity
        core.lineWidth = 2
        core.glowWidth = 3
        core.name = "core"
        addChild(core)

        // Accretion ring
        let ring = SKShapeNode(circleOfRadius: 25)
        ring.fillColor = .clear
        ring.strokeColor = ColorPalette.superGravitySingularity.withAlphaComponent(0.6)
        ring.lineWidth = 2
        ring.name = "ring"
        addChild(ring)

        // Outer distortion ring
        let outerRing = SKShapeNode(circleOfRadius: pullRadius)
        outerRing.fillColor = ColorPalette.superGravitySingularity.withAlphaComponent(0.04)
        outerRing.strokeColor = ColorPalette.superGravitySingularity.withAlphaComponent(0.15)
        outerRing.lineWidth = 1.5
        outerRing.name = "outerRing"
        addChild(outerRing)

        // Debris particles (orbiting sprites)
        for i in 0..<12 {
            let debrisSize = CGFloat.random(in: 2...4)
            let debris = SKSpriteNode(color: ColorPalette.superGravitySingularity, size: CGSize(width: debrisSize, height: debrisSize))
            debris.name = "debris_\(i)"
            debris.blendMode = .add
            debris.alpha = CGFloat.random(in: 0.3...0.7)
            let dist = CGFloat.random(in: 20...60)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            debris.position = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            addChild(debris)
        }

        // Spawn flash
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.fillColor = ColorPalette.superGravitySingularity
        flash.strokeColor = .white
        flash.lineWidth = 2
        flash.blendMode = .add
        flash.alpha = 0.8
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 4.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Returns true when expired
    func update(deltaTime: TimeInterval, enemies: [EnemyNode], gameState: GameState) -> Bool {
        remainingTime -= deltaTime
        if remainingTime <= 0 {
            expire()
            return true
        }

        // Rotate debris
        rotationAngle += 2.5 * CGFloat(deltaTime)
        for i in 0..<12 {
            if let debris = childNode(withName: "debris_\(i)") {
                let baseAngle = CGFloat(i) * (.pi * 2 / 12) + rotationAngle
                let dist: CGFloat = 20 + CGFloat(i % 4) * 12
                debris.position = CGPoint(x: cos(baseAngle) * dist, y: sin(baseAngle) * dist)
            }
        }

        // Rotate ring
        if let ring = childNode(withName: "ring") {
            ring.zRotation = rotationAngle * 0.5
        }

        // Pull enemies
        for enemy in enemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            let dx = position.x - enemy.position.x
            let dy = position.y - enemy.position.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < pullRadius && dist > 5 {
                let strength = pullForce * (1.0 - dist / pullRadius)
                let dirX = dx / dist
                let dirY = dy / dist
                if let vel = enemy.physicsBody?.velocity {
                    enemy.physicsBody?.velocity = CGVector(
                        dx: vel.dx + dirX * strength * CGFloat(deltaTime) * 60,
                        dy: vel.dy + dirY * strength * CGFloat(deltaTime) * 60
                    )
                }
            }
        }

        // Periodic damage
        damageAccumulator += deltaTime
        if damageAccumulator >= damageInterval {
            damageAccumulator -= damageInterval
            let damage = damagePerSecond * CGFloat(damageInterval)
            for enemy in enemies {
                guard enemy.parent != nil && enemy.hp > 0 else { continue }
                let dx = position.x - enemy.position.x
                let dy = position.y - enemy.position.y
                if sqrt(dx * dx + dy * dy) < pullRadius {
                    enemy.takeDamage(damage)
                }
            }
        }

        // Fade at end of life
        if remainingTime < 3.0 {
            alpha = CGFloat(remainingTime / 3.0)
        }

        return false
    }

    private func expire() {
        guard let scene = self.scene else { removeFromParent(); return }

        // Implosion effect
        let implosion = SKShapeNode(circleOfRadius: pullRadius * 0.5)
        implosion.fillColor = ColorPalette.superGravitySingularity
        implosion.strokeColor = .white
        implosion.lineWidth = 2
        implosion.blendMode = .add
        implosion.position = position
        implosion.zPosition = 85
        scene.addChild(implosion)
        implosion.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.01, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        removeFromParent()
    }
}
