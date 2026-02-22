import SpriteKit

struct GameConfig {
    // MARK: - Arena
    static let arenaSize = CGSize(width: 2000, height: 2000)

    // MARK: - Player
    static let playerBaseSpeed: CGFloat = 200
    static let playerBaseHP: CGFloat = 100
    static let playerBaseAttackInterval: TimeInterval = 0.4
    static let playerBaseDamage: CGFloat = 10
    static let playerBaseProjectileSpeed: CGFloat = 500
    static let playerInvincibilityDuration: TimeInterval = 1.5
    static let playerBaseAttackRange: CGFloat = 300

    // MARK: - Ghost Replay
    static let snapshotInterval: TimeInterval = 1.0 / 20.0
    static let maxSnapshots: Int = 200
    static let ghostAlpha: CGFloat = 0.55
    static let ghostDamageMultiplier: CGFloat = 0.7

    // MARK: - Scoring & Death Currency
    // Scaling formula: each threshold requires progressively more score
    // threshold(n) = 500 * 1.90^n, rounded to nearest 500
    static let deathThresholdBase: Double = 500
    static let deathThresholdGrowth: Double = 1.90

    static func deathThreshold(forIndex n: Int) -> Int {
        let raw = deathThresholdBase * pow(deathThresholdGrowth, Double(n))
        // Round to nearest 500 for clean display
        return Int((raw / 500.0).rounded()) * 500
    }

    static let initialDeaths: Int = 0
    static let pointsPerKillPerWave: Int = 2

    // MARK: - Waves
    static let baseEnemiesPerWave: Int = 8
    static let enemiesPerWaveGrowth: Double = 1.35
    static let maxEnemiesPerWave: Int = 80
    static let enemyHPScalePerWave: Double = 1.12
    static let enemyHPScalePerGhost: CGFloat = 0.12
    static let enemyDamageScalePerGhost: CGFloat = 0.08
    static let enemySpeedScalePerWave: CGFloat = 0.02
    static let enemyMaxSpeedMultiplier: CGFloat = 2.0

    // MARK: - Visual
    static let rewindEffectDuration: TimeInterval = 1.5
    static let screenShakeMagnitude: CGFloat = 8.0
    static let damageNumberDuration: TimeInterval = 0.8

    // MARK: - Spawn
    static let spawnMargin: CGFloat = 100
    static let minSpawnDistanceFromPlayer: CGFloat = 300
}
