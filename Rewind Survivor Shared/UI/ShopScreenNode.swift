import SpriteKit

class ShopScreenNode: SKNode {
    private var onBack: (() -> Void)?
    private var currentCategory: CosmeticCategory = .skin
    private var screenSize: CGSize = .zero
    private var coinLabel: SKLabelNode?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize, onBack: @escaping () -> Void) {
        self.onBack = onBack
        self.screenSize = screenSize
        self.isHidden = false
        self.alpha = 1
        currentCategory = .skin
        rebuild()
    }

    private func rebuild() {
        removeAllChildren()

        // Background
        let bg = SKSpriteNode(color: ColorPalette.arenaFloor, size: screenSize)
        bg.zPosition = 0
        addChild(bg)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "SHOP"
        title.fontSize = 36
        title.fontColor = ColorPalette.gold
        title.position = CGPoint(x: 0, y: screenSize.height * 0.35)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Coin display
        let coinBg = SKShapeNode(rectOf: CGSize(width: 120, height: 28), cornerRadius: 6)
        coinBg.fillColor = ColorPalette.hudBackground
        coinBg.strokeColor = ColorPalette.gold.withAlphaComponent(0.5)
        coinBg.lineWidth = 1
        coinBg.position = CGPoint(x: 0, y: screenSize.height * 0.29)
        coinBg.zPosition = 1
        addChild(coinBg)

        let coins = SKLabelNode(fontNamed: "Menlo-Bold")
        coins.text = "\(PersistenceManager.shared.profile.coins) coins"
        coins.fontSize = 13
        coins.fontColor = ColorPalette.gold
        coins.position = coinBg.position
        coins.zPosition = 2
        coins.verticalAlignmentMode = .center
        coins.horizontalAlignmentMode = .center
        addChild(coins)
        self.coinLabel = coins

        // Category tabs
        let tabs: [(CosmeticCategory, String)] = [(.skin, "SKINS"), (.hat, "HATS"), (.trail, "TRAILS")]
        let tabWidth: CGFloat = 70
        let tabY = screenSize.height * 0.22

        for (i, tab) in tabs.enumerated() {
            let x = CGFloat(i - 1) * (tabWidth + 10)
            let isSelected = tab.0 == currentCategory

            let tabBg = SKShapeNode(rectOf: CGSize(width: tabWidth, height: 32), cornerRadius: 6)
            tabBg.fillColor = isSelected ? ColorPalette.playerPrimary.withAlphaComponent(0.3) : ColorPalette.hudBackground
            tabBg.strokeColor = isSelected ? ColorPalette.playerPrimary : ColorPalette.textSecondary.withAlphaComponent(0.5)
            tabBg.lineWidth = isSelected ? 2 : 1
            tabBg.position = CGPoint(x: x, y: tabY)
            tabBg.zPosition = 1
            tabBg.name = "tab_\(tab.0.rawValue)"
            addChild(tabBg)

            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = tab.1
            label.fontSize = 11
            label.fontColor = isSelected ? ColorPalette.playerPrimary : ColorPalette.textSecondary
            label.position = CGPoint(x: x, y: tabY)
            label.zPosition = 2
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            addChild(label)
        }

        // Item list
        let items = CosmeticCatalog.items(forCategory: currentCategory)
        let pm = PersistenceManager.shared
        let startY = screenSize.height * 0.13
        let cardHeight: CGFloat = 68
        let cardWidth: CGFloat = 240

        for (i, item) in items.enumerated() {
            let y = startY - CGFloat(i) * (cardHeight + 8)
            let isOwned = pm.isUnlocked(item.id)
            let isEquipped: Bool = {
                switch item.category {
                case .skin: return pm.profile.equippedSkin == item.id
                case .hat: return pm.profile.equippedHat == item.id
                case .trail: return pm.profile.equippedTrail == item.id
                }
            }()

            let card = SKNode()
            card.position = CGPoint(x: 0, y: y)
            card.name = "item_\(item.id)"
            card.zPosition = 1

            // Card background
            let cardBg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 8)
            cardBg.fillColor = isEquipped ? ColorPalette.playerPrimary.withAlphaComponent(0.15) : ColorPalette.hudBackground
            cardBg.strokeColor = isEquipped ? ColorPalette.playerPrimary : ColorPalette.textSecondary.withAlphaComponent(0.3)
            cardBg.lineWidth = isEquipped ? 2 : 1
            card.addChild(cardBg)

            // Preview sprite
            let previewX: CGFloat = -88
            let previewSprite: SKSpriteNode
            switch item.category {
            case .skin:
                // Show player with this skin + currently equipped hat
                let tex = SpriteFactory.shared.shopPreviewTexture(skinId: item.id, hatId: pm.profile.equippedHat)
                previewSprite = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 44))
            case .hat:
                // Show default-skin player with this hat
                let tex = SpriteFactory.shared.shopPreviewTexture(skinId: pm.profile.equippedSkin, hatId: item.id)
                previewSprite = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 44))
            case .trail:
                if let trailColor = item.trailColor {
                    let tex = SpriteFactory.shared.trailPreviewTexture(trailColor: trailColor)
                    previewSprite = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 44))
                } else {
                    // "None" trail — just show a small dash
                    previewSprite = SKSpriteNode(color: .clear, size: CGSize(width: 44, height: 44))
                    let noLabel = SKLabelNode(fontNamed: "Menlo")
                    noLabel.text = "--"
                    noLabel.fontSize = 16
                    noLabel.fontColor = ColorPalette.textSecondary
                    noLabel.verticalAlignmentMode = .center
                    noLabel.horizontalAlignmentMode = .center
                    previewSprite.addChild(noLabel)
                }
            }
            previewSprite.position = CGPoint(x: previewX, y: 0)
            card.addChild(previewSprite)

            // Preview background (dark square behind the sprite)
            let previewBg = SKShapeNode(rectOf: CGSize(width: 50, height: 54), cornerRadius: 6)
            previewBg.fillColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)
            previewBg.strokeColor = ColorPalette.textSecondary.withAlphaComponent(0.15)
            previewBg.lineWidth = 1
            previewBg.position = CGPoint(x: previewX, y: 0)
            previewBg.zPosition = -1
            card.addChild(previewBg)

            // Text area — right of preview
            let textX: CGFloat = -50

            // Name
            let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            nameLabel.text = item.displayName
            nameLabel.fontSize = 13
            nameLabel.fontColor = ColorPalette.textPrimary
            nameLabel.position = CGPoint(x: textX, y: 12)
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .left
            card.addChild(nameLabel)

            // Description
            let descLabel = SKLabelNode(fontNamed: "Menlo")
            descLabel.text = item.description
            descLabel.fontSize = 10
            descLabel.fontColor = ColorPalette.textSecondary
            descLabel.position = CGPoint(x: textX, y: -3)
            descLabel.verticalAlignmentMode = .center
            descLabel.horizontalAlignmentMode = .left
            card.addChild(descLabel)

            // Status — on its own row below description, right-aligned
            let statusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            statusLabel.fontSize = 11
            statusLabel.verticalAlignmentMode = .center
            statusLabel.horizontalAlignmentMode = .left
            statusLabel.position = CGPoint(x: textX, y: -19)

            if isEquipped {
                statusLabel.text = "EQUIPPED"
                statusLabel.fontColor = ColorPalette.playerPrimary
            } else if isOwned {
                statusLabel.text = "TAP TO EQUIP"
                statusLabel.fontColor = ColorPalette.textPrimary
            } else {
                statusLabel.text = "\(item.price) coins"
                statusLabel.fontColor = ColorPalette.gold
            }
            card.addChild(statusLabel)

            // Animate in
            card.alpha = 0
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.1 + Double(i) * 0.06),
                SKAction.fadeIn(withDuration: 0.2)
            ]))

            addChild(card)
        }

        // Back button
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 0, y: -screenSize.height * 0.35)
        backBtn.name = "backButton"
        backBtn.zPosition = 1

        let backBg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 8)
        backBg.fillColor = ColorPalette.hudBackground
        backBg.strokeColor = ColorPalette.textSecondary
        backBg.lineWidth = 2
        backBtn.addChild(backBg)

        let backLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        backLabel.text = "BACK"
        backLabel.fontSize = 18
        backLabel.fontColor = ColorPalette.textSecondary
        backLabel.verticalAlignmentMode = .center
        backLabel.horizontalAlignmentMode = .center
        backBtn.addChild(backLabel)
        addChild(backBtn)
    }

    func handleTouch(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        // Check tab taps
        for cat in CosmeticCategory.allCases {
            if let tab = childNode(withName: "tab_\(cat.rawValue)") {
                let tabLocal = tab.convert(localPoint, from: self)
                if abs(tabLocal.x) < 40 && abs(tabLocal.y) < 20 {
                    currentCategory = cat
                    rebuild()
                    return
                }
            }
        }

        // Check item taps
        let items = CosmeticCatalog.items(forCategory: currentCategory)
        let pm = PersistenceManager.shared

        for item in items {
            if let card = childNode(withName: "item_\(item.id)") {
                let cardLocal = card.convert(localPoint, from: self)
                if abs(cardLocal.x) < 125 && abs(cardLocal.y) < 38 {
                    let isOwned = pm.isUnlocked(item.id)
                    let isEquipped: Bool = {
                        switch item.category {
                        case .skin: return pm.profile.equippedSkin == item.id
                        case .hat: return pm.profile.equippedHat == item.id
                        case .trail: return pm.profile.equippedTrail == item.id
                        }
                    }()

                    if isEquipped {
                        return
                    }

                    if isOwned {
                        switch item.category {
                        case .skin: pm.equipSkin(item.id)
                        case .hat: pm.equipHat(item.id)
                        case .trail: pm.equipTrail(item.id)
                        }
                        SpriteFactory.shared.invalidatePlayerTextures()
                        rebuild()
                    } else {
                        if pm.spendCoins(item.price) {
                            pm.unlockCosmetic(item.id)
                            switch item.category {
                            case .skin: pm.equipSkin(item.id)
                            case .hat: pm.equipHat(item.id)
                            case .trail: pm.equipTrail(item.id)
                            }
                            SpriteFactory.shared.invalidatePlayerTextures()
                            rebuild()
                        } else {
                            // Not enough coins — shake the card
                            let shake = SKAction.sequence([
                                SKAction.moveBy(x: -5, y: 0, duration: 0.05),
                                SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                                SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                                SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                            ])
                            card.run(shake)
                        }
                    }
                    return
                }
            }
        }

        // Check back button
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
