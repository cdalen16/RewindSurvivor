import SpriteKit

class CameraManager {
    let cameraNode: SKCameraNode
    private var shakeIntensity: CGFloat = 0
    private var shakeDuration: TimeInterval = 0
    private var shakeTimer: TimeInterval = 0
    private let lerpFactor: CGFloat = 0.1

    init() {
        cameraNode = SKCameraNode()
        cameraNode.name = "gameCamera"
    }

    func update(target: CGPoint, deltaTime: TimeInterval, sceneSize: CGSize) {
        // Smooth follow with lerp
        cameraNode.position.x += (target.x - cameraNode.position.x) * lerpFactor
        cameraNode.position.y += (target.y - cameraNode.position.y) * lerpFactor

        // Clamp to arena bounds
        let halfSceneW = sceneSize.width / 2
        let halfSceneH = sceneSize.height / 2
        let halfArenaW = GameConfig.arenaSize.width / 2
        let halfArenaH = GameConfig.arenaSize.height / 2

        if halfArenaW > halfSceneW {
            cameraNode.position.x = max(-halfArenaW + halfSceneW, min(halfArenaW - halfSceneW, cameraNode.position.x))
        } else {
            cameraNode.position.x = 0
        }
        if halfArenaH > halfSceneH {
            cameraNode.position.y = max(-halfArenaH + halfSceneH, min(halfArenaH - halfSceneH, cameraNode.position.y))
        } else {
            cameraNode.position.y = 0
        }

        // Screen shake
        if shakeTimer > 0 {
            shakeTimer -= deltaTime
            let t = CGFloat(shakeTimer / shakeDuration)
            let offsetX = CGFloat.random(in: -shakeIntensity...shakeIntensity) * t
            let offsetY = CGFloat.random(in: -shakeIntensity...shakeIntensity) * t
            cameraNode.position.x += offsetX
            cameraNode.position.y += offsetY
        }
    }

    func shake(intensity: CGFloat = GameConfig.screenShakeMagnitude, duration: TimeInterval = 0.3) {
        shakeIntensity = intensity
        shakeDuration = duration
        shakeTimer = duration
    }

}
