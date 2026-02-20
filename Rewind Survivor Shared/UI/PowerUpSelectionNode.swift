import SpriteKit

class PowerUpSelectionNode: SKNode {
    private var cards: [PowerUpCardNode] = []
    private var onSelect: ((PowerUpType) -> Void)?
    private var dimmer: SKSpriteNode?
    private let titleLabel: SKLabelNode
    private var screenSize: CGSize = .zero

    override init() {
        titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "CHOOSE AN UPGRADE"
        titleLabel.fontSize = 22
        titleLabel.fontColor = ColorPalette.gold
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center

        super.init()
        self.zPosition = 900
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(choices: [PowerUpType], gameState: GameState, screenSize: CGSize, onSelect: @escaping (PowerUpType) -> Void) {
        self.onSelect = onSelect
        self.screenSize = screenSize
        self.isHidden = false
        removeAllChildren()
        cards.removeAll()

        // Dimmer
        let dim = SKSpriteNode(color: .black, size: screenSize)
        dim.alpha = 0.7
        dim.zPosition = 0
        addChild(dim)
        dimmer = dim

        // Title
        titleLabel.position = CGPoint(x: 0, y: screenSize.height * 0.3)
        titleLabel.zPosition = 1
        addChild(titleLabel)

        // Cards
        let cardWidth: CGFloat = 110
        let cardHeight: CGFloat = 160
        let spacing: CGFloat = 15
        let totalWidth = CGFloat(choices.count) * cardWidth + CGFloat(choices.count - 1) * spacing
        let startX = -totalWidth / 2 + cardWidth / 2

        for (i, type) in choices.enumerated() {
            let stacks = gameState.acquiredPowerUps[type, default: 0]
            let card = PowerUpCardNode(type: type, stacks: stacks, size: CGSize(width: cardWidth, height: cardHeight))
            card.position = CGPoint(x: startX + CGFloat(i) * (cardWidth + spacing), y: 0)
            card.zPosition = 1
            addChild(card)
            cards.append(card)

            // Animate in
            card.alpha = 0
            card.setScale(0.5)
            let delay = Double(i) * 0.1
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.3)
                ])
            ]))
        }
    }

    func handleTouch(at point: CGPoint) {
        // point is in camera (parent) coordinate space
        let localPoint = convert(point, from: self.parent!)
        for card in cards {
            if card.contains(localPoint) {
                // Pulse and select
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
    }

    func hide() {
        removeAllChildren()
        cards.removeAll()
        isHidden = true
    }
}

class PowerUpCardNode: SKNode {
    let type: PowerUpType
    private let bg: SKShapeNode
    private let border: SKShapeNode

    init(type: PowerUpType, stacks: Int, size: CGSize) {
        self.type = type

        bg = SKShapeNode(rectOf: size, cornerRadius: 8)
        bg.fillColor = ColorPalette.hudBackground
        bg.strokeColor = type.iconColor
        bg.lineWidth = 2

        border = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: size.height + 4), cornerRadius: 10)
        border.fillColor = .clear
        border.strokeColor = type.iconColor.withAlphaComponent(0.3)
        border.lineWidth = 1

        super.init()

        addChild(border)
        addChild(bg)

        // Icon
        let icon = SKSpriteNode(texture: SpriteFactory.shared.powerUpIconTexture(type: type))
        icon.size = CGSize(width: 40, height: 40)
        icon.position = CGPoint(x: 0, y: size.height * 0.2)
        addChild(icon)

        // Name
        let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nameLabel.text = type.displayName
        nameLabel.fontSize = 12
        nameLabel.fontColor = type.iconColor
        nameLabel.position = CGPoint(x: 0, y: -10)
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        addChild(nameLabel)

        // Description (wrapped to fit card width)
        let descLabel = SKLabelNode(fontNamed: "Menlo")
        descLabel.text = type.description
        descLabel.fontSize = 9
        descLabel.fontColor = ColorPalette.textSecondary
        descLabel.position = CGPoint(x: 0, y: -28)
        descLabel.verticalAlignmentMode = .top
        descLabel.horizontalAlignmentMode = .center
        descLabel.numberOfLines = 2
        descLabel.preferredMaxLayoutWidth = size.width - 16
        addChild(descLabel)

        // Stack indicator
        if stacks > 0 || type.maxStacks > 1 {
            let stackText = SKLabelNode(fontNamed: "Menlo")
            stackText.text = "\(stacks)/\(type.maxStacks)"
            stackText.fontSize = 10
            stackText.fontColor = ColorPalette.textSecondary
            stackText.position = CGPoint(x: 0, y: -size.height * 0.35)
            stackText.verticalAlignmentMode = .center
            stackText.horizontalAlignmentMode = .center
            addChild(stackText)
        }

        // Glow animation
        let glowPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak border] in border?.strokeColor = type.iconColor.withAlphaComponent(0.6) },
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak border] in border?.strokeColor = type.iconColor.withAlphaComponent(0.2) },
            SKAction.wait(forDuration: 0.5),
        ]))
        run(glowPulse)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
