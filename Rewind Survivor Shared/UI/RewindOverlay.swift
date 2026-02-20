import SpriteKit

class RewindOverlay: SKNode {
    private var dimmer: SKSpriteNode?
    private var scanLines: [SKSpriteNode] = []
    private var rewindLabel: SKLabelNode?
    private var screenSize: CGSize = .zero

    override init() {
        super.init()
        self.zPosition = 800
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(screenSize: CGSize) {
        self.screenSize = screenSize
        self.isHidden = false
        removeAllChildren()
        scanLines.removeAll()

        // Dimmer (magenta tint)
        let dim = SKSpriteNode(color: ColorPalette.rewindMagenta, size: screenSize)
        dim.alpha = 0
        dim.zPosition = 0
        addChild(dim)
        dimmer = dim
        dim.run(SKAction.fadeAlpha(to: 0.25, duration: 0.2))

        // Scan lines
        let lineCount = 15
        let lineHeight: CGFloat = 2
        for i in 0..<lineCount {
            let line = SKSpriteNode(color: ColorPalette.rewindScanline, size: CGSize(width: screenSize.width, height: lineHeight))
            line.alpha = 0.2
            line.zPosition = 1
            line.position.y = -screenSize.height / 2 + CGFloat(i) * (screenSize.height / CGFloat(lineCount))
            addChild(line)
            scanLines.append(line)

            // Scroll upward
            let scrollDuration = 0.6 + Double.random(in: 0...0.3)
            line.run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.moveTo(y: screenSize.height / 2, duration: scrollDuration),
                    SKAction.moveTo(y: -screenSize.height / 2, duration: 0)
                ])
            ))
        }

        // Rewind text
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "<<< REWIND <<<"
        label.fontSize = 28
        label.fontColor = ColorPalette.rewindMagenta
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 2
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
        rewindLabel = label

        // Blink animation
        label.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.12),
            SKAction.fadeAlpha(to: 1.0, duration: 0.12),
        ])))

        // Chromatic aberration hint: offset colored copies of text
        let redCopy = SKLabelNode(fontNamed: "Menlo-Bold")
        redCopy.text = "<<< REWIND <<<"
        redCopy.fontSize = 28
        redCopy.fontColor = SKColor(red: 1, green: 0, blue: 0, alpha: 0.3)
        redCopy.position = CGPoint(x: 3, y: 1)
        redCopy.zPosition = 1.5
        redCopy.verticalAlignmentMode = .center
        redCopy.horizontalAlignmentMode = .center
        label.addChild(redCopy)

        let blueCopy = SKLabelNode(fontNamed: "Menlo-Bold")
        blueCopy.text = "<<< REWIND <<<"
        blueCopy.fontSize = 28
        blueCopy.fontColor = SKColor(red: 0, green: 0, blue: 1, alpha: 0.3)
        blueCopy.position = CGPoint(x: -3, y: -1)
        blueCopy.zPosition = 1.5
        blueCopy.verticalAlignmentMode = .center
        blueCopy.horizontalAlignmentMode = .center
        label.addChild(blueCopy)

        // Horizontal glitch bars
        for _ in 0..<5 {
            let glitch = SKSpriteNode(color: .white, size: CGSize(
                width: CGFloat.random(in: 100...screenSize.width * 0.8),
                height: CGFloat.random(in: 2...6)
            ))
            glitch.alpha = 0
            glitch.zPosition = 3
            glitch.position = CGPoint(
                x: CGFloat.random(in: -screenSize.width * 0.3...screenSize.width * 0.3),
                y: CGFloat.random(in: -screenSize.height * 0.4...screenSize.height * 0.4)
            )
            addChild(glitch)

            // Random flicker
            let flickerDelay = Double.random(in: 0...1.0)
            glitch.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: flickerDelay),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.1...0.3), duration: 0.02),
                SKAction.wait(forDuration: 0.05),
                SKAction.fadeAlpha(to: 0, duration: 0.02),
                SKAction.wait(forDuration: Double.random(in: 0.2...0.8)),
            ])))
        }

        // VHS noise overlay
        let noiseAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in self?.addNoiseFlicker() },
            SKAction.wait(forDuration: 0.05),
        ]))
        run(noiseAction, withKey: "noise")
    }

    private func addNoiseFlicker() {
        guard !screenSize.equalTo(.zero) else { return }
        let noise = SKSpriteNode(color: .white, size: CGSize(
            width: CGFloat.random(in: 20...80),
            height: 1
        ))
        noise.alpha = CGFloat.random(in: 0.05...0.15)
        noise.position = CGPoint(
            x: CGFloat.random(in: -screenSize.width / 2...screenSize.width / 2),
            y: CGFloat.random(in: -screenSize.height / 2...screenSize.height / 2)
        )
        noise.zPosition = 4
        addChild(noise)
        noise.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.05),
            SKAction.removeFromParent()
        ]))
    }

    func update(progress: CGFloat) {
        // Intensify effects as progress goes from 0 to 1
        dimmer?.alpha = 0.15 + progress * 0.2
    }

    func hide() {
        removeAction(forKey: "noise")
        removeAllChildren()
        scanLines.removeAll()
        rewindLabel = nil
        dimmer = nil
        isHidden = true
    }
}
