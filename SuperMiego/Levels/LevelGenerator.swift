import Foundation

struct LevelGeneratorConfig {
    // Level dimensions
    var width: Int = 100
    var height: Int = 14

    // Ground settings
    var groundRows: Int = 2  // Bottom rows that are solid ground

    // Water gap settings
    var minWaterGapWidth: Int = 2
    var maxWaterGapWidth: Int = 3
    var minDistanceBetweenWaterGaps: Int = 20
    var waterGapCount: Int = 2

    // Pipe settings
    var pipeCount: Int = 3
    var minPipeHeight: Int = 2
    var maxPipeHeight: Int = 3
    var minDistanceBetweenPipes: Int = 15
    var minDistanceFromWater: Int = 5

    // Platform settings (bricks above water)
    var platformWidth: Int = 6
    var platformHeightAboveGround: Int = 3  // Rows above ground level

    // Enemy settings
    var goombaCount: Int = 2
    var turtleCount: Int = 1
    var minDistanceBetweenEnemies: Int = 15
    var minEnemyDistanceFromStart: Int = 20

    // Coin settings
    var coinArcCount: Int = 3
    var coinsPerArc: Int = 3
    var coinArcSpacing: Int = 3
    var scatteredCoinCount: Int = 4

    // Power-up settings
    var mushroomCount: Int = 1
    var fireFlowerCount: Int = 1
    var starCount: Int = 1
    var dollarBurstCount: Int = 1

    // Question block settings
    var questionBlockCount: Int = 4
    var minDistanceBetweenBlocks: Int = 10

    // Safe zones
    var safeZoneFromStart: Int = 15  // No obstacles near player start
    var safeZoneBeforeEnd: Int = 10  // Clear path to flagpole

    // Player start position (column)
    var playerStartColumn: Int = 4

    // Flagpole position (columns from end)
    var flagpoleColumnsFromEnd: Int = 5
}

class LevelGenerator {
    private var config: LevelGeneratorConfig
    private var grid: [[Character]]
    private var waterGapPositions: [(start: Int, end: Int)] = []
    private var pipePositions: [Int] = []
    private var occupiedColumns: Set<Int> = []

    init(config: LevelGeneratorConfig = LevelGeneratorConfig()) {
        self.config = config
        self.grid = Array(repeating: Array(repeating: "-", count: config.width), count: config.height)
    }

    func generate(difficulty: Int = 1) -> [[Character]] {
        // Reset state
        grid = Array(repeating: Array(repeating: "-", count: config.width), count: config.height)
        waterGapPositions = []
        pipePositions = []
        occupiedColumns = []

        // Scale difficulty
        let scaledConfig = scaleDifficulty(difficulty)
        config = scaledConfig

        // Build level in order (dependencies matter)
        buildGround()
        placeWaterGaps()
        placePlatformsAboveWater()
        placePipes()
        placePlayer()
        placeFlagpole()
        placeEnemies()
        placeQuestionBlocks()
        placeCoins()

        return grid
    }

    private func scaleDifficulty(_ level: Int) -> LevelGeneratorConfig {
        var c = config

        // More enemies at higher levels
        c.goombaCount = min(1 + level, 5)
        c.turtleCount = min(level / 2, 3)

        // More/wider water gaps
        c.waterGapCount = min(1 + level / 2, 4)
        c.maxWaterGapWidth = min(2 + level / 2, 4)

        // Fewer power-ups at higher levels
        c.mushroomCount = max(2 - level / 3, 1)
        c.starCount = level >= 3 ? 1 : 0

        // More coins at higher levels (reward)
        c.coinArcCount = min(2 + level / 2, 5)
        c.scatteredCoinCount = min(3 + level, 8)

        return c
    }

    // MARK: - Ground

    private func buildGround() {
        let groundRow = config.height - 2  // Second to last row
        let solidRow = config.height - 1   // Last row

        for col in 0..<config.width {
            grid[groundRow][col] = "G"
            grid[solidRow][col] = "#"
        }
    }

    // MARK: - Water Gaps

