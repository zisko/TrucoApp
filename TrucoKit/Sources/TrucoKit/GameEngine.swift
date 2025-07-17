import Foundation

public class TrucoEngine {
    public private(set) var gameState: GameState
    
    public init(initialState: GameState = GameState()) {
        self.gameState = initialState
    }
    
    public func handle(move: GameMove) {
        print("Handling move: \(move)")
        
        switch move {
        case .playCard(let card):
            guard gameState.gamePhase == .playing else { return }
            guard var currentPlayer = gameState.players.first(where: { $0.id == gameState.players[gameState.currentPlayerIndex].id }) else { return }
            
            if let index = currentPlayer.hand.firstIndex(of: card) {
                currentPlayer.hand.remove(at: index)
                gameState.playedCards.append(card)
                
                // Update the player in the gameState
                if let playerIndex = gameState.players.firstIndex(where: { $0.id == currentPlayer.id }) {
                    gameState.players[playerIndex] = currentPlayer
                }
                
                // Switch turns (simple alternating for now)
                gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count
            }
        default:
            break
        }
    }

    public func dealInitialCards(player1Id: UUID, player2Id: UUID) {
        var newDeck = GameState.newDeck()
        newDeck.shuffle()

        var player1 = Player(id: player1Id, name: "Player 1", hand: [], score: 0)
        var player2 = Player(id: player2Id, name: "Player 2", hand: [], score: 0)

        // Deal 3 cards to each player
        for _ in 0..<3 {
            if let card = newDeck.popLast() {
                player1.hand.append(card)
            }
            if let card = newDeck.popLast() {
                player2.hand.append(card)
            }
        }

        self.gameState.players = [player1, player2]
        self.gameState.deck = newDeck
        self.gameState.gamePhase = .playing
        self.gameState.currentPlayerIndex = 0 // Player 1 starts
    }
}