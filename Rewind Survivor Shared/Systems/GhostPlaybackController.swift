import SpriteKit

class GhostPlaybackController {
    private(set) var activeGhosts: [GhostNode] = []

    func spawnGhost(from recording: GhostRecording, scene: SKScene) {
        guard !recording.snapshots.isEmpty else { return }

        // Remove oldest ghost if at cap
        if activeGhosts.count >= GameConfig.maxActiveGhosts {
            let oldest = activeGhosts.removeFirst()
            oldest.cleanup()
        }

        let ghost = GhostNode(recording: recording, ghostIndex: activeGhosts.count)
        scene.addChild(ghost)
        activeGhosts.append(ghost)

        // Spawn effect
        spawnGhostEffect(at: ghost.position, scene: scene)
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
}
