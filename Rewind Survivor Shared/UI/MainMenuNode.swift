import SpriteKit

class MainMenuNode: SKNode {
    private var onPlay: (() -> Void)?
    private var onResume: (() -> Void)?
    private var onShop: (() -> Void)?
    private var onStats: (() -> Void)?
    private var onTutorial: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize, hasSavedRun: Bool = false, onPlay: @escaping () -> Void, onResume: (() -> Void)? = nil, onShop: @escaping () -> Void, onStats: @escaping () -> Void, onTutorial: @escaping () -> Void) {
        self.onPlay = onPlay
        self.onResume = onResume
        self.onShop = onShop
        self.onStats = onStats
        self.onTutorial = onTutorial
        self.isHidden = false
        self.alpha = 1
        removeAllChildren()

        // Background
        let bg = SKSpriteNode(color: ColorPalette.arenaFloor, size: screenSize)
        bg.zPosition = 0
        addChild(bg)

        // Title: "REWIND"
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "REWIND"
        title.fontSize = 48
        title.fontColor = ColorPalette.playerPrimary
        title.position = CGPoint(x: 0, y: screenSize.height * 0.25)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Chromatic aberration
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

        // "SURVIVOR"
        let subtitle = SKLabelNode(fontNamed: "Menlo-Bold")
        subtitle.text = "SURVIVOR"
        subtitle.fontSize = 32
        subtitle.fontColor = ColorPalette.rewindMagenta
        subtitle.position = CGPoint(x: 0, y: screenSize.height * 0.17)
        subtitle.zPosition = 1
        subtitle.verticalAlignmentMode = .center
        subtitle.horizontalAlignmentMode = .center
        addChild(subtitle)

        // Coin display
        let coinCount = PersistenceManager.shared.profile.coins
        let coinLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        coinLabel.text = "\(coinCount) coins"
        coinLabel.fontSize = 14
        coinLabel.fontColor = ColorPalette.gold
        coinLabel.position = CGPoint(x: 0, y: screenSize.height * 0.09)
        coinLabel.zPosition = 1
        coinLabel.verticalAlignmentMode = .center
        coinLabel.horizontalAlignmentMode = .center
        addChild(coinLabel)

        // High score
        let highScore = PersistenceManager.shared.profile.highScore
        if highScore > 0 {
            let hsLabel = SKLabelNode(fontNamed: "Menlo")
            hsLabel.text = "BEST: \(highScore)"
            hsLabel.fontSize = 12
            hsLabel.fontColor = ColorPalette.textSecondary
            hsLabel.position = CGPoint(x: 0, y: screenSize.height * 0.05)
            hsLabel.zPosition = 1
            hsLabel.verticalAlignmentMode = .center
            hsLabel.horizontalAlignmentMode = .center
            addChild(hsLabel)
        }

        // Ghost decorations
        for i in 0..<3 {
            let ghost = SKSpriteNode(texture: SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: 0))
            ghost.size = CGSize(width: 32, height: 32)
            ghost.alpha = 0.25 - CGFloat(i) * 0.06
            ghost.position = CGPoint(x: CGFloat(i - 1) * 50, y: -screenSize.height * 0.02)
            ghost.zPosition = 1
            addChild(ghost)
            ghost.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 1.5 + Double(i) * 0.3),
                SKAction.moveBy(x: 0, y: -8, duration: 1.5 + Double(i) * 0.3),
            ])))
        }

        // Button layout: adaptive spacing for all screen sizes
        let playText = hasSavedRun ? "NEW GAME" : "PLAY"

        // (text, color, idealHeight, name)
        var btnDefs: [(String, SKColor, CGFloat, String)] = []
        if hasSavedRun {
            btnDefs.append(("RESUME", ColorPalette.rewindMagenta, 55, "resumeButton"))
        }
        btnDefs.append((playText, ColorPalette.playerPrimary, 55, "playButton"))
        btnDefs.append(("SHOP", ColorPalette.gold, 48, "shopButton"))
        btnDefs.append(("RECORDS", ColorPalette.textSecondary, 48, "statsButton"))
        btnDefs.append(("HOW TO PLAY", ColorPalette.textSecondary.withAlphaComponent(0.7), 40, "tutorialButton"))

        // Available space: below ghost decorations to near screen bottom
        let buttonsTopY = -screenSize.height * 0.06
        let buttonsBottomY = -screenSize.height / 2 + 16
        let availableHeight = buttonsTopY - buttonsBottomY

        // Compute gap and scale to fit all buttons
        let idealGap: CGFloat = 14
        let minGap: CGFloat = 8
        var totalIdealH: CGFloat = 0
        for d in btnDefs { totalIdealH += d.2 }
        let gapCount = CGFloat(max(1, btnDefs.count - 1))

        let btnScale: CGFloat
        let btnGap: CGFloat
        if totalIdealH + gapCount * idealGap <= availableHeight {
            btnScale = 1.0
            btnGap = idealGap
        } else if totalIdealH + gapCount * minGap <= availableHeight {
            btnScale = 1.0
            btnGap = (availableHeight - totalIdealH) / gapCount
        } else {
            btnScale = max(0.65, (availableHeight - gapCount * minGap) / totalIdealH)
            btnGap = minGap
        }

        // Center the button stack vertically in available space
        let btnHeights = btnDefs.map { $0.2 * btnScale }
        let totalStackH = btnHeights.reduce(CGFloat(0), +) + gapCount * btnGap
        let topPadding = max(0, (availableHeight - totalStackH) / 2)

        var buttonY = buttonsTopY - topPadding
        var buttonNames: [String] = []

        for (i, def) in btnDefs.enumerated() {
            let h = btnHeights[i]
            buttonY -= h / 2
            let btn = createButton(text: def.0, color: def.1,
                                   position: CGPoint(x: 0, y: buttonY),
                                   size: CGSize(width: 200, height: h), name: def.3)
            addChild(btn)
            buttonNames.append(def.3)
            if i < btnDefs.count - 1 { buttonY -= h / 2 + btnGap }
        }

        // Animate in
        title.alpha = 0; title.setScale(0.8)
        title.run(SKAction.group([SKAction.fadeIn(withDuration: 0.5), SKAction.scale(to: 1.0, duration: 0.5)]))
        subtitle.alpha = 0
        subtitle.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeIn(withDuration: 0.4)]))

        for (i, name) in buttonNames.enumerated() {
            if let btn = childNode(withName: name) {
                btn.alpha = 0; btn.setScale(0.8)
                btn.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.4 + Double(i) * 0.1),
                    SKAction.group([SKAction.fadeIn(withDuration: 0.3), SKAction.scale(to: 1.0, duration: 0.3)])
                ]))
            }
        }
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
        label.fontSize = min(20, size.height * 0.4)
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    func handleTouch(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        let buttons: [(String, (() -> Void)?)] = [
            ("resumeButton", onResume),
            ("playButton", onPlay),
            ("shopButton", onShop),
            ("statsButton", onStats),
            ("tutorialButton", onTutorial),
        ]
        for (name, action) in buttons {
            guard let btn = childNode(withName: name), let callback = action else { continue }
            let btnLocal = btn.convert(localPoint, from: self)
            if abs(btnLocal.x) < 110 && abs(btnLocal.y) < 30 {
                btn.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                ])) {
                    callback()
                }
                return
            }
        }
    }

    func hide() {
        removeAllChildren()
        isHidden = true
        alpha = 1
    }
}
