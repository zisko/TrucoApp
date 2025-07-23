import SwiftUI
import TrucoKit

struct RoundSummaryView: View {
    let gameState: GameState
    var onStartNewRound: () -> Void

    private var roundWinnerName: String {
        guard let winnerId = gameState.roundWinner,
              let winner = gameState.players.first(where: { $0.id == winnerId }) else {
            return "No one"
        }
        return winner.name
    }

    private var pointsBreakdown: [(label: String, value: String)] {
        var breakdown = [(String, String)]()
        
        // Round points (excluding truco)
        if gameState.trucoState == .none || gameState.trucoState == .rejected {
            breakdown.append(("Round Winner", "+1"))
        }
        
        // Truco points
        if gameState.trucoState == .accepted || gameState.trucoState == .retrucoCalled || gameState.trucoState == .valeCuatroCalled {
            let trucoLabel: String
            switch gameState.trucoState {
            case .retrucoCalled:
                trucoLabel = "Retruco"
            case .valeCuatroCalled:
                trucoLabel = "Vale Cuatro"
            default:
                trucoLabel = "Truco"
            }
            breakdown.append((trucoLabel, "+\(gameState.trucoPoints)"))
        } else if gameState.trucoState == .rejected {
            let points = (gameState.trucoPoints > 0) ? (gameState.trucoPoints - 1) : 1
            breakdown.append(("Truco Rejected", "+\(points)"))
        }
        
        // Envido points
        if gameState.envidoState == .accepted {
            breakdown.append(("Envido", "+\(gameState.envidoPoints)"))
        } else if gameState.envidoState == .rejected {
            breakdown.append(("Envido Rejected", "+1"))
        }
        
        return breakdown
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Round Over")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("\(roundWinnerName) wins the round!")
                .font(.title)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 10) {
                Text("Points Awarded:")
                    .font(.headline)
                
                ForEach(pointsBreakdown, id: \.label) { item in
                    HStack {
                        Text(item.label)
                        Spacer()
                        Text(item.value)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

            Button("Start Next Round") {
                onStartNewRound()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(30)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
        .foregroundColor(.white)
        .shadow(radius: 20)
    }
}
