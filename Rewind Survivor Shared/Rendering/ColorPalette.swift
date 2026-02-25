import SpriteKit

struct ColorPalette {
    // MARK: - Arena
    static let arenaFloor = SKColor(red: 0.051, green: 0.051, blue: 0.102, alpha: 1.0)     // #0D0D1A
    static let arenaWall = SKColor(red: 0.173, green: 0.173, blue: 0.329, alpha: 1.0)      // #2C2C54

    // MARK: - Player
    static let playerPrimary = SKColor(red: 0.0, green: 0.961, blue: 1.0, alpha: 1.0)      // #00F5FF
    static let playerSecondary = SKColor(red: 0.0, green: 0.502, blue: 1.0, alpha: 1.0)    // #0080FF
    // MARK: - Ghost
    static let ghostCyan = SKColor(red: 0.502, green: 1.0, blue: 1.0, alpha: 1.0)          // #80FFFF
    // MARK: - Enemies
    static let enemyMelee = SKColor(red: 1.0, green: 0.267, blue: 0.267, alpha: 1.0)       // #FF4444
    static let enemyRanged = SKColor(red: 1.0, green: 0.533, blue: 0.0, alpha: 1.0)        // #FF8800
    static let enemyFast = SKColor(red: 1.0, green: 0.933, blue: 0.0, alpha: 1.0)          // #FFEE00
    static let enemyTank = SKColor(red: 0.545, green: 0.0, blue: 0.0, alpha: 1.0)          // #8B0000
    static let enemyBoss = SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)            // #FF00FF
    static let enemyJuggernaut = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)       // Brown-grey brute
    static let enemyWraith = SKColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0)          // Ghostly blue
    static let enemySplitter = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)        // Green slime
    static let enemyShieldBearer = SKColor(red: 0.6, green: 0.7, blue: 0.85, alpha: 1.0)  // Metallic silver-blue
    static let enemyOutline = SKColor(red: 0.2, green: 0.0, blue: 0.0, alpha: 1.0)         // #330000
    static let enemyEyes = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)            // #FFFF00

    // MARK: - Projectiles
    static let bulletPlayer = SKColor(red: 0.0, green: 1.0, blue: 0.533, alpha: 1.0)       // #00FF88
    static let bulletEnemy = SKColor(red: 1.0, green: 0.133, blue: 0.0, alpha: 1.0)        // #FF2200
    static let bulletGhost = SKColor(red: 0.502, green: 1.0, blue: 1.0, alpha: 1.0)        // #80FFFF
    // MARK: - Power-ups
    static let powerUpGreen = SKColor(red: 0.0, green: 1.0, blue: 0.533, alpha: 1.0)
    static let powerUpBlue = SKColor(red: 0.0, green: 0.749, blue: 1.0, alpha: 1.0)
    static let powerUpYellow = SKColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0)
    static let powerUpRed = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
    static let powerUpCyan = SKColor(red: 0.0, green: 0.961, blue: 1.0, alpha: 1.0)
    static let powerUpPink = SKColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
    static let powerUpPurple = SKColor(red: 0.69, green: 0.0, blue: 1.0, alpha: 1.0)
    static let freezeAuraBlue = SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0)

    // MARK: - UI/HUD
    static let hudHealthFull = SKColor(red: 0.0, green: 1.0, blue: 0.533, alpha: 1.0)
    static let hudHealthMid = SKColor(red: 1.0, green: 0.667, blue: 0.0, alpha: 1.0)
    static let hudHealthLow = SKColor(red: 1.0, green: 0.133, blue: 0.0, alpha: 1.0)
    static let hudBackground = SKColor(red: 0.102, green: 0.102, blue: 0.180, alpha: 1.0)
    static let hudXPBar = SKColor(red: 0.0, green: 0.961, blue: 1.0, alpha: 1.0)
    static let textPrimary = SKColor.white
    static let textSecondary = SKColor(red: 0.533, green: 0.533, blue: 0.667, alpha: 1.0)
    static let gold = SKColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0)

    // MARK: - Super Power-Ups
    static let superChronoShift = SKColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 1.0)     // Purple
    static let superRadiationField = SKColor(red: 0.2, green: 1.0, blue: 0.0, alpha: 1.0)    // Toxic green
    static let superShockwavePulse = SKColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1.0)    // Electric blue
    static let superVoidBarrier = SKColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1.0)      // Bright cyan

    // MARK: - Rewind Effect
    static let rewindMagenta = SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
    static let rewindScanline = SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.25)
    static let rewindPurple = SKColor(red: 0.69, green: 0.0, blue: 1.0, alpha: 1.0)
}
