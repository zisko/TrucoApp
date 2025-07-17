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
                gameState.playedCards.append(PlayedCardInfo(player: currentPlayer.id, card: card))
                
                // Update the player in the gameState
                if let playerIndex = gameState.players.firstIndex(where: { $0.id == currentPlayer.id }) {
                    gameState.players[playerIndex] = currentPlayer
                }
                
                // Switch turns
                gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count

                // Check if round is over
                if gameState.playedCards.count == 2 {
                    determineRoundWinner()
                }
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
        self.gameState.playedCards = [] // Clear played cards for new round
    }

    private func determineRoundWinner() {
        guard gameState.playedCards.count == 2 else { return }

        let card1 = gameState.playedCards[0]
        let card2 = gameState.playedCards[1]

        if card1.card.trucoValue < card2.card.trucoValue {
            gameState.roundWinner = card1.player
            print("Round winner: Player \(card1.player)")
        } else if card2.card.trucoValue < card1.card.trucoValue {
            gameState.roundWinner = card2.player
            print("Round winner: Player \(card2.player)")
        } else {
            // Tie - handle according to Truco rules (e.g., highest card played first wins, or next round decides)
            // For simplicity, let's say the first player to play the tying card wins for now.
            gameState.roundWinner = card1.player
            print("Round tie, first player to play wins: Player \(card1.player)")
        }

        // Increment winner's score (basic for now, Truco scoring is complex)
        if let winnerId = gameState.roundWinner,
           let winnerIndex = gameState.players.firstIndex(where: { $0.id == winnerId }) {
            gameState.players[winnerIndex].score += 1
        }

        // Reset played cards for the next round
        gameState.playedCards = []
        gameState.gamePhase = .roundOver // Transition to round over
    }
}