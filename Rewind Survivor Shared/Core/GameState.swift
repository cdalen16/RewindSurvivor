import SpriteKit

enum GamePhase {
    case mainMenu
    case playing
    case waveComplete
    case powerUpSelect
    case deathRewind
    case gameOver
    case statsScreen
    case shopScreen
    case paused
    case tutorial
    case superPowerUpSelect
}

enum PowerUpType: String, CaseIterable {
    case attackSpeed
    case damage
    case multishot
    case piercing
    case moveSpeed
    case maxHP
    case ghostDamage
    case orbitalShield
    case magnetRange
    case chainLightning
    case lifeSteal
    case explosiveRounds
    case thorns
    case freezeAura
    case criticalStrike

    var maxStacks: Int {
        switch self {
        case .attackSpeed: return 5
        case .damage: return 5
        case .multishot: return 3
        case .piercing: return 3
        case .moveSpeed: return 4
        case .maxHP: return 5
        case .ghostDamage: return 3
        case .orbitalShield: return 3
        case .magnetRange: return 3
        case .chainLightning: return 3
        case .lifeSteal: return 3
        case .explosiveRounds: return 3
        case .thorns: return 3
        case .freezeAura: return 3
        case .criticalStrike: return 5
        }
    }

    var displayName: String {
        switch self {
        case .attackSpeed: return "Rapid Fire"
        case .damage: return "Power Shot"
        case .multishot: return "Multi Shot"
        case .piercing: return "Piercing"
        case .moveSpeed: return "Swift Boots"
        case .maxHP: return "Vitality"
        case .ghostDamage: return "Echo Power"
        case .orbitalShield: return "Orbital"
        case .magnetRange: return "Magnet"
        case .chainLightning: return "Chain Bolt"
        case .lifeSteal: return "Soul Siphon"
        case .explosiveRounds: return "Blast Shot"
        case .thorns: return "Retaliate"
        case .freezeAura: return "Frost Field"
        case .criticalStrike: return "Lethal Aim"
        }
    }

    var description: String {
        switch self {
        case .attackSpeed: return "Fire faster"
        case .damage: return "+25% damage"
        case .multishot: return "+1 projectile"
        case .piercing: return "Pierce +1 enemy"
        case .moveSpeed: return "Move faster"
        case .maxHP: return "+50 max HP"
        case .ghostDamage: return "Ghosts hit harder"
        case .orbitalShield: return "Orbiting projectile"
        case .magnetRange: return "Wider pickup range"
        case .chainLightning: return "Bolts chain to nearby foes"
        case .lifeSteal: return "Heal on damage dealt"
        case .explosiveRounds: return "Shots explode on hit"
        case .thorns: return "Damage melee attackers"
        case .freezeAura: return "Slow nearby enemies"
        case .criticalStrike: return "Chance for 2x damage"
        }
    }

    var iconColor: SKColor {
        switch self {
        case .attackSpeed: return ColorPalette.powerUpYellow
        case .damage: return ColorPalette.powerUpRed
        case .multishot: return ColorPalette.powerUpCyan
        case .piercing: return ColorPalette.powerUpGreen
        case .moveSpeed: return ColorPalette.powerUpBlue
        case .maxHP: return ColorPalette.powerUpPink
        case .ghostDamage: return ColorPalette.ghostCyan
        case .orbitalShield: return ColorPalette.powerUpPurple
        case .magnetRange: return ColorPalette.powerUpYellow
        case .chainLightning: return ColorPalette.powerUpCyan
        case .lifeSteal: return ColorPalette.powerUpPink
        case .explosiveRounds: return ColorPalette.powerUpRed
        case .thorns: return ColorPalette.powerUpPurple
        case .freezeAura: return ColorPalette.freezeAuraBlue
        case .criticalStrike: return ColorPalette.gold
        }
    }
}

class GameState {
    var score: Int = 0
    var currentWave: Int = 0
    var deathsRemaining: Int = GameConfig.initialDeaths
    var nextDeathThresholdIndex: Int = 0
    var gameTime: TimeInterval = 0
    var gamePhase: GamePhase = .mainMenu

    // Player stats (modified by power-ups)
    var playerSpeedMultiplier: CGFloat = 1.0
    var playerDamageMultiplier: CGFloat = 1.0
    var playerAttackSpeedMultiplier: CGFloat = 1.0
    var playerProjectileCountBonus: Int = 0
    var playerHPBonus: CGFloat = 0
    var playerProjectilePiercing: Int = 0
    var playerGhostDamageMultiplier: CGFloat = GameConfig.ghostDamageMultiplier
    var pickupMagnetRange: CGFloat = 50
    var orbitalCount: Int = 0
    var chainLightningBounces: Int = 0
    var lifeStealPercent: CGFloat = 0
    var explosionRadius: CGFloat = 0
    var thornsDamage: CGFloat = 0
    var freezeAuraRadius: CGFloat = 0
    var freezeAuraSlowPercent: CGFloat = 0
    var critChance: CGFloat = 0

    // Power-up tracking
    var acquiredPowerUps: [PowerUpType: Int] = [:]
    var acquiredSuperPowerUps: Set<SuperPowerUpType> = []

    // Run stats (for persistence)
    var coinsEarnedThisRun: Int = 0
    var killsThisRun: Int = 0

    @discardableResult
    func checkDeathThreshold() -> Bool {
        let threshold = GameConfig.deathThreshold(forIndex: nextDeathThresholdIndex)
        if score >= threshold {
            deathsRemaining += 1
            nextDeathThresholdIndex += 1
            return true
        }
        return false
    }

    var nextDeathThreshold: Int {
        return GameConfig.deathThreshold(forIndex: nextDeathThresholdIndex)
    }

    var deathThresholdProgress: CGFloat {
        let threshold = nextDeathThreshold
        let previousThreshold = nextDeathThresholdIndex > 0 ? GameConfig.deathThreshold(forIndex: nextDeathThresholdIndex - 1) : 0
        let range = threshold - previousThreshold
        guard range > 0 else { return 1.0 }
        return min(1.0, max(0.0, CGFloat(score - previousThreshold) / CGFloat(range)))
    }

    func reset() {
        score = 0
        currentWave = 0
        deathsRemaining = GameConfig.initialDeaths
        nextDeathThresholdIndex = 0
        gameTime = 0
        gamePhase = .mainMenu
        playerSpeedMultiplier = 1.0
        playerDamageMultiplier = 1.0
        playerAttackSpeedMultiplier = 1.0
        playerProjectileCountBonus = 0
        playerHPBonus = 0
        playerProjectilePiercing = 0
        playerGhostDamageMultiplier = GameConfig.ghostDamageMultiplier
        pickupMagnetRange = 50
        orbitalCount = 0
        chainLightningBounces = 0
        lifeStealPercent = 0
        explosionRadius = 0
        thornsDamage = 0
        freezeAuraRadius = 0
        freezeAuraSlowPercent = 0
        critChance = 0
        acquiredPowerUps.removeAll()
        acquiredSuperPowerUps.removeAll()
        coinsEarnedThisRun = 0
        killsThisRun = 0
    }
}
