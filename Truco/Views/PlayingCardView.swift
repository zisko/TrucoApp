import SwiftUI
import TrucoKit

struct PlayingCardView: View {
    let card: Card
    var onTap: (() -> Void)? = nil

    private var suitImageName: String {
        switch card.suit {
        case .oros:
            return "suit-oros"
        case .copas:
            return "suit-copas"
        case .espadas:
            return "suit-espadas"
        case .bastos:
            return "suit-bastos"
        }
    }

    var body: some View {
        ZStack {
            // Layer 1: Card Background
            Image("card-background")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(radius: 3)

            // Layer 2: Card Content (Rank and Suit)
            VStack {
                HStack {
                    CornerLabel(
                        rank: card.rank.description,
                        suitImageName: suitImageName
                    )
                    Spacer()
                }
                Spacer()
                // Future: Add logic here for center pips or face card art
                Image(suitImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                Spacer()
                HStack {
                    Spacer()
                    CornerLabel(
                        rank: card.rank.description,
                        suitImageName: suitImageName
                    )
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(8)
        }
        // lock the aspect ratio so the cards never look wonky.
        .aspectRatio(contentMode: .fit)
        .onTapGesture {
            onTap?()
        }
    }
}

// A helper view for the corner labels of the card
struct CornerLabel: View {
    let rank: String
    let suitImageName: String

    var body: some View {
        VStack(spacing: 2) {
            Text(rank)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            Image(suitImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 15, height: 15)
        }
    }
}

#Preview {
    VStack {
        PlayingCardView(card: Card(rank: .ace, suit: .espadas))
            .frame(width: 100, height: 150)
    }.frame(width: 200, height: 850)
    HStack {
        PlayingCardView(card: Card(rank: .ace, suit: .espadas))
            .frame(width: 100, height: 150)
        PlayingCardView(card: Card(rank: .ace, suit: .copas))
            .frame(width: 100, height: 150)
        PlayingCardView(card: Card(rank: .ace, suit: .oros))
            .frame(width: 100, height: 150)
        PlayingCardView(card: Card(rank: .five, suit: .bastos))
            .frame(width: 100, height: 150)
    }
}
