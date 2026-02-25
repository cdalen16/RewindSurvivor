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
        removeFromParent()
    }
}
