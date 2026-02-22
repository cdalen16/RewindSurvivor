import SpriteKit

class SuperPowerUpSelectionNode: SKNode {
    private var cards: [SuperPowerUpCardNode] = []
    private var onSelect: ((SuperPowerUpType) -> Void)?
    private var onSkip: (() -> Void)?
    private var screenSize: CGSize = .zero

    override init() {
        super.init()
        self.zPosition = 900
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(choices: [SuperPowerUpType], deathsAvailable: Int, screenSize: CGSize,
              onSelect: @escaping (SuperPowerUpType) -> Void, onSkip: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onSkip = onSkip
        self.screenSize = screenSize
        self.isHidden = false
        removeAllChildren()
        cards.removeAll()

        // Dimmer
        let dim = SKSpriteNode(color: .black, size: screenSize)
        dim.alpha = 0.75
        dim.zPosition = 0
        addChild(dim)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "SUPER POWER-UP"
        title.fontSize = 24
        title.fontColor = ColorPalette.rewindMagenta
        title.position = CGPoint(x: 0, y: screenSize.height * 0.32)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Subtitle
        let sub = SKLabelNode(fontNamed: "Menlo")
        sub.text = "Costs deaths from your bank"
        sub.fontSize = 11
        sub.fontColor = ColorPalette.textSecondary
        sub.position = CGPoint(x: 0, y: screenSize.height * 0.27)
        sub.zPosition = 1
        sub.verticalAlignmentMode = .center
        sub.horizontalAlignmentMode = .center
        addChild(sub)

        // Death bank display
        let bankLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        bankLabel.text = "DEATHS: \(deathsAvailable)"
        bankLabel.fontSize = 14
        bankLabel.fontColor = ColorPalette.rewindMagenta
        bankLabel.position = CGPoint(x: 0, y: screenSize.height * 0.22)
        bankLabel.zPosition = 1
        bankLabel.verticalAlignmentMode = .center
        bankLabel.horizontalAlignmentMode = .center
        addChild(bankLabel)

        // 2-row card layout: row 1 = first 3, row 2 = remaining
        let spacing: CGFloat = 12
        let cardWidth: CGFloat = 110
        let cardsTopY = screenSize.height * 0.18
        let cardsBottomY = -screenSize.height * 0.26
        let rowGap: CGFloat = 14
        let availableHeight = cardsTopY - cardsBottomY
        let cardHeight = min(150, (availableHeight - rowGap) / 2)

        // Row 1: first 3 (or fewer)
        let row1Count = min(3, choices.count)
        let row1Y = rowGap / 2 + cardHeight / 2
        let row1Width = CGFloat(row1Count) * cardWidth + CGFloat(max(0, row1Count - 1)) * spacing
        let row1StartX = -row1Width / 2 + cardWidth / 2

        for i in 0..<row1Count {
            let type = choices[i]
            let affordable = deathsAvailable >= type.deathCost
            let card = SuperPowerUpCardNode(type: type, affordable: affordable,
                                             size: CGSize(width: cardWidth, height: cardHeight))
            card.position = CGPoint(x: row1StartX + CGFloat(i) * (cardWidth + spacing), y: row1Y)
            card.zPosition = 1
            addChild(card)
            cards.append(card)

            card.alpha = 0; card.setScale(0.5)
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.1 + Double(i) * 0.08),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.3)
                ])
            ]))
        }

        // Row 2: remaining cards (centered)
        if choices.count > 3 {
            let row2Count = choices.count - 3
            let row2Y = -(rowGap / 2 + cardHeight / 2)
            let row2Width = CGFloat(row2Count) * cardWidth + CGFloat(max(0, row2Count - 1)) * spacing
            let row2StartX = -row2Width / 2 + cardWidth / 2

            for j in 0..<row2Count {
                let i = 3 + j
                let type = choices[i]
                let affordable = deathsAvailable >= type.deathCost
                let card = SuperPowerUpCardNode(type: type, affordable: affordable,
                                                 size: CGSize(width: cardWidth, height: cardHeight))
                card.position = CGPoint(x: row2StartX + CGFloat(j) * (cardWidth + spacing), y: row2Y)
                card.zPosition = 1
                addChild(card)
                cards.append(card)

                card.alpha = 0; card.setScale(0.5)
                card.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.1 + Double(i) * 0.08),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.3),
                        SKAction.scale(to: 1.0, duration: 0.3)
                    ])
                ]))
            }
        }

        // Skip button
        let skipContainer = SKNode()
        skipContainer.position = CGPoint(x: 0, y: -screenSize.height * 0.32)
        skipContainer.name = "skipButton"
        skipContainer.zPosition = 1

        let skipBg = SKShapeNode(rectOf: CGSize(width: 140, height: 40), cornerRadius: 8)
        skipBg.fillColor = ColorPalette.hudBackground
        skipBg.strokeColor = ColorPalette.textSecondary.withAlphaComponent(0.5)
        skipBg.lineWidth = 1.5
        skipContainer.addChild(skipBg)

        let skipLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        skipLabel.text = "SKIP"
        skipLabel.fontSize = 16
        skipLabel.fontColor = ColorPalette.textSecondary
        skipLabel.verticalAlignmentMode = .center
        skipLabel.horizontalAlignmentMode = .center
        skipContainer.addChild(skipLabel)

        skipContainer.alpha = 0
        skipContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.3)
        ]))
        addChild(skipContainer)
    }

    func handleTouch(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        // Check cards
        for card in cards {
            if card.contains(localPoint) && card.affordable {
                card.run(SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.08),
                    SKAction.scale(to: 1.0, duration: 0.08),
                ])) { [weak self] in
                    self?.onSelect?(card.type)
                    self?.hide()
                }
                return
            }
        }

        // Check skip
        if let btn = childNode(withName: "skipButton") {
            let btnLocal = btn.convert(localPoint, from: self)
            if abs(btnLocal.x) < 80 && abs(btnLocal.y) < 25 {
                btn.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05),
                ])) { [weak self] in
                    self?.onSkip?()
                    self?.hide()
                }
                return
            }
        }
    }

    func hide() {
        removeAllChildren()
        cards.removeAll()
        isHidden = true
    }
}

