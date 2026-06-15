import SwiftUI
import TrucoKit

struct EnvidoSummaryView: View {
    let gameState: GameState
    var localPlayerId: UUID?
    var onContinue: () -> Void

    private func displayName(for id: UUID?) -> String {
        guard let id else { return "No one" }
        guard let localPlayerId else {
            return gameState.players.first(where: { $0.id == id })?.name ?? "—"
        }
        return PlayerNaming.displayName(for: id, localPlayerId: localPlayerId)
    }

    private var winnerName: String { displayName(for: gameState.envidoWinnerId) }

    var body: some View {
        VStack(spacing: 18) {
            Text("Envido Resolved")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(.purple)

            Text("\(winnerName) won \(gameState.envidoPoints) point\(gameState.envidoPoints == 1 ? "" : "s")!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.cream)

            VStack(spacing: 12) {
                if gameState.players.count > 0 {
                    envidoRow(
                        name: displayName(for: gameState.players[0].id),
                        hand: gameState.players[0].hand,
                        points: gameState.player1EnvidoPoints ?? 0,
                        isWinner: gameState.envidoWinnerId == gameState.players[0].id
                    )
                }
                if gameState.players.count > 1 {
                    envidoRow(
                        name: displayName(for: gameState.players[1].id),
                        hand: gameState.players[1].hand,
                        points: gameState.player2EnvidoPoints ?? 0,
                        isWinner: gameState.envidoWinnerId == gameState.players[1].id
                    )
                }
            }

            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryActionButtonStyle(tint: .purple))
        }
        .padding(24)
        .frame(maxWidth: 440)
        .glassPanel(accent: .purple)
    }

    private func envidoRow(name: String, hand: [Card], points: Int, isWinner: Bool) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(name).font(.headline).foregroundStyle(isWinner ? Theme.gold : Theme.cream)
                if isWinner { Image(systemName: "crown.fill").foregroundStyle(Theme.gold) }
                Spacer()
                Text("\(points)")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(isWinner ? Theme.gold : Theme.cream)
            }
            HandView(cards: hand, cardWidth: 44)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isWinner ? Theme.gold.opacity(0.6) : .clear, lineWidth: 1.5)
                )
        )
    }
}
