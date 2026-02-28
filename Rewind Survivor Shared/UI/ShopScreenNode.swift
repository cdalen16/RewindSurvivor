import SpriteKit

class ShopScreenNode: SKNode {
    private var onBack: (() -> Void)?
    private var currentCategory: CosmeticCategory = .skin
    private var screenSize: CGSize = .zero
    private var coinLabel: SKLabelNode?

    // Scrolling
    private var scrollContainer: SKNode?
    private var cropNode: SKCropNode?
    private var scrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    private var touchStartY: CGFloat = 0
    private var scrollStartOffset: CGFloat = 0
    private var isDragging: Bool = false
    private var hasActiveTouch: Bool = false
    private var scrollVelocity: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var lastTouchTime: TimeInterval = 0

    // Layout constants
    private let cardHeight: CGFloat = 68
    private let cardSpacing: CGFloat = 8
    private let cardWidth: CGFloat = 240

    // Confirmation dialog
    private var confirmOverlay: SKNode?
    private var pendingPurchaseItem: CosmeticItem?

    override init() {
        super.init()
        self.zPosition = 950
        self.isHidden = true
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize, onBack: @escaping () -> Void) {
        self.onBack = onBack
        self.screenSize = screenSize
        self.isHidden = false
        self.alpha = 1
        currentCategory = .skin
        scrollOffset = 0
        scrollVelocity = 0
        rebuild()
    }

    private func rebuild() {
        removeAllChildren()
        scrollOffset = max(0, min(scrollOffset, maxScrollOffset))
        scrollVelocity = 0

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
        title.zPosition = 5
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Coin display
        let coinBg = SKShapeNode(rectOf: CGSize(width: 120, height: 28), cornerRadius: 6)
        coinBg.fillColor = ColorPalette.hudBackground
        coinBg.strokeColor = ColorPalette.gold.withAlphaComponent(0.5)
        coinBg.lineWidth = 1
        coinBg.position = CGPoint(x: 0, y: screenSize.height * 0.29)
        coinBg.zPosition = 5
        addChild(coinBg)

        let coins = SKLabelNode(fontNamed: "Menlo-Bold")
        coins.text = "\(PersistenceManager.shared.profile.coins) coins"
        coins.fontSize = 13
        coins.fontColor = ColorPalette.gold
        coins.position = coinBg.position
        coins.zPosition = 6
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
            tabBg.zPosition = 5
            tabBg.name = "tab_\(tab.0.rawValue)"
            addChild(tabBg)

            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = tab.1
            label.fontSize = 11
            label.fontColor = isSelected ? ColorPalette.playerPrimary : ColorPalette.textSecondary
            label.position = CGPoint(x: x, y: tabY)
            label.zPosition = 6
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            addChild(label)
        }

