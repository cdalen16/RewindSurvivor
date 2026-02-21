import SpriteKit

class PowerUpManager {

    func apply(_ type: PowerUpType, to gameState: GameState, player: PlayerNode) {
        let currentStacks = gameState.acquiredPowerUps[type, default: 0]
        guard currentStacks < type.maxStacks else { return }
        gameState.acquiredPowerUps[type] = currentStacks + 1

        switch type {
        case .attackSpeed:
            gameState.playerAttackSpeedMultiplier *= 1.20

        case .damage:
            gameState.playerDamageMultiplier += 0.25

        case .multishot:
            gameState.playerProjectileCountBonus += 1

        case .piercing:
            gameState.playerProjectilePiercing += 1

        case .moveSpeed:
            gameState.playerSpeedMultiplier += 0.15

        case .maxHP:
            gameState.playerHPBonus += 25
            player.maxHP = GameConfig.playerBaseHP + gameState.playerHPBonus
            player.heal(25)

        case .ghostDamage:
            gameState.playerGhostDamageMultiplier += 0.15

        case .orbitalShield:
            gameState.orbitalCount += 1

        case .magnetRange:
            gameState.pickupMagnetRange += 50

        case .chainLightning:
            gameState.chainLightningBounces += 1

        case .lifeSteal:
            gameState.lifeStealPercent += 0.05

        case .explosiveRounds:
            gameState.explosionRadius = gameState.explosionRadius == 0 ? 40 : gameState.explosionRadius + 15

        case .thorns:
            gameState.thornsDamage += 15

        case .freezeAura:
            gameState.freezeAuraRadius = gameState.freezeAuraRadius == 0 ? 80 : gameState.freezeAuraRadius + 40
            gameState.freezeAuraSlowPercent = gameState.freezeAuraSlowPercent == 0 ? 0.30 : min(gameState.freezeAuraSlowPercent + 0.15, 0.60)

        case .criticalStrike:
            gameState.critChance += 0.10
        }
    }

    func generateChoices(count: Int, gameState: GameState) -> [PowerUpType] {
        let available = PowerUpType.allCases.filter { type in
            (gameState.acquiredPowerUps[type, default: 0]) < type.maxStacks
        }

        guard !available.isEmpty else {
            return Array(PowerUpType.allCases.prefix(count))
        }

        var choices: [PowerUpType] = []
        var pool = available

        for _ in 0..<min(count, pool.count) {
            let weights = pool.map { weightFor($0, gameState: gameState) }
            let totalWeight = weights.reduce(0, +)
            guard totalWeight > 0 else { break }

            var roll = Double.random(in: 0..<totalWeight)
            for (i, w) in weights.enumerated() {
                roll -= w
                if roll <= 0 {
                    choices.append(pool.remove(at: i))
                    break
                }
            }
        }

        return choices
    }

    private func weightFor(_ type: PowerUpType, gameState: GameState) -> Double {
        let stacks = gameState.acquiredPowerUps[type, default: 0]
        let baseWeight: Double = 1.0
        let stackPenalty = 1.0 - Double(stacks) * 0.15
        return max(baseWeight * stackPenalty, 0.2)
    }
}
