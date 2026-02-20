import SpriteKit

class TitleScreenNode: SKNode {
    private var onStart: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(screenSize: CGSize, onStart: @escaping () -> Void) {
        self.onStart = onStart
        self.isHidden = false
        removeAllChildren()

        // Background
        let bg = SKSpriteNode(color: ColorPalette.arenaFloor, size: screenSize)
        bg.zPosition = 0
        addChild(bg)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "REWIND"
        title.fontSize = 48
        title.fontColor = ColorPalette.playerPrimary
        title.position = CGPoint(x: 0, y: screenSize.height * 0.2)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Chromatic aberration on title
        let titleRed = SKLabelNode(fontNamed: "Menlo-Bold")
        titleRed.text = "REWIND"
        titleRed.fontSize = 48
        titleRed.fontColor = SKColor(red: 1, green: 0, blue: 0, alpha: 0.2)
        titleRed.position = CGPoint(x: 2, y: 1)
        titleRed.zPosition = -0.1
        titleRed.verticalAlignmentMode = .center
        titleRed.horizontalAlignmentMode = .center
        title.addChild(titleRed)

        let titleBlue = SKLabelNode(fontNamed: "Menlo-Bold")
        titleBlue.text = "REWIND"
        titleBlue.fontSize = 48
        titleBlue.fontColor = SKColor(red: 0, green: 0, blue: 1, alpha: 0.2)
        titleBlue.position = CGPoint(x: -2, y: -1)
        titleBlue.zPosition = -0.1
        titleBlue.verticalAlignmentMode = .center
        titleBlue.horizontalAlignmentMode = .center
        title.addChild(titleBlue)

        // Subtitle
        let subtitle = SKLabelNode(fontNamed: "Menlo-Bold")
        subtitle.text = "SURVIVOR"
        subtitle.fontSize = 32
        subtitle.fontColor = ColorPalette.rewindMagenta
        subtitle.position = CGPoint(x: 0, y: screenSize.height * 0.12)
        subtitle.zPosition = 1
        subtitle.verticalAlignmentMode = .center
        subtitle.horizontalAlignmentMode = .center
        addChild(subtitle)

        // Tagline
        let tagline = SKLabelNode(fontNamed: "Menlo")
        tagline.text = "Death is just the beginning"
        tagline.fontSize = 14
        tagline.fontColor = ColorPalette.textSecondary
        tagline.position = CGPoint(x: 0, y: screenSize.height * 0.04)
        tagline.zPosition = 1
        tagline.verticalAlignmentMode = .center
        tagline.horizontalAlignmentMode = .center
        addChild(tagline)

        // Ghost icons (decorative)
        for i in 0..<3 {
            let ghost = SKSpriteNode(texture: SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: 0))
            ghost.size = CGSize(width: 32, height: 32)
            ghost.alpha = 0.3 - CGFloat(i) * 0.08
            ghost.position = CGPoint(
                x: CGFloat(i - 1) * 50,
                y: -screenSize.height * 0.08
            )
            ghost.zPosition = 1
            addChild(ghost)

            // Floating animation
            ghost.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 1.5 + Double(i) * 0.3),
                SKAction.moveBy(x: 0, y: -8, duration: 1.5 + Double(i) * 0.3),
            ])))
        }

        // Tap to start
        let startLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        startLabel.text = "TAP TO START"
        startLabel.fontSize = 18
        startLabel.fontColor = ColorPalette.textPrimary
        startLabel.position = CGPoint(x: 0, y: -screenSize.height * 0.25)
        startLabel.zPosition = 1
        startLabel.verticalAlignmentMode = .center
        startLabel.horizontalAlignmentMode = .center
        addChild(startLabel)

        // Pulse animation
        startLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8),
        ])))

        // Title animation
        title.alpha = 0
        title.setScale(0.8)
        title.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ]))

        subtitle.alpha = 0
        subtitle.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.5)
        ]))

        tagline.alpha = 0
        tagline.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.fadeIn(withDuration: 0.5)
        ]))
    }

    func handleTouch() {
        onStart?()
        hide()
    }

    func hide() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.run { [weak self] in
                self?.removeAllChildren()
                self?.isHidden = true
                self?.alpha = 1
            }
        ]))
    }
}
