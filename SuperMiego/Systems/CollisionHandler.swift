import SpriteKit

protocol CollisionHandlerDelegate: AnyObject {
    func collisionHandlerDidCollectCoin()
    func collisionHandlerDidCollectPowerUp(type: ItemType)
    func collisionHandlerDidStompEnemy(points: Int, at position: CGPoint)
    func collisionHandlerDidKillEnemy(at position: CGPoint)
    func collisionHandlerPlayerDidDie()
    func collisionHandlerDidReachFlagpole()
}

class CollisionHandler: NSObject, SKPhysicsContactDelegate {
    weak var delegate: CollisionHandlerDelegate?
    weak var player: Player?
    weak var gameState: GameStateManager?

    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node

        // Player + Ground/Block (for ground detection)
        if collision == PhysicsCategory.player | PhysicsCategory.ground ||
           collision == PhysicsCategory.player | PhysicsCategory.block {
            // Check if player is landing on top
            if isPlayerLandingOn(contact: contact) {
                player?.contactWithGround()
            }
        }

        // Player + Enemy
        if collision == PhysicsCategory.player | PhysicsCategory.enemy {
            handlePlayerEnemyContact(contact, nodeA: nodeA, nodeB: nodeB)
        }

        // Player + Item
        if collision == PhysicsCategory.player | PhysicsCategory.item {
            handlePlayerItemContact(nodeA: nodeA, nodeB: nodeB)
        }

        // Player + Coin
        if collision == PhysicsCategory.player | PhysicsCategory.coin {
            handlePlayerCoinContact(nodeA: nodeA, nodeB: nodeB)
        }

        // Player + Death Zone
        if collision == PhysicsCategory.player | PhysicsCategory.deathZone {
            player?.die()
        }

        // Player + Flagpole
        if collision == PhysicsCategory.player | PhysicsCategory.flagpole {
            delegate?.collisionHandlerDidReachFlagpole()
        }

        // Fireball + Enemy
        if collision == PhysicsCategory.fireball | PhysicsCategory.enemy {
            handleFireballEnemyContact(nodeA: nodeA, nodeB: nodeB)
        }

        // Fireball + Ground/Block (bounce or destroy)
        if collision == PhysicsCategory.fireball | PhysicsCategory.ground ||
           collision == PhysicsCategory.fireball | PhysicsCategory.block {
            if let fireball = (nodeA as? Fireball) ?? (nodeB as? Fireball) {
                // Check if hitting wall (horizontal contact)
                if abs(contact.contactNormal.dx) > 0.5 {
                    fireball.hitWall()
                }
            }
        }

        // Enemy + Ground/Block (for turning)
        if collision == PhysicsCategory.enemy | PhysicsCategory.ground ||
           collision == PhysicsCategory.enemy | PhysicsCategory.block {
            if let enemy = (nodeA as? Enemy) ?? (nodeB as? Enemy) {
                // Check if hitting wall
                if abs(contact.contactNormal.dx) > 0.5 {
                    enemy.hitWall()
                }
            }
        }

        // Item + Ground/Block
        if collision == PhysicsCategory.item | PhysicsCategory.ground ||
           collision == PhysicsCategory.item | PhysicsCategory.block {
            if let item = (nodeA as? ItemNode) ?? (nodeB as? ItemNode) {
                if abs(contact.contactNormal.dx) > 0.5 {
                    item.hitWall()
                }
            }
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // Player leaving ground
        if collision == PhysicsCategory.player | PhysicsCategory.ground ||
           collision == PhysicsCategory.player | PhysicsCategory.block {
            player?.endContactWithGround()
        }
    }

    private func isPlayerLandingOn(contact: SKPhysicsContact) -> Bool {
        // Check contact normal - player should be above the ground
        let playerBody: SKPhysicsBody

        if contact.bodyA.categoryBitMask == PhysicsCategory.player {
            playerBody = contact.bodyA
        } else {
            playerBody = contact.bodyB
        }

        // Contact normal should point upward relative to ground
        // and player should be moving downward or stationary
        let playerVelocity = playerBody.velocity.dy
        let normalY = contact.bodyA.categoryBitMask == PhysicsCategory.player ? -contact.contactNormal.dy : contact.contactNormal.dy

        return normalY > 0.5 && playerVelocity <= 10
    }

    // MARK: - Player + Enemy

    private func handlePlayerEnemyContact(_ contact: SKPhysicsContact, nodeA: SKNode?, nodeB: SKNode?) {
        guard let player = player,
              let enemy = (nodeA as? Enemy) ?? (nodeB as? Enemy) else { return }

        guard !enemy.isDead else { return }

        // Check if player is invincible
        if player.playerState == .invincible {
            enemy.hitByInvinciblePlayer()
            delegate?.collisionHandlerDidKillEnemy(at: enemy.position)
            return
        }

        // Determine if stomp based on:
        // 1. Player is above enemy center
        // 2. Player is moving downward
        let playerBottom = player.position.y - player.size.height / 2
        let playerVelocity = player.physicsBody?.velocity.dy ?? 0

        let isAbove = playerBottom > enemy.position.y - 5
        let isMovingDown = playerVelocity < 50

        if isAbove && isMovingDown && enemy.canDamagePlayer {
            // Stomp!
            enemy.stomp()
            player.bounce()

            if let gameState = gameState {
                let points = gameState.addStompScore(at: CACurrentMediaTime())
                delegate?.collisionHandlerDidStompEnemy(points: points, at: enemy.position)
            }
        } else if enemy.canDamagePlayer {
            // Player takes damage
            player.takeDamage()
            if player.playerState == .dead {
                delegate?.collisionHandlerPlayerDidDie()
            }
        }
    }

    // MARK: - Player + Item

    private func handlePlayerItemContact(nodeA: SKNode?, nodeB: SKNode?) {
        guard let player = player,
              let item = (nodeA as? ItemNode) ?? (nodeB as? ItemNode) else { return }

        switch item.itemType {
        case .mushroom:
            player.collectMushroom()
        case .fireFlower:
            player.collectFireFlower()
        case .star:
            player.collectStar()
        case .oneUp:
            gameState?.addLife()
        case .coin:
            gameState?.collectCoin()
        }

        delegate?.collisionHandlerDidCollectPowerUp(type: item.itemType)
        item.collected()
    }

    // MARK: - Player + Coin

    private func handlePlayerCoinContact(nodeA: SKNode?, nodeB: SKNode?) {
        let coinNode = nodeA?.name == "coin" ? nodeA : (nodeB?.name == "coin" ? nodeB : nil)
        guard let coin = coinNode as? SKSpriteNode else { return }

        gameState?.collectCoin()
        delegate?.collisionHandlerDidCollectCoin()

        // Animate and remove
        coin.physicsBody = nil
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        coin.run(SKAction.sequence([
            SKAction.group([scaleUp, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Fireball + Enemy

    private func handleFireballEnemyContact(nodeA: SKNode?, nodeB: SKNode?) {
        guard let fireball = (nodeA as? Fireball) ?? (nodeB as? Fireball),
              let enemy = (nodeA as? Enemy) ?? (nodeB as? Enemy) else { return }

        guard !enemy.isDead else { return }

        enemy.hitByFireball()
        fireball.hitEnemy()

        if let gameState = gameState {
            _ = gameState.addStompScore(at: CACurrentMediaTime())
        }
        delegate?.collisionHandlerDidKillEnemy(at: enemy.position)
    }
}
