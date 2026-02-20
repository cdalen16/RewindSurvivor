import SpriteKit

class JoystickNode: SKNode {
    private let baseNode: SKSpriteNode
    private let knobNode: SKSpriteNode
    private let maxRadius: CGFloat = 60

    override init() {
        baseNode = SKSpriteNode(texture: SpriteFactory.shared.joystickBaseTexture())
        baseNode.size = CGSize(width: 120, height: 120)
        baseNode.alpha = 0

        knobNode = SKSpriteNode(texture: SpriteFactory.shared.joystickKnobTexture())
        knobNode.size = CGSize(width: 50, height: 50)
        knobNode.alpha = 0

        super.init()

        addChild(baseNode)
        addChild(knobNode)
        isUserInteractionEnabled = false
        zPosition = 1000
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(inputManager: InputManager, camera: SKCameraNode, scene: SKScene) {
        guard scene.view != nil else { return }

        if inputManager.isActive, let origin = inputManager.joystickPosition {
            // Convert view position to scene position (accounting for camera)
            let scenePos = scene.convertPoint(fromView: origin)

            self.position = scenePos
            baseNode.alpha = 0.6
            knobNode.alpha = 0.8

            let offset = inputManager.knobOffset
            knobNode.position = CGPoint(x: offset.dx, y: offset.dy)
        } else {
            baseNode.alpha = 0
            knobNode.alpha = 0
            knobNode.position = .zero
        }
    }
}
