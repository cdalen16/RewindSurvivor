import Foundation

protocol AdBridge: AnyObject {
    func showCoinAd(completion: @escaping (Bool) -> Void)
    func showReviveAd(completion: @escaping (Bool) -> Void)
    var isCoinAdReady: Bool { get }
    var isReviveAdReady: Bool { get }
}