class SuperPowerUpCardNode: SKNode {
    let type: SuperPowerUpType
    let affordable: Bool

    init(type: SuperPowerUpType, affordable: Bool, size: CGSize) {
        self.type = type
        self.affordable = affordable
        super.init()

        let bg = SKShapeNode(rectOf: size, cornerRadius: 10)
        bg.fillColor = ColorPalette.hudBackground
        bg.strokeColor = affordable ? type.iconColor : ColorPalette.textSecondary.withAlphaComponent(0.3)
        bg.lineWidth = affordable ? 2.5 : 1.5
        addChild(bg)

        let outerBorder = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: size.height + 4), cornerRadius: 12)
        outerBorder.fillColor = .clear
        outerBorder.strokeColor = (affordable ? type.iconColor : ColorPalette.textSecondary).withAlphaComponent(0.2)
        outerBorder.lineWidth = 1
        addChild(outerBorder)

        // Scale content with card size
        let iconSize = min(40, size.height * 0.28)
        let nameFontSize = min(13, size.width * 0.12)
        let descFontSize = min(10, size.width * 0.09)
        let skullFontSize = min(16, size.height * 0.11)

        // Icon
        let icon = SKSpriteNode(texture: SpriteFactory.shared.superPowerUpIconTexture(type: type))
        icon.size = CGSize(width: iconSize, height: iconSize)
        icon.position = CGPoint(x: 0, y: size.height * 0.25)
        icon.alpha = affordable ? 1.0 : 0.3
        addChild(icon)

        // Name
        let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nameLabel.text = type.displayName
        nameLabel.fontSize = nameFontSize
        nameLabel.fontColor = affordable ? type.iconColor : ColorPalette.textSecondary.withAlphaComponent(0.4)
        nameLabel.position = CGPoint(x: 0, y: size.height * 0.05)
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        addChild(nameLabel)

        // Description
        let descLabel = SKLabelNode(fontNamed: "Menlo")
        descLabel.text = type.description
        descLabel.fontSize = descFontSize
        descLabel.fontColor = (affordable ? ColorPalette.textSecondary : ColorPalette.textSecondary.withAlphaComponent(0.3))
        descLabel.position = CGPoint(x: 0, y: -size.height * 0.1)
        descLabel.verticalAlignmentMode = .top
        descLabel.horizontalAlignmentMode = .center
        descLabel.numberOfLines = 3
        descLabel.preferredMaxLayoutWidth = size.width - 16
        addChild(descLabel)

        // Death cost (skull icons)
        let costY = -size.height * 0.35
        let skullSpacing: CGFloat = min(18, size.width * 0.15)
        let skullStartX = -CGFloat(type.deathCost - 1) * skullSpacing / 2
        for i in 0..<type.deathCost {
            let skull = SKLabelNode(fontNamed: "Menlo-Bold")
            skull.text = "☠"
            skull.fontSize = skullFontSize
            skull.fontColor = affordable ? ColorPalette.rewindMagenta : ColorPalette.textSecondary.withAlphaComponent(0.3)
            skull.position = CGPoint(x: skullStartX + CGFloat(i) * skullSpacing, y: costY)
            skull.verticalAlignmentMode = .center
            skull.horizontalAlignmentMode = .center
            addChild(skull)
        }

        // Dimmed overlay if unaffordable
        if !affordable {
            self.alpha = 0.5
        } else {
            // Glow pulse
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.run { [weak outerBorder] in outerBorder?.strokeColor = type.iconColor.withAlphaComponent(0.5) },
                SKAction.wait(forDuration: 0.6),
                SKAction.run { [weak outerBorder] in outerBorder?.strokeColor = type.iconColor.withAlphaComponent(0.15) },
                SKAction.wait(forDuration: 0.6),
            ]))
            run(pulse)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}
