
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
            HandView(cards: viewModel.gameState.playedCards, onCardTap: { _ in })
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

            Button("Start New Game") {
                viewModel.dealInitialCards()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
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
}

#Preview {
    ContentView()
}
