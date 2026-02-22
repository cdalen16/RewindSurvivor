import SpriteKit

class ShadowCloneNode: SKSpriteNode {
    var hp: CGFloat = 50
    let maxHP: CGFloat = 50
    private var orbitAngle: CGFloat = 0
    private let orbitRadius: CGFloat = 150
    private let orbitSpeed: CGFloat = 1.5
    private var attackTimer: TimeInterval = 0
    private var hpBar: SKShapeNode?
    private var hpFill: SKSpriteNode?

    init() {
        let texture = SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: 0)
        super.init(texture: texture, color: ColorPalette.superShadowClone, size: CGSize(width: 32, height: 32))

        self.name = "shadowClone"
        self.zPosition = 95
        self.alpha = 0.7
        self.colorBlendFactor = 0.5

        // Physics
        let body = SKPhysicsBody(circleOfRadius: 12)
        body.categoryBitMask = PhysicsCategory.ghost
        body.contactTestBitMask = PhysicsCategory.enemyBullet
        body.collisionBitMask = PhysicsCategory.none
        body.allowsRotation = false
        body.affectedByGravity = false
        self.physicsBody = body

        // Purple glow
        let glow = SKSpriteNode(texture: texture, size: CGSize(width: 48, height: 48))
        glow.alpha = 0.3
        glow.blendMode = .add
        glow.color = ColorPalette.superShadowClone
        glow.colorBlendFactor = 0.8
        glow.name = "cloneGlow"
        addChild(glow)

        // Mini HP bar
        let barWidth: CGFloat = 24
        let barHeight: CGFloat = 3
        let barBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 1)
        barBg.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8)
        barBg.strokeColor = .clear
        barBg.position = CGPoint(x: 0, y: -20)
        barBg.zPosition = 1
        addChild(barBg)
        hpBar = barBg

        let fill = SKSpriteNode(color: ColorPalette.superShadowClone, size: CGSize(width: barWidth - 2, height: barHeight - 1))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -(barWidth - 2) / 2, y: -20)
        fill.zPosition = 2
        addChild(fill)
        hpFill = fill
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(deltaTime: TimeInterval, playerPosition: CGPoint, enemies: [EnemyNode],
                combatSystem: CombatSystem, scene: SKScene, gameState: GameState) {
        // Orbit player
        orbitAngle += orbitSpeed * CGFloat(deltaTime)
        let targetX = playerPosition.x + cos(orbitAngle) * orbitRadius
        let targetY = playerPosition.y + sin(orbitAngle) * orbitRadius

        let dx = targetX - position.x
        let dy = targetY - position.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist > 2 {
            let speed: CGFloat = dist > 250 ? 600 : 300
            let move = min(speed * CGFloat(deltaTime), dist)
            position.x += (dx / dist) * move
            position.y += (dy / dist) * move
        }

        // Animation
        let frame = Int(orbitAngle * 2) % 2
        self.texture = SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: frame)

        // Auto-fire at nearest enemy
        attackTimer += deltaTime
        let effectiveInterval = GameConfig.playerBaseAttackInterval / gameState.playerAttackSpeedMultiplier
        if attackTimer >= effectiveInterval {
            if let target = combatSystem.findNearestEnemy(to: position, enemies: enemies) {
                attackTimer = 0
                combatSystem.fireGhostProjectile(from: position, toward: target, scene: scene, gameState: gameState, levelMultiplier: 0.8)
            }
        }

        // Update HP bar
        let ratio = hp / maxHP
        let barWidth: CGFloat = 22
        hpFill?.size.width = barWidth * ratio
    }

    @discardableResult
    func takeDamage(_ amount: CGFloat) -> Bool {
        hp -= amount
        // Flash
        run(SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(with: ColorPalette.superShadowClone, colorBlendFactor: 0.5, duration: 0.05)
        ]), withKey: "cloneHit")

        if hp <= 0 {
            hp = 0
            die()
            return true
        }
        return false
    }

    private func die() {
        guard let scene = self.scene else { removeFromParent(); return }

        // Death particles
        for _ in 0..<15 {
            let p = SKSpriteNode(color: ColorPalette.superShadowClone, size: CGSize(width: 3, height: 3))
            p.position = position
            p.zPosition = 96
            p.blendMode = .add
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...120)
            scene.addChild(p)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: cos(angle) * speed * 0.4, dy: sin(angle) * speed * 0.4), duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.1, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        removeFromParent()
    }
}
