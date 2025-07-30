import SwiftUI
import TrucoKit

struct ActiveBetView: View {
    let bet: ActiveBet
    let players: [Player]
    let gameState: GameState
    let localPlayerId: UUID
    @Binding var gameEngine: TrucoEngine

    private var callerName: String {
        players.first(where: { $0.id == bet.callerId })?.name ?? "Unknown Player"
    }

    private var betTypeDisplayName: String {
        switch bet.betType {
        case .truco:
            return "Truco"
        case .envido:
            return "Envido"
        case .realEnvido:
            return "Real Envido"
        case .faltaEnvido:
            return "Falta Envido"
        }
    }

    private var betColor: Color {
        switch bet.betType {
        case .truco:
            return .orange
        case .envido, .realEnvido, .faltaEnvido:
            return .purple
        }
    }

    // MARK: - Game Actions

    private var isLocalPlayerTurn: Bool {
        guard !gameState.players.isEmpty else { return false }
        return gameState.players[gameState.currentPlayerIndex].id == localPlayerId
    }

    func acceptEnvido() {
        gameEngine.handle(move: .acceptEnvido)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func rejectEnvido() {
        gameEngine.handle(move: .rejectEnvido)
    }

    func acceptTruco() {
        gameEngine.handle(move: .acceptTruco)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func rejectTruco() {
        gameEngine.handle(move: .rejectTruco)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Bet Type Badge
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(betColor)
                Text(betTypeDisplayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(betColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(betColor.opacity(0.2))
            .cornerRadius(20)

            // Caller Information
            VStack(spacing: 8) {
                Text("Called by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(callerName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // Points Display
            HStack {
                Text("Points at stake:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(bet.points)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(betColor)
            }

            // Decorative Elements
            HStack(spacing: 20) {
                ForEach(0 ..< 3) { _ in
                    Circle()
                        .fill(betColor.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Accept/Reject Buttons
            VStack(spacing: 12) {
                // Envido Accept/Reject Buttons
                if bet.betType == .envido || bet.betType == .realEnvido || bet.betType == .faltaEnvido {
                    if gameState.envidoState == .envidoCalled && gameState.envidoCallerId != localPlayerId {
                        HStack(spacing: 12) {
                            Button("Accept Envido") {
                                acceptEnvido()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Reject Envido") {
                                rejectEnvido()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }

                        HStack(spacing: 12) {
                            Button("Real Envido") {
                                gameEngine.handle(move: .callRealEnvido)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)

                            Button("Falta Envido") {
                                gameEngine.handle(move: .callFaltaEnvido)
                            }
                            .buttonStyle(.bordered)
                            .tint(.yellow)
                        }
                    }
                }

                // Truco Accept/Reject Buttons
                if bet.betType == .truco {
                    if gameState.trucoState == .trucoCalled && gameState.trucoCallerId != localPlayerId {
                        HStack(spacing: 12) {
                            Button("Accept Truco") {
                                acceptTruco()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Reject Truco") {
                                rejectTruco()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Retruco") {
                                gameEngine.handle(move: .callTruco)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    } else if gameState.trucoState == .retrucoCalled && gameState.trucoCallerId != localPlayerId {
                        HStack(spacing: 12) {
                            Button("Accept Retruco") {
                                acceptTruco()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Reject Retruco") {
                                rejectTruco()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Vale Cuatro") {
                                gameEngine.handle(move: .callTruco)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(betColor.opacity(0.3), lineWidth: 2)
        )
        .frame(maxWidth: 300)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: bet)
    }
}

#Preview {
    let sampleBet = ActiveBet(
        betType: .envido,
        callerId: UUID(),
        points: 2
    )

    let samplePlayers = [
        Player(id: UUID(), name: "Player 1", hand: [], score: 0),
        Player(id: UUID(), name: "Player 2", hand: [], score: 0),
    ]

    let sampleGameState = GameState()
    let sampleGameEngine = TrucoEngine(gameState: sampleGameState)

    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        ActiveBetView(
            bet: sampleBet,
            players: samplePlayers,
            gameState: sampleGameState,
            localPlayerId: UUID(),
            gameEngine: .constant(sampleGameEngine)
        )
    }
}
