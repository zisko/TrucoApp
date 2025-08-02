import Foundation

/// A refactored engine to play the game of Truco using a proper state machine framework.
public class TrucoEngineRefactored: TrucoGameEngine {
    public var gameState: GameState
    private let stateMachine: HierarchicalStateMachine

    public init(gameState: GameState) {
        self.gameState = gameState
        stateMachine = HierarchicalStateMachine()

        // Synchronize state machines with current game state
        synchronizeStateMachines()
    }

    /// Handles a game move with proper state machine validation and error handling
    public func handleWithError(move: GameMove) -> StateMachineError? {
        print("Handling move: \(move)")

        // First, validate that the move is allowed in the current state
        if let error = stateMachine.validateMove(move, in: gameState) {
            print("Move validation failed: \(error.localizedDescription)")
            return error
        }

        // Handle the move based on its type
        switch move {
        case let .playCard(card):
            return handlePlayCard(card)

        case .callTruco:
            return handleCallTruco()

        case .acceptTruco:
            return handleAcceptTruco()

        case .rejectTruco:
            return handleRejectTruco()

        case .callEnvido:
            return handleCallEnvido()

        case .callRealEnvido:
            return handleCallRealEnvido()

        case .callFaltaEnvido:
            return handleCallFaltaEnvido()

        case .acceptEnvido:
            return handleAcceptEnvido()

        case .rejectEnvido:
            return handleRejectEnvido()

        case .continueAfterHand:
            return handleContinueAfterHand()

        case .continueAfterEnvido:
            return handleContinueAfterEnvido()

        default:
            return StateMachineError.invalidMove(move: "\(move)", stateName: "Unknown")
        }
    }

    /// Protocol-compliant handle method that ignores errors
    public func handle(move: GameMove) {
        _ = handleWithError(move: move)
    }

    // MARK: - Private Move Handlers

    private func handlePlayCard(_ card: Card) -> StateMachineError? {
        guard let currentPlayer = gameState.players.first(where: {
            $0.id == gameState.players[gameState.currentPlayerIndex].id
        }) else {
            return StateMachineError.invalidMove(move: "playCard", stateName: "PlayerNotFound")
        }

        guard let index = currentPlayer.hand.firstIndex(of: card) else {
            return StateMachineError.invalidMove(move: "playCard", stateName: "CardNotInHand")
        }

        // Update player's hand
        var updatedPlayer = currentPlayer
        updatedPlayer.hand.remove(at: index)

        // Update the player in the gameState
        if let playerIndex = gameState.players.firstIndex(where: { $0.id == currentPlayer.id }) {
            gameState.players[playerIndex] = updatedPlayer
        }

        // Add card to played cards
        gameState.currentHandPlayedCards.append(
            PlayedCardInfo(player: currentPlayer.id, card: card)
        )

        // Check if hand is over and transition state accordingly
        if gameState.currentHandPlayedCards.count == 2 {
            let outcome = determineHandOutcome()
            gameState.handOutcomes.append(outcome)

            // Transition to handOver state
            if let error = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState) {
                return error
            }
        } else {
            // Switch turns
            gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count
        }

