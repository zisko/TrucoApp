import Foundation

/// Protocol that defines the interface for Truco game engines.
/// This allows easy swapping between different engine implementations.
public protocol TrucoGameEngine {
    var gameState: GameState { get }

    /// Deals initial cards to players
    func dealInitialCards(player1Id: UUID, player2Id: UUID)

    /// Handles a game move
    func handle(move: GameMove)

    /// Starts a new round
    func startNewRound()

    /// Makes an opponent move (for CPU player)
    func makeOpponentMove()

    /// Checks if the match has ended
    func checkMatchEnd()
}

// MARK: - Protocol Extensions for Enhanced Error Handling

extension TrucoGameEngine {
    /// Enhanced handle method that returns errors (for engines that support it)
    func handle(move: GameMove) -> StateMachineError? {
        handle(move: move)
        return nil // Default implementation assumes no errors
    }
}
