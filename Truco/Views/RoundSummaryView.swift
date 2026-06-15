import SwiftUI
import TrucoKit

struct RoundSummaryView: View {
    let gameState: GameState
    var localPlayerId: UUID?
    var onStartNewRound: () -> Void

    private var roundWinnerName: String {
        guard let winnerId = gameState.roundWinner else { return "No one" }
        guard let localPlayerId else {
            return gameState.players.first(where: { $0.id == winnerId })?.name ?? "No one"
        }
        return PlayerNaming.displayName(for: winnerId, localPlayerId: localPlayerId)
    }

    private var pointsBreakdown: [(label: String, value: String)] {
        var breakdown = [(String, String)]()

        switch gameState.trucoState {
        case .none:
            breakdown.append(("Round Winner", "+1"))
        case .accepted:
            let label = gameState.trucoPoints >= 4 ? "Vale Cuatro"
                : (gameState.trucoPoints == 3 ? "Retruco" : "Truco")
            breakdown.append((label, "+\(gameState.trucoPoints)"))
        case .rejected:
            breakdown.append(("Truco Rejected", "+\(max(gameState.trucoPoints - 1, 1))"))
        default:
            break
        }

        if gameState.envidoState == .accepted {
            breakdown.append(("Envido", "+\(gameState.envidoPoints)"))
        } else if gameState.envidoState == .rejected {
            breakdown.append(("Envido Rejected", "+1"))
        }
        return breakdown
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("Round Over")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Theme.gold)

            Text("\(roundWinnerName) won the round!")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.cream)

            VStack(alignment: .leading, spacing: 10) {
                Text("Points Awarded")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.cream.opacity(0.8))
                ForEach(pointsBreakdown, id: \.label) { item in
                    HStack {
                        Text(item.label)
                        Spacer()
                        Text(item.value).fontWeight(.bold).foregroundStyle(Theme.gold)
                    }
                    .font(.callout)
                    .foregroundStyle(Theme.cream)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.2)))

            Button("Next Round", action: onStartNewRound)
                .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: 420)
        .glassPanel()
    }
}
