import SpriteKit

class GhostNode: SKSpriteNode {
    let recording: GhostRecording
    private var playbackTime: TimeInterval = 0
    private var currentSnapshotIndex: Int = 0
    private var attackTimer: TimeInterval = 0
    let ghostIndex: Int
    var facingDirection: CGVector = CGVector(dx: 0, dy: -1)

    // Ghost level (upgrades after orbit ring is full)
    private(set) var ghostLevel: Int = 1

    // Leash: ghost stays near the player
    private let maxLeashDistance: CGFloat = 180
    private let followSpeed: CGFloat = 250

    // Trail effect
    private var trailNodes: [SKSpriteNode] = []
    private var trailUpdateTimer: TimeInterval = 0
    private let trailUpdateInterval: TimeInterval = 0.08
    private let maxTrailNodes: Int = 5

    // Orbit offset based on ghost index (so multiple ghosts spread out)
    private var orbitAngle: CGFloat = 0
    private var orbitRadius: CGFloat = 90
    private let orbitSpeed: CGFloat = 1.2

    /// Damage multiplier from ghost level: +35% per level beyond 1
    var levelDamageMultiplier: CGFloat {
        return 1.0 + 0.35 * CGFloat(ghostLevel - 1)
    }

    init(recording: GhostRecording, ghostIndex: Int) {
        self.recording = recording
        self.ghostIndex = ghostIndex
        self.orbitAngle = 0 // Will be set by redistributeOrbits

        let texture = SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: 0)
        super.init(texture: texture, color: .clear, size: CGSize(width: 32, height: 32))

        self.name = "ghost"
        self.zPosition = 95
        self.alpha = GameConfig.ghostAlpha

        // Ghost glow effect
        let glow = SKSpriteNode(texture: texture, size: CGSize(width: 48, height: 48))
        glow.alpha = 0.25
        glow.blendMode = .add
        glow.color = ColorPalette.ghostCyan
        glow.colorBlendFactor = 0.5
        glow.name = "glow"
        addChild(glow)

