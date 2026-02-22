import SpriteKit

class VoidBarrierNode: SKNode {
    private var remainingTime: TimeInterval
    private let destroyRadius: CGFloat = 70
    private var rotationAngle: CGFloat = 0

    init(duration: TimeInterval) {
        self.remainingTime = duration
        super.init()

        self.name = "voidBarrier"
        self.zPosition = 96

        // Main ring
        let ring = SKShapeNode(circleOfRadius: destroyRadius)
        ring.fillColor = .clear
        ring.strokeColor = ColorPalette.superVoidBarrier
        ring.lineWidth = 3
        ring.glowWidth = 4
        ring.name = "mainRing"
        ring.blendMode = .add
        ring.alpha = 0.8
        addChild(ring)

        // Inner fill
        let fill = SKShapeNode(circleOfRadius: destroyRadius)
        fill.fillColor = ColorPalette.superVoidBarrier.withAlphaComponent(0.04)
        fill.strokeColor = .clear
        fill.name = "innerFill"
        addChild(fill)

        // Rotating markers (8 small dots around ring)
        for i in 0..<8 {
            let marker = SKSpriteNode(color: ColorPalette.superVoidBarrier, size: CGSize(width: 4, height: 4))
            marker.name = "marker_\(i)"
            marker.blendMode = .add
            marker.alpha = 0.7
            addChild(marker)
        }

        // Spawn flash
        let flash = SKShapeNode(circleOfRadius: destroyRadius * 0.5)
        flash.fillColor = ColorPalette.superVoidBarrier
        flash.strokeColor = .white
        flash.lineWidth = 2
        flash.blendMode = .add
        flash.alpha = 0.7
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))

        // Pulse animation on main ring
        ring.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.0),
            SKAction.fadeAlpha(to: 0.8, duration: 1.0)
        ])))
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Returns true when expired. Call with player position to follow.
    func update(deltaTime: TimeInterval, playerPosition: CGPoint, scene: SKScene) -> Bool {
        remainingTime -= deltaTime
        if remainingTime <= 0 {
            expire()
            return true
        }

        // Follow player
        position = playerPosition

        // Rotate markers
        rotationAngle += 2.0 * CGFloat(deltaTime)
        for i in 0..<8 {
            if let marker = childNode(withName: "marker_\(i)") {
                let angle = rotationAngle + CGFloat(i) * (.pi * 2 / 8)
                marker.position = CGPoint(x: cos(angle) * destroyRadius, y: sin(angle) * destroyRadius)
            }
        }

        // Destroy enemy projectiles within radius
        scene.enumerateChildNodes(withName: "//projectile") { [weak self] node, _ in
            guard let self = self, let proj = node as? ProjectileNode else { return }
            guard proj.projectileType == .enemy else { return }
            let dx = proj.position.x - self.position.x
            let dy = proj.position.y - self.position.y
            if sqrt(dx * dx + dy * dy) < self.destroyRadius {
                // Destroy with spark effect
                let spark = SKSpriteNode(color: ColorPalette.superVoidBarrier, size: CGSize(width: 6, height: 6))
                spark.position = proj.position
                spark.zPosition = 97
                spark.blendMode = .add
                scene.addChild(spark)
                spark.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.15),
                        SKAction.scale(to: 2.0, duration: 0.15)
                    ]),
                    SKAction.removeFromParent()
                ]))
                proj.removeFromParent()
            }
        }

        return false
    }

    private func expire() {
        guard let scene = self.scene else { removeFromParent(); return }

        // Dissolve ring outward
        let dissolve = SKShapeNode(circleOfRadius: destroyRadius)
        dissolve.fillColor = .clear
        dissolve.strokeColor = ColorPalette.superVoidBarrier
        dissolve.lineWidth = 2
        dissolve.blendMode = .add
        dissolve.position = position
        dissolve.zPosition = 96
        scene.addChild(dissolve)
        dissolve.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        removeFromParent()
    }
}
