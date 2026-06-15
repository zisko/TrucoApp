import SwiftUI
import TrucoKit

struct PlayingCardView: View {
    let card: Card
    var isHighlighted: Bool = false
    var onTap: (() -> Void)? = nil

    private var suitImageName: String {
        switch card.suit {
        case .oros: return "suit-oros"
        case .copas: return "suit-copas"
        case .espadas: return "suit-espadas"
        case .bastos: return "suit-bastos"
        }
    }

    var body: some View {
        ZStack {
            // Layer 1: Card Background
            Image("card-background")
                .resizable()
                .aspectRatio(contentMode: .fit)

            // Layer 2: Card Content (Rank and Suit)
            VStack {
                HStack {
                    CornerLabel(rank: card.rank.description, suitImageName: suitImageName)
                    Spacer()
                }
                Spacer()
                Image(suitImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                Spacer()
                HStack {
                    Spacer()
                    CornerLabel(rank: card.rank.description, suitImageName: suitImageName)
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(8)
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHighlighted ? Theme.gold : Color.black.opacity(0.15),
                        lineWidth: isHighlighted ? 3 : 1)
        )
        .shadow(color: isHighlighted ? Theme.gold.opacity(0.6) : .black.opacity(0.3),
                radius: isHighlighted ? 10 : 4, x: 0, y: isHighlighted ? 0 : 3)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture { onTap?() }
    }
}

/// A face-down card, used for the opponent's hidden hand.
struct CardBackView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0x7A1F1F), Color(hex: 0x4E1212)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Theme.gold.opacity(0.55), lineWidth: 1.5)
                    .padding(5)
            )
            .overlay(
                Image(systemName: "seal.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.gold.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black.opacity(0.25), lineWidth: 1)
            )
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 3)
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
    HStack {
        PlayingCardView(card: Card(rank: .ace, suit: .espadas), isHighlighted: true)
            .frame(width: 100, height: 150)
        PlayingCardView(card: Card(rank: .twelve, suit: .copas))
            .frame(width: 100, height: 150)
        CardBackView()
            .frame(width: 100, height: 150)
    }
    .padding()
    .background(Theme.feltBottom)
}
