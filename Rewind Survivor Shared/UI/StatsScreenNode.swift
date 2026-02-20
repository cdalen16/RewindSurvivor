import SpriteKit

class StatsScreenNode: SKNode {
    private var onBack: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize, onBack: @escaping () -> Void) {
        self.onBack = onBack
        self.isHidden = false
        self.alpha = 1
        removeAllChildren()

        // Background
        let bg = SKSpriteNode(color: ColorPalette.arenaFloor, size: screenSize)
        bg.zPosition = 0
        addChild(bg)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "RECORDS"
        title.fontSize = 36
        title.fontColor = ColorPalette.playerPrimary
        title.position = CGPoint(x: 0, y: screenSize.height * 0.32)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Stats
        let profile = PersistenceManager.shared.profile
        let stats: [(String, String)] = [
            ("HIGH SCORE", "\(profile.highScore)"),
            ("BEST WAVE", "\(profile.highestWave)"),
            ("TOTAL KILLS", "\(profile.totalKills)"),
            ("GAMES PLAYED", "\(profile.totalGamesPlayed)"),
            ("AVG KILLS/GAME", String(format: "%.1f", profile.killsPerGame)),
            ("TOTAL DEATHS", "\(profile.totalDeaths)"),
            ("TOTAL COINS", "\(profile.coins)"),
            ("PLAY TIME", formatTime(profile.totalPlayTime)),
        ]

        let startY = screenSize.height * 0.2
        let rowHeight: CGFloat = 42

        for (i, stat) in stats.enumerated() {
            let y = startY - CGFloat(i) * rowHeight

            let nameLabel = SKLabelNode(fontNamed: "Menlo")
            nameLabel.text = stat.0
            nameLabel.fontSize = 13
            nameLabel.fontColor = ColorPalette.textSecondary
            nameLabel.position = CGPoint(x: -85, y: y)
            nameLabel.zPosition = 1
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .left
            addChild(nameLabel)

            let valueLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            valueLabel.text = stat.1
            valueLabel.fontSize = 16
            valueLabel.fontColor = ColorPalette.textPrimary
            valueLabel.position = CGPoint(x: 85, y: y)
            valueLabel.zPosition = 1
            valueLabel.verticalAlignmentMode = .center
            valueLabel.horizontalAlignmentMode = .right
            addChild(valueLabel)

            // Separator line
            if i < stats.count - 1 {
                let line = SKShapeNode(rectOf: CGSize(width: 180, height: 1))
                line.fillColor = ColorPalette.textSecondary.withAlphaComponent(0.2)
                line.strokeColor = .clear
                line.position = CGPoint(x: 0, y: y - rowHeight / 2)
                line.zPosition = 1
                addChild(line)
            }

            // Animate in
            nameLabel.alpha = 0
            valueLabel.alpha = 0
            let delay = 0.1 + Double(i) * 0.05
            nameLabel.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.2)]))
            valueLabel.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.2)]))
        }

        // Back button
        let backBtn = createBackButton(screenSize: screenSize)
        addChild(backBtn)

        // Title animation
        title.alpha = 0; title.setScale(0.8)
        title.run(SKAction.group([SKAction.fadeIn(withDuration: 0.4), SKAction.scale(to: 1.0, duration: 0.4)]))
    }

    private func createBackButton(screenSize: CGSize) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -screenSize.height * 0.35)
        container.name = "backButton"
        container.zPosition = 1

        let bg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 8)
        bg.fillColor = ColorPalette.hudBackground
        bg.strokeColor = ColorPalette.textSecondary
        bg.lineWidth = 2
        container.addChild(bg)

        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "BACK"
        label.fontSize = 18
        label.fontColor = ColorPalette.textSecondary
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        container.alpha = 0
        container.run(SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.fadeIn(withDuration: 0.3)]))

        return container
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%dh %dm", h, m)
        }
        return String(format: "%dm %ds", m, s)
    }

    func handleTouch(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        if let btn = childNode(withName: "backButton") {
            let btnLocal = btn.convert(localPoint, from: self)
            if abs(btnLocal.x) < 90 && abs(btnLocal.y) < 25 {
                btn.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                ])) { [weak self] in
                    self?.hide()
                    self?.onBack?()
                }
            }
        }
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
