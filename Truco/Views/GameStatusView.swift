import SwiftUI
import TrucoKit

struct GameStatusView: View {
    let gameState: GameState
    let localPlayerId: UUID

    var isLocalPlayerTurn: Bool {
        guard !gameState.players.isEmpty else { return false }
        return gameState.players[gameState.currentPlayerIndex].id == localPlayerId
    }

    var body: some View {
        VStack {
            // Turn Indicator
            Text(isLocalPlayerTurn ? "Your Turn" : "Opponent's Turn")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 2)

            // Truco and Envido Status
            if gameState.trucoState != .none, gameState.trucoState != .accepted {
                Text("\(gameState.trucoState.rawValue.capitalized)!")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            if gameState.envidoState != .none, gameState.envidoState != .accepted, gameState.envidoState != .rejected {
                Text("\(gameState.envidoState.rawValue.capitalized)!")
                    .font(.headline)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
        .animation(.default, value: gameState.trucoState)
        .animation(.default, value: gameState.envidoState)
    }
}
