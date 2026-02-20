import SpriteKit

class DamageNumberNode: SKLabelNode {

    init(text: String, color: SKColor, position: CGPoint) {
        super.init()
        self.text = text
        self.fontName = "Menlo-Bold"
        self.fontSize = 14
        self.fontColor = color
        self.position = position
        self.zPosition = 500
        self.verticalAlignmentMode = .center
        self.horizontalAlignmentMode = .center

        // Shadow
        let shadow = SKLabelNode(fontNamed: "Menlo-Bold")
        shadow.text = text
        shadow.fontSize = 14
        shadow.fontColor = .black
        shadow.position = CGPoint(x: 1, y: -1)
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.zPosition = -1
        addChild(shadow)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animate() {
        let offsetX = CGFloat.random(in: -15...15)
        run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: offsetX, y: 40, duration: GameConfig.damageNumberDuration),
                SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: GameConfig.damageNumberDuration - 0.1)
                ]),
                SKAction.sequence([
                    SKAction.wait(forDuration: GameConfig.damageNumberDuration * 0.6),
                    SKAction.fadeOut(withDuration: GameConfig.damageNumberDuration * 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    static func spawn(in scene: SKScene, text: String, at position: CGPoint, color: SKColor) {
        let node = DamageNumberNode(text: text, color: color, position: position)
        scene.addChild(node)
        node.animate()
    }
}
