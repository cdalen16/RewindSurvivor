import SpriteKit

class HUDNode: SKNode {
    // Health bar
    private let healthBarBG: SKSpriteNode
    private let healthBarFill: SKSpriteNode
    private let healthBarBorder: SKShapeNode
    private let healthLabel: SKLabelNode

    // Score
    private let scoreLabel: SKLabelNode
    private let scoreShadow: SKLabelNode

    // Wave + enemies remaining
    private let waveLabel: SKLabelNode
    private let enemyCountLabel: SKLabelNode

    // Deaths remaining
    private let deathIcon: SKLabelNode
    private let deathCountLabel: SKLabelNode
    private let deathProgressBG: SKSpriteNode
    private let deathProgressFill: SKSpriteNode

    // Coins
    private let coinLabel: SKLabelNode

    // Ghost count
    private let ghostLabel: SKLabelNode

    // Wave banner (appears between waves)
    private let waveBanner: SKLabelNode
    private let waveBannerSub: SKLabelNode

    private let barWidth: CGFloat = 110
    private let barHeight: CGFloat = 12

    override init() {
        // Health bar
        healthBarBG = SKSpriteNode(color: ColorPalette.hudBackground, size: CGSize(width: barWidth, height: barHeight))
        healthBarFill = SKSpriteNode(color: ColorPalette.hudHealthFull, size: CGSize(width: barWidth, height: barHeight))
        healthBarBorder = SKShapeNode(rectOf: CGSize(width: barWidth + 2, height: barHeight + 2), cornerRadius: 2)
        healthBarBorder.strokeColor = ColorPalette.textSecondary.withAlphaComponent(0.6)
        healthBarBorder.fillColor = .clear
        healthBarBorder.lineWidth = 1

        healthLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        healthLabel.fontSize = 9
        healthLabel.fontColor = ColorPalette.textPrimary

        // Score
        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = ColorPalette.gold

        scoreShadow = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreShadow.fontSize = 18
        scoreShadow.fontColor = .black

        // Wave
        waveLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        waveLabel.fontSize = 12
        waveLabel.fontColor = ColorPalette.textSecondary

        // Enemy count
        enemyCountLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        enemyCountLabel.fontSize = 11
        enemyCountLabel.fontColor = ColorPalette.enemyMelee.withAlphaComponent(0.8)

        // Deaths
        deathIcon = SKLabelNode(text: "💀")
        deathIcon.fontSize = 16

        deathCountLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        deathCountLabel.fontSize = 14
        deathCountLabel.fontColor = ColorPalette.rewindMagenta

        deathProgressBG = SKSpriteNode(color: ColorPalette.hudBackground, size: CGSize(width: 80, height: 6))
        deathProgressFill = SKSpriteNode(color: ColorPalette.rewindMagenta, size: CGSize(width: 0, height: 6))

        // Coins
        coinLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        coinLabel.fontSize = 11
        coinLabel.fontColor = ColorPalette.gold

        // Ghost count
        ghostLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        ghostLabel.fontSize = 12
        ghostLabel.fontColor = ColorPalette.ghostCyan

        // Wave banner
        waveBanner = SKLabelNode(fontNamed: "Menlo-Bold")
        waveBanner.fontSize = 36
        waveBanner.fontColor = ColorPalette.gold
        waveBanner.alpha = 0

        waveBannerSub = SKLabelNode(fontNamed: "Menlo")
        waveBannerSub.fontSize = 16
        waveBannerSub.fontColor = ColorPalette.textSecondary
        waveBannerSub.alpha = 0

        super.init()

        self.zPosition = 1000
        self.name = "hud"

        addChild(healthBarBG)
        addChild(healthBarFill)
        addChild(healthBarBorder)
        addChild(healthLabel)
        addChild(scoreShadow)
        addChild(scoreLabel)
        addChild(waveLabel)
        addChild(enemyCountLabel)
        addChild(deathIcon)
        addChild(deathCountLabel)
        addChild(deathProgressBG)
        addChild(deathProgressFill)
        addChild(coinLabel)
        addChild(ghostLabel)
        addChild(waveBanner)
        addChild(waveBannerSub)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(screenSize: CGSize, safeAreaInsets: UIEdgeInsets = .zero) {
        let safeTop = safeAreaInsets.top > 0 ? safeAreaInsets.top : 20
        let safeLeft = safeAreaInsets.left > 0 ? safeAreaInsets.left : 0
        let safeRight = safeAreaInsets.right > 0 ? safeAreaInsets.right : 0

        let left = -screenSize.width / 2 + 12 + safeLeft
        let top = screenSize.height / 2 - safeTop - 12
        let right = screenSize.width / 2 - 12 - safeRight

        // Health bar - top left
        let barX = left + barWidth / 2
        let barY = top
        healthBarBG.position = CGPoint(x: barX, y: barY)
        healthBarFill.position = CGPoint(x: barX, y: barY)
        healthBarBorder.position = CGPoint(x: barX, y: barY)
        healthLabel.position = CGPoint(x: barX, y: barY - 2)
        healthLabel.verticalAlignmentMode = .center

        // Score - top center
        scoreLabel.position = CGPoint(x: 0, y: top)
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .center
        scoreShadow.position = CGPoint(x: 1, y: top - 1)
        scoreShadow.verticalAlignmentMode = .center
        scoreShadow.horizontalAlignmentMode = .center

        // Wave - below score
        waveLabel.position = CGPoint(x: 0, y: top - 20)
        waveLabel.verticalAlignmentMode = .center
        waveLabel.horizontalAlignmentMode = .center

        // Enemies remaining - below wave
        enemyCountLabel.position = CGPoint(x: 0, y: top - 34)
        enemyCountLabel.verticalAlignmentMode = .center
        enemyCountLabel.horizontalAlignmentMode = .center

        // Deaths - top right
        deathIcon.position = CGPoint(x: right - 70, y: top)
        deathIcon.verticalAlignmentMode = .center
        deathCountLabel.position = CGPoint(x: right - 48, y: top)
        deathCountLabel.verticalAlignmentMode = .center
        deathCountLabel.horizontalAlignmentMode = .left

        // Death progress bar
        deathProgressBG.position = CGPoint(x: right - 40, y: top - 16)
        deathProgressFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        deathProgressFill.position = CGPoint(x: right - 80, y: top - 16)

        // Coins - below health bar
        coinLabel.position = CGPoint(x: left + barWidth / 2, y: top - 18)
        coinLabel.verticalAlignmentMode = .center
        coinLabel.horizontalAlignmentMode = .center

        // Ghost count - below deaths
        ghostLabel.position = CGPoint(x: right - 40, y: top - 32)
        ghostLabel.verticalAlignmentMode = .center
        ghostLabel.horizontalAlignmentMode = .center

        // Wave banner - center of screen
        waveBanner.position = CGPoint(x: 0, y: 40)
        waveBanner.verticalAlignmentMode = .center
        waveBanner.horizontalAlignmentMode = .center
        waveBannerSub.position = CGPoint(x: 0, y: 10)
        waveBannerSub.verticalAlignmentMode = .center
        waveBannerSub.horizontalAlignmentMode = .center
    }

    func refresh(gameState: GameState, playerHP: CGFloat, playerMaxHP: CGFloat, ghostCount: Int, enemiesRemaining: Int) {
        // Health bar
        let healthPct = max(0, min(1, playerHP / playerMaxHP))
        healthBarFill.xScale = healthPct
        healthBarFill.position.x = healthBarBG.position.x - barWidth * (1 - healthPct) / 2

        if healthPct > 0.5 {
            healthBarFill.color = ColorPalette.hudHealthFull
        } else if healthPct > 0.25 {
            healthBarFill.color = ColorPalette.hudHealthMid
        } else {
            healthBarFill.color = ColorPalette.hudHealthLow
        }

        healthLabel.text = "\(Int(playerHP))/\(Int(playerMaxHP))"

        // Score
        scoreLabel.text = "\(gameState.score)"
        scoreShadow.text = "\(gameState.score)"

        // Wave
        waveLabel.text = "WAVE \(gameState.currentWave)"

        // Enemies remaining
        if enemiesRemaining > 0 {
            enemyCountLabel.text = "\(enemiesRemaining) enemies left"
            enemyCountLabel.isHidden = false
        } else {
            enemyCountLabel.isHidden = true
        }

        // Deaths
        deathCountLabel.text = "×\(gameState.deathsRemaining)"

        // Death progress
        let progress = gameState.deathThresholdProgress
        deathProgressFill.xScale = progress
        let fillWidth = 80 * progress
        deathProgressFill.size = CGSize(width: fillWidth, height: 6)

        // Coins
        coinLabel.text = "🪙 \(gameState.coinsEarnedThisRun)"

        // Ghost count
        if ghostCount > 0 {
            ghostLabel.text = "GHOSTS: \(ghostCount)"
            ghostLabel.isHidden = false
        } else {
            ghostLabel.isHidden = true
        }
    }

    func showWaveBanner(wave: Int, enemyCount: Int) {
        waveBanner.text = "WAVE \(wave)"
        waveBannerSub.text = "\(enemyCount) enemies"

        waveBanner.alpha = 0
        waveBanner.setScale(0.5)
        waveBannerSub.alpha = 0

        waveBanner.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ]),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5)
        ]))

        waveBannerSub.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
    }

    func showDeathEarned() {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "+1 DEATH!"
        label.fontSize = 24
        label.fontColor = ColorPalette.rewindMagenta
        label.position = CGPoint(x: 0, y: -30)
        label.zPosition = 1001
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 60, duration: 1.0),
                SKAction.sequence([
                    SKAction.fadeIn(withDuration: 0.2),
                    SKAction.wait(forDuration: 0.5),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.scale(to: 1.5, duration: 1.0)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func hide() {
        self.isHidden = true
    }

    func show() {
        self.isHidden = false
    }
}
