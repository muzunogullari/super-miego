import Foundation

protocol GameStateDelegate: AnyObject {
    func gameStateDidUpdateScore(_ score: Int)
    func gameStateDidUpdateCoins(_ coins: Int)
    func gameStateDidUpdateLives(_ lives: Int)
    func gameStateDidUpdateTime(_ time: TimeInterval)
    func gameStateDidGetExtraLife()
    func gameStateDidTimeExpire()
    func gameStateDidTriggerGameOver()
}

class GameStateManager {
    weak var delegate: GameStateDelegate?

    // MARK: - State
    private(set) var score: Int = 0
    private(set) var coins: Int = 0
    private(set) var lives: Int = GameConstants.startingLives
    private(set) var timeRemaining: TimeInterval = GameConstants.levelTimeLimit

    private(set) var isGameOver: Bool = false
    private(set) var isLevelComplete: Bool = false
    private(set) var isPaused: Bool = false
    private var hasTimedOut: Bool = false

    // Combo tracking
    private var comboCount: Int = 0
    private var lastStompTime: TimeInterval = 0
    private let comboWindow: TimeInterval = 0.5

    // MARK: - Score

    func addScore(_ points: Int) {
        score += points
        delegate?.gameStateDidUpdateScore(score)
    }

    func addStompScore(at time: TimeInterval) -> Int {
        if time - lastStompTime < comboWindow {
            comboCount = min(comboCount + 1, GameConstants.maxComboMultiplier)
        } else {
            comboCount = 1
        }
        lastStompTime = time

        let points = GameConstants.enemyStompPoints * comboCount
        addScore(points)
        return points
    }

    // MARK: - Coins

    func collectCoin() {
        coins += 1
        addScore(GameConstants.coinPoints)
        delegate?.gameStateDidUpdateCoins(coins)

        if coins >= GameConstants.coinsForLife {
            coins -= GameConstants.coinsForLife
            addLife()
            delegate?.gameStateDidUpdateCoins(coins)
        }
    }

    // MARK: - Lives

    func addLife() {
        lives += 1
        delegate?.gameStateDidUpdateLives(lives)
        delegate?.gameStateDidGetExtraLife()
    }

    func loseLife() {
        lives -= 1
        delegate?.gameStateDidUpdateLives(lives)

        if lives <= 0 {
            isGameOver = true
            delegate?.gameStateDidTriggerGameOver()
        }
    }

    // MARK: - Time

    func updateTime(_ deltaTime: TimeInterval) {
        guard !isPaused && !isGameOver && !isLevelComplete && !hasTimedOut else { return }

        timeRemaining -= deltaTime

        if timeRemaining <= 0 {
            timeRemaining = 0
            hasTimedOut = true
            delegate?.gameStateDidUpdateTime(timeRemaining)
            delegate?.gameStateDidTimeExpire()
            return
        }

        delegate?.gameStateDidUpdateTime(timeRemaining)
    }

    func getTimeBonus() -> Int {
        return Int(timeRemaining) * 50
    }

    // MARK: - Level Complete

    func completeLevel() {
        isLevelComplete = true
        let timeBonus = getTimeBonus()
        addScore(timeBonus)
    }

    // MARK: - Pause

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func togglePause() {
        isPaused.toggle()
    }

    // MARK: - Reset

    func resetForNewLife() {
        // Keep score, coins, lives - reset level state
        timeRemaining = GameConstants.levelTimeLimit
        comboCount = 0
        isLevelComplete = false
        hasTimedOut = false
    }

    func resetForNewGame() {
        score = 0
        coins = 0
        lives = GameConstants.startingLives
        timeRemaining = GameConstants.levelTimeLimit
        isGameOver = false
        isLevelComplete = false
        isPaused = false
        comboCount = 0
        hasTimedOut = false

        delegate?.gameStateDidUpdateScore(score)
        delegate?.gameStateDidUpdateCoins(coins)
        delegate?.gameStateDidUpdateLives(lives)
        delegate?.gameStateDidUpdateTime(timeRemaining)
    }

    /// Full reset for level restart (alias for resetForNewGame)
    func reset() {
        resetForNewGame()
    }
}
