import SwiftUI
import TrucoKit
import Observation

struct GameView: View {
    @State var gameState: GameState
    @State private var localPlayerId: UUID
    @State private var isHandWinnersExpanded = false
    private var gameEngine: TrucoEngine

    var isLocalPlayerTurn: Bool {
        guard let localPlayer = gameState.players.first(where: { $0.id == localPlayerId }) else { return false }
        return gameState.players[gameState.currentPlayerIndex].id == localPlayer.id
    }

    var roundWinnerName: String? {
        if let winnerId = gameState.roundWinner {
            return gameState.players.first(where: { $0.id == winnerId })?.name
        }
        return nil
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
    
    private func setupEngineCallbacks() {
        gameEngine.onHandEnd = { winnerId, isRoundOver in
            if isRoundOver {
                // Round is over, do not clear cards immediately
                // The UI will show all hands
            } else {
                // Hand is over, clear played cards and start new hand
                // The engine already calls startNewHand internally
            }
            // If it's opponent's turn after hand end, make opponent move
            if !self.isLocalPlayerTurn && self.gameState.gamePhase == .playing {
                self.makeOpponentMove()
            }
        }
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
            print("playCard - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        }
        // Opponent move is handled by onHandEnd closure in GameEngine
    }

    func callTruco() {
        gameEngine.handle(move: .callTruco)
        print("callTruco - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func acceptTruco() {
        gameEngine.handle(move: .acceptTruco)
        print("acceptTruco - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func rejectTruco() {
        gameEngine.handle(move: .rejectTruco)

        print("rejectTruco - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func callEnvido() {
        gameEngine.handle(move: .callEnvido)
        print("callEnvido - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func acceptEnvido() {
        gameEngine.handle(move: .acceptEnvido)
        print("acceptEnvido - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func rejectEnvido() {
        gameEngine.handle(move: .rejectEnvido)
        print("rejectEnvido - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }

    func startNewRound() {
        gameEngine.startNewRound()
        print("startNewRound - isLocalPlayerTurn: \(isLocalPlayerTurn), gamePhase: \(gameState.gamePhase)")
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            makeOpponentMove()
        }
    }
    
    private func makeOpponentMove() {
        // Simulate thinking time
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let opponent = self.gameState.players.first(where: { $0.id != self.localPlayerId }) else { return }
            guard let randomCard = opponent.hand.randomElement() else { return }
            
            self.gameEngine.handle(move: .playCard(randomCard))
            print("makeOpponentMove - isLocalPlayerTurn: \(self.isLocalPlayerTurn), gamePhase: \(self.gameState.gamePhase)")
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

                if let winnerName = roundWinnerName, gameState.gamePhase == .roundOver {
                    Text("Round Winner: \(winnerName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

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

                HStack {
                    if gameState.gamePhase != .playing && gameState.gamePhase != .roundOver {
                        Button("Start New Game") {
                            dealInitialCards()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    if gameState.gamePhase == .roundOver {
                        Button("Start New Round") {
                            startNewRound()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                // Truco and Envido Buttons
                HStack {
                    if isLocalPlayerTurn {
                        if gameEngine.gameState.trucoState == .none {
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
                        }
                    }

                    if isLocalPlayerTurn && gameEngine.gameState.envidoState == .none {
                        Button("Envido") {
                            callEnvido()
                            
                        }
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else if isLocalPlayerTurn && gameEngine.gameState.envidoState == .envidoCalled && gameEngine.gameState.envidoCallerId != localPlayerId {
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
            .onAppear(perform: setupEngineCallbacks)
            
            // Match Over Overlay
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