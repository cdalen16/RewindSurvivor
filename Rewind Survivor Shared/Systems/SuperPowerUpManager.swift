import SpriteKit

class SuperPowerUpManager {
    // Active effect tracking
    private var chronoShiftActive: Bool = false
    private var radiationFieldNode: RadiationFieldNode?
    private var shockwavePulseNode: ShockwavePulseNode?
    private var voidBarrierNode: VoidBarrierNode?

    /// Whether to show super selection after this wave
    func shouldShowSuperSelection(wave: Int, deathsAvailable: Int, acquired: Set<SuperPowerUpType>) -> Bool {
        guard wave >= 15, deathsAvailable >= 1 else { return false }
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
        guard gameState.deathsRemaining >= type.deathCost else { return }
        gameState.deathsRemaining -= type.deathCost
        gameState.acquiredSuperPowerUps.insert(type)

        switch type {
        case .chronoShift:
            applyChronoShift(enemies: enemies)

        case .radiationField:
            applyRadiationField(scene: scene, player: player)

        case .shockwavePulse:
            applyShockwavePulse(scene: scene, player: player)

        case .voidBarrier:
            applyVoidBarrier(scene: scene, player: player)
        }
    }

    private func applyChronoShift(enemies: [EnemyNode]) {
        chronoShiftActive = true
        for enemy in enemies {
            enemy.applyChronoSlow()
        }
    }

    private func applyRadiationField(scene: SKScene, player: PlayerNode) {
        let field = RadiationFieldNode()
        field.position = player.position
        scene.addChild(field)
        radiationFieldNode = field
    }

    private func applyShockwavePulse(scene: SKScene, player: PlayerNode) {
        let pulse = ShockwavePulseNode()
        pulse.position = player.position
        scene.addChild(pulse)
        shockwavePulseNode = pulse
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
        // Chrono Shift — permanently slow all enemies
        if chronoShiftActive {
            for enemy in enemies {
                if !enemy.isChronoSlowed {
                    enemy.applyChronoSlow()
                }
            }
        }

        // Radiation Field
        if let field = radiationFieldNode {
            if field.parent == nil {
                radiationFieldNode = nil
            } else {
                field.update(deltaTime: deltaTime, playerPosition: player.position,
                           enemies: enemies, scene: scene)
            }
        }

        // Shockwave Pulse
        if let pulse = shockwavePulseNode {
            if pulse.parent == nil {
                shockwavePulseNode = nil
            } else {
                pulse.update(deltaTime: deltaTime, playerPosition: player.position,
                           enemies: enemies, scene: scene)
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
        radiationFieldNode?.removeFromParent()
        radiationFieldNode = nil
        shockwavePulseNode?.removeFromParent()
        shockwavePulseNode = nil
        voidBarrierNode?.removeFromParent()
        voidBarrierNode = nil
    }

    /// Respawn persistent super power-ups (for save/resume)
    func respawnSuperPowerUps(acquired: Set<SuperPowerUpType>, scene: SKScene, player: PlayerNode, enemies: [EnemyNode]) {
        for type in acquired {
            switch type {
            case .chronoShift:
                chronoShiftActive = true
                for enemy in enemies {
                    enemy.applyChronoSlow()
                }
            case .radiationField:
                let field = RadiationFieldNode()
                field.position = player.position
                scene.addChild(field)
                radiationFieldNode = field
            case .shockwavePulse:
                let pulse = ShockwavePulseNode()
                pulse.position = player.position
                scene.addChild(pulse)
                shockwavePulseNode = pulse
            case .voidBarrier:
                let barrier = VoidBarrierNode(duration: SuperPowerUpType.voidBarrier.duration)
                barrier.position = player.position
                scene.addChild(barrier)
                voidBarrierNode = barrier
            }
        }
    }
}
