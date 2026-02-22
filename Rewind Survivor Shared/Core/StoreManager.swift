import StoreKit

class StoreManager {
    static let shared = StoreManager()

    private(set) var products: [Product] = []
    private var transactionListener: Task<Void, Never>?

    // Product IDs
    private let coinPackIDs: Set<String> = [
        "com.rewindsurvivor.coins.500",
        "com.rewindsurvivor.coins.1200",
        "com.rewindsurvivor.coins.3500",
        "com.rewindsurvivor.coins.8000",
        "com.rewindsurvivor.coins.20000"
    ]

    private let premiumIDs: Set<String> = [
        "com.rewindsurvivor.premium.skin_chrono",
        "com.rewindsurvivor.premium.hat_phoenix",
        "com.rewindsurvivor.premium.trail_vortex"
    ]

    // Map product ID -> coin amount for consumables
    private let coinAmounts: [String: Int] = [
        "com.rewindsurvivor.coins.500": 500,
        "com.rewindsurvivor.coins.1200": 1200,
        "com.rewindsurvivor.coins.3500": 3500,
        "com.rewindsurvivor.coins.8000": 8000,
        "com.rewindsurvivor.coins.20000": 20000
    ]

    // Map product ID -> cosmetic ID for non-consumables
    private let cosmeticIDs: [String: String] = [
        "com.rewindsurvivor.premium.skin_chrono": "skin_chrono",
        "com.rewindsurvivor.premium.hat_phoenix": "hat_phoenix",
        "com.rewindsurvivor.premium.trail_vortex": "trail_vortex"
    ]

    var onPurchaseComplete: (() -> Void)?

    private init() {}

    // MARK: - Transaction Observer

    func startObservingTransactions() {
        guard transactionListener == nil else { return }
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                if case .verified(let transaction) = result {
                    await MainActor.run {
                        self.handleVerifiedTransaction(transaction)
                    }
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Load Products

    private(set) var loadError: String?
    private(set) var didAttemptLoad: Bool = false

    func loadProducts() async {
        let allIDs = coinPackIDs.union(premiumIDs)
        print("StoreManager: Requesting \(allIDs.count) products: \(allIDs)")
        loadError = nil
        do {
            products = try await Product.products(for: allIDs)
            didAttemptLoad = true
            print("StoreManager: Loaded \(products.count) products")
            for p in products {
                print("  - \(p.id): \(p.displayName) \(p.displayPrice)")
            }
            if products.isEmpty {
                loadError = "No products returned"
                print("StoreManager: WARNING — 0 products returned. Check StoreKit config is set in scheme.")
            }
        } catch {
            didAttemptLoad = true
            loadError = error.localizedDescription
            print("StoreManager: Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                handleVerifiedTransaction(transaction)
                await transaction.finish()
                return true
            }
            return false
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                handleVerifiedTransaction(transaction)
            }
        }
    }

    // MARK: - Check Entitlements (on launch)

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Only re-grant non-consumables
                if premiumIDs.contains(transaction.productID) {
                    if let cosmeticId = cosmeticIDs[transaction.productID] {
                        let pm = PersistenceManager.shared
                        if !pm.isUnlocked(cosmeticId) {
                            pm.unlockCosmetic(cosmeticId)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Handle Verified Transaction

    private func handleVerifiedTransaction(_ transaction: Transaction) {
        let productID = transaction.productID

        if let coins = coinAmounts[productID] {
            // Consumable: grant coins
            PersistenceManager.shared.addCoins(coins)
        } else if let cosmeticId = cosmeticIDs[productID] {
            // Non-consumable: unlock cosmetic
            let pm = PersistenceManager.shared
            pm.unlockCosmetic(cosmeticId)
            // Auto-equip on first purchase
            if let item = CosmeticCatalog.item(byId: cosmeticId) {
                switch item.category {
                case .skin: pm.equipSkin(cosmeticId)
                case .hat: pm.equipHat(cosmeticId)
                case .trail: pm.equipTrail(cosmeticId)
                }
                SpriteFactory.shared.invalidatePlayerTextures()
            }
        }

        onPurchaseComplete?()
    }

    // MARK: - Filtered Accessors

    func coinPackProducts() -> [Product] {
        products.filter { coinPackIDs.contains($0.id) }
            .sorted { (coinAmounts[$0.id] ?? 0) < (coinAmounts[$1.id] ?? 0) }
    }

    func premiumProducts() -> [Product] {
        products.filter { premiumIDs.contains($0.id) }
            .sorted { $0.displayName < $1.displayName }
    }

    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }
}
