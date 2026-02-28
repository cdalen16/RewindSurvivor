import SpriteKit

enum ProjectileType {
    case player
    case ghost
    case enemy
}

class ProjectileNode: SKSpriteNode {
    let damage: CGFloat
    let projectileVelocity: CGVector
    var piercingRemaining: Int
    let projectileType: ProjectileType
    private let lifetime: TimeInterval = 2.0

    init(damage: CGFloat, velocity: CGVector, piercing: Int, type: ProjectileType) {
        self.damage = damage
        self.projectileVelocity = velocity
        self.piercingRemaining = piercing
        self.projectileType = type

        let texture: SKTexture
        switch type {
        case .player:
            texture = SpriteFactory.shared.projectileTexture(isGhost: false)
        case .ghost:
            texture = SpriteFactory.shared.projectileTexture(isGhost: true)
        case .enemy:
            texture = SpriteFactory.shared.enemyProjectileTexture()
        }

        let size = type == .enemy ? CGSize(width: 10, height: 10) : CGSize(width: 8, height: 8)
        super.init(texture: texture, color: .clear, size: size)

        self.name = "projectile"
        self.zPosition = 80
        self.blendMode = .add

        // Add glow child
        let glow = SKSpriteNode(texture: texture, size: CGSize(width: size.width * 2, height: size.height * 2))
        glow.alpha = 0.3
        glow.blendMode = .add
        addChild(glow)

        // Physics
        let body = SKPhysicsBody(circleOfRadius: size.width * 0.4)
        switch type {
        case .player:
            body.categoryBitMask = PhysicsCategory.playerBullet
            body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.wall
        case .ghost:
            body.categoryBitMask = PhysicsCategory.ghostBullet
            body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.wall
        case .enemy:
            body.categoryBitMask = PhysicsCategory.enemyBullet
            body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.wall
        }
        body.collisionBitMask = PhysicsCategory.none
        body.allowsRotation = false
        body.affectedByGravity = false
        body.linearDamping = 0
        self.physicsBody = body

        // Set velocity
        self.physicsBody?.velocity = CGVector(dx: velocity.dx, dy: velocity.dy)

        // Auto-remove after lifetime
        run(SKAction.sequence([
            SKAction.wait(forDuration: lifetime),
            SKAction.removeFromParent()
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onWallHit() {
        // Walls always destroy projectiles regardless of piercing
        if let scene = self.scene {
            let spark = SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6))
            spark.position = position
            spark.zPosition = 85
            spark.blendMode = .add
            scene.addChild(spark)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.15),
                    SKAction.scale(to: 2.0, duration: 0.15)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        removeFromParent()
    }

    func onHit() {
        if piercingRemaining > 0 {
            piercingRemaining -= 1
        } else {
            // Small hit effect
            if let scene = self.scene {
                let spark = SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6))
                spark.position = position
                spark.zPosition = 85
                spark.blendMode = .add
                scene.addChild(spark)
                spark.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.15),
                        SKAction.scale(to: 2.0, duration: 0.15)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
            removeFromParent()
        }
    }
}