        return nil
    }

    private func handleCallTruco() -> StateMachineError? {
        let currentPlayerId = gameState.players[gameState.currentPlayerIndex].id

        // Determine the next Truco state based on current state
        let nextState: TrucoState
        switch gameState.trucoState {
        case .none:
            nextState = .called(caller: currentPlayerId)
        case let .accepted(caller):
            if caller != currentPlayerId {
                nextState = .retrucoCalled(caller: currentPlayerId)
            } else {
                return StateMachineError.invalidMove(move: "callTruco", stateName: "CannotRaiseOwnBet")
            }
        case let .retrucoAccepted(caller):
            if caller != currentPlayerId {
                nextState = .valeCuatroCalled(caller: currentPlayerId)
            } else {
                return StateMachineError.invalidMove(move: "callTruco", stateName: "CannotRaiseOwnBet")
            }
        default:
            return StateMachineError.invalidMove(move: "callTruco", stateName: "InvalidTrucoState")
        }

        // Transition Truco state
        if let error = stateMachine.trucoMachine.transition(to: nextState, in: gameState) {
            return error
        }

        // Switch turns
        gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count

        return nil
    }

    private func handleAcceptTruco() -> StateMachineError? {
        // Determine the next Truco state based on current state
        let nextState: TrucoState
        switch gameState.trucoState {
        case let .called(caller):
            nextState = .accepted(caller: caller)
        case let .retrucoCalled(caller):
            nextState = .retrucoAccepted(caller: caller)
        case let .valeCuatroCalled(caller):
            nextState = .valeCuatroAccepted(caller: caller)
        default:
            return StateMachineError.invalidMove(move: "acceptTruco", stateName: "InvalidTrucoState")
        }

        // Transition to accepted state
        if let error = stateMachine.trucoMachine.transition(to: nextState, in: gameState) {
            return error
        }

        // Switch turn back to caller
        if let callerIndex = gameState.players.firstIndex(where: { $0.id == gameState.players[gameState.currentPlayerIndex].id }) {
            gameState.currentPlayerIndex = (callerIndex + 1) % gameState.players.count
        }

        print("Truco accepted!")
        return nil
    }

    private func handleRejectTruco() -> StateMachineError? {
        // Determine the next Truco state based on current state
        let nextState: TrucoState
        switch gameState.trucoState {
        case let .called(caller):
            nextState = .rejected(caller: caller)
        case let .retrucoCalled(caller):
            nextState = .rejected(caller: caller)
        case let .valeCuatroCalled(caller):
            nextState = .rejected(caller: caller)
        default:
            return StateMachineError.invalidMove(move: "rejectTruco", stateName: "InvalidTrucoState")
        }

        // Transition to rejected state (this will award points to caller)
        if let error = stateMachine.trucoMachine.transition(to: nextState, in: gameState) {
            return error
        }

        // Set round winner to caller for immediate round end
        if case let .rejected(caller) = gameState.trucoState {
            gameState.roundWinner = caller
        }

        // Transition to round summary
        if let error = stateMachine.gamePhaseMachine.transition(to: .roundSummary, in: gameState) {
            return error
        }

        checkMatchEnd()
        return nil
    }

    private func handleCallEnvido() -> StateMachineError? {
        let currentPlayerId = gameState.players[gameState.currentPlayerIndex].id

        // Determine the next Envido state
        let nextState: EnvidoState
        switch gameState.envidoState {
        case .none:
            nextState = .envidoCalled
        case .envidoCalled:
            nextState = .envidoEnvidoCalled
        default:
            return StateMachineError.invalidMove(move: "callEnvido", stateName: "InvalidEnvidoState")
        }

        // Transition Envido state
        if let error = stateMachine.envidoMachine.transition(to: nextState, in: gameState) {
            return error
        }

        // Set caller and switch turns
        gameState.envidoCallerId = currentPlayerId
        gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count

        return nil
    }

    private func handleCallRealEnvido() -> StateMachineError? {
        let currentPlayerId = gameState.players[gameState.currentPlayerIndex].id

        // Transition to real envido state
        if let error = stateMachine.envidoMachine.transition(to: .realEnvidoCalled, in: gameState) {
            return error
        }

        // Set caller and switch turns
        gameState.envidoCallerId = currentPlayerId
        gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count

        return nil
    }

    private func handleCallFaltaEnvido() -> StateMachineError? {
        let currentPlayerId = gameState.players[gameState.currentPlayerIndex].id

        // Transition to falta envido state
        if let error = stateMachine.envidoMachine.transition(to: .faltaEnvidoCalled, in: gameState) {
            return error
        }

        // Set caller and switch turns
        gameState.envidoCallerId = currentPlayerId
        gameState.currentPlayerIndex = (gameState.currentPlayerIndex + 1) % gameState.players.count

        return nil
    }

    private func handleAcceptEnvido() -> StateMachineError? {
        // Resolve Envido first
        resolveEnvido()

        // Transition to accepted state
        if let error = stateMachine.envidoMachine.transition(to: .accepted, in: gameState) {
            return error
        }

        // Transition to envido summary
        if let error = stateMachine.gamePhaseMachine.transition(to: .envidoSummary, in: gameState) {
            return error
        }

        print("Envido accepted!")
        return nil
    }

    private func handleRejectEnvido() -> StateMachineError? {
        // Transition to rejected state (this will award points to caller)
        if let error = stateMachine.envidoMachine.transition(to: .rejected, in: gameState) {
            return error
        }

        checkMatchEnd()
        return nil
    }

    private func handleContinueAfterEnvido() -> StateMachineError? {
        // Clear the envido summary data
        gameState.player1EnvidoPoints = nil
        gameState.player2EnvidoPoints = nil
        gameState.envidoWinnerId = nil

        // The Envido interruption is over, so the turn goes back to the original caller
        if let callerId = gameState.envidoCallerId,
           let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
        {
            gameState.currentPlayerIndex = callerIndex
        }

        // Transition back to playing
        if let error = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState) {
            return error
        }

        return nil
    }

    private func handleContinueAfterHand() -> StateMachineError? {
        checkRoundEnd()

        // If the round didn't end, start the next hand
        if gameState.gamePhase != .roundSummary && gameState.gamePhase != .gameOver {
            gameState.currentHandPlayedCards = []
            startNewHand()

            // Transition back to playing
            if let error = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState) {
                return error
            }
        }

        return nil
    }

    // MARK: - State Synchronization

    private func synchronizeStateMachines() {
        // Synchronize game phase machine
        stateMachine.gamePhaseMachine.reset(to: gameState.gamePhase)

        // Synchronize truco machine
        stateMachine.trucoMachine.reset()
        if gameState.trucoState != .none {
            // Manually set the truco state in the state machine
            // This is a workaround since we can't directly set the internal state
            _ = stateMachine.trucoMachine.transition(to: gameState.trucoState, in: gameState)
        }

        // Synchronize envido machine
        stateMachine.envidoMachine.reset()
        if gameState.envidoState != .none {
            // Manually set the envido state in the state machine
            _ = stateMachine.envidoMachine.transition(to: gameState.envidoState, in: gameState)
        }
    }

    // MARK: - Game Logic Methods (unchanged from original)

    public func dealInitialCards(player1Id: UUID, player2Id: UUID) {
        var newDeck = GameState.newDeck()
        newDeck.shuffle()

        var player1 = Player(id: player1Id, name: "Player 1", hand: [], score: 0)
        var player2 = Player(id: player2Id, name: "Player 2", hand: [], score: 0)

        // Deal 3 cards to each player
        for _ in 0 ..< 3 {
            if let card = newDeck.popLast() {
                player1.hand.append(card)
            }
            if let card = newDeck.popLast() {
                player2.hand.append(card)
            }
        }

        gameState.players = [player1, player2]
        gameState.deck = newDeck
        gameState.currentPlayerIndex = 0
        gameState.currentHandPlayedCards = []
        gameState.handOutcomes = []
        gameState.roundWinner = nil
        gameState.matchWinner = nil
        gameState.manoPlayerId = player1Id

        // Reset all state machines
        stateMachine.resetAll()

        // Transition to playing state
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
    }

    private func determineHandOutcome() -> HandOutcome {
        guard gameState.currentHandPlayedCards.count == 2 else {
            return HandOutcome(winnerId: nil, winningCard: nil, losingCard: nil)
        }

        let play1 = gameState.currentHandPlayedCards[0]
        let play2 = gameState.currentHandPlayedCards[1]

        if play1.card.trucoValue < play2.card.trucoValue {
            return HandOutcome(winnerId: play1.player, winningCard: play1.card, losingCard: play2.card)
        } else if play2.card.trucoValue < play1.card.trucoValue {
            return HandOutcome(winnerId: play2.player, winningCard: play2.card, losingCard: play1.card)
        } else {
            return HandOutcome(winnerId: nil, winningCard: play1.card, losingCard: play2.card)
        }
    }

    private func checkRoundEnd() {
        let handWinners = gameState.handOutcomes.map { $0.winnerId }
        let player1Id = gameState.players[0].id
        let player2Id = gameState.players[1].id

        let player1HandWins = handWinners.filter { $0 == player1Id }.count
        let player2HandWins = handWinners.filter { $0 == player2Id }.count
        let tiedHands = handWinners.filter { $0 == nil }.count

        var roundWinnerDetermined = false

        // Rule 1: A player wins two hands outright
        if player1HandWins >= 2 {
            gameState.roundWinner = player1Id
            roundWinnerDetermined = true
        } else if player2HandWins >= 2 {
            gameState.roundWinner = player2Id
            roundWinnerDetermined = true
        }
        // Rule 2: All three hands played
        else if handWinners.count == 3 {
            if tiedHands == 3 {
                gameState.roundWinner = gameState.manoPlayerId
            } else {
                if let firstNonTiedHandWinner = handWinners.first(where: { $0 != nil }) {
                    gameState.roundWinner = firstNonTiedHandWinner
                }
            }
            roundWinnerDetermined = true
        }

        if roundWinnerDetermined {
            _ = stateMachine.gamePhaseMachine.transition(to: .roundSummary, in: gameState)
            awardRoundPoints()
            checkMatchEnd()
        }
    }

    private func awardRoundPoints() {
        guard let winnerId = gameState.roundWinner,
              let winnerIndex = gameState.players.firstIndex(where: { $0.id == winnerId }) else { return }

        let points: Int
        switch gameState.trucoState {
        case .none:
            points = 1
        case let .rejected(caller):
            points = 1
        case let .accepted(caller):
            points = 2
        case let .retrucoAccepted(caller):
            points = 3
        case let .valeCuatroAccepted(caller):
            points = 4
        default:
            points = 0
        }

        gameState.players[winnerIndex].score += points
        print("Awarded \(points) to \(gameState.players[winnerIndex].name). New score: \(gameState.players[winnerIndex].score)")
    }

    public func checkMatchEnd() {
        if let winningPlayer = gameState.players.first(where: { $0.score >= 30 }) {
            gameState.matchWinner = winningPlayer.id
            _ = stateMachine.gamePhaseMachine.transition(to: .gameOver, in: gameState)
            print("Match over! Winner is \(winningPlayer.name)")
        }
    }

    private func startNewHand() {
        if let lastOutcome = gameState.handOutcomes.last,
           let winnerId = lastOutcome.winnerId
        {
            gameState.currentPlayerIndex = gameState.players.firstIndex(where: { $0.id == winnerId }) ?? 0
        } else {
            gameState.currentPlayerIndex = gameState.players.firstIndex(where: { $0.id == gameState.manoPlayerId }) ?? 0
        }
        print("Starting new hand. Current player: \(gameState.players[gameState.currentPlayerIndex].name)")
    }

    public func startNewRound() {
        // Reset game state for a new round
        gameState.currentHandPlayedCards = []
        gameState.handOutcomes = []
        gameState.roundWinner = nil

        // Reset state machines
        stateMachine.trucoMachine.reset()
        stateMachine.envidoMachine.reset()

        // Determine new mano player (alternates each round)
        if let currentManoIndex = gameState.players.firstIndex(where: { $0.id == gameState.manoPlayerId }) {
            let nextManoIndex = (currentManoIndex + 1) % gameState.players.count
            gameState.manoPlayerId = gameState.players[nextManoIndex].id
            gameState.currentPlayerIndex = nextManoIndex
        } else {
            gameState.manoPlayerId = gameState.players.first?.id
            gameState.currentPlayerIndex = 0
        }

        // Re-deal cards
        var newDeck = GameState.newDeck()
        newDeck.shuffle()
        for i in 0 ..< gameState.players.count {
            gameState.players[i].hand = []
            for _ in 0 ..< 3 {
                if let card = newDeck.popLast() {
                    gameState.players[i].hand.append(card)
                }
            }
        }
        gameState.deck = newDeck

        // Transition to playing
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
        print("Starting new round. New mano: \(gameState.manoPlayerId!)")
    }

    private func calculateEnvidoPoints(for player: Player) -> Int {
        guard player.hand.count >= 3 else {
            fatalError("card in hand count must be >= 3 to call envido")
        }
        var maxPoints = 0
        let groupedBySuit = Dictionary(grouping: player.hand, by: { $0.suit })

        for (_, cardsInSuit) in groupedBySuit {
            if cardsInSuit.count >= 2 {
                let sortedCards = cardsInSuit.sorted { $0.envidoValue < $1.envidoValue }
                if sortedCards.count >= 2 {
                    let points = sortedCards.suffix(2).reduce(0) { $0 + $1.envidoValue } + 20
                    maxPoints = max(maxPoints, points)
                }
            }
        }

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
        guard let player1 = gameState.players.first,
              let player2 = gameState.players.last else { return }

        let player1EnvidoPoints = calculateEnvidoPoints(for: player1)
        let player2EnvidoPoints = calculateEnvidoPoints(for: player2)

        gameState.player1EnvidoPoints = player1EnvidoPoints
        gameState.player2EnvidoPoints = player2EnvidoPoints

        print("Player 1 Envido Points: \(player1EnvidoPoints)")
        print("Player 2 Envido Points: \(player2EnvidoPoints)")

        var winnerId: UUID?
        if player1EnvidoPoints > player2EnvidoPoints {
            winnerId = player1.id
        } else if player2EnvidoPoints > player1EnvidoPoints {
            winnerId = player2.id
        } else {
            winnerId = gameState.manoPlayerId
        }

        gameState.envidoWinnerId = winnerId

        if let winner = winnerId,
           let winnerIndex = gameState.players.firstIndex(where: { $0.id == winner })
        {
            gameState.players[winnerIndex].score += gameState.envidoPoints
            print("Envido winner: \(gameState.players[winnerIndex].name) gets \(gameState.envidoPoints) points.")
            checkMatchEnd()
        }
    }

    // MARK: - CPU Player Logic (unchanged from original)

    public func makeOpponentMove() {
        let cpuPlayer = CPUPlayer(personality: .balanced)

        // 1. Respond to Truco calls (all levels)
        switch gameState.trucoState {
        case .called, .retrucoCalled, .valeCuatroCalled:
            if Double.random(in: 0 ... 1) < cpuPlayer.acceptBetChance {
                _ = handleWithError(move: .acceptTruco)
            } else {
                _ = handleWithError(move: .rejectTruco)
            }
            return
        default:
            break
        }

        // 2. Respond to Envido calls (all levels)
        if gameState.envidoState == .envidoCalled ||
            gameState.envidoState == .envidoEnvidoCalled ||
            gameState.envidoState == .realEnvidoCalled ||
            gameState.envidoState == .faltaEnvidoCalled
        {
            if Double.random(in: 0 ... 1) < cpuPlayer.acceptBetChance {
                _ = handleWithError(move: .acceptEnvido)
            } else {
                _ = handleWithError(move: .rejectEnvido)
            }
            return
        }

        // 3. Decide to call Envido
        if gameState.handOutcomes.isEmpty && gameState.envidoState == .none {
            if Double.random(in: 0 ... 1) < cpuPlayer.callEnvidoChance {
                _ = handleWithError(move: .callEnvido)
                return
            }
        }

        // 4. Decide to call Truco
        if gameState.trucoState == .none {
            if Double.random(in: 0 ... 1) < cpuPlayer.callTrucoChance {
                _ = handleWithError(move: .callTruco)
                return
            }
        }

        // 5. Play a card (default action)
        if let opponent = gameState.players.first(where: {
            $0.id == gameState.players[gameState.currentPlayerIndex].id
        }),
            let randomCard = opponent.hand.randomElement()
        {
            _ = handleWithError(move: .playCard(randomCard))
        }
    }
}
