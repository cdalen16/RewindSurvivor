import SpriteKit

class RadiationFieldNode: SKNode {
    private let damageRadius: CGFloat = 100
    private let damagePerTick: CGFloat = 8
    private let tickInterval: TimeInterval = 0.4
    private var damageAccumulator: TimeInterval = 0
    private var rotationAngle: CGFloat = 0
    private var pulsePhase: CGFloat = 0

    override init() {
        super.init()

        self.name = "radiationField"
        self.zPosition = 80

        // Outer toxic ring
        let outerRing = SKShapeNode(circleOfRadius: damageRadius)
        outerRing.fillColor = ColorPalette.superRadiationField.withAlphaComponent(0.06)
        outerRing.strokeColor = ColorPalette.superRadiationField.withAlphaComponent(0.5)
        outerRing.lineWidth = 2
        outerRing.glowWidth = 3
        outerRing.name = "outerRing"
        outerRing.blendMode = .add
        addChild(outerRing)

        // Inner ring
        let innerRing = SKShapeNode(circleOfRadius: damageRadius * 0.6)
        innerRing.fillColor = ColorPalette.superRadiationField.withAlphaComponent(0.04)
        innerRing.strokeColor = ColorPalette.superRadiationField.withAlphaComponent(0.3)
        innerRing.lineWidth = 1.5
        innerRing.name = "innerRing"
        innerRing.blendMode = .add
        addChild(innerRing)

        // Radiation hazard markers orbiting
        for i in 0..<6 {
            let marker = SKSpriteNode(color: ColorPalette.superRadiationField, size: CGSize(width: 5, height: 5))
            marker.name = "radMarker_\(i)"
            marker.blendMode = .add
            marker.alpha = 0.6
            addChild(marker)
        }

        // Smaller inner particles
        for i in 0..<4 {
            let particle = SKSpriteNode(color: ColorPalette.superRadiationField, size: CGSize(width: 3, height: 3))
            particle.name = "radInner_\(i)"
            particle.blendMode = .add
            particle.alpha = 0.4
            addChild(particle)
        }

        // Spawn flash
        let flash = SKShapeNode(circleOfRadius: damageRadius * 0.5)
        flash.fillColor = ColorPalette.superRadiationField
        flash.strokeColor = .white
        flash.lineWidth = 2
        flash.blendMode = .add
        flash.alpha = 0.8
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // Pulse animation on outer ring
        outerRing.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 1.2),
            SKAction.fadeAlpha(to: 0.6, duration: 1.2)
        ])))
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(deltaTime: TimeInterval, playerPosition: CGPoint, enemies: [EnemyNode], scene: SKScene) {
        // Follow player
        position = playerPosition

        // Rotate markers
        rotationAngle += 1.5 * CGFloat(deltaTime)
        pulsePhase += 2.0 * CGFloat(deltaTime)

        for i in 0..<6 {
            if let marker = childNode(withName: "radMarker_\(i)") {
                let angle = rotationAngle + CGFloat(i) * (.pi * 2 / 6)
                let pulseOffset = sin(pulsePhase + CGFloat(i)) * 8
                let dist = damageRadius * 0.8 + pulseOffset
                marker.position = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            }
        }

        // Inner particles orbit opposite direction
        for i in 0..<4 {
            if let particle = childNode(withName: "radInner_\(i)") {
                let angle = -rotationAngle * 1.3 + CGFloat(i) * (.pi * 2 / 4)
                let dist = damageRadius * 0.4
                particle.position = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            }
        }

        // Periodic damage to enemies in range
        damageAccumulator += deltaTime
        if damageAccumulator >= tickInterval {
            damageAccumulator -= tickInterval
            for enemy in enemies {
                guard enemy.parent != nil && enemy.hp > 0 else { continue }
                let dx = position.x - enemy.position.x
                let dy = position.y - enemy.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < damageRadius {
                    // More damage closer to center
                    let falloff = 1.0 - (dist / damageRadius) * 0.5
                    let actualDmg = damagePerTick * falloff
                    enemy.takeDamage(actualDmg)
                }
            }
        }
    }
}
