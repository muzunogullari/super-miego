import Foundation

struct Level1 {
    static var tiles: [[Character]] {
        let generator = LevelGenerator()
        return generator.generate(difficulty: 1)
    }

    static func getData() -> LevelData {
        let loader = LevelLoader()
        return loader.loadLevel(from: tiles)
    }
}

struct Level2 {
    static var tiles: [[Character]] {
        let generator = LevelGenerator()
        return generator.generate(difficulty: 2)
    }

    static func getData() -> LevelData {
        let loader = LevelLoader()
        return loader.loadLevel(from: tiles)
    }
}

struct Level3 {
    static var tiles: [[Character]] {
        let generator = LevelGenerator()
        return generator.generate(difficulty: 3)
    }

    static func getData() -> LevelData {
        let loader = LevelLoader()
        return loader.loadLevel(from: tiles)
    }
}

struct Level4 {
    static var tiles: [[Character]] {
        let generator = LevelGenerator()
        return generator.generate(difficulty: 4)
    }

    static func getData() -> LevelData {
        let loader = LevelLoader()
        return loader.loadLevel(from: tiles)
    }
}

struct Level5 {
    static var tiles: [[Character]] {
        let generator = LevelGenerator()
        return generator.generate(difficulty: 5)
    }

    static func getData() -> LevelData {
        let loader = LevelLoader()
        return loader.loadLevel(from: tiles)
    }
}

// Level manager to get level data by number
struct LevelManager {
    static let totalLevels = 5

    static func getData(for level: Int) -> LevelData {
        let generator = LevelGenerator()
        let tiles = generator.generate(difficulty: level)
        let loader = LevelLoader()
        return loader.loadLevel(from: tiles)
    }
}
