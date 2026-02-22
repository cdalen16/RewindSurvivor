import SpriteKit

enum SuperPowerUpType: String, CaseIterable, Codable, Hashable {
    case chronoShift
    case quantumNuke
    case shadowClone
    case gravitySingularity
    case voidBarrier

    var displayName: String {
        switch self {
        case .chronoShift: return "Chrono Shift"
        case .quantumNuke: return "Quantum Nuke"
        case .shadowClone: return "Shadow Clone"
        case .gravitySingularity: return "Gravity Singularity"
        case .voidBarrier: return "Void Barrier"
        }
    }

    var description: String {
        switch self {
        case .chronoShift: return "All enemies slowed to 40% speed for 15s"
        case .quantumNuke: return "150 damage to ALL enemies in the arena"
        case .shadowClone: return "AI clone orbits you and fires at enemies"
        case .gravitySingularity: return "Black hole pulls and damages nearby enemies for 20s"
        case .voidBarrier: return "Energy ring destroys enemy projectiles for 20s"
        }
    }

    var deathCost: Int {
        switch self {
        case .chronoShift: return 1
        case .quantumNuke: return 2
        case .shadowClone: return 2
        case .gravitySingularity: return 1
        case .voidBarrier: return 1
        }
    }

    var iconColor: SKColor {
        switch self {
        case .chronoShift: return ColorPalette.superChronoShift
        case .quantumNuke: return ColorPalette.superQuantumNuke
        case .shadowClone: return ColorPalette.superShadowClone
        case .gravitySingularity: return ColorPalette.superGravitySingularity
        case .voidBarrier: return ColorPalette.superVoidBarrier
        }
    }

    var duration: TimeInterval {
        switch self {
        case .chronoShift: return 15.0
        case .quantumNuke: return 0 // instant
        case .shadowClone: return .infinity // permanent
        case .gravitySingularity: return 20.0
        case .voidBarrier: return 20.0
        }
    }
}
