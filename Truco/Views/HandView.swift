import SwiftUI
import TrucoKit

struct HandView: View {
    let cards: [Card]
    var onCardTap: ((Card) -> Void)? = nil

    var body: some View {
        HStack {
            ForEach(cards) { card in
                PlayingCardView(card: card) {
                    onCardTap?(card)
                }
                .frame(width: 60, height: 90)
            }
        }
    }
}
