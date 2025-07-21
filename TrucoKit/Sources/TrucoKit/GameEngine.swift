import Foundation

public class TrucoEngine {
    public var gameState: GameState
    public var onHandEnd: ((UUID?, Bool) -> Void)?  // New closure for hand end

    public init(gameState: GameState) {
        self.gameState = gameState
    }

    public func handle(move: GameMove) {
        print("Handling move: \(move)")

        switch move {
        case .playCard(let card):
            guard gameState.gamePhase == .playing else { return }
            guard
                var currentPlayer = gameState.players.first(where: {
                    $0.id == gameState.players[gameState.currentPlayerIndex].id
                })
            else { return }

            if let index = currentPlayer.hand.firstIndex(of: card) {
                currentPlayer.hand.remove(at: index)
                gameState.currentHandPlayedCards.append(
                    PlayedCardInfo(player: currentPlayer.id, card: card)
                )

                // Update the player in the gameState
                if let playerIndex = gameState.players.firstIndex(where: {
                    $0.id == currentPlayer.id
                }) {
                    gameState.players[playerIndex] = currentPlayer
                }

                // Check if hand is over
                if gameState.currentHandPlayedCards.count == 2 {
                    let outcome = determineHandOutcome()
                    gameState.handOutcomes.append(outcome)

                    // Delay before clearing cards and checking round end
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        [weak self] in
                        guard let self = self else { return }
                        self.checkRoundEnd() // checkRoundEnd will now be called here
                        let isRoundOverAfterCheck =
                            self.gameState.gamePhase == .roundOver

                        if !isRoundOverAfterCheck {  // Only clear if round is not over
                            self.gameState.currentHandPlayedCards = []
                            self.startNewHand()
                        }
                        self.onHandEnd?(outcome.winnerId, isRoundOverAfterCheck)
                    }
                } else {
                    // Only one card played, switch turns
                    gameState.currentPlayerIndex =
                        (gameState.currentPlayerIndex + 1)
                        % gameState.players.count
                    self.onHandEnd?(nil, false)  // Signal that a card was played and turn switched
                }
            }
        case .callTruco:
            guard gameState.trucoState != .rejected else { return }  // Cannot call truco if already rejected

            let currentTrucoPoints: Int
            switch gameState.trucoState {
            case .none:
                gameState.trucoState = .trucoCalled
                currentTrucoPoints = 2
            case .trucoCalled:
                gameState.trucoState = .retrucoCalled
                currentTrucoPoints = 3
            case .retrucoCalled:
                gameState.trucoState = .valeCuatroCalled
                currentTrucoPoints = 4
            case .valeCuatroCalled:
                return  // Cannot call truco beyond vale cuatro
            case .accepted, .rejected:
                return  // Should not happen if guard is correct
            }
            gameState.trucoCallerId =
                gameState.players[gameState.currentPlayerIndex].id
            gameState.envidoPoints = currentTrucoPoints  // Truco points are stored in envidoPoints for now
            print(
                "Truco called by \(gameState.players[gameState.currentPlayerIndex].name). Current Truco points: \(currentTrucoPoints)"
            )

        case .acceptTruco:
            gameState.trucoState = .accepted
            print("Truco accepted!")

        case .rejectTruco:
            if let callerId = gameState.trucoCallerId {
                if let callerIndex = gameState.players.firstIndex(where: {
                    $0.id == callerId
                }) {
                    gameState.players[callerIndex].score +=
                        (gameState.envidoPoints - 1)  // Award points for rejected truco
                    print(
                        "Truco rejected! \(gameState.players[callerIndex].name) gets \(gameState.envidoPoints - 1) points."
                    )
                }
            }
            gameState.gamePhase = .roundOver  // Round ends immediately
            gameState.trucoState = .rejected

        case .callEnvido:
            guard gameState.envidoState == .none else { return }  // Envido can only be called once per round
            gameState.envidoState = .envidoCalled
            gameState.envidoCallerId =
                gameState.players[gameState.currentPlayerIndex].id
            gameState.envidoPoints = 2  // Initial Envido value
            print(
                "Envido called by \(gameState.players[gameState.currentPlayerIndex].name). Current Envido points: \(gameState.envidoPoints)"
            )

        case .acceptEnvido:
            resolveEnvido()
            gameState.envidoState = .accepted
            print("Envido accepted!")

        case .rejectEnvido:
            if let callerId = gameState.envidoCallerId {
                if let callerIndex = gameState.players.firstIndex(where: {
                    $0.id == callerId
                }) {
                    gameState.players[callerIndex].score += 1  // 1 point for rejected envido
                    print(
                        "Envido rejected! \(gameState.players[callerIndex].name) gets 1 point."
                    )
                }
            }
            gameState.envidoState = .rejected

        default:
            break
        }
    }

    public func dealInitialCards(player1Id: UUID, player2Id: UUID) {
        var newDeck = GameState.newDeck()
        newDeck.shuffle()

        var player1 = Player(
            id: player1Id,
            name: "Player 1",
            hand: [],
            score: 0
        )
        var player2 = Player(
            id: player2Id,
            name: "Player 2",
            hand: [],
            score: 0
        )

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
        self.gameState.currentPlayerIndex = 0  // Player 1 starts
        self.gameState.currentHandPlayedCards = []  // Clear played cards for new hand
        self.gameState.handOutcomes = []  // Clear hand outcomes for new round
        self.gameState.roundWinner = nil  // Clear round winner
        self.gameState.manoPlayerId = player1Id  // Player 1 is mano for the first round
        self.gameState.trucoState = .none  // Reset truco state
        self.gameState.trucoCallerId = nil  // Reset truco caller
        self.gameState.envidoState = .none  // Reset envido state
        self.gameState.envidoCallerId = nil  // Reset envido caller
        self.gameState.envidoPoints = 0  // Reset envido points
    }

    private func determineHandOutcome() -> HandOutcome {
    guard gameState.currentHandPlayedCards.count == 2 else {
        // This case should ideally not be reached if called correctly
        return HandOutcome(winnerId: nil, winningCard: nil, losingCard: nil)
    }

    let play1 = gameState.currentHandPlayedCards[0]
    let play2 = gameState.currentHandPlayedCards[1]

    if play1.card.trucoValue < play2.card.trucoValue {
        return HandOutcome(winnerId: play1.player, winningCard: play1.card, losingCard: play2.card)
    } else if play2.card.trucoValue < play1.card.trucoValue {
        return HandOutcome(winnerId: play2.player, winningCard: play2.card, losingCard: play1.card)
    } else {
        // Tie
        return HandOutcome(winnerId: nil, winningCard: play1.card, losingCard: play2.card)
    }
}

    private func checkRoundEnd() {
        let handWinners = gameState.handOutcomes.map { $0.winnerId }
        let player1Id = gameState.players[0].id
        let player2Id = gameState.players[1].id

        let player1HandWins = handWinners.filter { $0 == player1Id }
            .count
        let player2HandWins = handWinners.filter { $0 == player2Id }
            .count
        let tiedHands = handWinners.filter { $0 == nil }.count

        // Rule 1: A player wins two hands outright
        if player1HandWins >= 2 {
            gameState.roundWinner = player1Id
            gameState.gamePhase = .roundOver
            print("Round over. Player 1 wins the round!")
        } else if player2HandWins >= 2 {
            gameState.roundWinner = player2Id
            gameState.gamePhase = .roundOver
            print("Round over. Player 2 wins the round!")
        }
        // Rule 2: All three hands played
        else if handWinners.count == 3 {
            // Scenario A: All three hands are tied (e.g., [nil, nil, nil])
            if tiedHands == 3 {
                gameState.roundWinner = gameState.manoPlayerId
                gameState.gamePhase = .roundOver
                print(
                    "Round over. All hands tied, mano player \(gameState.manoPlayerId!) wins the round!"
                )
            }
            // Scenario B: One hand tied, one won by each player (e.g., [winner1, nil, winner2] or [nil, winner1, winner2])
            // The rule states: "If a player or team wins the first hand, loses the second, and ties the third, the player or team that won the first hand wins the round."
            // This implies that if there's a tie in any hand, the winner of the first non-tied hand wins the round.
            else {
                // Find the winner of the first non-tied hand
                if let firstNonTiedHandWinner = handWinners.first(
                    where: { $0 != nil })
                {
                    gameState.roundWinner = firstNonTiedHandWinner
                    gameState.gamePhase = .roundOver
                    print(
                        "Round over. First non-tied hand winner \(firstNonTiedHandWinner!) wins the round due to tie-breaking rules."
                    )
                } else {
                    // This case should ideally not be reached if all rules are covered.
                    // It means there are hands played, but all are ties, and not all 3 hands are tied.
                    print("Unexpected round end scenario with ties.")
                }
            }
        }
    }

    private func startNewHand() {
        // Only clear played cards if the round is not over
        if gameState.gamePhase != .roundOver && gameState.gamePhase != .gameOver
        {
            gameState.currentHandPlayedCards = []
        }
        // The player who won the last hand starts the next hand. If it was a tie, the mano player starts.
        if let lastOutcome = gameState.handOutcomes.last,
            let winnerId = lastOutcome.winnerId
        {
            gameState.currentPlayerIndex =
                gameState.players.firstIndex(where: { $0.id == winnerId }) ?? 0
        } else {
            // If the last hand was a tie, the mano player starts the next hand.
            gameState.currentPlayerIndex =
                gameState.players.firstIndex(where: {
                    $0.id == gameState.manoPlayerId
                }) ?? 0
        }
        print(
            "Starting new hand. Current player: \(gameState.players[gameState.currentPlayerIndex].name)"
        )
    }

    public func startNewRound() {
        // Reset game state for a new round
        gameState.currentHandPlayedCards = []
        gameState.handOutcomes = []
        gameState.roundWinner = nil
        gameState.gamePhase = .playing
        gameState.trucoState = .none  // Reset truco state
        gameState.trucoCallerId = nil  // Reset truco caller
        gameState.envidoState = .none  // Reset envido state
        gameState.envidoCallerId = nil  // Reset envido caller
        gameState.envidoPoints = 0  // Reset envido points

        // Determine new mano player (alternates each round)
        if let currentManoIndex = gameState.players.firstIndex(where: {
            $0.id == gameState.manoPlayerId
        }) {
            let nextManoIndex = (currentManoIndex + 1) % gameState.players.count
            gameState.manoPlayerId = gameState.players[nextManoIndex].id
            gameState.currentPlayerIndex = nextManoIndex  // New mano starts the round
        } else {
            // Fallback if mano not found, assign to first player
            gameState.manoPlayerId = gameState.players.first?.id
            gameState.currentPlayerIndex = 0
        }

        // Re-deal cards
        var newDeck = GameState.newDeck()
        newDeck.shuffle()
        for i in 0..<gameState.players.count {
            gameState.players[i].hand = []  // Clear old hands
            for _ in 0..<3 {
                if let card = newDeck.popLast() {
                    gameState.players[i].hand.append(card)
                }
            }
        }
        gameState.deck = newDeck
        print("Starting new round. New mano: \(gameState.manoPlayerId!)")
    }

    private func calculateEnvidoPoints(for player: Player) -> Int {
        var maxPoints = 0
        let groupedBySuit = Dictionary(grouping: player.hand, by: { $0.suit })

        for (_, cardsInSuit) in groupedBySuit {
            if cardsInSuit.count >= 2 {
                // Calculate points for cards of the same suit
                let sortedCards = cardsInSuit.sorted {
                    $0.envidoValue < $1.envidoValue
                }
                if sortedCards.count >= 2 {
                    let points =
                        sortedCards.suffix(2).reduce(0) { $0 + $1.envidoValue }
                        + 20
                    maxPoints = max(maxPoints, points)
                }
            }
        }

        // If no two cards of the same suit, the highest single card value is the envido
        if maxPoints == 0 {
            maxPoints = player.hand.map { $0.envidoValue }.max() ?? 0
        }
        return maxPoints
    }

    private func resolveEnvido() {
        guard gameState.envidoCallerId != nil else {
            print("error: attempted to resolve envido but it was never called")
            return
        }
        guard
            let player1 = gameState.players.first(where: {
                $0.id == gameState.players[0].id
            })
        else { return }
        guard
            let player2 = gameState.players.first(where: {
                $0.id == gameState.players[1].id
            })
        else { return }

        let player1EnvidoPoints = calculateEnvidoPoints(for: player1)
        let player2EnvidoPoints = calculateEnvidoPoints(for: player2)

        print("Player 1 Envido Points: \(player1EnvidoPoints)")
        print("Player 2 Envido Points: \(player2EnvidoPoints)")

        var winnerId: UUID?
        if player1EnvidoPoints > player2EnvidoPoints {
            winnerId = player1.id
        } else if player2EnvidoPoints > player1EnvidoPoints {
            winnerId = player2.id
        } else {
            // Tie in Envido: The player who is "mano" (started the round) wins the envido tie.
            winnerId = gameState.manoPlayerId
        }

        if let winner = winnerId {
            if let winnerIndex = gameState.players.firstIndex(where: {
                $0.id == winner
            }) {
                gameState.players[winnerIndex].score += gameState.envidoPoints
                print(
                    "Envido winner: \(gameState.players[winnerIndex].name) gets \(gameState.envidoPoints) points."
                )
            }
        }
        // Reset envido state after resolution
        gameState.envidoState = .none
        gameState.envidoCallerId = nil
        gameState.envidoPoints = 0
    }
}
