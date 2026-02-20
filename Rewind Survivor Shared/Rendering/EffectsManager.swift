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
        flash.position = cam.cameraNode.position
        flash.zPosition = 600
        flash.alpha = 0.5
        flash.blendMode = .add
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ]))
    }

    func flashRed(duration: TimeInterval = 0.15) {
        guard let scene = scene, let cam = camera else { return }
        let flash = SKSpriteNode(color: .red, size: scene.size)
        flash.position = cam.cameraNode.position
        flash.zPosition = 600
        flash.alpha = 0.3
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Damage Vignette

    func showDamageVignette() {
        guard let scene = scene, let cam = camera else { return }
        let vignette = SKSpriteNode(color: .red, size: CGSize(width: scene.size.width + 40, height: scene.size.height + 40))
        vignette.position = cam.cameraNode.position
        vignette.zPosition = 500
        vignette.alpha = 0.25
        scene.addChild(vignette)
        vignette.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Damage Numbers

    func spawnDamageNumber(at position: CGPoint, text: String, color: SKColor) {
        guard let scene = scene else { return }
        DamageNumberNode.spawn(in: scene, text: text, at: position, color: color)
    }

    func spawnScoreNumber(at position: CGPoint, score: Int) {
        guard let scene = scene else { return }
        DamageNumberNode.spawn(in: scene, text: "+\(score)", at: position, color: ColorPalette.gold)
    }
}
