import SwiftUI
import TrucoKit

struct HandOutcomeView: View {
    let outcome: HandOutcome
    let players: [Player]
    var onContinue: () -> Void

    private func playerName(for id: UUID) -> String {
        return players.first(where: { $0.id == id })?.name ?? "Unknown Player"
    }

    private var outcomeDescription: String {
        guard let winnerId = outcome.winnerId,
              let winningCard = outcome.winningCard,
              let losingCard = outcome.losingCard else {
            return "It's a tie!"
        }
        
        let winnerName = playerName(for: winnerId)
        return "\(winnerName) wins with \(winningCard.rank.description) of \(winningCard.suit.rawValue) against \(losingCard.rank.description) of \(losingCard.suit.rawValue)."
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Hand Over")
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 30) {
                if let winningCard = outcome.winningCard {
                    VStack {
                        Text("Winner")
                            .font(.headline)
                        PlayingCardView(card: winningCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 4)
                            )
                    }
                }
                
                if let losingCard = outcome.losingCard {
                    VStack {
                        Text("Loser")
                            .font(.headline)
                        PlayingCardView(card: losingCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 4)
                            )
                    }
                }
            }

            Text(outcomeDescription)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()

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
