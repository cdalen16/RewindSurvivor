import SpriteKit

class PlayerNode: SKSpriteNode {
    var hp: CGFloat = GameConfig.playerBaseHP
    var maxHP: CGFloat = GameConfig.playerBaseHP
    var isInvincible: Bool = false
    var facingDirection: CGVector = CGVector(dx: 0, dy: -1)
    private var animationTimer: TimeInterval = 0
    private var currentFrame: Int = 0
    private let animationInterval: TimeInterval = 0.2
    private var currentFacing: SpriteFactory.Direction = .down
    private var trailTimer: TimeInterval = 0
    private let trailInterval: TimeInterval = 0.06

    init() {
        let texture = SpriteFactory.shared.playerTexture(facing: .down, frame: 0)
        super.init(texture: texture, color: .clear, size: CGSize(width: 32, height: 32))

        self.name = "player"
        self.zPosition = 100

        // Physics body
        let body = SKPhysicsBody(circleOfRadius: 12)
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.enemyBullet | PhysicsCategory.pickup
        body.collisionBitMask = PhysicsCategory.wall
        body.allowsRotation = false
        body.affectedByGravity = false
        body.linearDamping = 0
        body.friction = 0
        self.physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(gameState: GameState) {
        maxHP = GameConfig.playerBaseHP + gameState.playerHPBonus
        hp = maxHP
        isInvincible = false
        position = .zero
    }

    func update(deltaTime: TimeInterval, velocity: CGVector, gameState: GameState) {
        // Movement
        let speed = GameConfig.playerBaseSpeed * gameState.playerSpeedMultiplier
        let moveX = velocity.dx * speed * CGFloat(deltaTime)
        let moveY = velocity.dy * speed * CGFloat(deltaTime)

        position.x += moveX
        position.y += moveY

        // Clamp to arena bounds
        let halfArena = GameConfig.arenaSize.width / 2 - 20
        position.x = max(-halfArena, min(halfArena, position.x))
        position.y = max(-halfArena, min(halfArena, position.y))

        // Update facing direction
        if abs(velocity.dx) > 0.1 || abs(velocity.dy) > 0.1 {
            facingDirection = velocity

            // Determine facing
            let newFacing: SpriteFactory.Direction
            if abs(velocity.dx) > abs(velocity.dy) {
                newFacing = velocity.dx > 0 ? .right : .left
            } else {
                newFacing = velocity.dy > 0 ? .up : .down
            }

            // Animation
            animationTimer += deltaTime
            if animationTimer >= animationInterval {
                animationTimer = 0
                currentFrame = (currentFrame + 1) % 2
            }

            if newFacing != currentFacing || animationTimer == 0 {
                currentFacing = newFacing
                self.texture = SpriteFactory.shared.playerTexture(facing: currentFacing, frame: currentFrame)
            }

            // Trail particles
            let trailId = PersistenceManager.shared.profile.equippedTrail
            if trailId != "none", let trailItem = CosmeticCatalog.item(byId: trailId), let trailColor = trailItem.trailColor {
                trailTimer += deltaTime
                if trailTimer >= trailInterval {
                    trailTimer = 0
                    spawnTrailParticle(color: trailColor)
                }
            }
        } else {
            // Idle - frame 0
            if currentFrame != 0 {
                currentFrame = 0
                self.texture = SpriteFactory.shared.playerTexture(facing: currentFacing, frame: 0)
            }
            animationTimer = 0
        }

        // Invincibility visual
        if isInvincible {
            self.alpha = (Int(animationTimer * 20) % 2 == 0) ? 1.0 : 0.4
        } else {
            self.alpha = 1.0
        }
    }

    @discardableResult
    func takeDamage(_ amount: CGFloat) -> Bool {
        guard !isInvincible else { return false }

        hp -= amount

        // Flash red
        let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05)
        let restore = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.05)
        let flash = SKAction.sequence([flashRed, restore])
        run(SKAction.repeat(flash, count: 3), withKey: "damageFlash")

        if hp <= 0 {
            hp = 0
            return true // Player died
        }
        return false
    }

    func applyInvincibility(duration: TimeInterval = GameConfig.playerInvincibilityDuration) {
        isInvincible = true
        run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.run { [weak self] in
                self?.isInvincible = false
                self?.alpha = 1.0
            }
        ]), withKey: "invincibility")
    }

    func heal(_ amount: CGFloat) {
        hp = min(hp + amount, maxHP)
    }

    private func spawnTrailParticle(color: SKColor) {
        guard let scene = self.scene else { return }
        let particle = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
        particle.position = CGPoint(
            x: position.x + CGFloat.random(in: -6...6),
            y: position.y + CGFloat.random(in: -6...6)
        )
        particle.zPosition = 90
        particle.alpha = 0.6
        particle.blendMode = .add
        scene.addChild(particle)
        particle.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 0.2, duration: 0.4),
                SKAction.moveBy(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -8...8), duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func resetForNewGame(gameState: GameState) {
        removeAllActions()
        maxHP = GameConfig.playerBaseHP + gameState.playerHPBonus
        hp = maxHP
        isInvincible = false
        position = .zero
        alpha = 1.0
        currentFrame = 0
        currentFacing = .down
        self.texture = SpriteFactory.shared.playerTexture(facing: .down, frame: 0)
    }
}
