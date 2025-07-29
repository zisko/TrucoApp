@testable import TrucoKit
import XCTest

class TrucoEngineTestHelper {
    var engine: TrucoEngine!
    var gameState: GameState!

    var player1: Player {
        return gameState.players[0]
    }

    var player2: Player {
        return gameState.players[1]
    }

    @discardableResult
    func createNewGame(player1Hand: [Card], player2Hand: [Card]) -> GameState {
        let state = GameState()
        gameState = state
        engine = TrucoEngine(gameState: state)

        let player1Id = UUID()
        let player2Id = UUID()

        state.players = [
            Player(id: player1Id, name: "Player 1", hand: player1Hand, score: 0),
            Player(id: player2Id, name: "Player 2", hand: player2Hand, score: 0),
        ]

        state.manoPlayerId = player1Id
        state.currentPlayerIndex = 0
        state.gamePhase = .playing

        return state
    }
}
