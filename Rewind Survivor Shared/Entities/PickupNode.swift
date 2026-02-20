import SpriteKit

class PickupNode: SKSpriteNode {
    let coinValue: Int

    init(value: Int, position: CGPoint) {
        self.coinValue = value

        let texture = SpriteFactory.shared.coinPickupTexture()
        super.init(texture: texture, color: .clear, size: CGSize(width: 12, height: 12))

        self.position = position
        self.name = "pickup"
        self.zPosition = 75
        self.blendMode = .add

        // Glow child
        let glow = SKSpriteNode(texture: texture, size: CGSize(width: 20, height: 20))
        glow.alpha = 0.3
        glow.blendMode = .add
        addChild(glow)

        // Physics
        let body = SKPhysicsBody(circleOfRadius: 6)
        body.categoryBitMask = PhysicsCategory.pickup
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        body.allowsRotation = false
        body.affectedByGravity = false
        body.linearDamping = 3.0
        self.physicsBody = body

        // Pop out from death position
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let burst = CGFloat.random(in: 30...80)
        physicsBody?.velocity = CGVector(dx: cos(angle) * burst, dy: sin(angle) * burst)

        // Spawn animation
        self.setScale(0)
        self.run(SKAction.scale(to: 1.0, duration: 0.2))

        // Bob animation
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 0.6),
            SKAction.moveBy(x: 0, y: -3, duration: 0.6),
        ])
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.repeatForever(bob)
        ]))

        // Despawn after 15 seconds with warning blink
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 12),
            SKAction.repeat(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.15),
                SKAction.fadeAlpha(to: 1.0, duration: 0.15),
            ]), count: 10),
            SKAction.removeFromParent()
        ]))
    }

    required init?(coder: NSCoder) { fatalError() }

    func collect() {
        // Sparkle effect
        if let scene = self.scene {
            let sparkle = SKSpriteNode(color: ColorPalette.gold, size: CGSize(width: 8, height: 8))
            sparkle.position = position
            sparkle.zPosition = 85
            sparkle.blendMode = .add
            scene.addChild(sparkle)
            sparkle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.scale(to: 2.5, duration: 0.2)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        removeFromParent()
    }
}
