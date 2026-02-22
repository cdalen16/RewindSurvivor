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
    private let savedRunKey = "com.rewindsurvivor.savedRun"
    private let iCloudProfileKey = "playerProfile"
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private(set) var profile: PlayerProfile

    private init() {
        // Load local profile
        var localProfile: PlayerProfile?
        if let data = UserDefaults.standard.data(forKey: profileKey),
           var decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            if decoded.equippedHat == "none" { decoded.equippedHat = "hat_none" }
            if decoded.equippedTrail == "none" { decoded.equippedTrail = "trail_none" }
            localProfile = decoded
        }

        // Load cloud profile
        var cloudProfile: PlayerProfile?
        if let cloudData = iCloudStore.data(forKey: iCloudProfileKey),
           let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: cloudData) {
            cloudProfile = decoded
        }

        // Merge
        if let local = localProfile, let cloud = cloudProfile {
            profile = PersistenceManager.merge(local: local, cloud: cloud)
        } else if let local = localProfile {
            profile = local
        } else if let cloud = cloudProfile {
            profile = cloud
        } else {
            profile = PlayerProfile()
        }

        // Save merged result to both stores
        save()

        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        iCloudStore.synchronize()
    }

    // MARK: - Merge Strategy

    private static func merge(local: PlayerProfile, cloud: PlayerProfile) -> PlayerProfile {
        var merged = PlayerProfile()
        merged.highScore = max(local.highScore, cloud.highScore)
        merged.highestWave = max(local.highestWave, cloud.highestWave)
        merged.totalKills = max(local.totalKills, cloud.totalKills)
        merged.totalDeaths = max(local.totalDeaths, cloud.totalDeaths)
        merged.totalGamesPlayed = max(local.totalGamesPlayed, cloud.totalGamesPlayed)
        merged.totalPlayTime = max(local.totalPlayTime, cloud.totalPlayTime)
        merged.coins = max(local.coins, cloud.coins)
        // Prefer local equipped cosmetics (user's current device)
        merged.equippedSkin = local.equippedSkin
        merged.equippedHat = local.equippedHat
        merged.equippedTrail = local.equippedTrail
        // Union of unlocked cosmetics
        let allUnlocked = Set(local.unlockedCosmetics).union(Set(cloud.unlockedCosmetics))
        merged.unlockedCosmetics = Array(allUnlocked).sorted()
        return merged
    }

    @objc private func iCloudDidChange(_ notification: Notification) {
        guard let cloudData = iCloudStore.data(forKey: iCloudProfileKey),
              let cloudProfile = try? JSONDecoder().decode(PlayerProfile.self, from: cloudData) else { return }
        // Merge incoming cloud data with local
        profile = PersistenceManager.merge(local: profile, cloud: cloudProfile)
        // Save locally only (avoid write loop back to iCloud)
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    // MARK: - Save

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
            iCloudStore.set(data, forKey: iCloudProfileKey)
        }
    }

    // MARK: - Game Stats

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

    // MARK: - Mid-Round Save/Resume

    var hasSavedRun: Bool {
        return UserDefaults.standard.data(forKey: savedRunKey) != nil
    }

    func saveRun(_ state: SavedRunState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: savedRunKey)
        }
    }

    func loadSavedRun() -> SavedRunState? {
        guard let data = UserDefaults.standard.data(forKey: savedRunKey) else { return nil }
        return try? JSONDecoder().decode(SavedRunState.self, from: data)
    }

    func clearSavedRun() {
        UserDefaults.standard.removeObject(forKey: savedRunKey)
    }
}
