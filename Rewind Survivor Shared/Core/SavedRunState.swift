import Foundation

struct CodablePoint: Codable {
    var x: Double
    var y: Double
}

struct CodableVector: Codable {
    var dx: Double
    var dy: Double
}

struct SavedEnemy: Codable {
    var typeName: String
    var position: CodablePoint
    var hp: Double
    var maxHP: Double
    var splitGeneration: Int
    var scale: Double
}

struct SavedSnapshot: Codable {
    var position: CodablePoint
    var facingDirection: CodableVector
    var isFiring: Bool
    var timestamp: Double
}

struct SavedGhostRecording: Codable {
    var snapshots: [SavedSnapshot]
    var ghostLevel: Int
}

struct SavedSpawnEntry: Codable {
    var typeName: String
    var count: Int
}

struct SavedRunState: Codable {
    // GameState
    var score: Int
    var currentWave: Int
    var deathsRemaining: Int
    var nextDeathThresholdIndex: Int
    var gameTime: Double

    // Player stats (power-up multipliers)
    var playerSpeedMultiplier: Double
    var playerDamageMultiplier: Double
    var playerAttackSpeedMultiplier: Double
    var playerProjectileCountBonus: Int
    var playerHPBonus: Double
    var playerProjectilePiercing: Int
    var playerGhostDamageMultiplier: Double
    var pickupMagnetRange: Double
    var orbitalCount: Int
    var chainLightningBounces: Int
    var lifeStealPercent: Double
    var explosionRadius: Double
    var thornsDamage: Double
    var freezeAuraRadius: Double
    var freezeAuraSlowPercent: Double
    var critChance: Double

    // Power-ups acquired
    var acquiredPowerUps: [String: Int]
    var acquiredSuperPowerUps: [String]

    // Run stats
    var coinsEarnedThisRun: Int
    var killsThisRun: Int

    // Player
    var playerPosition: CodablePoint
    var playerHP: Double
    var playerMaxHP: Double

    // Enemies
    var enemies: [SavedEnemy]

    // Ghosts
    var ghosts: [SavedGhostRecording]

    // WaveManager
    var spawnQueue: [SavedSpawnEntry]
    var totalToSpawn: Int
    var totalSpawned: Int
    var spawnTimer: Double
    var spawnInterval: Double

    // CombatSystem
    var attackTimer: Double
    var orbitalAngle: Double
}
