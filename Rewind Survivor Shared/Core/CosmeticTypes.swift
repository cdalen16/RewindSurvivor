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
        CosmeticItem(id: "skin_crimson", category: .skin, displayName: "Crimson Ops", description: "Blood red armor", price: 500, previewColor: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), primaryColor: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), secondaryColor: SKColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "skin_toxic", category: .skin, displayName: "Toxic Hazard", description: "Radioactive green", price: 500, previewColor: SKColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0), primaryColor: SKColor(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0), secondaryColor: SKColor(red: 0.0, green: 0.5, blue: 0.15, alpha: 1.0)),
        CosmeticItem(id: "skin_gold", category: .skin, displayName: "Gold Edition", description: "Prestigious plating", price: 2000, previewColor: ColorPalette.gold, primaryColor: ColorPalette.gold, secondaryColor: SKColor(red: 0.7, green: 0.5, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "skin_void", category: .skin, displayName: "Void Walker", description: "From beyond the rift", price: 1500, previewColor: ColorPalette.rewindMagenta, primaryColor: ColorPalette.rewindMagenta, secondaryColor: ColorPalette.rewindPurple),
    ]

    static let hats: [CosmeticItem] = [
        CosmeticItem(id: "none", category: .hat, displayName: "None", description: "No hat", price: 0, previewColor: .clear),
        CosmeticItem(id: "hat_crown", category: .hat, displayName: "Royal Crown", description: "Rule the arena", price: 1000, previewColor: ColorPalette.gold),
        CosmeticItem(id: "hat_halo", category: .hat, displayName: "Angel Halo", description: "Divine protection", price: 800, previewColor: SKColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 1.0)),
        CosmeticItem(id: "hat_horns", category: .hat, displayName: "Demon Horns", description: "Embrace the darkness", price: 800, previewColor: SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)),
    ]

    static let trails: [CosmeticItem] = [
        CosmeticItem(id: "none", category: .trail, displayName: "None", description: "No trail", price: 0, previewColor: .clear),
        CosmeticItem(id: "trail_fire", category: .trail, displayName: "Flame Trail", description: "Leave fire in your wake", price: 600, previewColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), trailColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)),
        CosmeticItem(id: "trail_ice", category: .trail, displayName: "Frost Trail", description: "Chilling presence", price: 600, previewColor: ColorPalette.freezeAuraBlue, trailColor: ColorPalette.freezeAuraBlue),
        CosmeticItem(id: "trail_shadow", category: .trail, displayName: "Shadow Trail", description: "Dark afterimages", price: 1200, previewColor: SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1.0), trailColor: SKColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1.0)),
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
