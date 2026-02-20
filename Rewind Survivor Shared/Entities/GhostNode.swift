import SpriteKit

class GhostNode: SKSpriteNode {
    let recording: GhostRecording
    private var playbackTime: TimeInterval = 0
    private var currentSnapshotIndex: Int = 0
    private var attackTimer: TimeInterval = 0
    let ghostIndex: Int
    var facingDirection: CGVector = CGVector(dx: 0, dy: -1)

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
    private let orbitRadius: CGFloat = 90
    private let orbitSpeed: CGFloat = 1.2

    init(recording: GhostRecording, ghostIndex: Int) {
        self.recording = recording
        self.ghostIndex = ghostIndex
        self.orbitAngle = CGFloat(ghostIndex) * (.pi * 2 / 8) // Spread evenly

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

        // Physics (ghosts don't collide with anything, just visual)
        let body = SKPhysicsBody(circleOfRadius: 12)
        body.categoryBitMask = PhysicsCategory.ghost
        body.contactTestBitMask = PhysicsCategory.none
        body.collisionBitMask = PhysicsCategory.none
        body.allowsRotation = false
        body.affectedByGravity = false
        self.physicsBody = body

        // Set initial position
        if let first = recording.snapshots.first {
            self.position = first.position
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
                    combatSystem.fireGhostProjectile(from: position, toward: target, scene: scene, gameState: gameState)
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

    func cleanup() {
        for trail in trailNodes {
            trail.removeFromParent()
        }
        trailNodes.removeAll()
        removeFromParent()
    }
}
