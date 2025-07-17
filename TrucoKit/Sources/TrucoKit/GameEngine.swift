
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
                gameState.currentHandPlayedCards.append(PlayedCardInfo(player: currentPlayer.id, card: card))
                
                // Update the player in the gameState
                if let playerIndex = gameState.players.firstIndex(where: { $0.id == currentPlayer.id }) {
                    gameState.players[playerIndex] = currentPlayer
                }
                
                // Switch turns
                gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count

                // Check if hand is over
                if gameState.currentHandPlayedCards.count == 2 {
                    let handWinnerId = determineHandWinner()
                    gameState.handWinners.append(handWinnerId)
                    
                    // Clear played cards for the next hand
                    gameState.currentHandPlayedCards = []

                    // Check if round is over
                    checkRoundEnd()
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
        self.gameState.currentHandPlayedCards = [] // Clear played cards for new hand
        self.gameState.handWinners = [] // Clear hand winners for new round
        self.gameState.roundWinner = nil // Clear round winner
        self.gameState.manoPlayerId = player1Id // Player 1 is mano for the first round
    }

    private func determineHandWinner() -> UUID? {
        guard gameState.currentHandPlayedCards.count == 2 else { return nil }

        let card1Info = gameState.currentHandPlayedCards[0]
        let card2Info = gameState.currentHandPlayedCards[1]

        if card1Info.card.trucoValue < card2Info.card.trucoValue {
            print("Hand winner: Player \(card1Info.player)")
            return card1Info.player
        } else if card2Info.card.trucoValue < card1Info.card.trucoValue {
            print("Hand winner: Player \(card2Info.player)")
            return card2Info.player
        } else {
            // Tie: The player who is "mano" (started the round) wins the hand if they played the tying card first.
            // If both cards have the same trucoValue, the player who played first wins the hand.
            // This is a simplification for now, as Truco tie-breaking is more complex (e.g., highest card played first wins, or next hand decides)
            print("Hand tie, first player to play wins: Player \(card1Info.player)")
            return card1Info.player
        }
    }

    private func checkRoundEnd() {
        let player1Wins = gameState.handWinners.filter { $0 == gameState.players[0].id }.count
        let player2Wins = gameState.handWinners.filter { $0 == gameState.players[1].id }.count

        if player1Wins >= 2 {
            gameState.roundWinner = gameState.players[0].id
            gameState.gamePhase = .roundOver
            print("Round over. Player 1 wins the round!")
        } else if player2Wins >= 2 {
            gameState.roundWinner = gameState.players[1].id
            gameState.gamePhase = .roundOver
            print("Round over. Player 2 wins the round!")
        } else if gameState.handWinners.count == 3 {
            // All three hands played, and no one has won two hands outright (e.g., 1-1-1 tie)
            // In Truco, if all three hands are tied, the "mano" (player who started the round) wins the round.
            gameState.roundWinner = gameState.manoPlayerId
            gameState.gamePhase = .roundOver
            print("Round over. All hands tied, mano player \(gameState.manoPlayerId!) wins the round!")
        }
    }

    public func startNewRound() {
        // Reset game state for a new round
        gameState.currentHandPlayedCards = []
        gameState.handWinners = []
        gameState.roundWinner = nil
        gameState.gamePhase = .playing

        // Determine new mano player (alternates each round)
        if let currentManoIndex = gameState.players.firstIndex(where: { $0.id == gameState.manoPlayerId }) {
            let nextManoIndex = (currentManoIndex + 1) % gameState.players.count
            gameState.manoPlayerId = gameState.players[nextManoIndex].id
            gameState.currentPlayerIndex = nextManoIndex // New mano starts the round
        } else {
            // Fallback if mano not found, assign to first player
            gameState.manoPlayerId = gameState.players.first?.id
            gameState.currentPlayerIndex = 0
        }

        // Re-deal cards
        var newDeck = GameState.newDeck()
        newDeck.shuffle()
        for i in 0..<gameState.players.count {
            gameState.players[i].hand = [] // Clear old hands
            for _ in 0..<3 {
                if let card = newDeck.popLast() {
                    gameState.players[i].hand.append(card)
                }
            }
        }
        gameState.deck = newDeck
        print("Starting new round. New mano: \(gameState.manoPlayerId!)")
    }
}
