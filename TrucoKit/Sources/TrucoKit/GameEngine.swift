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
                
                // Check if hand is over
                if gameState.currentHandPlayedCards.count == 2 {
                    let handWinnerId = determineHandWinner()
                    gameState.handWinners.append(handWinnerId)
                    
                    // Check if round is over
                    checkRoundEnd()

                    // If round is not over, start a new hand
                    if gameState.gamePhase == .playing {
                        startNewHand()
                    }
                } else {
                    // Only one card played, switch turns
                    gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count
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
            // It's a tie for this hand. Return nil to indicate a tie.
            print("Hand tie.")
            return nil
        }
    }

    private func checkRoundEnd() {
        let player1Id = gameState.players[0].id
        let player2Id = gameState.players[1].id

        let player1HandWins = gameState.handWinners.filter { $0 == player1Id }.count
        let player2HandWins = gameState.handWinners.filter { $0 == player2Id }.count
        let tiedHands = gameState.handWinners.filter { $0 == nil }.count

        if player1HandWins >= 2 {
            gameState.roundWinner = player1Id
            gameState.gamePhase = .roundOver
            print("Round over. Player 1 wins the round!")
        } else if player2HandWins >= 2 {
            gameState.roundWinner = player2Id
            gameState.gamePhase = .roundOver
            print("Round over. Player 2 wins the round!")
        } else if gameState.handWinners.count == 3 {
            // All three hands played, and no one has won two hands outright (e.g., 1-1-1 tie)
            // In Truco, if all three hands are tied, the "mano" (player who started the round) wins the round.
            gameState.roundWinner = gameState.manoPlayerId
            gameState.gamePhase = .roundOver
            print("Round over. All hands tied, mano player \(gameState.manoPlayerId!) wins the round!")
        } else if gameState.handWinners.count == 2 && tiedHands == 1 {
            // One hand tied, one won by each player. The winner of the first hand wins the round.
            if let firstHandWinner = gameState.handWinners[0] {
                gameState.roundWinner = firstHandWinner
                gameState.gamePhase = .roundOver
                print("Round over. First hand winner \(firstHandWinner) wins the round due to tie.")
            }
        }
    }

    private func startNewHand() {
        gameState.currentHandPlayedCards = []
        // The player who won the last hand starts the next hand. If it was a tie, the mano player starts.
        if let lastHandWinner = gameState.handWinners.last, let winnerId = lastHandWinner {
            gameState.currentPlayerIndex = gameState.players.firstIndex(where: { $0.id == winnerId }) ?? 0
        } else {
            // If the last hand was a tie, the mano player starts the next hand.
            gameState.currentPlayerIndex = gameState.players.firstIndex(where: { $0.id == gameState.manoPlayerId }) ?? 0
        }
        print("Starting new hand. Current player: \(gameState.players[gameState.currentPlayerIndex].name)")
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