import SpriteKit

class TutorialNode: SKNode {
    private var onBack: (() -> Void)?
    private var currentPage: Int = 0
    private let totalPages = 5
    private var screenSize: CGSize = .zero
    private var pageDots: [SKShapeNode] = []

    // Swipe tracking
    private var touchStartX: CGFloat?
    private let swipeThreshold: CGFloat = 50

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
        currentPage = 0
        buildPage()
    }

    // MARK: - Touch Handling (Swipe + Back Button)

    func handleTouchBegan(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        // Check back button tap immediately
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

        // Start tracking swipe
        touchStartX = localPoint.x
    }

    func handleTouchEnded(at point: CGPoint) {
        guard let parent = self.parent else { return }
        let localPoint = convert(point, from: parent)

        guard let startX = touchStartX else { return }
        touchStartX = nil

        let deltaX = localPoint.x - startX
        if deltaX < -swipeThreshold && currentPage < totalPages - 1 {
            // Swipe left → next page
            currentPage += 1
            buildPageAnimated(direction: .left)
        } else if deltaX > swipeThreshold && currentPage > 0 {
            // Swipe right → previous page
            currentPage -= 1
            buildPageAnimated(direction: .right)
        }
    }

    // MARK: - Page Building

    private enum SlideDirection { case left, right }

    private func buildPageAnimated(direction: SlideDirection) {
        let slideOut = direction == .left ? -screenSize.width * 0.3 : screenSize.width * 0.3
        let slideIn = -slideOut

        // Fade out current content
        let snapshot = SKNode()
        for child in children {
            // Skip — we'll rebuild everything
        }

        // Quick fade transition
        let overlay = SKSpriteNode(color: .black, size: screenSize)
        overlay.alpha = 0
        overlay.zPosition = 999
        addChild(overlay)

        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.run { [weak self] in
                self?.buildPage()
            },
            SKAction.fadeAlpha(to: 0, duration: 0.15),
            SKAction.removeFromParent()
        ]))
    }

    private func buildPage() {
        removeAllChildren()
        pageDots.removeAll()

        // Background
        let bg = SKSpriteNode(color: ColorPalette.arenaFloor, size: screenSize)
        bg.zPosition = 0
        addChild(bg)

        // Title
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "HOW TO PLAY"
        title.fontSize = 28
        title.fontColor = ColorPalette.playerPrimary
        title.position = CGPoint(x: 0, y: screenSize.height * 0.38)
        title.zPosition = 1
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        addChild(title)

        // Page number
        let pageLabel = SKLabelNode(fontNamed: "Menlo")
        pageLabel.text = "\(currentPage + 1) / \(totalPages)"
        pageLabel.fontSize = 12
        pageLabel.fontColor = ColorPalette.textSecondary
        pageLabel.position = CGPoint(x: 0, y: screenSize.height * 0.33)
        pageLabel.zPosition = 1
        pageLabel.verticalAlignmentMode = .center
        pageLabel.horizontalAlignmentMode = .center
        addChild(pageLabel)

        // Swipe hint (subtle)
        let swipeHint = SKLabelNode(fontNamed: "Menlo")
        swipeHint.fontSize = 10
        swipeHint.fontColor = ColorPalette.textSecondary.withAlphaComponent(0.4)
        swipeHint.verticalAlignmentMode = .center
        swipeHint.horizontalAlignmentMode = .center
        swipeHint.zPosition = 1
        if currentPage == 0 {
            swipeHint.text = "SWIPE LEFT >"
        } else if currentPage == totalPages - 1 {
            swipeHint.text = "< SWIPE RIGHT"
        } else {
            swipeHint.text = "< SWIPE >"
        }
        swipeHint.position = CGPoint(x: 0, y: -screenSize.height * 0.30)
        addChild(swipeHint)

        // Page content
        buildPageContent(page: currentPage)

        // Page dots
        let dotSpacing: CGFloat = 18
        let dotsWidth = CGFloat(totalPages - 1) * dotSpacing
        let dotsStartX = -dotsWidth / 2
        for i in 0..<totalPages {
            let dot = SKShapeNode(circleOfRadius: i == currentPage ? 5 : 3.5)
            dot.fillColor = i == currentPage ? ColorPalette.playerPrimary : ColorPalette.textSecondary.withAlphaComponent(0.4)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: dotsStartX + CGFloat(i) * dotSpacing, y: -screenSize.height * 0.34)
            dot.zPosition = 1
            addChild(dot)
            pageDots.append(dot)
        }

        // Back button
        let backBtn = createBackButton()
        addChild(backBtn)
    }

    private func buildPageContent(page: Int) {
        let contentY = screenSize.height * 0.08
        let illustrationY = contentY + 70
        let textY = contentY - 60

        switch page {
        case 0: // Movement & auto-attack
            addIllustration(at: illustrationY, width: 260, height: 90) { parent in
                // Joystick illustration
                let base = SKShapeNode(circleOfRadius: 30)
                base.fillColor = ColorPalette.hudBackground
                base.strokeColor = ColorPalette.playerPrimary.withAlphaComponent(0.5)
                base.lineWidth = 2
                base.position = CGPoint(x: -60, y: 0)
                parent.addChild(base)

                let knob = SKShapeNode(circleOfRadius: 12)
                knob.fillColor = ColorPalette.playerPrimary.withAlphaComponent(0.6)
                knob.strokeColor = ColorPalette.playerPrimary
                knob.lineWidth = 1.5
                knob.position = CGPoint(x: -48, y: 10)
                parent.addChild(knob)

                // Arrow showing direction
                let arrow = SKLabelNode(fontNamed: "Menlo-Bold")
                arrow.text = ">"
                arrow.fontSize = 24
                arrow.fontColor = ColorPalette.playerPrimary
                arrow.position = CGPoint(x: -20, y: -3)
                arrow.verticalAlignmentMode = .center
                parent.addChild(arrow)

                // Player sprite
                let player = SKSpriteNode(texture: SpriteFactory.shared.playerTexture(facing: .right, frame: 0))
                player.size = CGSize(width: 32, height: 32)
                player.position = CGPoint(x: 20, y: 0)
                parent.addChild(player)

                // Bullets
                let bullet = SKSpriteNode(color: ColorPalette.bulletPlayer, size: CGSize(width: 6, height: 6))
                bullet.position = CGPoint(x: 55, y: 0)
                bullet.blendMode = .add
                parent.addChild(bullet)

                let bullet2 = SKSpriteNode(color: ColorPalette.bulletPlayer, size: CGSize(width: 6, height: 6))
                bullet2.position = CGPoint(x: 75, y: 0)
                bullet2.blendMode = .add
                bullet2.alpha = 0.5
                parent.addChild(bullet2)
            }

            addTextBlock(at: textY, heading: "MOVEMENT & COMBAT", lines: [
                "Touch and drag anywhere on screen",
                "to move your character around.",
                "",
                "You automatically fire at the nearest",
                "enemy — no aiming required!",
                "",
                "Keep moving to dodge enemy attacks",
                "and stay alive as long as possible."
            ])

        case 1: // Enemies & waves — actual enemy sprites
            addIllustration(at: illustrationY, width: 300, height: 110) { parent in
                // Show 6 enemy types with actual sprites
                let enemies: [(EnemyType, CGFloat, CGFloat)] = [
                    (.shambler,  -100, 22),
                    (.dasher,     -35, 22),
                    (.strafer,     30, 22),
                    (.bomber,    -100, -22),
                    (.necromancer, -35, -22),
                    (.juggernaut,  30, -22),
                ]

                for (type, x, y) in enemies {
                    let sprite = SKSpriteNode(texture: SpriteFactory.shared.enemyTexture(type: type, frame: 0))
                    let displaySize: CGFloat = type.name == "Juggernaut" ? 36 : (type.name == "Necromancer" ? 32 : 28)
                    sprite.size = CGSize(width: displaySize, height: displaySize)
                    sprite.position = CGPoint(x: x, y: y)
                    parent.addChild(sprite)

                    // Name label under each sprite
                    let nameLabel = SKLabelNode(fontNamed: "Menlo")
                    nameLabel.text = type.name.uppercased()
                    nameLabel.fontSize = 6
                    nameLabel.fontColor = type.color
                    nameLabel.position = CGPoint(x: x, y: y - displaySize / 2 - 6)
                    nameLabel.verticalAlignmentMode = .center
                    nameLabel.horizontalAlignmentMode = .center
                    parent.addChild(nameLabel)
                }

                // "& more" label on the right
                let moreLbl = SKLabelNode(fontNamed: "Menlo-Bold")
                moreLbl.text = "& MORE"
                moreLbl.fontSize = 11
                moreLbl.fontColor = ColorPalette.textSecondary.withAlphaComponent(0.6)
                moreLbl.position = CGPoint(x: 110, y: 0)
                moreLbl.verticalAlignmentMode = .center
                moreLbl.horizontalAlignmentMode = .center
                parent.addChild(moreLbl)
            }

            addTextBlock(at: textY, heading: "ENEMIES & WAVES", lines: [
                "Survive waves of increasingly tough",
                "enemies to progress through the game.",
                "",
                "Each enemy type has unique behavior:",
                "Shamblers chase, Dashers charge,",
                "Strafers circle and shoot, Bombers",
                "explode on death, and many more!",
                "New types unlock as waves increase."
            ])

        case 2: // Death → Rewind → Ghost
            addIllustration(at: illustrationY, width: 260, height: 90) { parent in
                // Death icon
                let skull = SKLabelNode(fontNamed: "Menlo-Bold")
                skull.text = "HP:0"
                skull.fontSize = 14
                skull.fontColor = ColorPalette.powerUpRed
                skull.position = CGPoint(x: -65, y: 0)
                skull.verticalAlignmentMode = .center
                parent.addChild(skull)

                // Arrow
                let arr1 = SKLabelNode(fontNamed: "Menlo-Bold")
                arr1.text = ">"
                arr1.fontSize = 18
                arr1.fontColor = ColorPalette.rewindMagenta
                arr1.position = CGPoint(x: -35, y: -1)
                arr1.verticalAlignmentMode = .center
                parent.addChild(arr1)

                // Rewind icon
                let rewind = SKLabelNode(fontNamed: "Menlo-Bold")
                rewind.text = "<<"
                rewind.fontSize = 16
                rewind.fontColor = ColorPalette.rewindMagenta
                rewind.position = CGPoint(x: -5, y: 0)
                rewind.verticalAlignmentMode = .center
                parent.addChild(rewind)

                // Arrow 2
                let arr2 = SKLabelNode(fontNamed: "Menlo-Bold")
                arr2.text = ">"
                arr2.fontSize = 18
                arr2.fontColor = ColorPalette.ghostCyan
                arr2.position = CGPoint(x: 25, y: -1)
                arr2.verticalAlignmentMode = .center
                parent.addChild(arr2)

                // Ghost sprite
                let ghost = SKSpriteNode(texture: SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: 0))
                ghost.size = CGSize(width: 32, height: 32)
                ghost.position = CGPoint(x: 60, y: 0)
                ghost.alpha = 0.6
                parent.addChild(ghost)
            }

            addTextBlock(at: textY, heading: "DEATH & REWIND", lines: [
                "When you die, time rewinds! You",
                "respawn at center with full HP.",
                "",
                "A ghost replays your previous life,",
                "fighting alongside you forever!",
                "",
                "Earn deaths by hitting score goals:",
                "500 > 950 > 1800 > 3400 and beyond.",
                "Each death is an extra life!"
            ])

        case 3: // Power-ups & stacking
            addIllustration(at: illustrationY, width: 260, height: 90) { parent in
                let types: [PowerUpType] = [.damage, .multishot, .chainLightning]
                for (i, type) in types.enumerated() {
                    let x = CGFloat(i - 1) * 55
                    let icon = SKSpriteNode(texture: SpriteFactory.shared.powerUpIconTexture(type: type))
                    icon.size = CGSize(width: 32, height: 32)
                    icon.position = CGPoint(x: x, y: 0)
                    parent.addChild(icon)

                    let border = SKShapeNode(rectOf: CGSize(width: 40, height: 40), cornerRadius: 6)
                    border.fillColor = ColorPalette.hudBackground
                    border.strokeColor = type.iconColor
                    border.lineWidth = 1.5
                    border.position = CGPoint(x: x, y: 0)
                    border.zPosition = -1
                    parent.addChild(border)
                }

                // Stack indicator
                let stackLbl = SKLabelNode(fontNamed: "Menlo")
                stackLbl.text = "x3"
                stackLbl.fontSize = 10
                stackLbl.fontColor = ColorPalette.gold
                stackLbl.position = CGPoint(x: -55 + 18, y: -18)
                stackLbl.verticalAlignmentMode = .center
                parent.addChild(stackLbl)
            }

            addTextBlock(at: textY, heading: "POWER-UPS", lines: [
                "After each wave, choose one of three",
                "random power-ups to boost your stats.",
                "",
                "Power-ups stack! Pick the same one",
                "multiple times for stronger effects.",
                "",
                "15 upgrades: rapid fire, multi shot,",
                "chain lightning, life steal, thorns,",
                "explosive rounds, frost aura & more!"
            ])

        case 4: // Deaths & super power-ups
            addIllustration(at: illustrationY, width: 280, height: 90) { parent in
                // Death bank with skull icons
                let bankLabel = SKLabelNode(fontNamed: "Menlo-Bold")
                bankLabel.text = "DEATHS:"
                bankLabel.fontSize = 12
                bankLabel.fontColor = ColorPalette.rewindMagenta
                bankLabel.position = CGPoint(x: -70, y: 20)
                bankLabel.verticalAlignmentMode = .center
                bankLabel.horizontalAlignmentMode = .left
                parent.addChild(bankLabel)

                // Skull icons for death count
                for i in 0..<3 {
                    let skull = SKLabelNode(fontNamed: "Menlo-Bold")
                    skull.text = "\u{2620}"
                    skull.fontSize = 16
                    skull.fontColor = ColorPalette.rewindMagenta
                    skull.position = CGPoint(x: CGFloat(i) * 20 + 10, y: 20)
                    skull.verticalAlignmentMode = .center
                    parent.addChild(skull)
                }

                // Arrow down to super icons
                let arrow = SKLabelNode(fontNamed: "Menlo-Bold")
                arrow.text = "SPEND"
                arrow.fontSize = 8
                arrow.fontColor = ColorPalette.textSecondary
                arrow.position = CGPoint(x: -15, y: 2)
                arrow.verticalAlignmentMode = .center
                parent.addChild(arrow)

                // Super power-up icons
                let supers: [SuperPowerUpType] = [.chronoShift, .quantumNuke, .shadowClone]
                for (i, superType) in supers.enumerated() {
                    let x = CGFloat(i - 1) * 45 - 15
                    let icon = SKSpriteNode(texture: SpriteFactory.shared.superPowerUpIconTexture(type: superType))
                    icon.size = CGSize(width: 24, height: 24)
                    icon.position = CGPoint(x: x, y: -20)
                    parent.addChild(icon)

                    let border = SKShapeNode(rectOf: CGSize(width: 30, height: 30), cornerRadius: 4)
                    border.fillColor = ColorPalette.hudBackground
                    border.strokeColor = superType.iconColor.withAlphaComponent(0.6)
                    border.lineWidth = 1
                    border.position = CGPoint(x: x, y: -20)
                    border.zPosition = -1
                    parent.addChild(border)
                }

                // Cost label
                let costLbl = SKLabelNode(fontNamed: "Menlo")
                costLbl.text = "1-2 DEATHS EACH"
                costLbl.fontSize = 7
                costLbl.fontColor = ColorPalette.rewindMagenta.withAlphaComponent(0.7)
                costLbl.position = CGPoint(x: -15, y: -40)
                costLbl.verticalAlignmentMode = .center
                parent.addChild(costLbl)
            }

            addTextBlock(at: textY, heading: "DEATHS & SUPER POWERS", lines: [
                "Your death bank holds extra lives.",
                "Earn deaths by reaching score goals.",
                "",
                "After wave 15, you can SPEND deaths",
                "on powerful super abilities!",
                "",
                "Chrono Shift, Quantum Nuke, Shadow",
                "Clone, Gravity Well & Void Barrier.",
                "Choose wisely — deaths are precious!"
            ])

        default:
            break
        }
    }

    // MARK: - Helpers

    private func addIllustration(at y: CGFloat, width: CGFloat = 260, height: CGFloat = 90, build: (SKNode) -> Void) {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: y)
        container.zPosition = 2

        // Background panel
        let panel = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        panel.fillColor = ColorPalette.hudBackground
        panel.strokeColor = ColorPalette.playerPrimary.withAlphaComponent(0.2)
        panel.lineWidth = 1
        container.addChild(panel)

        build(container)
        addChild(container)

        // Animate in
        container.alpha = 0
        container.setScale(0.9)
        container.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ]))
    }

    private func addTextBlock(at y: CGFloat, heading: String, lines: [String]) {
        let headLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        headLabel.text = heading
        headLabel.fontSize = 15
        headLabel.fontColor = ColorPalette.gold
        headLabel.position = CGPoint(x: 0, y: y)
        headLabel.zPosition = 1
        headLabel.verticalAlignmentMode = .center
        headLabel.horizontalAlignmentMode = .center
        addChild(headLabel)

        for (i, line) in lines.enumerated() {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = line
            label.fontSize = 11
            label.fontColor = line.isEmpty ? .clear : ColorPalette.textSecondary
            label.position = CGPoint(x: 0, y: y - 22 - CGFloat(i) * 16)
            label.zPosition = 1
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            addChild(label)

            // Stagger fade in
            if !line.isEmpty {
                label.alpha = 0
                label.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.1 + Double(i) * 0.04),
                    SKAction.fadeIn(withDuration: 0.2)
                ]))
            }
        }

        headLabel.alpha = 0
        headLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.fadeIn(withDuration: 0.2)
        ]))
    }

    private func createBackButton() -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -screenSize.height * 0.42)
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
        container.run(SKAction.sequence([SKAction.wait(forDuration: 0.3), SKAction.fadeIn(withDuration: 0.3)]))

        return container
    }

    // Legacy single-touch handler (back button only) — kept for compatibility
    func handleTouch(at point: CGPoint) {
        handleTouchBegan(at: point)
    }

    func hide() {
        removeAllChildren()
        pageDots.removeAll()
        touchStartX = nil
        isHidden = true
        alpha = 1
    }
}
