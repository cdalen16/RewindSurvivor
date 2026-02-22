import SpriteKit

class ShockwavePulseNode: SKNode {
    private let pulseInterval: TimeInterval = 10.0
    private var pulseTimer: TimeInterval = 9.0 // First pulse after 1 second
    private let pushRadius: CGFloat = 200
    private let pushForce: CGFloat = 800
    private let pulseDamage: CGFloat = 15
    private var orbAngle: CGFloat = 0
    private var chargePhase: CGFloat = 0

    override init() {
        super.init()

        self.name = "shockwavePulse"
        self.zPosition = 83

        // Core energy orb
        let core = SKShapeNode(circleOfRadius: 8)
        core.fillColor = ColorPalette.superShockwavePulse
        core.strokeColor = .white
        core.lineWidth = 1.5
        core.glowWidth = 3
        core.name = "core"
        core.blendMode = .add
        core.alpha = 0.6
        addChild(core)

        // Orbiting charge particles
        for i in 0..<4 {
            let particle = SKSpriteNode(color: ColorPalette.superShockwavePulse,
                                         size: CGSize(width: 4, height: 4))
            particle.name = "chargeOrb_\(i)"
            particle.blendMode = .add
            particle.alpha = 0.5
            addChild(particle)
        }

        // Spawn flash
        let flash = SKSpriteNode(color: ColorPalette.superShockwavePulse,
                                  size: CGSize(width: 48, height: 48))
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
        position = playerPosition

        pulseTimer += deltaTime
        orbAngle += 2.5 * CGFloat(deltaTime)

        // Charge-up visual: particles orbit faster and glow brighter as pulse approaches
        let chargeProgress = min(1.0, CGFloat(pulseTimer / pulseInterval))
        let orbitDist: CGFloat = 25 - chargeProgress * 10 // Tighten orbit as charge builds
        let orbitSpeedMult: CGFloat = 1.0 + chargeProgress * 2.0

        for i in 0..<4 {
            if let particle = childNode(withName: "chargeOrb_\(i)") {
                let angle = orbAngle * orbitSpeedMult + CGFloat(i) * (.pi * 2 / 4)
                particle.position = CGPoint(x: cos(angle) * orbitDist, y: sin(angle) * orbitDist)
                particle.alpha = 0.3 + chargeProgress * 0.5
            }
        }

        // Core pulses brighter as charge builds
        if let core = childNode(withName: "core") as? SKShapeNode {
            core.alpha = 0.4 + chargeProgress * 0.5
        }

        // Trigger shockwave
        if pulseTimer >= pulseInterval {
            pulseTimer -= pulseInterval
            triggerShockwave(enemies: enemies, scene: scene)
        }
    }

    private func triggerShockwave(enemies: [EnemyNode], scene: SKScene) {
        let color = ColorPalette.superShockwavePulse

        // Expanding shockwave ring
        let ring = SKShapeNode(circleOfRadius: 15)
        ring.strokeColor = color
        ring.fillColor = color.withAlphaComponent(0.15)
        ring.lineWidth = 4
        ring.glowWidth = 6
        ring.blendMode = .add
        ring.position = position
        ring.zPosition = 200
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: pushRadius / 15, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))

        // Second ring (slightly delayed for layered effect)
        let ring2 = SKShapeNode(circleOfRadius: 10)
        ring2.strokeColor = .white
        ring2.fillColor = .clear
        ring2.lineWidth = 2
        ring2.glowWidth = 3
        ring2.blendMode = .add
        ring2.position = position
        ring2.zPosition = 201
        scene.addChild(ring2)
        ring2.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.group([
                SKAction.scale(to: pushRadius / 10, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // Center flash
        let flash = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 30))
        flash.position = position
        flash.zPosition = 202
        flash.blendMode = .add
        flash.alpha = 0.9
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.scale(to: 2.5, duration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))

        // Radial debris particles
        for _ in 0..<20 {
            let debris = SKSpriteNode(color: [color, .white, color].randomElement()!,
                                       size: CGSize(width: CGFloat.random(in: 2...4),
                                                     height: CGFloat.random(in: 2...4)))
            debris.position = position
            debris.zPosition = 199
            debris.blendMode = .add
            debris.alpha = 0.7
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: pushRadius * 0.5...pushRadius * 1.1)
            scene.addChild(debris)
            debris.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: CGPoint(x: position.x + cos(angle) * dist,
                                               y: position.y + sin(angle) * dist), duration: 0.35),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.3, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Push and damage all enemies in radius
        for enemy in enemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            let dx = enemy.position.x - position.x
            let dy = enemy.position.y - position.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist < pushRadius && dist > 1 {
                // Damage
                enemy.takeDamage(pulseDamage)

                // Push away from center — stronger when closer
                let falloff = 1.0 - (dist / pushRadius) * 0.5
                let dirX = dx / dist
                let dirY = dy / dist
                let force = pushForce * falloff
                if let body = enemy.physicsBody {
                    body.velocity = CGVector(
                        dx: body.velocity.dx + dirX * force,
                        dy: body.velocity.dy + dirY * force
                    )
                }
            }
        }
    }
}
