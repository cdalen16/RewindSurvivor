import Foundation

struct PlayerProfile: Codable {
    var highScore: Int = 0
    var highestWave: Int = 0
    var totalKills: Int = 0
    var totalDeaths: Int = 0
    var totalGamesPlayed: Int = 0
    var totalPlayTime: TimeInterval = 0
    var coins: Int = 0
    var equippedSkin: String = "default"
    var equippedHat: String = "hat_none"
    var equippedTrail: String = "trail_none"
    var unlockedCosmetics: [String] = []

    var killsPerGame: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalKills) / Double(totalGamesPlayed)
    }
}

class PersistenceManager {
    static let shared = PersistenceManager()

    private let profileKey = "com.rewindsurvivor.playerProfile"
    private(set) var profile: PlayerProfile

    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           var decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            // Migrate old "none" IDs from before the rename
            if decoded.equippedHat == "none" { decoded.equippedHat = "hat_none" }
            if decoded.equippedTrail == "none" { decoded.equippedTrail = "trail_none" }
            profile = decoded
        } else {
            profile = PlayerProfile()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    func recordGameEnd(score: Int, wave: Int, kills: Int, deaths: Int, playTime: TimeInterval, coinsEarned: Int) {
        profile.totalGamesPlayed += 1
        profile.totalKills += kills
        profile.totalDeaths += deaths
        profile.totalPlayTime += playTime
        profile.coins += coinsEarned

        if score > profile.highScore {
            profile.highScore = score
        }
        if wave > profile.highestWave {
            profile.highestWave = wave
        }

        save()
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard profile.coins >= amount else { return false }
        profile.coins -= amount
        save()
        return true
    }

    func unlockCosmetic(_ id: String) {
        guard !profile.unlockedCosmetics.contains(id) else { return }
        profile.unlockedCosmetics.append(id)
        save()
    }

    func isUnlocked(_ id: String) -> Bool {
        return profile.unlockedCosmetics.contains(id) || id == "default" || id == "hat_none" || id == "trail_none"
    }

    func equipSkin(_ id: String) {
        profile.equippedSkin = id
        save()
    }

    func equipHat(_ id: String) {
        profile.equippedHat = id
        save()
    }

    func equipTrail(_ id: String) {
        profile.equippedTrail = id
        save()
    }
}
