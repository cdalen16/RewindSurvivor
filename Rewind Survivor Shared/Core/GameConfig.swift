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

    // MARK: - Waves (enemy count)
    static let baseEnemiesPerWave: Int = 12
    static let enemyCountPower: Double = 0.95      // power curve: base * wave^power, reaches ~500 at wave 50
    static let maxEnemiesPerWave: Int = 500

    // MARK: - Wave Scaling (all linear with caps — no level should feel impossible)
    static let enemyDamagePerWave: Double = 0.10    // +10% per wave, cap at 6x
    static let enemyDamageMaxMultiplier: Double = 6.0
    static let enemyHPPerWave: Double = 0.40        // +40% per wave, uncapped
    static let enemySpeedPerWave: Double = 0.04     // +4% per wave, cap at 3x
    static let enemySpeedMaxWaveMultiplier: Double = 3.0

    // MARK: - Death Scaling (additive bonus on top of wave scaling, uncapped)
    static let enemyDamageScalePerGhost: CGFloat = 0.20
    static let enemySpeedScalePerGhost: CGFloat = 0.08  // uncapped — stacks forever
    static let enemyHPScalePerGhost: CGFloat = 0.40

    // MARK: - Visual
    static let rewindEffectDuration: TimeInterval = 1.5
    static let screenShakeMagnitude: CGFloat = 8.0

    // MARK: - Spawn
    static let spawnMargin: CGFloat = 100
    static let minSpawnDistanceFromPlayer: CGFloat = 300
}
