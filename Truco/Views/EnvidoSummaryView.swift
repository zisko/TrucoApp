import SwiftUI
import TrucoKit

struct EnvidoSummaryView: View {
    let gameState: GameState
    var onContinue: () -> Void

    private func playerName(for id: UUID) -> String {
        return gameState.players.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    private var winnerName: String {
        guard let winnerId = gameState.envidoWinnerId else { return "No one" }
        return playerName(for: winnerId)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Envido Resolved")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(winnerName) wins \(gameState.envidoPoints) points!")
                .font(.title)
                .foregroundColor(.green)

            VStack(spacing: 15) {
                // Player 1
                VStack {
                    Text("\(gameState.players[0].name)'s Hand")
                        .font(.headline)
                    HandView(cards: gameState.players[0].hand)
                    Text("Points: \(gameState.player1EnvidoPoints ?? 0)")
                        .font(.title2)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)

                // Player 2
                VStack {
                    Text("\(gameState.players[1].name)'s Hand")
                        .font(.headline)
                    HandView(cards: gameState.players[1].hand)
                    Text("Points: \(gameState.player2EnvidoPoints ?? 0)")
                        .font(.title2)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }

            Button("Continue") {
                onContinue()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(30)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
        .foregroundColor(.white)
        .shadow(radius: 20)
    }
}
