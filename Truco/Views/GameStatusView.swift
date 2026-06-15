import SwiftUI
import TrucoKit

struct GameStatusView: View {
    let gameState: GameState
    let localPlayerId: UUID

    var isLocalPlayerTurn: Bool {
        guard !gameState.players.isEmpty else { return false }
        return gameState.players[gameState.currentPlayerIndex].id == localPlayerId
    }

    private var trucoCallerName: String {
        gameState.players.first(where: { $0.id == gameState.trucoCallerId })?.name ?? ""
    }

    var body: some View {
        VStack {
            // Turn Indicator
            Text(isLocalPlayerTurn ? "Your Turn" : "Opponent's Turn")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 2)

            // Truco and Envido Status
            switch gameState.trucoState {
            case .none:
                EmptyView()
            case .trucoCalled:
                Text("Truco called by \(trucoCallerName)")
                    .font(.headline)
                    .foregroundColor(.orange)
            case .retrucoCalled:
                Text("Retruco called by \(trucoCallerName)")
                    .font(.headline)
                    .foregroundColor(.orange)
            case .valeCuatroCalled:
                Text("Vale Cuatro called by \(trucoCallerName)")
                    .font(.headline)
                    .foregroundColor(.orange)
            case .accepted:
                Text("Truco accepted (\(gameState.trucoPoints) pts)")
                    .font(.headline)
                    .foregroundColor(.orange)
            case .rejected:
                Text("Truco rejected")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            // Show Envido state independently
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
