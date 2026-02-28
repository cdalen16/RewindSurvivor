import SpriteKit

class EffectsManager {
    private weak var scene: SKScene?
    private weak var camera: CameraManager?

    func setup(scene: SKScene, camera: CameraManager) {
        self.scene = scene
        self.camera = camera
    }

    // MARK: - Screen Shake

    func shakeLight() {
        camera?.shake(intensity: 4, duration: 0.15)
    }

    func shakeMedium() {
        camera?.shake(intensity: 8, duration: 0.25)
    }

    func shakeHeavy() {
        camera?.shake(intensity: 16, duration: 0.4)
    }

    func shakeExtreme() {
        camera?.shake(intensity: 24, duration: 0.6)
    }

    // MARK: - Screen Flash

    func flashWhite(duration: TimeInterval = 0.1) {
        guard let scene = scene, let cam = camera else { return }
        let flash = SKSpriteNode(color: .white, size: scene.size)
        flash.position = .zero
        flash.zPosition = 600
        flash.alpha = 0.5
        flash.blendMode = .add
        cam.cameraNode.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Damage Vignette

    func showDamageVignette() {
        guard let scene = scene, let cam = camera else { return }
        let vignette = SKSpriteNode(color: .red, size: CGSize(width: scene.size.width + 40, height: scene.size.height + 40))
        vignette.position = .zero
        vignette.zPosition = 500
        vignette.alpha = 0.25
        cam.cameraNode.addChild(vignette)
        vignette.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Shield Block Spark

    func spawnShieldBlockSpark(at position: CGPoint, shieldDirection: CGVector) {
        guard let scene = scene else { return }

        // Bright flash at impact point
        let flash = SKSpriteNode(color: ColorPalette.enemyShieldBearer, size: CGSize(width: 24, height: 24))
        flash.position = position
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.9
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.scale(to: 2.0, duration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))

        // Spark particles spray outward from shield face
        let sparkCount = 8
        for _ in 0..<sparkCount {
            let spark = SKSpriteNode(color: .white, size: CGSize(width: 3, height: 3))
            spark.position = position
            spark.zPosition = 199
            spark.blendMode = .add

            // Spray in the shield-facing direction with spread
            let baseAngle = atan2(shieldDirection.dy, shieldDirection.dx)
            let angle = baseAngle + CGFloat.random(in: -(.pi / 3)...(.pi / 3))
            let speed = CGFloat.random(in: 60...140)

            scene.addChild(spark)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: cos(angle) * speed * 0.25, dy: sin(angle) * speed * 0.25), duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25),
                    SKAction.scale(to: 0.2, duration: 0.25)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Small shield shimmer ring
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.strokeColor = ColorPalette.enemyShieldBearer
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.position = position
        ring.zPosition = 198
        ring.alpha = 0.6
        ring.blendMode = .add
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 4.0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
