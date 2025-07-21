import SwiftUI
import TrucoKit

struct HandWinnersDisplayView: View {
    let handOutcomes: [HandOutcome]
    let players: [Player]

    private func playerName(for id: UUID) -> String {
        return players.first(where: { $0.id == id })?.name ?? "Unknown Player"
    }

    var body: some View {
        VStack {
            Text("Hand Results:")
                .font(.subheadline)

            ForEach(handOutcomes.indices, id: \.self) { index in
                let outcome = handOutcomes[index]
                HStack {
                    if let winnerId = outcome.winnerId {
                        Text("Hand \(index + 1): \(playerName(for: winnerId))")
                    } else {
                        Text("Hand \(index + 1): Tie")
                    }

                    ZStack {
                        if let losingCard = outcome.losingCard {
                            CardView(card: losingCard)
                                .frame(width: 30, height: 45)
                                .rotationEffect(.degrees(-5))
                                .offset(x: -10)
                        }
                        if let winningCard = outcome.winningCard {
                            CardView(card: winningCard)
                                .frame(width: 30, height: 45)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.brown.opacity(0.3))
        .cornerRadius(10)
        .padding()
    }
}

#Preview {
    let player1 = Player(id: UUID(), name: "Alice", hand: [], score: 0)
    let player2 = Player(id: UUID(), name: "Bob", hand: [], score: 0)

    let card1 = Card(rank: .ace, suit: .espadas)
    let card2 = Card(rank: .twelve, suit: .copas)
    let card3 = Card(rank: .three, suit: .bastos)
    let card4 = Card(rank: .seven, suit: .oros)

    HandWinnersDisplayView(
        handOutcomes: [
            HandOutcome(winnerId: player1.id, winningCard: card1, losingCard: card2),
            HandOutcome(winnerId: player2.id, winningCard: card4, losingCard: card3),
            HandOutcome(winnerId: nil, winningCard: card1, losingCard: card1) // Tie example
        ],
        players: [player1, player2]
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
