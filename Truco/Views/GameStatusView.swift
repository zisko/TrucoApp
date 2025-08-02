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
            switch gameState.trucoState {
            case .none:
                EmptyView()
            case let .called(caller):
                Text("Truco called by \(gameState.players.first(where: { $0.id == caller })?.name ?? "")")
                    .font(.headline)
                    .foregroundColor(.orange)
            case let .accepted(caller):
                Text("Truco accepted by \(gameState.players.first(where: { $0.id != caller })?.name ?? "")")
                    .font(.headline)
                    .foregroundColor(.orange)
            case let .retrucoCalled(caller):
                Text("Retruco called by \(gameState.players.first(where: { $0.id == caller })?.name ?? "")")
                    .font(.headline)
                    .foregroundColor(.orange)
            case let .retrucoAccepted(caller):
                Text("Retruco accepted by \(gameState.players.first(where: { $0.id != caller })?.name ?? "")")
                    .font(.headline)
                    .foregroundColor(.orange)
            case let .valeCuatroCalled(caller):
                Text("Vale Cuatro called by \(gameState.players.first(where: { $0.id == caller })?.name ?? "")")
                    .font(.headline)
                    .foregroundColor(.orange)
            case let .valeCuatroAccepted(caller):
                Text("Vale Cuatro accepted by \(gameState.players.first(where: { $0.id != caller })?.name ?? "")")
                    .font(.headline)
                    .foregroundColor(.orange)
            case let .rejected(caller):
                Text("Truco rejected by \(gameState.players.first(where: { $0.id != caller })?.name ?? "")")
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
