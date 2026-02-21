import SpriteKit

class GameOverNode: SKNode {
    private var onRestart: (() -> Void)?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(screenSize: CGSize, gameState: GameState, onRestart: @escaping () -> Void) {
        self.onRestart = onRestart
        self.isHidden = false
        removeAllChildren()

        // Dimmer
        let dim = SKSpriteNode(color: .black, size: screenSize)
        dim.alpha = 0
        dim.zPosition = 0
        addChild(dim)
        dim.run(SKAction.fadeAlpha(to: 0.8, duration: 0.5))

        // Game Over text
        let gameOverLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = ColorPalette.bulletEnemy
        gameOverLabel.position = CGPoint(x: 0, y: screenSize.height * 0.2)
        gameOverLabel.zPosition = 1
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.horizontalAlignmentMode = .center
        addChild(gameOverLabel)

        // High score check
        let isNewHighScore = gameState.score >= PersistenceManager.shared.profile.highScore && gameState.score > 0
        if isNewHighScore {
            let highScoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            highScoreLabel.text = "NEW HIGH SCORE!"
            highScoreLabel.fontSize = 20
            highScoreLabel.fontColor = ColorPalette.gold
            highScoreLabel.position = CGPoint(x: 0, y: screenSize.height * 0.12)
            highScoreLabel.zPosition = 1
            highScoreLabel.verticalAlignmentMode = .center
            highScoreLabel.horizontalAlignmentMode = .center
            addChild(highScoreLabel)
            highScoreLabel.alpha = 0
            highScoreLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5),
                ]))
            ]))
        }

        // Stats
        let statLabels: [(String, String)] = [
            ("SCORE", "\(gameState.score)"),
            ("WAVE", "\(gameState.currentWave)"),
            ("KILLS", "\(gameState.killsThisRun)"),
            ("COINS", "+\(gameState.coinsEarnedThisRun)"),
        ]

        for (i, stat) in statLabels.enumerated() {
            let y = screenSize.height * 0.05 - CGFloat(i) * 35

            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = stat.0
            label.fontSize = 12
            label.fontColor = ColorPalette.textSecondary
            label.position = CGPoint(x: -60, y: y)
            label.zPosition = 1
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .right
            addChild(label)

            let value = SKLabelNode(fontNamed: "Menlo-Bold")
            value.text = stat.1
            value.fontSize = 18
            value.fontColor = ColorPalette.gold
            value.position = CGPoint(x: -40, y: y)
            value.zPosition = 1
            value.verticalAlignmentMode = .center
            value.horizontalAlignmentMode = .left
            addChild(value)

            // Animate in
            label.alpha = 0
            value.alpha = 0
            let delay = 0.5 + Double(i) * 0.2
            label.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.3)]))
            value.run(SKAction.sequence([SKAction.wait(forDuration: delay), SKAction.fadeIn(withDuration: 0.3)]))
        }

        // Tap to restart
        let restartLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        restartLabel.text = "TAP TO RESTART"
        restartLabel.fontSize = 18
        restartLabel.fontColor = ColorPalette.textPrimary
        restartLabel.position = CGPoint(x: 0, y: -screenSize.height * 0.25)
        restartLabel.zPosition = 1
        restartLabel.verticalAlignmentMode = .center
        restartLabel.horizontalAlignmentMode = .center
        addChild(restartLabel)

        restartLabel.alpha = 0
        restartLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.8),
                SKAction.fadeAlpha(to: 1.0, duration: 0.8),
            ]))
        ]))

        // Game over animation
        gameOverLabel.alpha = 0
        gameOverLabel.setScale(2.0)
        gameOverLabel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ]))
    }

    func handleTouch() {
        // Only respond after delay
        guard !isHidden else { return }
        onRestart?()
    }

    func hide() {
        removeAllChildren()
        isHidden = true
        alpha = 1
    }
}