    private func placeWaterGaps() {
        let groundRow = config.height - 2
        let solidRow = config.height - 1

        // Calculate valid range for water gaps
        let minCol = config.safeZoneFromStart + 10
        let maxCol = config.width - config.safeZoneBeforeEnd - 10
        let availableSpace = maxCol - minCol

        guard availableSpace > 0 && config.waterGapCount > 0 else { return }

        // Distribute water gaps evenly
        let spacing = availableSpace / (config.waterGapCount + 1)

        for i in 0..<config.waterGapCount {
            let centerCol = minCol + spacing * (i + 1)
            let gapWidth = Int.random(in: config.minWaterGapWidth...config.maxWaterGapWidth)
            let startCol = centerCol - gapWidth / 2
            let endCol = startCol + gapWidth - 1

            // Place water
            for col in startCol...endCol {
                if col >= 0 && col < config.width {
                    grid[groundRow][col] = "W"
                    grid[solidRow][col] = "W"
                    occupiedColumns.insert(col)
                }
            }

            waterGapPositions.append((startCol, endCol))
        }
    }

    // MARK: - Platforms Above Water

    private func placePlatformsAboveWater() {
        let platformRow = config.height - 2 - config.platformHeightAboveGround

        for gap in waterGapPositions {
            // Place bricks directly above water gap, extending a bit on each side
            let startCol = max(0, gap.start - 1)
            let endCol = min(config.width - 1, gap.end + config.platformWidth)

            for col in startCol...endCol {
                if platformRow >= 0 && platformRow < config.height {
                    grid[platformRow][col] = "B"
                }
            }
        }
    }

    // MARK: - Pipes

    private func placePipes() {
        let groundRow = config.height - 2

        // Find valid positions for pipes (not near water, not near start/end)
        var validPositions: [Int] = []

        for col in config.safeZoneFromStart..<(config.width - config.safeZoneBeforeEnd - 3) {
            // Check if far enough from water
            var nearWater = false
            for gap in waterGapPositions {
                if col >= gap.start - config.minDistanceFromWater && col <= gap.end + config.minDistanceFromWater {
                    nearWater = true
                    break
                }
            }

            // Check if far enough from other pipes
            var nearPipe = false
            for pipeCol in pipePositions {
                if abs(col - pipeCol) < config.minDistanceBetweenPipes {
                    nearPipe = true
                    break
                }
            }

            if !nearWater && !nearPipe && !occupiedColumns.contains(col) {
                validPositions.append(col)
            }
        }

        // Place pipes
        for _ in 0..<config.pipeCount {
            guard !validPositions.isEmpty else { break }

            let idx = Int.random(in: 0..<validPositions.count)
            let col = validPositions[idx]
            let pipeHeight = Int.random(in: config.minPipeHeight...config.maxPipeHeight)

            // Place pipe top
            let topRow = groundRow - pipeHeight
            if topRow >= 0 {
                grid[topRow][col] = "["
                grid[topRow][col + 1] = "]"
            }

            // Place pipe body - column must align with '['
            for row in (topRow + 1)..<groundRow {
                grid[row][col] = "P"
                grid[row][col + 1] = "|"
            }

            pipePositions.append(col)
            occupiedColumns.insert(col)
            occupiedColumns.insert(col + 1)

            // Remove nearby positions from valid list
            validPositions.removeAll { abs($0 - col) < config.minDistanceBetweenPipes }
        }
    }

    // MARK: - Player

    private func placePlayer() {
        let playerRow = config.height - 3  // One row above ground
        grid[playerRow][config.playerStartColumn] = "@"
    }

    // MARK: - Flagpole

    private func placeFlagpole() {
        let flagpoleRow = config.height - 3
        let flagpoleCol = config.width - config.flagpoleColumnsFromEnd
        grid[flagpoleRow][flagpoleCol] = ">"
    }

    // MARK: - Enemies

    private func placeEnemies() {
        let enemyRow = config.height - 3  // Row above ground
        var enemyPositions: [Int] = []

        // Calculate valid range
        let minCol = config.minEnemyDistanceFromStart
        let maxCol = config.width - config.safeZoneBeforeEnd - 5

        // Place goombas
        for _ in 0..<config.goombaCount {
            if let col = findValidEnemyPosition(min: minCol, max: maxCol, existing: enemyPositions) {
                grid[enemyRow][col] = "g"
                enemyPositions.append(col)
            }
        }

        // Place turtles (ice type "T")
        for _ in 0..<config.turtleCount {
            if let col = findValidEnemyPosition(min: minCol, max: maxCol, existing: enemyPositions) {
                grid[enemyRow][col] = "T"
                enemyPositions.append(col)
            }
        }
    }

