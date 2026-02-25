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
        title.fontSize = 22
        title.fontColor = ColorPalette.rewindMagenta
        title.position = CGPoint(x: 0, y: screenSize.height * 0.30)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Subtitle
        let sub = SKLabelNode(fontNamed: "Menlo")
        sub.text = "Costs deaths from your bank"
        sub.fontSize = 10
        sub.fontColor = ColorPalette.textSecondary
        sub.position = CGPoint(x: 0, y: screenSize.height * 0.26)
        sub.zPosition = 1
        sub.verticalAlignmentMode = .center
        sub.horizontalAlignmentMode = .center
        addChild(sub)

        // Death bank display
        let bankLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        bankLabel.text = "DEATHS: \(deathsAvailable)"
        bankLabel.fontSize = 13
        bankLabel.fontColor = ColorPalette.rewindMagenta
        bankLabel.position = CGPoint(x: 0, y: screenSize.height * 0.22)
        bankLabel.zPosition = 1
        bankLabel.verticalAlignmentMode = .center
        bankLabel.horizontalAlignmentMode = .center
        addChild(bankLabel)

        // 3-row layout: 2 cards per row, last row may have 1
        let spacing: CGFloat = 10
        let cardWidth: CGFloat = 170
        let rowGap: CGFloat = 10
        let cardsTopY = screenSize.height * 0.18
        let cardsBottomY = -screenSize.height * 0.30
        let availableHeight = cardsTopY - cardsBottomY

        let rowCount = (choices.count + 1) / 2 // ceil division
        let cardHeight = min(120, (availableHeight - CGFloat(rowCount - 1) * rowGap) / CGFloat(rowCount))
        let totalRowsHeight = CGFloat(rowCount) * cardHeight + CGFloat(rowCount - 1) * rowGap
        let topRowY = totalRowsHeight / 2 - cardHeight / 2

        var cardIndex = 0
        for row in 0..<rowCount {
            let cardsInRow = min(2, choices.count - cardIndex)
            let rowY = topRowY - CGFloat(row) * (cardHeight + rowGap)
            let rowWidth = CGFloat(cardsInRow) * cardWidth + CGFloat(max(0, cardsInRow - 1)) * spacing
            let startX = -rowWidth / 2 + cardWidth / 2

            for col in 0..<cardsInRow {
                let type = choices[cardIndex]
                let affordable = deathsAvailable >= type.deathCost
                let card = SuperPowerUpCardNode(type: type, affordable: affordable,
                                                 size: CGSize(width: cardWidth, height: cardHeight))
                card.position = CGPoint(x: startX + CGFloat(col) * (cardWidth + spacing), y: rowY)
                card.zPosition = 1
                addChild(card)
                cards.append(card)

                card.alpha = 0; card.setScale(0.5)
                card.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.05 + Double(cardIndex) * 0.06),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                    ])
                ]))
                cardIndex += 1
            }
        }

        // Skip button
        let skipContainer = SKNode()
        skipContainer.position = CGPoint(x: 0, y: -screenSize.height * 0.36)
        skipContainer.name = "skipButton"
        skipContainer.zPosition = 1

        let skipBg = SKShapeNode(rectOf: CGSize(width: 140, height: 36), cornerRadius: 8)
        skipBg.fillColor = ColorPalette.hudBackground
        skipBg.strokeColor = ColorPalette.textSecondary.withAlphaComponent(0.5)
        skipBg.lineWidth = 1.5
        skipContainer.addChild(skipBg)

        let skipLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        skipLabel.text = "SKIP"
        skipLabel.fontSize = 15
        skipLabel.fontColor = ColorPalette.textSecondary
        skipLabel.verticalAlignmentMode = .center
        skipLabel.horizontalAlignmentMode = .center
        skipContainer.addChild(skipLabel)

        skipContainer.alpha = 0
        skipContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
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

        // Horizontal layout: icon on the left, text on the right
        let iconSize: CGFloat = min(36, size.height * 0.5)
        let leftX = -size.width / 2 + 14 + iconSize / 2
        let textLeftX = leftX + iconSize / 2 + 10

        // Icon
        let icon = SKSpriteNode(texture: SpriteFactory.shared.superPowerUpIconTexture(type: type))
        icon.size = CGSize(width: iconSize, height: iconSize)
        icon.position = CGPoint(x: leftX, y: 4)
        icon.alpha = affordable ? 1.0 : 0.3
        addChild(icon)

        // Death cost skulls below icon
        let skullFontSize: CGFloat = min(13, size.height * 0.13)
        let skullSpacing: CGFloat = 14
        let skullStartX = leftX - CGFloat(type.deathCost - 1) * skullSpacing / 2
        for i in 0..<type.deathCost {
            let skull = SKLabelNode(fontNamed: "Menlo-Bold")
            skull.text = "☠"
            skull.fontSize = skullFontSize
            skull.fontColor = affordable ? ColorPalette.rewindMagenta : ColorPalette.textSecondary.withAlphaComponent(0.3)
            skull.position = CGPoint(x: skullStartX + CGFloat(i) * skullSpacing, y: -iconSize / 2 - 2)
            skull.verticalAlignmentMode = .center
            skull.horizontalAlignmentMode = .center
            addChild(skull)
        }

        // Name (right side, top)
        let textAreaWidth = size.width / 2 + size.width / 2 - (textLeftX + size.width / 2) - 8
        let textCenterX = (textLeftX + size.width / 2 - 8) / 2

        let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nameLabel.text = type.displayName
        nameLabel.fontSize = min(12, size.width * 0.07)
        nameLabel.fontColor = affordable ? type.iconColor : ColorPalette.textSecondary.withAlphaComponent(0.4)
        nameLabel.position = CGPoint(x: textCenterX, y: size.height * 0.22)
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        addChild(nameLabel)

        // Description (right side, wrapping)
        let descLabel = SKLabelNode(fontNamed: "Menlo")
        descLabel.text = type.description
        descLabel.fontSize = min(9, size.width * 0.055)
        descLabel.fontColor = (affordable ? ColorPalette.textSecondary : ColorPalette.textSecondary.withAlphaComponent(0.3))
        descLabel.position = CGPoint(x: textCenterX, y: size.height * 0.05)
        descLabel.verticalAlignmentMode = .top
        descLabel.horizontalAlignmentMode = .center
        descLabel.numberOfLines = 3
        descLabel.preferredMaxLayoutWidth = abs(textAreaWidth) > 10 ? abs(textAreaWidth) : size.width * 0.55
        addChild(descLabel)

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
