import Foundation

/// Configuration for choosing between different game engine implementations.
///
/// The project now ships a single engine (`TrucoEngineRefactored`) built on the
/// explicit state-machine framework. The enum is retained for call-site
/// compatibility; every case maps to that engine.
public enum GameEngineType {
    case refactored // Uses the explicit state machine framework
}

/// Factory for creating game engines.
public enum GameEngineFactory {
    /// Creates a game engine of the specified type.
    public static func createEngine(type _: GameEngineType = .refactored, gameState: GameState) -> TrucoGameEngine {
        return TrucoEngineRefactored(gameState: gameState)
    }

    /// Creates the default (and currently only) engine.
    public static func createDefaultEngine(gameState: GameState) -> TrucoGameEngine {
        return createEngine(gameState: gameState)
    }
}
