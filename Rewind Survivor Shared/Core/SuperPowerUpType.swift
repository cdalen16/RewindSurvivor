import SpriteKit

enum SuperPowerUpType: String, CaseIterable, Codable, Hashable {
    case chronoShift
    case radiationField
    case shockwavePulse
    case voidBarrier

    var displayName: String {
        switch self {
        case .chronoShift: return "Chrono Shift"
        case .radiationField: return "Radiation Field"
        case .shockwavePulse: return "Shockwave Pulse"
        case .voidBarrier: return "Void Barrier"
        }
    }

    var description: String {
        switch self {
        case .chronoShift: return "All enemies permanently slowed to 75% speed"
        case .radiationField: return "Toxic aura burns all nearby enemies continuously"
        case .shockwavePulse: return "Massive shockwave pushes all enemies back every 10s"
        case .voidBarrier: return "Energy ring permanently destroys enemy projectiles"
        }
    }

    var deathCost: Int {
        switch self {
        case .chronoShift: return 1
        case .radiationField: return 2
        case .shockwavePulse: return 2
        case .voidBarrier: return 1
        }
    }

    var iconColor: SKColor {
        switch self {
        case .chronoShift: return ColorPalette.superChronoShift
        case .radiationField: return ColorPalette.superRadiationField
        case .shockwavePulse: return ColorPalette.superShockwavePulse
        case .voidBarrier: return ColorPalette.superVoidBarrier
        }
    }

}
