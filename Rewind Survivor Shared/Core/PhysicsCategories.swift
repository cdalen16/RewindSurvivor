import Foundation

struct PhysicsCategory {
    static let none:         UInt32 = 0
    static let player:       UInt32 = 0b0000_0001  // 1
    static let enemy:        UInt32 = 0b0000_0010  // 2
    static let playerBullet: UInt32 = 0b0000_0100  // 4
    static let enemyBullet:  UInt32 = 0b0000_1000  // 8
    static let ghost:        UInt32 = 0b0001_0000  // 16
    static let ghostBullet:  UInt32 = 0b0010_0000  // 32
    static let wall:         UInt32 = 0b0100_0000  // 64
    static let pickup:       UInt32 = 0b1000_0000  // 128
}
