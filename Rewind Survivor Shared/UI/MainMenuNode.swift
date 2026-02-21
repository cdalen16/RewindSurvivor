import SpriteKit

class MainMenuNode: SKNode {
    private var onPlay: (() -> Void)?
    private var onShop: (() -> Void)?
    private var onStats: (() -> Void)?
    private var onWatchAd: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize, isAdReady: Bool = false, onPlay: @escaping () -> Void, onShop: @escaping () -> Void, onStats: @escaping () -> Void, onWatchAd: (() -> Void)? = nil) {
        self.onPlay = onPlay
        self.onShop = onShop
        self.onStats = onStats
        self.onWatchAd = onWatchAd
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

        // PLAY button
        let playBtn = createButton(text: "PLAY", color: ColorPalette.playerPrimary,
                                    position: CGPoint(x: 0, y: -screenSize.height * 0.1),
                                    size: CGSize(width: 200, height: 55), name: "playButton")
        addChild(playBtn)

        // SHOP button
        let shopBtn = createButton(text: "SHOP", color: ColorPalette.gold,
                                    position: CGPoint(x: 0, y: -screenSize.height * 0.19),
                                    size: CGSize(width: 200, height: 48), name: "shopButton")
        addChild(shopBtn)

        // RECORDS button
        let statsBtn = createButton(text: "RECORDS", color: ColorPalette.textSecondary,
                                     position: CGPoint(x: 0, y: -screenSize.height * 0.27),
                                     size: CGSize(width: 200, height: 48), name: "statsButton")
        addChild(statsBtn)

        // FREE COINS button
        let adBtn = createButton(text: "▶ FREE COINS", color: ColorPalette.gold,
                                  position: CGPoint(x: 0, y: -screenSize.height * 0.36),
                                  size: CGSize(width: 200, height: 48), name: "adButton")
        addChild(adBtn)

        // Animate in
        title.alpha = 0; title.setScale(0.8)
        title.run(SKAction.group([SKAction.fadeIn(withDuration: 0.5), SKAction.scale(to: 1.0, duration: 0.5)]))
        subtitle.alpha = 0
        subtitle.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeIn(withDuration: 0.4)]))

        for (i, name) in ["playButton", "shopButton", "statsButton", "adButton"].enumerated() {
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

        for (name, action) in [("playButton", onPlay), ("shopButton", onShop), ("statsButton", onStats), ("adButton", onWatchAd)] {
            guard let btn = childNode(withName: name), let callback = action else { continue }
            let btnLocal = btn.convert(localPoint, from: self)
            // Check if within button bounds (approximate with distance)
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