        // Back button (fixed at bottom, above items)
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 0, y: -screenSize.height * 0.38)
        backBtn.name = "backButton"
        backBtn.zPosition = 10

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

        // Scrollable item area — crop node clips items to visible region
        let scrollTopY = tabY - 26 // just below tabs
        let scrollBottomY = -screenSize.height * 0.35 + 30 // just above back button
        let scrollAreaHeight = scrollTopY - scrollBottomY
        let scrollCenterY = (scrollTopY + scrollBottomY) / 2

        let crop = SKCropNode()
        crop.zPosition = 3
        let maskNode = SKSpriteNode(color: .white, size: CGSize(width: cardWidth + 40, height: scrollAreaHeight))
        maskNode.position = CGPoint(x: 0, y: scrollCenterY)
        crop.maskNode = maskNode
        addChild(crop)
        self.cropNode = crop

        let container = SKNode()
        crop.addChild(container)
        self.scrollContainer = container

        // Populate items (sorted by price, cheapest first)
        let items = CosmeticCatalog.items(forCategory: currentCategory).sorted { $0.price < $1.price }
        let pm = PersistenceManager.shared
        let itemStartY = scrollTopY - cardHeight / 2 - 6

        for (i, item) in items.enumerated() {
            let y = itemStartY - CGFloat(i) * (cardHeight + cardSpacing)
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
                let tex = SpriteFactory.shared.shopPreviewTexture(skinId: item.id, hatId: pm.profile.equippedHat)
                previewSprite = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 44))
            case .hat:
                let tex = SpriteFactory.shared.shopPreviewTexture(skinId: pm.profile.equippedSkin, hatId: item.id)
                previewSprite = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 44))
            case .trail:
                if let trailColor = item.trailColor {
                    let tex = SpriteFactory.shared.trailPreviewTexture(trailColor: trailColor)
                    previewSprite = SKSpriteNode(texture: tex, size: CGSize(width: 44, height: 44))
                } else {
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

            // Preview background
            let previewBg = SKShapeNode(rectOf: CGSize(width: 50, height: 54), cornerRadius: 6)
            previewBg.fillColor = SKColor(red: 0.03, green: 0.03, blue: 0.06, alpha: 1)
            previewBg.strokeColor = ColorPalette.textSecondary.withAlphaComponent(0.15)
            previewBg.lineWidth = 1
            previewBg.position = CGPoint(x: previewX, y: 0)
            previewBg.zPosition = -1
            card.addChild(previewBg)

            // Text area
            let textX: CGFloat = -50

            let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            nameLabel.text = item.displayName
            nameLabel.fontSize = 13
            nameLabel.fontColor = ColorPalette.textPrimary
            nameLabel.position = CGPoint(x: textX, y: 12)
            nameLabel.verticalAlignmentMode = .center
            nameLabel.horizontalAlignmentMode = .left
            card.addChild(nameLabel)

            let descLabel = SKLabelNode(fontNamed: "Menlo")
            descLabel.text = item.description
            descLabel.fontSize = 10
            descLabel.fontColor = ColorPalette.textSecondary
            descLabel.position = CGPoint(x: textX, y: -3)
            descLabel.verticalAlignmentMode = .center
            descLabel.horizontalAlignmentMode = .left
            card.addChild(descLabel)

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

            container.addChild(card)
        }

        // Calculate max scroll
        let totalContentHeight = CGFloat(items.count) * (cardHeight + cardSpacing)
        maxScrollOffset = max(0, totalContentHeight - scrollAreaHeight)

        // Apply current scroll offset
        container.position.y = scrollOffset

        // Scroll indicator (thin bar on the right)
        if maxScrollOffset > 0 {
            let indicatorTrackHeight = scrollAreaHeight - 20
            let indicatorHeight = max(30, indicatorTrackHeight * (scrollAreaHeight / totalContentHeight))
            let scrollFraction = maxScrollOffset > 0 ? scrollOffset / maxScrollOffset : 0
            let indicatorY = scrollCenterY + (indicatorTrackHeight / 2) - (indicatorHeight / 2) - scrollFraction * (indicatorTrackHeight - indicatorHeight)

            let indicator = SKShapeNode(rectOf: CGSize(width: 4, height: indicatorHeight), cornerRadius: 2)
            indicator.fillColor = ColorPalette.textSecondary.withAlphaComponent(0.3)
            indicator.strokeColor = .clear
            indicator.position = CGPoint(x: cardWidth / 2 + 12, y: indicatorY)
            indicator.zPosition = 4
            indicator.name = "scrollIndicator"
            addChild(indicator)
        }
    }

    // MARK: - Touch Handling

    func handleTouchBegan(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)
        touchStartY = localPoint.y
        scrollStartOffset = scrollOffset
        isDragging = false
        hasActiveTouch = true
        scrollVelocity = 0
        lastTouchY = localPoint.y
        lastTouchTime = CACurrentMediaTime()
        scrollContainer?.removeAction(forKey: "momentum")
    }

    func handleTouchMoved(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)
        let deltaY = localPoint.y - touchStartY

        if abs(deltaY) > 5 {
            isDragging = true
        }

        if isDragging {
            // Natural scrolling: drag up = content slides up = reveal items below
            let newOffset = scrollStartOffset + deltaY
            scrollOffset = max(0, min(newOffset, maxScrollOffset))
            scrollContainer?.position.y = scrollOffset

            // Track velocity
            let now = CACurrentMediaTime()
            let dt = now - lastTouchTime
            if dt > 0 {
                scrollVelocity = (localPoint.y - lastTouchY) / CGFloat(dt)
            }
            lastTouchY = localPoint.y
            lastTouchTime = now

            // Update scroll indicator
            updateScrollIndicator()
        }
    }

    func handleTouchEnded(at point: CGPoint) {
        guard hasActiveTouch else { return }
        hasActiveTouch = false

        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        if isDragging {
            isDragging = false
            // Apply momentum
            if abs(scrollVelocity) > 50 {
                applyMomentum()
            }
            return
        }

        // Not a drag — treat as a tap
        handleTap(at: localPoint)
    }

    private func applyMomentum() {
        let startOffset = scrollOffset
        let duration: TimeInterval = min(Double(abs(scrollVelocity)) / 2000.0 + 0.2, 1.0)
        let distance = scrollVelocity * CGFloat(duration) * 0.5
        let targetOffset = max(0, min(startOffset + distance, maxScrollOffset))

        let action = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self = self else { return }
            let t = CGFloat(elapsed / CGFloat(duration))
            // Cubic ease-out for smoother deceleration
            let eased = 1 - pow(1 - t, 3)
            let current = startOffset + (targetOffset - startOffset) * eased
            self.scrollContainer?.position.y = current
            self.scrollOffset = current
            self.updateScrollIndicator()
        }
        scrollContainer?.run(SKAction.sequence([
            action,
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.scrollOffset = targetOffset
                self.scrollContainer?.position.y = targetOffset
                self.updateScrollIndicator()
            }
        ]), withKey: "momentum")
    }

    private func indicatorY(for offset: CGFloat) -> CGFloat {
        let tabY = screenSize.height * 0.22
        let scrollTopY = tabY - 26
        let scrollBottomY = -screenSize.height * 0.35 + 30
        let scrollAreaHeight = scrollTopY - scrollBottomY
        let scrollCenterY = (scrollTopY + scrollBottomY) / 2

        let items = CosmeticCatalog.items(forCategory: currentCategory)
        let totalContentHeight = CGFloat(items.count) * (cardHeight + cardSpacing)
        let indicatorTrackHeight = scrollAreaHeight - 20
        let indicatorHeight = max(30, indicatorTrackHeight * (scrollAreaHeight / totalContentHeight))
        let scrollFraction = maxScrollOffset > 0 ? offset / maxScrollOffset : 0
        return scrollCenterY + (indicatorTrackHeight / 2) - (indicatorHeight / 2) - scrollFraction * (indicatorTrackHeight - indicatorHeight)
    }

    private func updateScrollIndicator() {
        guard maxScrollOffset > 0 else { return }
        if let indicator = childNode(withName: "scrollIndicator") {
            indicator.position.y = indicatorY(for: scrollOffset)
        }
    }

    private func handleTap(at localPoint: CGPoint) {
        // If confirmation dialog is showing, route taps there
        if confirmOverlay != nil {
            handleConfirmTap(at: localPoint)
            return
        }

        // Check tab taps
        for cat in CosmeticCategory.allCases {
            if let tab = childNode(withName: "tab_\(cat.rawValue)") {
                let tabLocal = tab.convert(localPoint, from: self)
                if abs(tabLocal.x) < 40 && abs(tabLocal.y) < 20 {
                    currentCategory = cat
                    scrollOffset = 0
                    rebuild()
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
                    self?.onBack?()
                }
                return
            }
        }

        // Check item taps (need to account for scroll offset in the container)
        guard let container = scrollContainer else { return }
        let containerLocal = container.convert(localPoint, from: self)

        let items = CosmeticCatalog.items(forCategory: currentCategory).sorted { $0.price < $1.price }
        let pm = PersistenceManager.shared
        let tabY = screenSize.height * 0.22
        let scrollTopY = tabY - 26
        let itemStartY = scrollTopY - cardHeight / 2 - 6

        for (i, item) in items.enumerated() {
            let cardY = itemStartY - CGFloat(i) * (cardHeight + cardSpacing)
            let dy = containerLocal.y - cardY
            let dx = containerLocal.x

            if abs(dx) < cardWidth / 2 && abs(dy) < cardHeight / 2 {
                let isOwned = pm.isUnlocked(item.id)
                let isEquipped: Bool = {
                    switch item.category {
                    case .skin: return pm.profile.equippedSkin == item.id
                    case .hat: return pm.profile.equippedHat == item.id
                    case .trail: return pm.profile.equippedTrail == item.id
                    }
                }()

                if isEquipped { return }

                if isOwned {
                    switch item.category {
                    case .skin: pm.equipSkin(item.id)
                    case .hat: pm.equipHat(item.id)
                    case .trail: pm.equipTrail(item.id)
                    }
                    SpriteFactory.shared.invalidatePlayerTextures()
                    rebuild()
                } else {
                    // Show purchase confirmation
                    showConfirmation(for: item)
                }
                return
            }
        }
    }

    // MARK: - Purchase Confirmation

    private func showConfirmation(for item: CosmeticItem) {
        dismissConfirmation()
        pendingPurchaseItem = item

        let overlay = SKNode()
        overlay.zPosition = 20
        overlay.name = "confirmOverlay"

        // Dim background
        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.6), size: screenSize)
        dim.zPosition = 0
        overlay.addChild(dim)

        // Dialog box
        let dialogW: CGFloat = 260
        let dialogH: CGFloat = 160
        let dialog = SKShapeNode(rectOf: CGSize(width: dialogW, height: dialogH), cornerRadius: 12)
        dialog.fillColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        dialog.strokeColor = ColorPalette.gold.withAlphaComponent(0.6)
        dialog.lineWidth = 2
        dialog.zPosition = 1
        overlay.addChild(dialog)

        // Title
        let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "Purchase?"
        titleLabel.fontSize = 18
        titleLabel.fontColor = ColorPalette.textPrimary
        titleLabel.position = CGPoint(x: 0, y: 45)
        titleLabel.zPosition = 2
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        overlay.addChild(titleLabel)

        // Item name
        let nameLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        nameLabel.text = item.displayName
        nameLabel.fontSize = 15
        nameLabel.fontColor = ColorPalette.playerPrimary
        nameLabel.position = CGPoint(x: 0, y: 18)
        nameLabel.zPosition = 2
        nameLabel.verticalAlignmentMode = .center
        nameLabel.horizontalAlignmentMode = .center
        overlay.addChild(nameLabel)

        // Price
        let priceLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        priceLabel.text = "\(item.price) coins"
        priceLabel.fontSize = 14
        priceLabel.fontColor = ColorPalette.gold
        priceLabel.position = CGPoint(x: 0, y: -5)
        priceLabel.zPosition = 2
        priceLabel.verticalAlignmentMode = .center
        priceLabel.horizontalAlignmentMode = .center
        overlay.addChild(priceLabel)

        // Insufficient funds warning
        let pm = PersistenceManager.shared
        if pm.profile.coins < item.price {
            let warnLabel = SKLabelNode(fontNamed: "Menlo")
            warnLabel.text = "Not enough coins!"
            warnLabel.fontSize = 11
            warnLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1)
            warnLabel.position = CGPoint(x: 0, y: -22)
            warnLabel.zPosition = 2
            warnLabel.verticalAlignmentMode = .center
            warnLabel.horizontalAlignmentMode = .center
            overlay.addChild(warnLabel)
        }

        // Confirm button
        let confirmBtn = SKNode()
        confirmBtn.name = "confirmBuy"
        confirmBtn.position = CGPoint(x: -60, y: -50)
        confirmBtn.zPosition = 2
        let confirmBg = SKShapeNode(rectOf: CGSize(width: 100, height: 36), cornerRadius: 6)
        confirmBg.fillColor = pm.profile.coins >= item.price ? ColorPalette.playerPrimary.withAlphaComponent(0.3) : ColorPalette.hudBackground
        confirmBg.strokeColor = pm.profile.coins >= item.price ? ColorPalette.playerPrimary : ColorPalette.textSecondary.withAlphaComponent(0.3)
        confirmBg.lineWidth = 2
        confirmBtn.addChild(confirmBg)
        let confirmLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        confirmLabel.text = "BUY"
        confirmLabel.fontSize = 14
        confirmLabel.fontColor = pm.profile.coins >= item.price ? ColorPalette.playerPrimary : ColorPalette.textSecondary
        confirmLabel.verticalAlignmentMode = .center
        confirmLabel.horizontalAlignmentMode = .center
        confirmBtn.addChild(confirmLabel)
        overlay.addChild(confirmBtn)

        // Cancel button
        let cancelBtn = SKNode()
        cancelBtn.name = "confirmCancel"
        cancelBtn.position = CGPoint(x: 60, y: -50)
        cancelBtn.zPosition = 2
        let cancelBg = SKShapeNode(rectOf: CGSize(width: 100, height: 36), cornerRadius: 6)
        cancelBg.fillColor = ColorPalette.hudBackground
        cancelBg.strokeColor = ColorPalette.textSecondary
        cancelBg.lineWidth = 2
        cancelBtn.addChild(cancelBg)
        let cancelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        cancelLabel.text = "CANCEL"
        cancelLabel.fontSize = 14
        cancelLabel.fontColor = ColorPalette.textSecondary
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.horizontalAlignmentMode = .center
        cancelBtn.addChild(cancelLabel)
        overlay.addChild(cancelBtn)

        // Animate in
        overlay.alpha = 0
        overlay.setScale(0.9)
        overlay.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))

        addChild(overlay)
        confirmOverlay = overlay
    }

    private func dismissConfirmation() {
        confirmOverlay?.removeFromParent()
        confirmOverlay = nil
        pendingPurchaseItem = nil
    }

    private func handleConfirmTap(at localPoint: CGPoint) {
        guard let overlay = confirmOverlay else { return }

        // Check confirm button
        if let btn = overlay.childNode(withName: "confirmBuy") {
            let btnLocal = btn.convert(localPoint, from: self)
            if abs(btnLocal.x) < 55 && abs(btnLocal.y) < 22 {
                if let item = pendingPurchaseItem {
                    let pm = PersistenceManager.shared
                    if pm.spendCoins(item.price) {
                        pm.unlockCosmetic(item.id)
                        switch item.category {
                        case .skin: pm.equipSkin(item.id)
                        case .hat: pm.equipHat(item.id)
                        case .trail: pm.equipTrail(item.id)
                        }
                        SpriteFactory.shared.invalidatePlayerTextures()
                        dismissConfirmation()
                        rebuild()
                    } else {
                        // Shake the dialog
                        overlay.run(SKAction.sequence([
                            SKAction.moveBy(x: -5, y: 0, duration: 0.04),
                            SKAction.moveBy(x: 10, y: 0, duration: 0.04),
                            SKAction.moveBy(x: -10, y: 0, duration: 0.04),
                            SKAction.moveBy(x: 5, y: 0, duration: 0.04),
                        ]))
                    }
                }
                return
            }
        }

        // Check cancel button (or tap anywhere else)
        dismissConfirmation()
    }

    func hide() {
        dismissConfirmation()
        removeAllChildren()
        isHidden = true
        alpha = 1
        scrollContainer = nil
        cropNode = nil
    }
}
