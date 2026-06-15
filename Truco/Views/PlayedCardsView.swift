import SwiftUI
import TrucoKit

struct PlayedCardsView: View {
    let playedCards: [PlayedCardInfo]
    var localPlayerId: UUID?

    var body: some View {
        HStack(spacing: 18) {
            if playedCards.isEmpty {
                placeholder
                placeholder
            } else {
                ForEach(playedCards) { played in
                    VStack(spacing: 6) {
                        PlayingCardView(card: played.card)
                            .frame(width: 70)
                        Text(label(for: played.player))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.cream.opacity(0.9))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.gold.opacity(0.18), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playedCards.count)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(Theme.cream.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .frame(width: 70)
    }

    private func label(for id: UUID) -> String {
        guard let localPlayerId else { return "" }
        return PlayerNaming.displayName(for: id, localPlayerId: localPlayerId)
    }
}
