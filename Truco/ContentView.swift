import SwiftUI
import TrucoKit
import Observation

struct ContentView: View {
    var body: some View {
        GameView()
    }
}

struct GameView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        VStack {
            Text("Truco Game")
                .font(.largeTitle)
                .padding()

            Spacer()

            // Opponent's Hand (placeholder)
            Text("Opponent's Hand")
                .font(.headline)
            HandView(cards: viewModel.gameState.players.first(where: { $0.id != viewModel.localPlayerId })?.hand ?? [], onCardTap: { _ in })
                .padding()

            Spacer()

            // Game Board
            Text("Played Cards")
                .font(.headline)
            PlayedCardsView(playedCards: viewModel.gameState.currentHandPlayedCards)
                .padding()

            if let winnerName = viewModel.roundWinnerName {
                Text("Round Winner: \(winnerName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            // Display hand winners
            VStack {
                Text("Hand Winners:")
                ForEach(viewModel.gameState.handWinners.indices, id: \.self) { index in
                    if let winnerId = viewModel.gameState.handWinners[index] {
                        Text("Hand \(index + 1): \(viewModel.playerName(for: winnerId))")
                    } else {
                        Text("Hand \(index + 1): Tie")
                    }
                }
            }
            .font(.subheadline)
            .padding()

            Spacer()

            // Current Player Indicator
            Text(viewModel.isLocalPlayerTurn ? "Your Turn" : "Opponent's Turn")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom)

            // Local Player's Hand
            Text("Your Hand")
                .font(.headline)
            HandView(cards: viewModel.gameState.players.first(where: { $0.id == viewModel.localPlayerId })?.hand ?? []) { card in
                if viewModel.isLocalPlayerTurn {
                    viewModel.playCard(card)
                }
            }
            .padding()

            HStack {
                Button("Start New Game") {
                    viewModel.dealInitialCards()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                if viewModel.gameState.gamePhase == .roundOver {
                    Button("Start New Round") {
                        viewModel.startNewRound()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }

            // Truco and Envido Buttons
            HStack {
                if viewModel.isLocalPlayerTurn {
                    if viewModel.gameState.trucoState == .none {
                        Button("Truco") {
                            viewModel.callTruco()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else if viewModel.gameState.trucoState == .trucoCalled && viewModel.gameState.trucoCallerId != viewModel.localPlayerId {
                        Button("Accept Truco") {
                            viewModel.acceptTruco()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Reject Truco") {
                            viewModel.rejectTruco()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                if viewModel.isLocalPlayerTurn && viewModel.gameState.envidoState == .none {
                    Button("Envido") {
                        viewModel.callEnvido()
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else if viewModel.isLocalPlayerTurn && viewModel.gameState.envidoState == .envidoCalled && viewModel.gameState.envidoCallerId != viewModel.localPlayerId {
                    Button("Accept Envido") {
                        viewModel.acceptEnvido()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Reject Envido") {
                        viewModel.rejectEnvido()
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct CardView: View {
    let card: Card
    var onTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 60, height: 90)
                .shadow(radius: 3)

            VStack {
                Text(card.rank.description)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(card.suit.rawValue.prefix(1).uppercased())
                    .font(.caption2)
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
}

struct HandView: View {
    let cards: [Card]
    var onCardTap: ((Card) -> Void)? = nil

    var body: some View {
        HStack {
            ForEach(cards) { card in
                CardView(card: card) {
                    onCardTap?(card)
                }
            }
        }
    }
}

struct PlayedCardsView: View {
    let playedCards: [PlayedCardInfo]

    var body: some View {
        HStack {
            ForEach(playedCards) { playedCard in
                VStack {
                    Text(playedCard.player.uuidString.prefix(4))
                        .font(.caption2)
                    CardView(card: playedCard.card)
                }
            }
        }
    }
}

@Observable
class GameViewModel {
    var gameState: GameState
    var localPlayerId: UUID // To identify the local player
    private var gameEngine: TrucoEngine
    private var multiplayerService: MultiplayerService

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

    func playerName(for id: UUID) -> String {
        return gameState.players.first(where: { $0.id == id })?.name ?? "Unknown Player"
    }

    init() {
        let initialGameState = GameState()
        self.gameState = initialGameState
        self.gameEngine = TrucoEngine(initialState: initialGameState)
        self.multiplayerService = GameKitService() // Placeholder
        self.localPlayerId = UUID() // Assign a dummy ID for now

        multiplayerService.moveReceived = { [weak self] move in
            self?.gameEngine.handle(move: move)
            self?.gameState = self?.gameEngine.gameState ?? GameState()
        }
    }

    func dealInitialCards() {
        gameEngine.dealInitialCards(player1Id: localPlayerId, player2Id: UUID())
        gameState = gameEngine.gameState
    }

    func playCard(_ card: Card) {
        if isLocalPlayerTurn {
            gameEngine.handle(move: .playCard(card))
            gameState = gameEngine.gameState
        }
    }

    func callTruco() {
        gameEngine.handle(move: .callTruco)
        gameState = gameEngine.gameState
    }

    func acceptTruco() {
        gameEngine.handle(move: .acceptTruco)
        gameState = gameEngine.gameState
    }

    func rejectTruco() {
        gameEngine.handle(move: .rejectTruco)
        gameState = gameEngine.gameState
    }

    func callEnvido() {
        gameEngine.handle(move: .callEnvido)
        gameState = gameEngine.gameState
    }

    func acceptEnvido() {
        gameEngine.handle(move: .acceptEnvido)
        gameState = gameEngine.gameState
    }

    func rejectEnvido() {
        gameEngine.handle(move: .rejectEnvido)
        gameState = gameEngine.gameState
    }

    func startNewRound() {
        gameEngine.startNewRound()
        gameState = gameEngine.gameState
    }
}

#Preview {
    ContentView()
}