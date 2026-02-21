import SpriteKit

enum EnemyBehavior {
    case chase
    case charger
    case strafe
    case bomber
    case spawner
    case juggernaut
    case wraith
    case splitter
}

struct EnemyType {
    let name: String
    let behavior: EnemyBehavior
    let baseHP: CGFloat
    let baseSpeed: CGFloat
    let baseDamage: CGFloat
    let basePoints: Int
    let spriteSize: Int
    let color: SKColor
    let minWave: Int

    // MARK: - All Enemy Types
    static let shambler = EnemyType(
        name: "Shambler",
        behavior: .chase,
        baseHP: 30,
        baseSpeed: 60,
        baseDamage: 10,
        basePoints: 10,
        spriteSize: 32,
        color: ColorPalette.enemyMelee,
        minWave: 1
    )

    static let dasher = EnemyType(
        name: "Dasher",
        behavior: .charger,
        baseHP: 20,
        baseSpeed: 45,
        baseDamage: 18,
        basePoints: 20,
        spriteSize: 32,
        color: ColorPalette.enemyFast,
        minWave: 3
    )

    static let strafer = EnemyType(
        name: "Strafer",
        behavior: .strafe,
        baseHP: 25,
        baseSpeed: 50,
        baseDamage: 8,
        basePoints: 25,
        spriteSize: 32,
        color: ColorPalette.enemyRanged,
        minWave: 6
    )

    static let bomber = EnemyType(
        name: "Bomber",
        behavior: .bomber,
        baseHP: 40,
        baseSpeed: 70,
        baseDamage: 30,
        basePoints: 30,
        spriteSize: 32,
        color: ColorPalette.enemyTank,
        minWave: 9
    )

    static let necromancer = EnemyType(
        name: "Necromancer",
        behavior: .spawner,
        baseHP: 60,
        baseSpeed: 35,
        baseDamage: 5,
        basePoints: 50,
        spriteSize: 40,
        color: ColorPalette.enemyBoss,
        minWave: 12
    )

    static let juggernaut = EnemyType(
        name: "Juggernaut",
        behavior: .juggernaut,
        baseHP: 200,
        baseSpeed: 40,
        baseDamage: 25,
        basePoints: 80,
        spriteSize: 48,
        color: ColorPalette.enemyJuggernaut,
        minWave: 15
    )

    static let wraith = EnemyType(
        name: "Wraith",
        behavior: .wraith,
        baseHP: 50,
        baseSpeed: 55,
        baseDamage: 15,
        basePoints: 60,
        spriteSize: 32,
        color: ColorPalette.enemyWraith,
        minWave: 18
    )

    static let splitter = EnemyType(
        name: "Splitter",
        behavior: .splitter,
        baseHP: 60,
        baseSpeed: 55,
        baseDamage: 12,
        basePoints: 40,
        spriteSize: 32,
        color: ColorPalette.enemySplitter,
        minWave: 21
    )

    static let allTypes: [EnemyType] = [shambler, dasher, strafer, bomber, necromancer, juggernaut, wraith, splitter]

    static func typesAvailable(forWave wave: Int) -> [EnemyType] {
        return allTypes.filter { $0.minWave <= wave }
    }

    // MARK: - Scaling

    static func scaledStats(type: EnemyType, wave: Int, ghostCount: Int) -> (hp: CGFloat, speed: CGFloat, damage: CGFloat) {
        let waveMultiplier = pow(GameConfig.enemyHPScalePerWave, Double(wave - 1))
        let ghostHPMultiplier = 1.0 + GameConfig.enemyHPScalePerGhost * CGFloat(ghostCount)
        let ghostDmgMultiplier = 1.0 + GameConfig.enemyDamageScalePerGhost * CGFloat(ghostCount)
        let speedScale = min(1.0 + GameConfig.enemySpeedScalePerWave * CGFloat(wave - 1), GameConfig.enemyMaxSpeedMultiplier)

        let hp = type.baseHP * CGFloat(waveMultiplier) * ghostHPMultiplier
        let speed = type.baseSpeed * speedScale
        let damage = type.baseDamage * CGFloat(waveMultiplier) * ghostDmgMultiplier

        return (hp, speed, damage)
    }

    static func enemyCount(forWave wave: Int) -> Int {
        let base = Double(GameConfig.baseEnemiesPerWave)
        let count = base * pow(GameConfig.enemiesPerWaveGrowth, Double(wave - 1))
        return min(Int(count), GameConfig.maxEnemiesPerWave)
    }

    static func composition(forWave wave: Int) -> [(EnemyType, Int)] {
        let total = enemyCount(forWave: wave)
        var composition: [(EnemyType, Int)] = []
        var remaining = total

        let available = typesAvailable(forWave: wave)

        // Shambler: always present, decreasing share
        let shamblerPct = max(0.3, 1.0 - Double(wave - 1) * 0.06)
        let shamblerCount = max(2, Int(Double(total) * shamblerPct))
        composition.append((.shambler, shamblerCount))
        remaining -= shamblerCount

        // Distribute remaining among unlocked types (excluding shambler)
        let otherTypes = available.filter { $0.name != "Shambler" }
        if !otherTypes.isEmpty && remaining > 0 {
            let perType = max(1, remaining / otherTypes.count)
            for type in otherTypes {
                let count = min(perType, remaining)
                if count > 0 {
                    composition.append((type, count))
                    remaining -= count
                }
            }
        }

        // Any leftover goes to shamblers
        if remaining > 0 {
            composition[0] = (.shambler, composition[0].1 + remaining)
        }

        return composition
    }
}
