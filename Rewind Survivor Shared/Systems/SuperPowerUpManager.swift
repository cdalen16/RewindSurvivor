import SpriteKit

class SuperPowerUpManager {
    // Active effect tracking
    private var chronoShiftTimer: TimeInterval = 0
    private var chronoShiftActive: Bool = false
    private var singularityNode: GravitySingularityNode?
    private var voidBarrierNode: VoidBarrierNode?
    private(set) var shadowCloneNode: ShadowCloneNode?

    /// Whether to show super selection after this wave
    func shouldShowSuperSelection(wave: Int, deathsAvailable: Int, acquired: Set<SuperPowerUpType>) -> Bool {
        guard wave >= 15 && (wave - 15) % 5 == 0 else { return false }
        let available = generateChoices(deathsAvailable: deathsAvailable, acquired: acquired)
        return !available.isEmpty
    }

    /// Available supers the player can see (includes unaffordable for display)
    func generateChoices(deathsAvailable: Int, acquired: Set<SuperPowerUpType>) -> [SuperPowerUpType] {
        return SuperPowerUpType.allCases.filter { !acquired.contains($0) }
    }

    /// Whether the player can afford at least one available super
    func canAffordAny(deathsAvailable: Int, acquired: Set<SuperPowerUpType>) -> Bool {
        let available = generateChoices(deathsAvailable: deathsAvailable, acquired: acquired)
        return available.contains { $0.deathCost <= deathsAvailable }
    }

    // MARK: - Apply Effects

    func apply(_ type: SuperPowerUpType, gameState: GameState, scene: SKScene, player: PlayerNode, enemies: [EnemyNode], combatSystem: CombatSystem) {
        gameState.deathsRemaining -= type.deathCost
        gameState.acquiredSuperPowerUps.insert(type)

        switch type {
        case .chronoShift:
            applyChronoShift(enemies: enemies)

        case .quantumNuke:
            applyQuantumNuke(scene: scene, enemies: enemies)

        case .shadowClone:
            applyShadowClone(scene: scene, player: player)

        case .gravitySingularity:
            applyGravitySingularity(scene: scene, player: player)

        case .voidBarrier:
            applyVoidBarrier(scene: scene, player: player)
        }
    }

    private func applyChronoShift(enemies: [EnemyNode]) {
        chronoShiftActive = true
        chronoShiftTimer = SuperPowerUpType.chronoShift.duration
        for enemy in enemies {
            enemy.applyChronoSlow()
        }
    }

    private func applyQuantumNuke(scene: SKScene, enemies: [EnemyNode]) {
        let damage: CGFloat = 150
        for enemy in enemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            enemy.takeDamage(damage)
        }

        // White flash
        let flash = SKSpriteNode(color: .white, size: scene.size)
        flash.position = scene.camera?.position ?? .zero
        flash.zPosition = 500
        flash.blendMode = .add
        flash.alpha = 0.9
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))

        // Shockwave ring from center
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = .white
        ring.fillColor = .clear
        ring.lineWidth = 4
        ring.position = scene.camera?.position ?? .zero
        ring.zPosition = 499
        ring.blendMode = .add
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 40.0, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func applyShadowClone(scene: SKScene, player: PlayerNode) {
        let clone = ShadowCloneNode()
        clone.position = CGPoint(x: player.position.x + 80, y: player.position.y)
        scene.addChild(clone)
        shadowCloneNode = clone

        // Spawn VFX
        let flash = SKSpriteNode(color: ColorPalette.superShadowClone, size: CGSize(width: 40, height: 40))
        flash.position = clone.position
        flash.zPosition = 200
        flash.blendMode = .add
        flash.alpha = 0.8
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 3.0, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func applyGravitySingularity(scene: SKScene, player: PlayerNode) {
        let singularity = GravitySingularityNode(duration: SuperPowerUpType.gravitySingularity.duration)
        singularity.position = player.position
        scene.addChild(singularity)
        singularityNode = singularity
    }

    private func applyVoidBarrier(scene: SKScene, player: PlayerNode) {
        let barrier = VoidBarrierNode(duration: SuperPowerUpType.voidBarrier.duration)
        barrier.position = player.position
        scene.addChild(barrier)
        voidBarrierNode = barrier
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval, scene: SKScene, enemies: [EnemyNode], player: PlayerNode,
                gameState: GameState, combatSystem: CombatSystem) {
        // Chrono Shift
        if chronoShiftActive {
            chronoShiftTimer -= deltaTime
            // Apply slow to newly spawned enemies too
            for enemy in enemies {
                if !enemy.isChronoSlowed {
                    enemy.applyChronoSlow()
                }
            }
            if chronoShiftTimer <= 0 {
                chronoShiftActive = false
                for enemy in enemies {
                    enemy.removeChronoSlow()
                }
            }
        }

        // Shadow Clone
        if let clone = shadowCloneNode {
            if clone.parent == nil {
                shadowCloneNode = nil
            } else {
                clone.update(deltaTime: deltaTime, playerPosition: player.position,
                           enemies: enemies, combatSystem: combatSystem, scene: scene, gameState: gameState)
            }
        }

        // Gravity Singularity
        if let singularity = singularityNode {
            if singularity.parent == nil {
                singularityNode = nil
            } else {
                let expired = singularity.update(deltaTime: deltaTime, enemies: enemies, gameState: gameState)
                if expired { singularityNode = nil }
            }
        }

        // Void Barrier
        if let barrier = voidBarrierNode {
            if barrier.parent == nil {
                voidBarrierNode = nil
            } else {
                let expired = barrier.update(deltaTime: deltaTime, playerPosition: player.position, scene: scene)
                if expired { voidBarrierNode = nil }
            }
        }
    }

    // MARK: - Cleanup

    func reset() {
        chronoShiftActive = false
        chronoShiftTimer = 0
        singularityNode?.removeFromParent()
        singularityNode = nil
        voidBarrierNode?.removeFromParent()
        voidBarrierNode = nil
        shadowCloneNode?.removeFromParent()
        shadowCloneNode = nil
    }

    func removeAllEffects() {
        reset()
    }

    /// Respawn shadow clone (for save/resume)
    func respawnShadowClone(scene: SKScene, player: PlayerNode) {
        let clone = ShadowCloneNode()
        clone.position = CGPoint(x: player.position.x + 80, y: player.position.y)
        scene.addChild(clone)
        shadowCloneNode = clone
    }
}
