import SpriteKit

class GhostPlaybackController {
    private(set) var activeGhosts: [GhostNode] = []

    /// Max ghosts in the orbit ring before upgrades kick in
    static let maxOrbitGhosts = 10

    func spawnGhost(from recording: GhostRecording, scene: SKScene) {
        guard !recording.snapshots.isEmpty else { return }

        if activeGhosts.count < Self.maxOrbitGhosts {
            // Room in the ring — add a new ghost
            let ghost = GhostNode(recording: recording, ghostIndex: activeGhosts.count)
            scene.addChild(ghost)
            activeGhosts.append(ghost)
            redistributeOrbits()
            spawnGhostEffect(at: ghost.position, scene: scene)
        } else {
            // Ring is full — upgrade the lowest-level ghost
            if let weakest = activeGhosts.min(by: { $0.ghostLevel < $1.ghostLevel }) {
                weakest.upgrade()
                spawnUpgradeEffect(at: weakest.position, level: weakest.ghostLevel, scene: scene)
            }
        }
    }

    private func redistributeOrbits() {
        let total = activeGhosts.count
        for (i, ghost) in activeGhosts.enumerated() {
            ghost.assignOrbitSlot(index: i, totalGhosts: total)
        }
    }

    func update(deltaTime: TimeInterval, scene: SKScene, gameState: GameState, enemies: [EnemyNode], combatSystem: CombatSystem, playerPosition: CGPoint) {
        for ghost in activeGhosts {
            ghost.update(deltaTime: deltaTime, scene: scene, gameState: gameState, enemies: enemies, combatSystem: combatSystem, playerPosition: playerPosition)
        }
    }

    func removeAll() {
        for ghost in activeGhosts {
            ghost.cleanup()
        }
        activeGhosts.removeAll()
    }

    var ghostTargetNodes: [SKNode] {
        return activeGhosts.map { $0 as SKNode }
    }

    // MARK: - Effects

    private func spawnGhostEffect(at position: CGPoint, scene: SKScene) {
        // Flash
        let flash = SKSpriteNode(color: .white, size: CGSize(width: 48, height: 48))
        flash.position = position
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.8
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 2.0, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: 5)
        ring.strokeColor = ColorPalette.ghostCyan
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.position = position
        ring.zPosition = 199
        ring.alpha = 0.6
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 8.0, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))

        // Particle burst
        let particleCount = 20
        for _ in 0..<particleCount {
            let p = SKSpriteNode(color: ColorPalette.ghostCyan, size: CGSize(width: 3, height: 3))
            p.position = position
            p.zPosition = 198
            p.blendMode = .add

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...120)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            scene.addChild(p)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: dx * 0.6, dy: dy * 0.6), duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6),
                    SKAction.scale(to: 0.2, duration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func spawnUpgradeEffect(at position: CGPoint, level: Int, scene: SKScene) {
        // Bright upward flash
        let color: SKColor = level >= 4
            ? SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
            : SKColor(red: 0.5, green: 0.95, blue: 1.0, alpha: 1)

        let flash = SKSpriteNode(color: color, size: CGSize(width: 40, height: 40))
        flash.position = position
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.9
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 2.5, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // Upward rising level text
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = "Lv\(level)!"
        label.fontSize = 14
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y + 20)
        label.zPosition = 201
        scene.addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 30, duration: 0.8),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))

        // Sparkle ring
        for _ in 0..<10 {
            let p = SKSpriteNode(color: color, size: CGSize(width: 3, height: 3))
            p.position = position
            p.zPosition = 199
            p.blendMode = .add

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 40...90)
            scene.addChild(p)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: cos(angle) * speed * 0.5, dy: sin(angle) * speed * 0.5 + 20), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.3, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