        // Level label (hidden at level 1)
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.name = "levelLabel"
        label.fontSize = 9
        label.fontColor = ColorPalette.ghostCyan
        label.verticalAlignmentMode = .bottom
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 18)
        label.zPosition = 2
        label.isHidden = true
        addChild(label)

        // Minimal physics — only collides with walls/obstacles, invisible to enemies
        // No physics body — ghosts pass through everything.
        // Obstacle overlap is handled manually in update() via pushOutOfObstacles().

        // Set initial position
        if let first = recording.snapshots.first {
            self.position = first.position
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Upgrade

    func upgrade() {
        ghostLevel += 1
        updateLevelVisuals()

        // Upgrade flash effect
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
        ])
        run(flash, withKey: "upgradeFlash")

        // Scale pop
        run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]), withKey: "upgradePop")
    }

    private func updateLevelVisuals() {
        // Update glow — bigger and brighter per level
        if let glow = childNode(withName: "glow") as? SKSpriteNode {
            let glowScale: CGFloat = 48 + CGFloat(ghostLevel - 1) * 8
            glow.size = CGSize(width: glowScale, height: glowScale)
            glow.alpha = min(0.25 + CGFloat(ghostLevel - 1) * 0.1, 0.65)

            // Shift color from cyan toward white/gold at higher levels
            if ghostLevel >= 4 {
                glow.color = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1)
            } else if ghostLevel >= 2 {
                glow.color = SKColor(red: 0.5, green: 0.9, blue: 1.0, alpha: 1)
            }
        }

        // Update level label
        if let label = childNode(withName: "levelLabel") as? SKLabelNode {
            if ghostLevel >= 2 {
                label.isHidden = false
                label.text = "Lv\(ghostLevel)"
                if ghostLevel >= 4 {
                    label.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
                } else {
                    label.fontColor = SKColor(red: 0.5, green: 0.95, blue: 1.0, alpha: 1)
                }
            }
        }

        // Ghost itself gets slightly brighter at higher levels
        alpha = min(GameConfig.ghostAlpha + CGFloat(ghostLevel - 1) * 0.08, 0.9)
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, scene: SKScene, gameState: GameState, enemies: [EnemyNode], combatSystem: CombatSystem, playerPosition: CGPoint) {
        guard !recording.snapshots.isEmpty else { return }
        guard recording.duration > 0 else { return }

        playbackTime += deltaTime

        // Loop the recording
        if playbackTime >= recording.duration {
            playbackTime = playbackTime.truncatingRemainder(dividingBy: max(0.01, recording.duration))
            currentSnapshotIndex = 0
        }

        // Advance to correct snapshot
        while currentSnapshotIndex < recording.snapshots.count - 1 &&
              recording.snapshots[currentSnapshotIndex + 1].timestamp <= playbackTime {
            currentSnapshotIndex += 1
        }

        let snap = recording.snapshots[currentSnapshotIndex]

        // Orbit around the player
        orbitAngle += orbitSpeed * CGFloat(deltaTime)
        let targetX = playerPosition.x + cos(orbitAngle) * orbitRadius
        let targetY = playerPosition.y + sin(orbitAngle) * orbitRadius

        // Smoothly move toward orbit point
        let dx = targetX - position.x
        let dy = targetY - position.y
        let dist = sqrt(dx * dx + dy * dy)

        if dist > 2 {
            let speed = dist > maxLeashDistance ? followSpeed * 3 : followSpeed
            let move = min(speed * CGFloat(deltaTime), dist)
            position.x += (dx / dist) * move
            position.y += (dy / dist) * move
        }

        self.facingDirection = snap.facingDirection

        // Update animation
        let frame = Int(playbackTime * 4) % 2
        self.texture = SpriteFactory.shared.ghostPlayerTexture(facing: .down, frame: frame)

        // Ghost firing: auto-target nearest enemy when the recording shows isFiring
        if snap.isFiring {
            attackTimer += deltaTime
            let effectiveInterval = GameConfig.playerBaseAttackInterval / gameState.playerAttackSpeedMultiplier
            if attackTimer >= effectiveInterval {
                attackTimer = 0
                if let target = combatSystem.findNearestEnemy(to: position, enemies: enemies) {
                    combatSystem.fireGhostProjectile(from: position, toward: target, scene: scene, gameState: gameState, levelMultiplier: levelDamageMultiplier)
                }
            }
        }

        // Update trail
        trailUpdateTimer += deltaTime
        if trailUpdateTimer >= trailUpdateInterval {
            trailUpdateTimer = 0
            updateTrail(scene: scene)
        }
    }

    private func updateTrail(scene: SKScene) {
        let trail = SKSpriteNode(texture: self.texture, size: CGSize(width: 32, height: 32))
        trail.position = self.position
        trail.alpha = 0.15
        trail.zPosition = self.zPosition - 1
        trail.blendMode = .add
        trail.color = ColorPalette.ghostCyan
        trail.colorBlendFactor = 0.7
        scene.addChild(trail)
        trailNodes.append(trail)

        trail.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        trailNodes.removeAll { $0.parent == nil }
        while trailNodes.count > maxTrailNodes {
            let oldest = trailNodes.removeFirst()
            oldest.removeFromParent()
        }
    }

    /// Reassign orbit parameters so ghosts are evenly spaced
    func assignOrbitSlot(index: Int, totalGhosts: Int) {
        let sliceAngle = (.pi * 2) / CGFloat(max(totalGhosts, 1))
        orbitAngle = sliceAngle * CGFloat(index)
        // Alternate radius so ghosts on opposite sides don't overlap — pushed out to clear frost aura
        orbitRadius = 120 + CGFloat(index % 2) * 30
    }

    func cleanup() {
        for trail in trailNodes {
            trail.removeFromParent()
        }
        trailNodes.removeAll()
        removeFromParent()
    }
}
