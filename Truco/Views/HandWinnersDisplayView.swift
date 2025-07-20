import SwiftUI
import TrucoKit

struct HandWinnersDisplayView: View {
    let handWinners: [UUID?]
    let handWinningCards: [Card?]
    let players: [Player]

    private func playerName(for id: UUID) -> String {
        return players.first(where: { $0.id == id })?.name ?? "Unknown Player"
    }

    var body: some View {
        VStack {
            Text("Hand Winners:")
                .font(.subheadline)

            ForEach(handWinners.indices, id: \.self) { index in
                HStack {
                    if let winnerId = handWinners[index] {
                        Text("Hand \(index + 1): \(playerName(for: winnerId))")
                    } else {
                        Text("Hand \(index + 1): Tie")
                    }

                    if let winningCard = handWinningCards[index] {
                        ZStack {
                            // Background card (if any)
                            if index > 0, let prevWinningCard = handWinningCards[index - 1] {
                                CardView(card: prevWinningCard)
                                    .frame(width: 30, height: 45) // Tiny size
                                    .rotationEffect(.degrees(-10)) // Slight rotation for overlapping effect
                                    .offset(x: -10) // Overlap
                            }
                            // Winning card on top
                            CardView(card: winningCard)
                                .frame(width: 30, height: 45) // Tiny size
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.brown.opacity(0.3)) // Card table like background
        .cornerRadius(10)
        .padding() // Inset from edges
    }
}

#Preview {
    let player1 = Player(id: UUID(), name: "Alice", hand: [], score: 0)
    let player2 = Player(id: UUID(), name: "Bob", hand: [], score: 0)

    let card1 = Card(rank: .ace, suit: .espadas)
    let card2 = Card(rank: .twelve, suit: .copas)

    HandWinnersDisplayView(
        handWinners: [player1.id, player2.id, nil],
        handWinningCards: [card1, card2, nil],
        players: [player1, player2]
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
