import Foundation

/// Configuration for choosing between different game engine implementations
public enum GameEngineType {
    case original // Uses implicit state management
    case refactored // Uses explicit state machine framework
}

/// Factory class for creating game engines
public class GameEngineFactory {
    /// Creates a game engine of the specified type
    /// - Parameters:
    ///   - type: The type of engine to create
    ///   - gameState: The initial game state
    /// - Returns: A configured game engine
    public static func createEngine(type: GameEngineType, gameState: GameState) -> TrucoGameEngine {
        switch type {
        case .original:
            return TrucoEngine(gameState: gameState)
        case .refactored:
            return TrucoEngineRefactored(gameState: gameState)
        }
    }

    /// Creates the default engine (currently the original for backward compatibility)
    /// - Parameter gameState: The initial game state
    /// - Returns: A configured game engine
    public static func createDefaultEngine(gameState: GameState) -> TrucoGameEngine {
        return createEngine(type: .original, gameState: gameState)
    }

    /// Creates the recommended engine (the refactored one with state machine)
    /// - Parameter gameState: The initial game state
    /// - Returns: A configured game engine
    public static func createRecommendedEngine(gameState: GameState) -> TrucoGameEngine {
        return createEngine(type: .refactored, gameState: gameState)
    }
}
