import Observation
import SwiftUI
import TrucoKit

struct GameView: View {
    @State private var gameState: GameState
    @State private var localPlayerId: UUID
    @State private var isHandWinnersExpanded = false
    @State private var gameEngine: TrucoGameEngine
    @State private var trucoAlertShown = false

    var isLocalPlayerTurn: Bool {
        guard !gameState.players.isEmpty else { return false }
        return gameState.players[gameState.currentPlayerIndex].id
            == localPlayerId
    }

    var matchWinnerName: String? {
        if let winnerId = gameState.matchWinner {
            return gameState.players.first(where: { $0.id == winnerId })?.name
        }
        return nil
    }

    init() {
        let initialGameState = GameState()
        _gameState = State(initialValue: initialGameState)
        _localPlayerId = State(initialValue: UUID())

        // Use the factory to create the engine
        // Change .original to .refactored to use the new state machine engine
        gameEngine = GameEngineFactory.createEngine(type: .refactored, gameState: initialGameState)
    }

    func dealInitialCards() {
        gameEngine.dealInitialCards(player1Id: localPlayerId, player2Id: UUID())
        print(
            "dealInitialCards - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)"
        )
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func playCard(_ card: Card) {
        if isLocalPlayerTurn {
            gameEngine.handle(move: .playCard(card))
            // After the local player plays, if it's now the opponent's turn, trigger their move.
            if !isLocalPlayerTurn {
                gameEngine.makeOpponentMove()
            }
        }
    }

    func startNewRound() {
        gameEngine.startNewRound()
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func continueAfterHand() {
        gameEngine.handle(move: .continueAfterHand)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func continueAfterEnvido() {
        gameEngine.handle(move: .continueAfterEnvido)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    var body: some View {
        ZStack {
            VStack {
                // Scoreboard
                if !gameState.players.isEmpty {
                    HStack {
                        Text(
                            "\(gameState.players[0].name): \(gameState.players[0].score)"
                        )
                        Spacer()
                        Text(
                            "\(gameState.players[1].name): \(gameState.players[1].score)"
                        )
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer()

                // Opponent's Hand
                Text("Opponent's Hand")
                    .font(.headline)
                HandView(
                    cards: gameState.players.first(where: {
                        $0.id != localPlayerId
                    })?.hand ?? [],
                    onCardTap: { _ in }
                )
                .padding()

                Spacer()

                // Game Board
                Text("Played Cards")
                    .font(.headline)
                PlayedCardsView(playedCards: gameState.currentHandPlayedCards)
                    .padding()

                HandWinnersDisplayView(
                    isExpanded: $isHandWinnersExpanded,
                    handOutcomes: gameState.handOutcomes,
                    players: gameState.players
                )

                Spacer()

                if gameState.gamePhase == .playing
                    || gameState.gamePhase == .handOver
                {
                    GameStatusView(
                        gameState: gameState,
                        localPlayerId: localPlayerId
                    )
                    .padding(.bottom)
                }

                // Local Player's Hand
                Text("Your Hand")
                    .font(.headline)
                HandView(
                    cards: gameState.players.first(where: {
                        $0.id == localPlayerId
                    })?.hand ?? []
                ) { card in
                    if isLocalPlayerTurn {
                        playCard(card)
                    }
                }
                .padding()

                if gameState.gamePhase == .preGame
                    || gameState.gamePhase == .gameOver
                {
                    Button("Start New Game") {
                        dealInitialCards()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Bet Buttons - Always available when it's the player's turn
                if isLocalPlayerTurn && gameState.gamePhase == .playing {
                    VStack(spacing: 12) {
                        // Envido Button - Only available at the beginning
                        if gameState.envidoState == .none
                            && gameState.currentHandPlayedCards.isEmpty
                        {
                            Button("Envido") {
                                gameEngine.handle(move: .callEnvido)
                                if !isLocalPlayerTurn
                                    && gameState.gamePhase == .playing
                                {
                                    gameEngine.makeOpponentMove()
                                }
                            }
                            .disabled(gameState.trucoState != .none)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        // Truco Button - Available on any turn when it's the player's turn
                        switch gameState.trucoState {
                        case .none:
                            Button("Truco") {
                                gameEngine.handle(move: .callTruco)
                            }
                            .disabled(gameState.envidoState != .none && gameState.envidoState != .accepted && gameState.envidoState != .rejected)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        case let .accepted(caller):
                            if caller != localPlayerId {
                                Button("Retruco") {
                                    gameEngine.handle(move: .callTruco)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        case let .retrucoAccepted(caller):
                            if caller != localPlayerId {
                                Button("Vale Cuatro") {
                                    gameEngine.handle(move: .callTruco)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .blur(
                radius: gameState.gamePhase == .handOver
                    || gameState.gamePhase == .roundSummary
                    || gameState.gamePhase == .gameOver
                    || gameState.gamePhase == .envidoSummary
                    ? 10 : 0
            )

            // Accept/Reject Buttons Overlay
            if case let .called(caller) = gameState.trucoState, caller != localPlayerId {
                VStack(spacing: 12) {
                    Text("Truco Called!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    HStack(spacing: 12) {
                        Button("Accept Truco") {
                            gameEngine.handle(move: .acceptTruco)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Reject Truco") {
                            gameEngine.handle(move: .rejectTruco)
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
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
            } else if case let .retrucoCalled(caller) = gameState.trucoState, caller != localPlayerId {
                VStack(spacing: 12) {
                    Text("Retruco Called!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    HStack(spacing: 12) {
                        Button("Accept Retruco") {
                            gameEngine.handle(move: .acceptTruco)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Reject Retruco") {
                            gameEngine.handle(move: .rejectTruco)
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
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
            } else if case let .valeCuatroCalled(caller) = gameState.trucoState, caller != localPlayerId {
                VStack(spacing: 12) {
                    Text("Vale Cuatro Called!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    HStack(spacing: 12) {
                        Button("Accept Vale Cuatro") {
                            gameEngine.handle(move: .acceptTruco)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Reject Vale Cuatro") {
                            gameEngine.handle(move: .rejectTruco)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
            } else if gameState.envidoState == .envidoCalled
                && gameState.envidoCallerId != localPlayerId
            {
                VStack(spacing: 12) {
                    Text("Envido Called!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)

                    HStack(spacing: 12) {
                        Button("Accept Envido") {
                            gameEngine.handle(move: .acceptEnvido)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reject Envido") {
                            gameEngine.handle(move: .rejectEnvido)
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
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                )
            }

            // Truco Result Feedback
            if case .accepted = gameState.trucoState, trucoAlertShown {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                        Text("Truco Accepted!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            trucoAlertShown = false
                        }
                    }
                }
            } else if case .rejected = gameState.trucoState, trucoAlertShown {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        Text("Truco Rejected!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                )
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            trucoAlertShown = false
                        }
                    }
                }
            }

            // Overlays
            if gameState.gamePhase == .handOver {
                if let lastOutcome = gameState.handOutcomes.last {
                    HandOutcomeView(
                        outcome: lastOutcome,
                        players: gameState.players
                    ) {
                        continueAfterHand()
                    }
                }
            }

            if gameState.gamePhase == .roundSummary {
                RoundSummaryView(gameState: gameState) {
                    startNewRound()
                }
            }

            if gameState.gamePhase == .envidoSummary {
                EnvidoSummaryView(gameState: gameState) {
                    continueAfterEnvido()
                }
            }

            if gameState.gamePhase == .gameOver {
                VStack {
                    Text("Match Over!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    if let winnerName = matchWinnerName {
                        Text("\(winnerName) wins!")
                            .font(.title)
                            .padding()
                    }
                    Button("Play Again") {
                        dealInitialCards()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
            }
        }
        .onChange(of: gameState.trucoState) { newValue in
            if case .accepted = newValue {
                withAnimation {
                    trucoAlertShown = true
                }
            } else if case .rejected = newValue {
                withAnimation {
                    trucoAlertShown = true
                }
            }
        }
    }
}

#Preview {
    GameView()
}
