import SpriteKit
import StoreKit

class CoinPurchaseNode: SKNode {
    private var screenSize: CGSize = .zero
    private var isPurchasing: Bool = false

    override init() {
        super.init()
        self.zPosition = 960
        self.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(screenSize: CGSize) {
        self.screenSize = screenSize
        self.isHidden = false
        self.isPurchasing = false
        rebuild()

        // Animate in
        self.alpha = 0
        self.setScale(0.9)
        self.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))

        // If products aren't loaded yet, load and refresh
        if StoreManager.shared.coinPackProducts().isEmpty {
            Task { [weak self] in
                await StoreManager.shared.loadProducts()
                guard let self = self, !self.isHidden else { return }
                self.rebuild()
            }
        }
    }

    func hide() {
        self.run(SKAction.group([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.scale(to: 0.9, duration: 0.15)
        ])) { [weak self] in
            self?.removeAllChildren()
            self?.isHidden = true
            self?.setScale(1.0)
            self?.alpha = 1.0
        }
    }

    private func rebuild() {
        removeAllChildren()

        // Dim background
        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.65), size: screenSize)
        dim.zPosition = 0
        dim.name = "dimBg"
        addChild(dim)

        // Panel
        let panelW: CGFloat = 280
        let panelH: CGFloat = 380
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 14)
        panel.fillColor = SKColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 0.98)
        panel.strokeColor = ColorPalette.gold
        panel.lineWidth = 2.5
        panel.zPosition = 1
        panel.name = "panel"
        addChild(panel)

        // Close button (X) in top-right of panel
        let closeBtn = SKNode()
        closeBtn.position = CGPoint(x: panelW / 2 - 20, y: panelH / 2 - 20)
        closeBtn.zPosition = 3
        closeBtn.name = "closeButton"

        let closeBg = SKShapeNode(circleOfRadius: 14)
        closeBg.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        closeBg.strokeColor = ColorPalette.textSecondary.withAlphaComponent(0.5)
        closeBg.lineWidth = 1
        closeBtn.addChild(closeBg)

        let closeLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        closeLabel.text = "X"
        closeLabel.fontSize = 14
        closeLabel.fontColor = ColorPalette.textSecondary
        closeLabel.verticalAlignmentMode = .center
        closeLabel.horizontalAlignmentMode = .center
        closeBtn.addChild(closeLabel)
        addChild(closeBtn)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "GET COINS"
        title.fontSize = 22
        title.fontColor = ColorPalette.gold
        title.position = CGPoint(x: 0, y: panelH / 2 - 35)
        title.zPosition = 2
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Current balance
        let balance = SKLabelNode(fontNamed: "Menlo")
        balance.text = "Balance: \(PersistenceManager.shared.profile.coins) coins"
        balance.fontSize = 12
        balance.fontColor = ColorPalette.textSecondary
        balance.position = CGPoint(x: 0, y: panelH / 2 - 56)
        balance.zPosition = 2
        balance.verticalAlignmentMode = .center
        balance.horizontalAlignmentMode = .center
        addChild(balance)

        // Coin pack rows
        let coinPacks = StoreManager.shared.coinPackProducts()
        let rowHeight: CGFloat = 48
        let startY: CGFloat = panelH / 2 - 90

        let coinLabels: [String: String] = [
            "com.rewindsurvivor.coins.500": "500",
            "com.rewindsurvivor.coins.1200": "1,200",
            "com.rewindsurvivor.coins.3500": "3,500",
            "com.rewindsurvivor.coins.8000": "8,000",
            "com.rewindsurvivor.coins.20000": "20,000"
        ]

        if coinPacks.isEmpty {
            let sm = StoreManager.shared
            let loading = SKLabelNode(fontNamed: "Menlo")
            if let error = sm.loadError {
                loading.text = "Error: \(error)"
            } else if sm.didAttemptLoad {
                loading.text = "No products found"
            } else {
                loading.text = "Loading..."
            }
            loading.fontSize = 13
            loading.fontColor = ColorPalette.textSecondary
            loading.position = CGPoint(x: 0, y: 8)
            loading.zPosition = 2
            loading.verticalAlignmentMode = .center
            loading.horizontalAlignmentMode = .center
            addChild(loading)

            let retry = SKLabelNode(fontNamed: "Menlo-Bold")
            retry.text = "Tap to retry"
            retry.fontSize = 12
            retry.fontColor = ColorPalette.playerPrimary
            retry.position = CGPoint(x: 0, y: -14)
            retry.zPosition = 2
            retry.verticalAlignmentMode = .center
            retry.horizontalAlignmentMode = .center
            retry.name = "retryButton"
            addChild(retry)
        } else {
            for (i, product) in coinPacks.enumerated() {
                let y = startY - CGFloat(i) * rowHeight

                let row = SKNode()
                row.position = CGPoint(x: 0, y: y)
                row.zPosition = 2
                row.name = "coinRow_\(product.id)"

                // Row background
                let rowBg = SKShapeNode(rectOf: CGSize(width: panelW - 30, height: 40), cornerRadius: 8)
                rowBg.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
                rowBg.strokeColor = ColorPalette.gold.withAlphaComponent(0.3)
                rowBg.lineWidth = 1
                row.addChild(rowBg)

                // Coin icon
                let coinIcon = SKLabelNode(fontNamed: "Menlo-Bold")
                coinIcon.text = "\u{25C9}"  // circle
                coinIcon.fontSize = 16
                coinIcon.fontColor = ColorPalette.gold
                coinIcon.position = CGPoint(x: -105, y: 0)
                coinIcon.verticalAlignmentMode = .center
                coinIcon.horizontalAlignmentMode = .left
                row.addChild(coinIcon)

                // Coin amount
                let amountLabel = SKLabelNode(fontNamed: "Menlo-Bold")
                amountLabel.text = coinLabels[product.id] ?? "\(product.id)"
                amountLabel.fontSize = 15
                amountLabel.fontColor = ColorPalette.textPrimary
                amountLabel.position = CGPoint(x: -85, y: 0)
                amountLabel.verticalAlignmentMode = .center
                amountLabel.horizontalAlignmentMode = .left
                row.addChild(amountLabel)

                // Price button
                let priceBg = SKShapeNode(rectOf: CGSize(width: 70, height: 30), cornerRadius: 6)
                priceBg.fillColor = ColorPalette.playerPrimary.withAlphaComponent(0.25)
                priceBg.strokeColor = ColorPalette.playerPrimary
                priceBg.lineWidth = 1.5
                priceBg.position = CGPoint(x: 85, y: 0)
                row.addChild(priceBg)

                let priceLabel = SKLabelNode(fontNamed: "Menlo-Bold")
                priceLabel.text = product.displayPrice
                priceLabel.fontSize = 12
                priceLabel.fontColor = ColorPalette.playerPrimary
                priceLabel.position = CGPoint(x: 85, y: 0)
                priceLabel.verticalAlignmentMode = .center
                priceLabel.horizontalAlignmentMode = .center
                row.addChild(priceLabel)

                addChild(row)
            }
        }

        // Restore Purchases
        let restoreLabel = SKLabelNode(fontNamed: "Menlo")
        restoreLabel.text = "Restore Purchases"
        restoreLabel.fontSize = 12
        restoreLabel.fontColor = ColorPalette.playerPrimary.withAlphaComponent(0.7)
        restoreLabel.position = CGPoint(x: 0, y: -panelH / 2 + 22)
        restoreLabel.zPosition = 2
        restoreLabel.verticalAlignmentMode = .center
        restoreLabel.horizontalAlignmentMode = .center
        restoreLabel.name = "restoreButton"
        addChild(restoreLabel)
    }

    func handleTouch(at point: CGPoint) {
        guard !isPurchasing else { return }
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        // Close button
        if let closeBtn = childNode(withName: "closeButton") {
            let btnLocal = closeBtn.convert(localPoint, from: self)
            if abs(btnLocal.x) < 18 && abs(btnLocal.y) < 18 {
                hide()
                return
            }
        }

        // Tap dim background (outside panel) to dismiss
        if let panel = childNode(withName: "panel") as? SKShapeNode {
            let panelLocal = panel.convert(localPoint, from: self)
            let panelW: CGFloat = 280
            let panelH: CGFloat = 380
            if abs(panelLocal.x) > panelW / 2 || abs(panelLocal.y) > panelH / 2 {
                hide()
                return
            }
        }

        // Retry loading
        if let retryBtn = childNode(withName: "retryButton") {
            let retryLocal = retryBtn.convert(localPoint, from: self)
            if abs(retryLocal.x) < 60 && abs(retryLocal.y) < 14 {
                Task { [weak self] in
                    await StoreManager.shared.loadProducts()
                    guard let self = self, !self.isHidden else { return }
                    self.rebuild()
                }
                return
            }
        }

        // Restore purchases
        if let restore = childNode(withName: "restoreButton") {
            let restoreLocal = restore.convert(localPoint, from: self)
            if abs(restoreLocal.x) < 80 && abs(restoreLocal.y) < 14 {
                Task { [weak self] in
                    await StoreManager.shared.restorePurchases()
                    self?.rebuild()
                }
                return
            }
        }

        // Coin pack rows
        let coinPacks = StoreManager.shared.coinPackProducts()
        for product in coinPacks {
            if let row = childNode(withName: "coinRow_\(product.id)") {
                let rowLocal = row.convert(localPoint, from: self)
                if abs(rowLocal.x) < 125 && abs(rowLocal.y) < 22 {
                    purchaseCoinPack(product)
                    return
                }
            }
        }
    }

    private func purchaseCoinPack(_ product: Product) {
        isPurchasing = true

        // Visual feedback
        if let row = childNode(withName: "coinRow_\(product.id)") {
            row.run(SKAction.sequence([
                SKAction.scale(to: 0.95, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ]))
        }

        Task { [weak self] in
            do {
                let success = try await StoreManager.shared.purchase(product)
                guard let self = self else { return }
                self.isPurchasing = false
                if success {
                    self.rebuild()
                }
            } catch {
                self?.isPurchasing = false
            }
        }
    }
}
