import SwiftUI
import TrucoKit

struct CardView: View {
    let card: Card
    var onTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .stroke(Color.gray, lineWidth: 1)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

            VStack {
                // Top-left corner
                HStack {
                    VStack {
                        Text(card.rank.description)
                            .font(.headline)
                            .fontWeight(.bold)
                        Image(systemName: card.suitSymbolName)
                            .font(.subheadline)
                    }
                    .foregroundColor(card.suitColor)
                    Spacer()
                }
                .padding(8)

                Spacer()

                // Center content
                ViewThatFits {
                    VStack {
                        Image(systemName: card.suitSymbolName)
                            .font(.system(size: 40))
                            .foregroundColor(card.suitColor)
                        if card.rank.rawValue >= 10 {
                            Text(card.rank.description)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                    }
                    Image(systemName: card.suitSymbolName)
                        .font(.system(size: 20))
                        .foregroundColor(card.suitColor)
                }

                Spacer()

                // Bottom-right corner (rotated)
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: card.suitSymbolName)
                            .font(.subheadline)
                        Text(card.rank.description)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(card.suitColor)
                }
                .padding(8)
                .rotationEffect(.degrees(180))
            }
        }
        .frame(width: 80, height: 120)
        .onTapGesture {
            onTap?()
        }
    }
}

extension Card {
    var suitColor: Color {
        switch suit {
        case .oros: return .yellow
        case .copas: return .red
        case .espadas: return .blue
        case .bastos: return .green
        }
    }

    var suitSymbolName: String {
        switch suit {
        case .oros: return "sun.max.fill"
        case .copas: return "cup.fill"
        case .espadas: return "scissors" // Using scissors as a proxy for swords
        case .bastos: return "leaf.fill" // Using leaf as a proxy for clubs
        }
    }
}

#Preview {
    VStack {
        HStack {
            CardView(card: Card(rank: .ace, suit: .espadas))
            CardView(card: Card(rank: .seven, suit: .oros))
            CardView(card: Card(rank: .twelve, suit: .copas))
            CardView(card: Card(rank: .three, suit: .bastos))
        }
        .padding()
    }
}