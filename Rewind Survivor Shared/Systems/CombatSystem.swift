import SpriteKit

class CombatSystem {
    private(set) var currentTarget: EnemyNode?
    private var playerAttackTimer: TimeInterval = 0
    private var targetTimer: TimeInterval = 0
    private let targetUpdateInterval: TimeInterval = 0.15

    // Orbitals
    private var orbitalNodes: [SKSpriteNode] = []
    private var orbitalAngle: CGFloat = 0
    private let orbitalRadius: CGFloat = 55
    private let orbitalSpeed: CGFloat = 3.0
    private let orbitalDamage: CGFloat = 15
    private var orbitalHitCooldowns: [ObjectIdentifier: TimeInterval] = [:]

    func update(deltaTime: TimeInterval,
                player: PlayerNode,
                enemies: [EnemyNode],
                scene: SKScene,
                gameState: GameState) {

        // Target acquisition (throttled)
        targetTimer += deltaTime
        if targetTimer >= targetUpdateInterval || currentTarget?.parent == nil || currentTarget?.hp ?? 0 <= 0 {
            targetTimer = 0
            currentTarget = findNearestEnemy(to: player.position, enemies: enemies, range: GameConfig.playerBaseAttackRange)
        }

        // Player auto-fire
        playerAttackTimer += deltaTime
        let effectiveInterval = GameConfig.playerBaseAttackInterval / gameState.playerAttackSpeedMultiplier
        if playerAttackTimer >= effectiveInterval, let target = currentTarget, target.parent != nil {
            playerAttackTimer = 0
            firePlayerProjectile(from: player, toward: target, scene: scene, gameState: gameState)
        }

        // Orbital shields
        updateOrbitals(deltaTime: deltaTime, player: player, enemies: enemies, scene: scene, gameState: gameState)
    }

    // Track orbital kills for GameScene to process
    struct OrbitalKill {
        let enemy: EnemyNode
        let position: CGPoint
    }
    var pendingOrbitalKills: [OrbitalKill] = []
    var pendingOrbitalHits: [(CGPoint, CGFloat)] = [] // (position, damage) for damage numbers

    private func updateOrbitals(deltaTime: TimeInterval, player: PlayerNode, enemies: [EnemyNode], scene: SKScene, gameState: GameState) {
        let count = gameState.orbitalCount
        pendingOrbitalKills.removeAll()
        pendingOrbitalHits.removeAll()

        // Spawn/remove orbital nodes to match count
        while orbitalNodes.count < count {
            let orb = SKSpriteNode(texture: SpriteFactory.shared.projectileTexture(isGhost: false),
                                    size: CGSize(width: 14, height: 14))
            orb.blendMode = .add
            orb.zPosition = 100
            orb.name = "orbital"
            // Add circular glow
            let glow = SKShapeNode(circleOfRadius: 10)
            glow.fillColor = ColorPalette.playerPrimary.withAlphaComponent(0.2)
            glow.strokeColor = ColorPalette.playerPrimary.withAlphaComponent(0.4)
            glow.lineWidth = 1
            glow.blendMode = .add
            glow.name = "orbGlow"
            orb.addChild(glow)
            scene.addChild(orb)
            orbitalNodes.append(orb)
        }
        while orbitalNodes.count > count {
            let removed = orbitalNodes.removeLast()
            removed.removeFromParent()
        }

        guard count > 0 else { return }

        // Rotate orbitals
        orbitalAngle += orbitalSpeed * CGFloat(deltaTime)

        // Decay hit cooldowns
        for key in orbitalHitCooldowns.keys {
            orbitalHitCooldowns[key]! -= deltaTime
            if orbitalHitCooldowns[key]! <= 0 {
                orbitalHitCooldowns.removeValue(forKey: key)
            }
        }

        // Position each orbital evenly spaced
        let angleStep = (CGFloat.pi * 2) / CGFloat(count)
        for (i, orb) in orbitalNodes.enumerated() {
            let angle = orbitalAngle + angleStep * CGFloat(i)
            orb.position = CGPoint(
                x: player.position.x + cos(angle) * orbitalRadius,
                y: player.position.y + sin(angle) * orbitalRadius
            )

            // Check collision with enemies
            for enemy in enemies {
                guard enemy.parent != nil && enemy.hp > 0 else { continue }
                let id = ObjectIdentifier(enemy)
                guard orbitalHitCooldowns[id] == nil else { continue }

                let dx = orb.position.x - enemy.position.x
                let dy = orb.position.y - enemy.position.y
                let dist = sqrt(dx * dx + dy * dy)
                let hitRadius: CGFloat = 20 + CGFloat(enemy.enemyType.spriteSize) * 0.3

                if dist < hitRadius {
                    let damage = orbitalDamage * gameState.playerDamageMultiplier
                    let killed = enemy.takeDamage(damage)
                    orbitalHitCooldowns[id] = 0.5

                    if killed {
                        pendingOrbitalKills.append(OrbitalKill(enemy: enemy, position: enemy.position))
                    } else {
                        pendingOrbitalHits.append((enemy.position, damage))
                    }

                    // Hit flash on orbital
                    orb.run(SKAction.sequence([
                        SKAction.scale(to: 1.5, duration: 0.05),
                        SKAction.scale(to: 1.0, duration: 0.05)
                    ]), withKey: "orbHit")
                }
            }
        }
    }

