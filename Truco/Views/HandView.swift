import SwiftUI
import TrucoKit

struct HandView: View {
    let cards: [Card]
    var faceDown: Bool = false
    var highlighted: Bool = false
    var cardWidth: CGFloat = 64
    var onCardTap: ((Card) -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            if faceDown {
                ForEach(cards) { card in
                    CardBackView()
                        .frame(width: cardWidth)
                        .id(card.id)
                }
            } else {
                ForEach(cards) { card in
                    PlayingCardView(card: card, isHighlighted: highlighted) {
                        onCardTap?(card)
                    }
                    .frame(width: cardWidth)
                    .offset(y: highlighted ? -4 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: highlighted)
                }
            }
        }
    }
}
