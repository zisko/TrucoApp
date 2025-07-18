import SwiftUI
import TrucoKit

struct HandView: View {
    let cards: [Card]
    var onCardTap: ((Card) -> Void)? = nil

    var body: some View {
        HStack {
            ForEach(cards) { card in
                CardView(card: card) {
                    onCardTap?(card)
                }
            }
        }
    }
}
