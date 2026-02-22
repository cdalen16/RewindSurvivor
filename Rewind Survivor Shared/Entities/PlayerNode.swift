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
            if trailId != "trail_none", let trailItem = CosmeticCatalog.item(byId: trailId), let trailColor = trailItem.trailColor {
                trailTimer += deltaTime
                if trailTimer >= trailInterval {
                    trailTimer = 0
                    spawnTrailParticle(color: trailColor, trailId: trailId)
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

    private var rainbowHue: CGFloat = 0

    private func spawnTrailParticle(color: SKColor, trailId: String = "") {
        guard let scene = self.scene else { return }

        switch trailId {
        case "trail_rainbow":
            // Cycle through rainbow hues
            rainbowHue += 0.08
            if rainbowHue > 1.0 { rainbowHue -= 1.0 }
            let rainbowColor = SKColor(hue: rainbowHue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            let particle = SKSpriteNode(color: rainbowColor, size: CGSize(width: 5, height: 5))
            particle.position = CGPoint(x: position.x + .random(in: -5...5), y: position.y + .random(in: -5...5))
            particle.zPosition = 90; particle.alpha = 0.7; particle.blendMode = .add
            scene.addChild(particle)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.3, duration: 0.5),
                    SKAction.moveBy(x: .random(in: -10...10), y: .random(in: -10...10), duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))

        case "trail_spark":
            // Electric spark — quick bright flash with jagged movement
            let sparkColor = SKColor(red: 1.0, green: 1.0, blue: .random(in: 0.3...0.8), alpha: 1.0)
            let particle = SKSpriteNode(color: sparkColor, size: CGSize(width: 3, height: 3))
            particle.position = CGPoint(x: position.x + .random(in: -8...8), y: position.y + .random(in: -8...8))
            particle.zPosition = 90; particle.alpha = 0.9; particle.blendMode = .add
            scene.addChild(particle)
            // Jagged path
            let jag1 = SKAction.moveBy(x: .random(in: -15...15), y: .random(in: -15...15), duration: 0.08)
            let jag2 = SKAction.moveBy(x: .random(in: -10...10), y: .random(in: -10...10), duration: 0.06)
            particle.run(SKAction.sequence([
                SKAction.group([jag1, SKAction.fadeAlpha(to: 0.5, duration: 0.08)]),
                SKAction.group([jag2, SKAction.fadeOut(withDuration: 0.06), SKAction.scale(to: 0.1, duration: 0.06)]),
                SKAction.removeFromParent()
            ]))

        case "trail_pixel":
            // Glitch trail — square blocks that appear/disappear
            let glitchColors = [color, color.withAlphaComponent(0.7), SKColor.white]
            let gc = glitchColors[Int.random(in: 0..<glitchColors.count)]
            let sz = CGFloat.random(in: 3...7)
            let particle = SKSpriteNode(color: gc, size: CGSize(width: sz, height: sz))
            particle.position = CGPoint(
                x: position.x + CGFloat(Int.random(in: -8...8)),
                y: position.y + CGFloat(Int.random(in: -8...8))
            )
            particle.zPosition = 90; particle.alpha = 0.8; particle.blendMode = .add
            scene.addChild(particle)
            // Glitch: appear, shift, disappear abruptly
            particle.run(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0.05...0.15)),
                SKAction.moveBy(x: CGFloat(Int.random(in: -6...6)), y: 0, duration: 0.02),
                SKAction.wait(forDuration: Double.random(in: 0.05...0.1)),
                SKAction.fadeOut(withDuration: 0.02),
                SKAction.removeFromParent()
            ]))

        default:
            // Standard trail particle (fire, ice, shadow)
            let particle = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            particle.position = CGPoint(
                x: position.x + CGFloat.random(in: -6...6),
                y: position.y + CGFloat.random(in: -6...6)
            )
            particle.zPosition = 90; particle.alpha = 0.6; particle.blendMode = .add
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
