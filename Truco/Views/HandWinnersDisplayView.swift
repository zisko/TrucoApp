import SwiftUI
import TrucoKit

struct HandWinnersDisplayView: View {
    @Binding var isExpanded: Bool
    let handOutcomes: [HandOutcome]
    let players: [Player]
    var localPlayerId: UUID?

    private func playerName(for id: UUID) -> String {
        guard let localPlayerId else {
            return players.first(where: { $0.id == id })?.name ?? "—"
        }
        return PlayerNaming.displayName(for: id, localPlayerId: localPlayerId)
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "list.number")
                    Text("Trick Results")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(handOutcomes.count)/3")
                        .font(.caption).foregroundStyle(Theme.cream.opacity(0.7))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.2))
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    if handOutcomes.isEmpty {
                        Text("No tricks played yet.")
                            .font(.caption).foregroundStyle(Theme.cream.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(handOutcomes.indices, id: \.self) { index in
                        let outcome = handOutcomes[index]
                        HStack {
                            Text("Trick \(index + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.cream.opacity(0.85))
                            Spacer()
                            if let winnerId = outcome.winnerId {
                                Text(playerName(for: winnerId))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.gold)
                            } else {
                                Text("Tie")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.cream.opacity(0.7))
                            }
                            ZStack {
                                if let losingCard = outcome.losingCard {
                                    PlayingCardView(card: losingCard)
                                        .frame(width: 26)
                                        .rotationEffect(.degrees(-6))
                                        .offset(x: -10)
                                }
                                if let winningCard = outcome.winningCard {
                                    PlayingCardView(card: winningCard)
                                        .frame(width: 26)
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.14))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
