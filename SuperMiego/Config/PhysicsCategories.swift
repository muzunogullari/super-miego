import Foundation

struct PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 1 << 0   // 1
    static let ground:      UInt32 = 1 << 1   // 2
    static let block:       UInt32 = 1 << 2   // 4
    static let enemy:       UInt32 = 1 << 3   // 8
    static let item:        UInt32 = 1 << 4   // 16
    static let coin:        UInt32 = 1 << 5   // 32
    static let playerFeet:  UInt32 = 1 << 6   // 64 - for stomp detection
    static let flagpole:    UInt32 = 1 << 7   // 128
    static let fireball:    UInt32 = 1 << 8   // 256
    static let deathZone:   UInt32 = 1 << 9   // 512 - pits
    static let platform:    UInt32 = 1 << 10  // 1024 - one-way platforms
    static let shell:       UInt32 = 1 << 11  // 2048 - kicked koopa shell

    // Collision masks
    static let playerCollision: UInt32 = ground | block | platform
    static let playerContact: UInt32 = enemy | item | coin | flagpole | deathZone | shell

    static let enemyCollision: UInt32 = ground | block
    static let enemyContact: UInt32 = player | playerFeet | fireball | shell

    static let itemCollision: UInt32 = ground | block
    static let itemContact: UInt32 = player

    static let fireballCollision: UInt32 = ground | block
    static let fireballContact: UInt32 = enemy
}