    func findNearestEnemy(to point: CGPoint, enemies: [EnemyNode], range: CGFloat = .greatestFiniteMagnitude) -> EnemyNode? {
        var closest: EnemyNode?
        var closestDistSq: CGFloat = range * range
        for enemy in enemies {
            guard enemy.parent != nil && enemy.hp > 0 else { continue }
            let dx = enemy.position.x - point.x
            let dy = enemy.position.y - point.y
            let distSq = dx * dx + dy * dy
            if distSq < closestDistSq {
                closestDistSq = distSq
                closest = enemy
            }
        }
        return closest
    }

    private func firePlayerProjectile(from player: PlayerNode,
                                       toward target: EnemyNode,
                                       scene: SKScene,
                                       gameState: GameState) {
        let direction = CGVector(
            dx: target.position.x - player.position.x,
            dy: target.position.y - player.position.y
        ).normalized()

        let baseCount = 1 + gameState.playerProjectileCountBonus
        var damage = GameConfig.playerBaseDamage * gameState.playerDamageMultiplier
        let speed = GameConfig.playerBaseProjectileSpeed

        // Critical strike roll
        var isCrit = false
        if gameState.critChance > 0 && CGFloat.random(in: 0...1) < gameState.critChance {
            damage *= 2.0
            isCrit = true
        }

        for i in 0..<baseCount {
            let spread = spreadAngle(index: i, total: baseCount)
            let rotated = direction.rotated(by: spread)

            let projectile = ProjectileNode(
                damage: damage,
                velocity: CGVector(dx: rotated.dx * speed, dy: rotated.dy * speed),
                piercing: gameState.playerProjectilePiercing,
                type: .player
            )
            projectile.isCrit = isCrit
            projectile.position = player.position
            scene.addChild(projectile)
        }
    }

    func fireGhostProjectile(from position: CGPoint,
                              toward target: EnemyNode,
                              scene: SKScene,
                              gameState: GameState) {
        let direction = CGVector(
            dx: target.position.x - position.x,
            dy: target.position.y - position.y
        ).normalized()

        let damage = GameConfig.playerBaseDamage * gameState.playerDamageMultiplier * gameState.playerGhostDamageMultiplier
        let speed = GameConfig.playerBaseProjectileSpeed

        let baseCount = 1 + gameState.playerProjectileCountBonus

        for i in 0..<baseCount {
            let spread = spreadAngle(index: i, total: baseCount)
            let rotated = direction.rotated(by: spread)

            let projectile = ProjectileNode(
                damage: damage,
                velocity: CGVector(dx: rotated.dx * speed, dy: rotated.dy * speed),
                piercing: gameState.playerProjectilePiercing,
                type: .ghost
            )
            projectile.position = position
            scene.addChild(projectile)
        }
    }

    private func spreadAngle(index: Int, total: Int) -> CGFloat {
        guard total > 1 else { return 0 }
        let totalSpread: CGFloat = .pi / 8
        let step = totalSpread / CGFloat(total - 1)
        return -totalSpread / 2 + step * CGFloat(index)
    }

    func reset() {
        currentTarget = nil
        playerAttackTimer = 0
        targetTimer = 0
        for orb in orbitalNodes { orb.removeFromParent() }
        orbitalNodes.removeAll()
        orbitalHitCooldowns.removeAll()
        orbitalAngle = 0
    }
}
