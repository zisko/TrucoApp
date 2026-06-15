import SwiftUI
import TrucoKit

struct HandOutcomeView: View {
    let outcome: HandOutcome
    let players: [Player]
    var localPlayerId: UUID?
    var onContinue: () -> Void

    private func playerName(for id: UUID) -> String {
        guard let localPlayerId else {
            return players.first(where: { $0.id == id })?.name ?? "—"
        }
        return PlayerNaming.displayName(for: id, localPlayerId: localPlayerId)
    }

    private var outcomeDescription: String {
        guard let winnerId = outcome.winnerId,
              let winningCard = outcome.winningCard,
              let losingCard = outcome.losingCard
        else {
            return "It's a tie!"
        }
        let winnerName = playerName(for: winnerId)
        return "\(winnerName) won with the \(winningCard.rank.description) of \(winningCard.suit.rawValue.capitalized) over the \(losingCard.rank.description) of \(losingCard.suit.rawValue.capitalized)."
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Trick Over")
                .font(.title.weight(.heavy))
                .foregroundStyle(Theme.gold)

            HStack(spacing: 24) {
                if let winningCard = outcome.winningCard {
                    cardColumn(title: "Winner", card: winningCard, tint: Theme.positive)
                }
                if let losingCard = outcome.losingCard {
                    cardColumn(title: "Loser", card: losingCard, tint: Theme.danger)
                }
            }

            Text(outcomeDescription)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.cream.opacity(0.9))

            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: 420)
        .glassPanel()
    }

    private func cardColumn(title: String, card: Card, tint: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            PlayingCardView(card: card)
                .frame(width: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(tint, lineWidth: 3)
                )
        }
    }
}
