import SpriteKit

class WaveManager {
    private(set) var activeEnemies: [EnemyNode] = []
    private(set) var isWaveInProgress: Bool = false
    private var spawnQueue: [(EnemyType, Int)] = []
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.5
    private var totalToSpawn: Int = 0
    private var totalSpawned: Int = 0

    var isWaveComplete: Bool {
        return isWaveInProgress && totalSpawned >= totalToSpawn && activeEnemies.isEmpty
    }

    var enemiesRemaining: Int {
        return max(0, totalToSpawn - totalSpawned) + activeEnemies.count
    }

    func beginWave(wave: Int, scene: SKScene, gameState: GameState, ghostCount: Int) {
        isWaveInProgress = true
        spawnQueue = EnemyType.composition(forWave: wave)
        totalToSpawn = spawnQueue.reduce(0) { $0 + $1.1 }
        totalSpawned = 0
        spawnTimer = 0

        // Faster spawning in later waves
        spawnInterval = max(0.15, 0.35 - Double(wave - 1) * 0.02)
    }

    func update(deltaTime: TimeInterval, scene: SKScene, gameState: GameState, ghostCount: Int, playerPosition: CGPoint) {
        guard isWaveInProgress else { return }

        // Spawn enemies
        if totalSpawned < totalToSpawn {
            spawnTimer += deltaTime
            if spawnTimer >= spawnInterval {
                spawnTimer = 0
                spawnNext(scene: scene, wave: gameState.currentWave, ghostCount: ghostCount, playerPosition: playerPosition)
            }
        }

        // Clean up dead enemies
        activeEnemies.removeAll { $0.parent == nil || $0.hp <= 0 }
    }

    private func spawnNext(scene: SKScene, wave: Int, ghostCount: Int, playerPosition: CGPoint) {
        guard !spawnQueue.isEmpty else { return }

        // Find next type to spawn
        var typeIndex = 0
        for (i, entry) in spawnQueue.enumerated() {
            if entry.1 > 0 {
                typeIndex = i
                break
            }
        }

        let type = spawnQueue[typeIndex].0
        spawnQueue[typeIndex].1 -= 1
        if spawnQueue[typeIndex].1 <= 0 {
            spawnQueue.remove(at: typeIndex)
        }

        // Spawn position: random edge of arena, at least minSpawnDistance from player
        let position = randomSpawnPosition(playerPosition: playerPosition)

        let enemy = EnemyNode(type: type, wave: wave, ghostCount: ghostCount)
        enemy.position = position
        scene.addChild(enemy)
        activeEnemies.append(enemy)
        totalSpawned += 1

        // Spawn animation
        enemy.alpha = 0
        enemy.setScale(0.5)
        enemy.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ]))
    }

    private func randomSpawnPosition(playerPosition: CGPoint) -> CGPoint {
        let margin = GameConfig.spawnMargin
        let halfArena = GameConfig.arenaSize.width / 2
        let minDist = GameConfig.minSpawnDistanceFromPlayer

        for _ in 0..<20 {
            // Pick random edge
            let edge = Int.random(in: 0...3)
            var x: CGFloat
            var y: CGFloat

            switch edge {
            case 0: // Top
                x = CGFloat.random(in: (-halfArena + margin)...(halfArena - margin))
                y = halfArena - margin
            case 1: // Bottom
                x = CGFloat.random(in: (-halfArena + margin)...(halfArena - margin))
                y = -halfArena + margin
            case 2: // Left
                x = -halfArena + margin
                y = CGFloat.random(in: (-halfArena + margin)...(halfArena - margin))
            default: // Right
                x = halfArena - margin
                y = CGFloat.random(in: (-halfArena + margin)...(halfArena - margin))
            }

            let dx = x - playerPosition.x
            let dy = y - playerPosition.y
            if sqrt(dx * dx + dy * dy) >= minDist {
                return CGPoint(x: x, y: y)
            }
        }

        // Fallback: random position far from player
        return CGPoint(
            x: playerPosition.x + (Bool.random() ? 1 : -1) * minDist,
            y: playerPosition.y + (Bool.random() ? 1 : -1) * minDist
        )
    }

    func enemyDied(_ enemy: EnemyNode) {
        activeEnemies.removeAll { $0 === enemy }
    }

    func freezeAll() {
        for enemy in activeEnemies {
            enemy.isFrozen = true
        }
    }

    func unfreezeAll() {
        for enemy in activeEnemies {
            enemy.isFrozen = false
        }
    }

    func removeAll() {
        for enemy in activeEnemies {
            enemy.removeFromParent()
        }
        activeEnemies.removeAll()
        spawnQueue.removeAll()
        isWaveInProgress = false
        totalSpawned = 0
        totalToSpawn = 0
    }

    func registerEnemy(_ enemy: EnemyNode) {
        activeEnemies.append(enemy)
    }

    // MARK: - Save/Resume Accessors

    var currentSpawnQueue: [(EnemyType, Int)] { spawnQueue }
    var currentTotalToSpawn: Int { totalToSpawn }
    var currentTotalSpawned: Int { totalSpawned }
    var currentSpawnTimer: TimeInterval { spawnTimer }
    var currentSpawnInterval: TimeInterval { spawnInterval }

    func restoreState(spawnQueue: [(EnemyType, Int)], totalToSpawn: Int, totalSpawned: Int,
                      spawnTimer: TimeInterval, spawnInterval: TimeInterval) {
        self.spawnQueue = spawnQueue
        self.totalToSpawn = totalToSpawn
        self.totalSpawned = totalSpawned
        self.spawnTimer = spawnTimer
        self.spawnInterval = spawnInterval
        self.isWaveInProgress = true
    }

    func spawnMinion(at position: CGPoint, scene: SKScene, wave: Int, ghostCount: Int) {
        let minion = EnemyNode(type: .shambler, wave: max(1, wave - 2), ghostCount: ghostCount)
        minion.position = position
        minion.contactDamage *= 0.5 // Minions deal half damage
        minion.setScale(0.7) // Minions are smaller
        // Recreate physics body to match scaled size (setScale doesn't affect physics)
        let scaledRadius = CGFloat(EnemyType.shambler.spriteSize) * 0.4 * 0.7
        let body = SKPhysicsBody(circleOfRadius: scaledRadius)
        body.categoryBitMask = PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.playerBullet | PhysicsCategory.ghostBullet | PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.enemy
        body.allowsRotation = false
        body.affectedByGravity = false
        body.linearDamping = 0
        body.friction = 0
        minion.physicsBody = body
        scene.addChild(minion)
        activeEnemies.append(minion)

        // Spawn effect
        minion.alpha = 0
        minion.run(SKAction.fadeIn(withDuration: 0.2))
    }
}
