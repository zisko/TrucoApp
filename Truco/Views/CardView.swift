import SwiftUI
import TrucoKit

struct CardView: View {
    let card: Card
    var onTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 60, height: 90)
                .shadow(radius: 3)

            VStack {
                Text(card.rank.description)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(card.suit.rawValue.prefix(1).uppercased())
                    .font(.caption2)
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
}