    private func findValidEnemyPosition(min: Int, max: Int, existing: [Int]) -> Int? {
        var attempts = 0
        while attempts < 50 {
            let col = Int.random(in: min..<max)

            // Check distance from other enemies
            var valid = true
            for pos in existing {
                if abs(col - pos) < config.minDistanceBetweenEnemies {
                    valid = false
                    break
                }
            }

            // Check not in water or occupied
            if valid && !occupiedColumns.contains(col) {
                // Check not on pipe
                var onPipe = false
                for pipeCol in pipePositions {
                    if col == pipeCol || col == pipeCol + 1 {
                        onPipe = true
                        break
                    }
                }
                if !onPipe {
                    return col
                }
            }

            attempts += 1
        }
        return nil
    }

    // MARK: - Question Blocks

    private func placeQuestionBlocks() {
        let blockRows = [3, 5]  // Upper area rows for blocks
        var blockPositions: [(row: Int, col: Int)] = []

        // Place mushroom block first (early in level)
        if config.mushroomCount > 0 {
            let col = config.safeZoneFromStart + Int.random(in: 5...15)
            let row = blockRows.randomElement()!
            grid[row][col] = "M"
            blockPositions.append((row, col))
        }

        // Place fire flower (mid-level)
        if config.fireFlowerCount > 0 {
            let col = config.width / 2 + Int.random(in: -10...10)
            let row = blockRows.randomElement()!
            if isValidBlockPosition(row: row, col: col, existing: blockPositions) {
                grid[row][col] = "F"
                blockPositions.append((row, col))
            }
        }

        // Place star (if configured)
        if config.starCount > 0 {
            let col = config.width / 3 + Int.random(in: -5...5)
            let row = blockRows.randomElement()!
            if isValidBlockPosition(row: row, col: col, existing: blockPositions) {
                grid[row][col] = "S"
                blockPositions.append((row, col))
            }
        }

        // Place dollar burst
        if config.dollarBurstCount > 0 {
            let col = config.width / 2 + Int.random(in: 5...20)
            let row = blockRows.randomElement()!
            if isValidBlockPosition(row: row, col: col, existing: blockPositions) {
                grid[row][col] = "$"
                blockPositions.append((row, col))
            }
        }

        // Place regular question blocks
        for _ in 0..<config.questionBlockCount {
            var attempts = 0
            while attempts < 30 {
                let col = Int.random(in: config.safeZoneFromStart..<(config.width - config.safeZoneBeforeEnd))
                let row = blockRows.randomElement()!

                if isValidBlockPosition(row: row, col: col, existing: blockPositions) {
                    grid[row][col] = "?"
                    blockPositions.append((row, col))
                    break
                }
                attempts += 1
            }
        }
    }

    private func isValidBlockPosition(row: Int, col: Int, existing: [(row: Int, col: Int)]) -> Bool {
        // Check distance from other blocks
        for pos in existing {
            if abs(col - pos.col) < config.minDistanceBetweenBlocks && pos.row == row {
                return false
            }
        }

        // Check not occupied
        if grid[row][col] != "-" {
            return false
        }

        return true
    }

    // MARK: - Coins

    private func placeCoins() {
        let coinRow = 6  // Mid-height for coin arcs
        var coinPositions: [Int] = []

        // Place coin arcs
        let arcSpacing = (config.width - config.safeZoneFromStart - config.safeZoneBeforeEnd) / (config.coinArcCount + 1)

        for i in 0..<config.coinArcCount {
            let startCol = config.safeZoneFromStart + arcSpacing * (i + 1)

            for j in 0..<config.coinsPerArc {
                let col = startCol + j * config.coinArcSpacing
                if col < config.width - config.safeZoneBeforeEnd && grid[coinRow][col] == "-" {
                    grid[coinRow][col] = "C"
                    coinPositions.append(col)
                }
            }
        }

        // Place scattered coins at different heights
        let scatterRows = [4, 5, 7, 8]
        for _ in 0..<config.scatteredCoinCount {
            var attempts = 0
            while attempts < 20 {
                let col = Int.random(in: config.safeZoneFromStart..<(config.width - config.safeZoneBeforeEnd))
                let row = scatterRows.randomElement()!

                if grid[row][col] == "-" && !coinPositions.contains(col) {
                    grid[row][col] = "C"
                    coinPositions.append(col)
                    break
                }
                attempts += 1
            }
        }
    }

    // MARK: - Utility

    func printLevel() {
        for row in grid {
            print(String(row))
        }
    }

    func getTiles() -> [[Character]] {
        return grid
    }
}
