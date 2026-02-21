import SpriteKit

enum CosmeticCategory: String, CaseIterable, Codable {
    case skin
    case hat
    case trail
}

struct CosmeticItem {
    let id: String
    let category: CosmeticCategory
    let displayName: String
    let description: String
    let price: Int
    let previewColor: SKColor
    var primaryColor: SKColor?
    var secondaryColor: SKColor?
    var trailColor: SKColor?
}

struct CosmeticCatalog {
    static let skins: [CosmeticItem] = [
        CosmeticItem(id: "default", category: .skin, displayName: "Chrono Agent", description: "Standard issue", price: 0, previewColor: ColorPalette.playerPrimary, primaryColor: ColorPalette.playerPrimary, secondaryColor: ColorPalette.playerSecondary),
        CosmeticItem(id: "skin_crimson", category: .skin, displayName: "Crimson Ops", description: "Blood red armor", price: 5000, previewColor: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), primaryColor: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), secondaryColor: SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "skin_toxic", category: .skin, displayName: "Toxic Hazard", description: "Radioactive green", price: 5000, previewColor: SKColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0), primaryColor: SKColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0), secondaryColor: SKColor(red: 0.0, green: 0.5, blue: 0.15, alpha: 1.0)),
        CosmeticItem(id: "skin_gold", category: .skin, displayName: "Gold Edition", description: "Prestigious plating", price: 25000, previewColor: ColorPalette.gold, primaryColor: ColorPalette.gold, secondaryColor: SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "skin_void", category: .skin, displayName: "Void Walker", description: "From beyond the rift", price: 15000, previewColor: ColorPalette.rewindMagenta, primaryColor: ColorPalette.rewindMagenta, secondaryColor: ColorPalette.rewindPurple),
        CosmeticItem(id: "skin_skeleton", category: .skin, displayName: "Bone Reaper", description: "Skull face, exposed ribs", price: 10000, previewColor: SKColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 1.0), primaryColor: SKColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 1.0), secondaryColor: SKColor(red: 0.5, green: 0.5, blue: 0.45, alpha: 1.0)),
        CosmeticItem(id: "skin_cyber", category: .skin, displayName: "Neon Cyber", description: "Glowing edge lines", price: 15000, previewColor: SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), primaryColor: SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), secondaryColor: SKColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1.0)),
        CosmeticItem(id: "skin_magma", category: .skin, displayName: "Magma Golem", description: "Molten cracks glow", price: 20000, previewColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), primaryColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), secondaryColor: SKColor(red: 0.2, green: 0.08, blue: 0.02, alpha: 1.0)),
        CosmeticItem(id: "skin_ghost", category: .skin, displayName: "Phantom", description: "Semi-transparent specter", price: 35000, previewColor: SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0), primaryColor: SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0), secondaryColor: SKColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)),
    ]

    static let hats: [CosmeticItem] = [
        CosmeticItem(id: "none", category: .hat, displayName: "None", description: "No hat", price: 0, previewColor: .clear),
        CosmeticItem(id: "hat_crown", category: .hat, displayName: "Royal Crown", description: "Rule the arena", price: 18000, previewColor: ColorPalette.gold),
        CosmeticItem(id: "hat_halo", category: .hat, displayName: "Angel Halo", description: "Divine protection", price: 8000, previewColor: SKColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 1.0)),
        CosmeticItem(id: "hat_horns", category: .hat, displayName: "Demon Horns", description: "Embrace the darkness", price: 8000, previewColor: SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "hat_wizard", category: .hat, displayName: "Wizard Hat", description: "Arcane knowledge", price: 10000, previewColor: SKColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0)),
        CosmeticItem(id: "hat_headband", category: .hat, displayName: "Ninja Band", description: "Swift and silent", price: 6000, previewColor: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)),
        CosmeticItem(id: "hat_tophat", category: .hat, displayName: "Top Hat", description: "Distinguished elegance", price: 14000, previewColor: SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)),
        CosmeticItem(id: "hat_antenna", category: .hat, displayName: "Antenna", description: "Picking up signals", price: 7000, previewColor: SKColor(red: 0.0, green: 0.9, blue: 0.3, alpha: 1.0)),
    ]

    static let trails: [CosmeticItem] = [
        CosmeticItem(id: "none", category: .trail, displayName: "None", description: "No trail", price: 0, previewColor: .clear),
        CosmeticItem(id: "trail_fire", category: .trail, displayName: "Flame Trail", description: "Leave fire in your wake", price: 7000, previewColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), trailColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "trail_ice", category: .trail, displayName: "Frost Trail", description: "Chilling presence", price: 7000, previewColor: ColorPalette.freezeAuraBlue, trailColor: ColorPalette.freezeAuraBlue),
        CosmeticItem(id: "trail_shadow", category: .trail, displayName: "Shadow Trail", description: "Dark afterimages", price: 12000, previewColor: SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1.0), trailColor: SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1.0)),
        CosmeticItem(id: "trail_rainbow", category: .trail, displayName: "Prismatic", description: "Shifting rainbow colors", price: 18000, previewColor: SKColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 1.0), trailColor: SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0)),
        CosmeticItem(id: "trail_spark", category: .trail, displayName: "Spark Trail", description: "Electric discharge", price: 8000, previewColor: SKColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 1.0), trailColor: SKColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 1.0)),
        CosmeticItem(id: "trail_pixel", category: .trail, displayName: "Glitch Trail", description: "Pixelated artifacts", price: 10000, previewColor: SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0), trailColor: SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1.0)),
    ]

    static func item(byId id: String) -> CosmeticItem? {
        return (skins + hats + trails).first { $0.id == id }
    }

    static func items(forCategory category: CosmeticCategory) -> [CosmeticItem] {
        switch category {
        case .skin: return skins
        case .hat: return hats
        case .trail: return trails
        }
    }
}
