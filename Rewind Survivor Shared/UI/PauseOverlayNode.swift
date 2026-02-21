import SpriteKit

class PauseOverlayNode: SKNode {
    private var onResume: (() -> Void)?
    private var onQuit: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 960
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize, onResume: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onResume = onResume
        self.onQuit = onQuit
        self.isHidden = false
        removeAllChildren()

        // Dimmer - instant
        let dim = SKSpriteNode(color: .black, size: screenSize)
        dim.alpha = 0.7
        dim.zPosition = 0
        addChild(dim)

        // PAUSED title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "PAUSED"
        title.fontSize = 40
        title.fontColor = ColorPalette.textPrimary
        title.position = CGPoint(x: 0, y: screenSize.height * 0.12)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Resume button
        let resumeBtn = createButton(
            text: "RESUME", color: ColorPalette.playerPrimary,
            position: CGPoint(x: 0, y: -screenSize.height * 0.02),
            size: CGSize(width: 200, height: 50), name: "resumeButton"
        )
        addChild(resumeBtn)

        // Quit button
        let quitBtn = createButton(
            text: "QUIT", color: ColorPalette.bulletEnemy,
            position: CGPoint(x: 0, y: -screenSize.height * 0.12),
            size: CGSize(width: 200, height: 50), name: "quitButton"
        )
        addChild(quitBtn)
    }

    private func createButton(text: String, color: SKColor, position: CGPoint, size: CGSize, name: String) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = name
        container.zPosition = 1

        let bg = SKShapeNode(rectOf: size, cornerRadius: 8)
        bg.fillColor = ColorPalette.hudBackground
        bg.strokeColor = color
        bg.lineWidth = 2
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 20
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    func handleTouch(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        for (name, action) in [("resumeButton", onResume), ("quitButton", onQuit)] {
            guard let btn = childNode(withName: name), let callback = action else { continue }
            let btnLocal = btn.convert(localPoint, from: self)
            if abs(btnLocal.x) < 110 && abs(btnLocal.y) < 30 {
                callback()
                return
            }
        }
    }

    func hide() {
        removeAllChildren()
        isHidden = true
    }
}
