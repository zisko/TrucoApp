import SwiftUI
import TrucoKit

struct PlayedCardsView: View {
    let playedCards: [PlayedCardInfo]

    var body: some View {
        HStack {
            ForEach(playedCards) { playedCard in
                VStack {
                    Text(playedCard.player.uuidString.prefix(4))
                        .font(.caption2)
                    PlayingCardView(card: playedCard.card)
                        .frame(width: 60, height: 90)
                }
            }
        }
    }
}
