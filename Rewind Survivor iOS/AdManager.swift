import GoogleMobileAds

class AdManager: NSObject, AdBridge {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs
    #if DEBUG
    private let coinRewardAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private let reviveRewardAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    private let coinRewardAdUnitID = "ca-app-pub-9824434774494118/9723497957"
    private let reviveRewardAdUnitID = "ca-app-pub-9824434774494118/5856909717"
    #endif

    private var coinRewardAd: RewardedAd?
    private var reviveRewardAd: RewardedAd?
    weak var presentingViewController: UIViewController?
    var isCoinAdReady: Bool {
        return coinRewardAd != nil
    }

    var isReviveAdReady: Bool {
        return reviveRewardAd != nil
    }

    private override init() {
        super.init()
        loadCoinAd()
        loadReviveAd()
    }

    // MARK: - Loading

    func loadCoinAd() {
        RewardedAd.load(with: coinRewardAdUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                print("[AdManager] Failed to load coin ad: \(error.localizedDescription)")
                return
            }
            self?.coinRewardAd = ad
            print("[AdManager] Coin reward ad loaded")
        }
    }

    func loadReviveAd() {
        RewardedAd.load(with: reviveRewardAdUnitID, request: Request()) { [weak self] ad, error in
            if let error = error {
                print("[AdManager] Failed to load revive ad: \(error.localizedDescription)")
                return
            }
            self?.reviveRewardAd = ad
            print("[AdManager] Revive reward ad loaded")
        }
    }

    // MARK: - Showing

    func showCoinAd(completion: @escaping (Bool) -> Void) {
        guard let ad = coinRewardAd, let vc = presentingViewController else {
            print("[AdManager] Coin ad not ready")
            completion(false)
            return
        }

        ad.present(from: vc) { [weak self] in
            print("[AdManager] User earned coin reward")
            completion(true)
            self?.coinRewardAd = nil
            self?.loadCoinAd()
        }
    }

    func showReviveAd(completion: @escaping (Bool) -> Void) {
        guard let ad = reviveRewardAd, let vc = presentingViewController else {
            print("[AdManager] Revive ad not ready")
            completion(false)
            return
        }

        ad.present(from: vc) { [weak self] in
            print("[AdManager] User earned revive reward")
            completion(true)
            self?.reviveRewardAd = nil
            self?.loadReviveAd()
        }
    }
}
