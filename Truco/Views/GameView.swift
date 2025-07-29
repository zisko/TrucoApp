import Observation
import SwiftUI
import TrucoKit

struct GameView: View {
    @State var gameState: GameState
    @State private var localPlayerId: UUID
    @State private var isHandWinnersExpanded = false
    private var gameEngine: TrucoEngine

    var isLocalPlayerTurn: Bool {
        guard let localPlayer = gameState.players.first(where: { $0.id == localPlayerId }) else { return false }
        return gameState.players[gameState.currentPlayerIndex].id == localPlayer.id
    }

    var matchWinnerName: String? {
        if let winnerId = gameState.matchWinner {
            return gameState.players.first(where: { $0.id == winnerId })?.name
        }
        return nil
    }

    func playerName(for id: UUID) -> String {
        return gameState.players.first(where: { $0.id == id })?.name ?? "Unknown Player"
    }

    init() {
        let initialGameState = GameState()
        _gameState = State(initialValue: initialGameState)
        _localPlayerId = State(initialValue: UUID())
        gameEngine = TrucoEngine(gameState: initialGameState)
    }

    func dealInitialCards() {
        gameEngine.dealInitialCards(player1Id: localPlayerId, player2Id: UUID())
        print("dealInitialCards - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func playCard(_ card: Card) {
        if isLocalPlayerTurn {
            gameEngine.handle(move: .playCard(card))
            // After the local player plays, if it's now the opponent's turn, trigger their move.
            if !isLocalPlayerTurn {
                makeOpponentMove()
            }
        }
    }

    func callTruco() {
        gameEngine.handle(move: .callTruco)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func acceptTruco() {
        gameEngine.handle(move: .acceptTruco)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func rejectTruco() {
        gameEngine.handle(move: .rejectTruco)
    }

    func callEnvido() {
        gameEngine.handle(move: .callEnvido)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func acceptEnvido() {
        gameEngine.handle(move: .acceptEnvido)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func rejectEnvido() {
        gameEngine.handle(move: .rejectEnvido)
    }

    func startNewRound() {
        gameEngine.startNewRound()
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func continueAfterHand() {
        gameEngine.handle(move: .continueAfterHand)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func continueAfterEnvido() {
        gameEngine.handle(move: .continueAfterEnvido)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    private func makeOpponentMove() {
        // Simulate thinking time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard !self.isLocalPlayerTurn else { return }

            // 1. Respond to Truco call
            if self.gameState.trucoState == .trucoCalled && self.gameState.trucoCallerId == self.localPlayerId {
                self.gameEngine.handle(move: .acceptTruco)
                return
            }

            // 2. Respond to Envido call
            if self.gameState.envidoState == .envidoCalled && self.gameState.envidoCallerId == self.localPlayerId {
                self.gameEngine.handle(move: .acceptEnvido)
                return
            }

            // 3. Play a card
            guard let opponent = self.gameState.players.first(where: { $0.id != self.localPlayerId }) else { return }
            if let randomCard = opponent.hand.randomElement() {
                self.gameEngine.handle(move: .playCard(randomCard))
            }
        }
    }

    var body: some View {
        ZStack {
            VStack {
                // Scoreboard
                if !gameState.players.isEmpty {
                    HStack {
                        Text("\(gameState.players[0].name): \(gameState.players[0].score)")
                        Spacer()
                        Text("\(gameState.players[1].name): \(gameState.players[1].score)")
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
                HandView(cards: gameState.players.first(where: { $0.id != localPlayerId })?.hand ?? [], onCardTap: { _ in })
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

                // Current Player Indicator
                if gameState.gamePhase == .playing {
                    Text(isLocalPlayerTurn ? "Your Turn" : "Opponent's Turn")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom)
                }

                // Local Player's Hand
                Text("Your Hand")
                    .font(.headline)
                HandView(cards: gameState.players.first(where: { $0.id == localPlayerId })?.hand ?? []) { card in
                    if isLocalPlayerTurn {
                        playCard(card)
                    }
                }
                .padding()

                if gameState.gamePhase == .preGame || gameState.gamePhase == .gameOver {
                    Button("Start New Game") {
                        dealInitialCards()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Truco and Envido Buttons
                HStack {
                    if isLocalPlayerTurn && gameState.gamePhase == .playing {
                        if gameEngine.gameState.trucoState == .none || (gameEngine.gameState.trucoState == .accepted && gameEngine.gameState.trucoCallerId == localPlayerId) {
                            Button("Truco") {
                                callTruco()
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else if gameEngine.gameState.trucoState == .trucoCalled && gameEngine.gameState.trucoCallerId != localPlayerId {
                            Button("Accept Truco") {
                                acceptTruco()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Reject Truco") {
                                rejectTruco()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Retruco") {
                                gameEngine.handle(move: .callTruco)
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else if gameEngine.gameState.trucoState == .retrucoCalled && gameEngine.gameState.trucoCallerId != localPlayerId {
                            Button("Accept Retruco") {
                                acceptTruco()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Reject Retruco") {
                                rejectTruco()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Vale Cuatro") {
                                gameEngine.handle(move: .callTruco)
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        if gameEngine.gameState.envidoState == .none {
                            Button("Envido") {
                                callEnvido()
                            }
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else if gameEngine.gameState.envidoState == .envidoCalled && gameEngine.gameState.envidoCallerId != localPlayerId {
                            Button("Accept Envido") {
                                acceptEnvido()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button("Reject Envido") {
                                rejectEnvido()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .blur(radius: gameState.gamePhase == .handOver || gameState.gamePhase == .roundSummary || gameState.gamePhase == .gameOver || gameState.gamePhase == .envidoSummary ? 10 : 0)

            // Overlays
            if gameState.gamePhase == .handOver {
                if let lastOutcome = gameState.handOutcomes.last {
                    HandOutcomeView(outcome: lastOutcome, players: gameState.players) {
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
    }
}
