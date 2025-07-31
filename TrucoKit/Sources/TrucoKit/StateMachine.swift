import Foundation

// MARK: - State Machine Framework

/// Represents a state transition with validation and side effects
public struct StateTransition<State: Hashable> {
    public let from: State
    public let to: State
    public let condition: (GameState) -> Bool
    public let action: (GameState) -> Void
    public let errorMessage: String

    public init(
        from: State,
        to: State,
        condition: @escaping (GameState) -> Bool,
        action: @escaping (GameState) -> Void,
        errorMessage: String
    ) {
        self.from = from
        self.to = to
        self.condition = condition
        self.action = action
        self.errorMessage = errorMessage
    }
}

/// Represents a state machine with explicit transition rules
public class StateMachine<State: Hashable> {
    private var transitions: [StateTransition<State>] = []
    private var currentState: State
    private let stateName: String

    public init(initialState: State, stateName: String) {
        currentState = initialState
        self.stateName = stateName
    }

    public func addTransition(_ transition: StateTransition<State>) {
        transitions.append(transition)
    }

    public func canTransition(to newState: State, in gameState: GameState) -> Bool {
        return transitions.contains { transition in
            transition.from == currentState &&
                transition.to == newState &&
                transition.condition(gameState)
        }
    }

    public func transition(to newState: State, in gameState: GameState) -> StateMachineError? {
        guard let transition = transitions.first(where: {
            $0.from == currentState && $0.to == newState
        }) else {
            return .invalidTransition(from: currentState, to: newState, stateName: stateName)
        }

        guard transition.condition(gameState) else {
            return .transitionConditionFailed(message: transition.errorMessage, stateName: stateName)
        }

        // Execute the transition action
        transition.action(gameState)
        currentState = newState
        return nil
    }

    public func getCurrentState() -> State {
        return currentState
    }

    public func reset(to state: State) {
        currentState = state
    }
}

/// Errors that can occur during state transitions
public enum StateMachineError: Error, LocalizedError {
    case invalidTransition(from: Any, to: Any, stateName: String)
    case transitionConditionFailed(message: String, stateName: String)
    case invalidMove(move: String, stateName: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidTransition(from, to, stateName):
            return "Invalid transition in \(stateName) from \(from) to \(to)"
        case let .transitionConditionFailed(message, stateName):
            return "\(stateName) transition failed: \(message)"
        case let .invalidMove(move, stateName):
            return "Invalid move '\(move)' in \(stateName)"
        }
    }
}

// MARK: - Game Phase State Machine

public class GamePhaseStateMachine {
    private let stateMachine: StateMachine<GamePhase>

    public init() {
        stateMachine = StateMachine(initialState: .preGame, stateName: "GamePhase")
        setupTransitions()
    }

    private func setupTransitions() {
        // Comprehensive sanity checks for game state integrity

        // Validate game state structure
        let validateGameState = { (gameState: GameState) -> Bool in
            // Check that players exist and have valid data
            guard gameState.players.count >= 2 else { return false }
            guard gameState.players.count <= 4 else { return false } // Max 4 players for Truco

            // Validate player data
            for player in gameState.players {
                guard !player.name.isEmpty else { return false }
                guard player.score >= 0 else { return false }
                guard player.score <= 30 else { return false } // Max score in Truco
            }

            // Validate current player index
            guard gameState.currentPlayerIndex >= 0 else { return false }
            guard gameState.currentPlayerIndex < gameState.players.count else { return false }

            // Validate hand outcomes
            guard gameState.handOutcomes.count <= 3 else { return false } // Max 3 hands per round

            // Validate played cards
            guard gameState.currentHandPlayedCards.count <= 2 else { return false } // Max 2 cards per hand

            // Validate betting states
            if gameState.trucoState != .none {
                guard gameState.trucoCallerId != nil else { return false }
                guard gameState.trucoPoints >= 1 else { return false }
                guard gameState.trucoPoints <= 4 else { return false }
            }

            if gameState.envidoState != .none {
                guard gameState.envidoCallerId != nil else { return false }
                guard gameState.envidoPoints >= 1 else { return false }
                guard gameState.envidoPoints <= 30 else { return false }
            }

            return true
        }

        // preGame -> playing
        stateMachine.addTransition(StateTransition(
            from: .preGame,
            to: .playing,
            condition: { gameState in
                // Sanity check: ensure game can start
                guard validateGameState(gameState) else { return false }
                guard gameState.players.count >= 2 else { return false }
                guard gameState.players.allSatisfy({ $0.hand.count == 3 }) else { return false }
                guard gameState.deck.count >= 0 else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .playing
            },
            errorMessage: "Cannot start game: invalid game state or insufficient players/cards"
        ))

        // playing -> handOver
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .handOver,
            condition: { gameState in
                // Sanity check: ensure hand is complete
                guard validateGameState(gameState) else { return false }
                guard gameState.currentHandPlayedCards.count == 2 else { return false }
                guard gameState.currentHandPlayedCards.allSatisfy({ $0.player != nil }) else { return false }
                guard gameState.currentHandPlayedCards.allSatisfy({ $0.card != nil }) else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .handOver
            },
            errorMessage: "Cannot transition to handOver: invalid hand state or insufficient cards played"
        ))

        // playing -> roundSummary
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .roundSummary,
            condition: { gameState in
                // Sanity check: ensure round has a valid winner
                guard validateGameState(gameState) else { return false }
                guard let roundWinner = gameState.roundWinner else { return false }
                guard gameState.players.contains(where: { $0.id == roundWinner }) else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .roundSummary
            },
            errorMessage: "Cannot transition to roundSummary: no valid round winner"
        ))

        // playing -> envidoSummary
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .envidoSummary,
            condition: { gameState in
                // Sanity check: ensure envido is properly resolved
                guard validateGameState(gameState) else { return false }
                guard gameState.envidoState == .accepted else { return false }
                guard gameState.player1EnvidoPoints != nil else { return false }
                guard gameState.player2EnvidoPoints != nil else { return false }
                guard gameState.envidoWinnerId != nil else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .envidoSummary
            },
            errorMessage: "Cannot transition to envidoSummary: envido not properly resolved"
        ))

        // playing -> gameOver
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .gameOver,
            condition: { gameState in
                // Sanity check: ensure match has a valid winner
                guard validateGameState(gameState) else { return false }
                guard let matchWinner = gameState.matchWinner else { return false }
                guard gameState.players.contains(where: { $0.id == matchWinner }) else { return false }
                guard let winnerPlayer = gameState.players.first(where: { $0.id == matchWinner }) else { return false }
                guard winnerPlayer.score >= 30 else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .gameOver
            },
            errorMessage: "Cannot transition to gameOver: no valid match winner"
        ))

        // handOver -> playing
        stateMachine.addTransition(StateTransition(
            from: .handOver,
            to: .playing,
            condition: { gameState in
                // Sanity check: ensure round can continue
                guard validateGameState(gameState) else { return false }
                guard gameState.handOutcomes.count < 3 else { return false }
                guard gameState.roundWinner == nil else { return false }
                guard gameState.players.allSatisfy({ $0.hand.count > 0 }) else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .playing
                gameState.currentHandPlayedCards = []
            },
            errorMessage: "Cannot continue hand: round should be over or players have no cards"
        ))

        // handOver -> roundSummary
        stateMachine.addTransition(StateTransition(
            from: .handOver,
            to: .roundSummary,
            condition: { gameState in
                // Sanity check: ensure round has a valid winner
                guard validateGameState(gameState) else { return false }
                guard let roundWinner = gameState.roundWinner else { return false }
                guard gameState.players.contains(where: { $0.id == roundWinner }) else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .roundSummary
            },
            errorMessage: "Cannot transition to roundSummary: no valid round winner"
        ))

        // envidoSummary -> playing
        stateMachine.addTransition(StateTransition(
            from: .envidoSummary,
            to: .playing,
            condition: { gameState in
                // Sanity check: ensure envido summary is complete
                guard validateGameState(gameState) else { return false }
                guard gameState.player1EnvidoPoints == nil else { return false }
                guard gameState.player2EnvidoPoints == nil else { return false }
                guard gameState.envidoWinnerId == nil else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .playing
                gameState.player1EnvidoPoints = nil
                gameState.player2EnvidoPoints = nil
                gameState.envidoWinnerId = nil
            },
            errorMessage: "Cannot continue after envido: summary not cleared"
        ))

        // roundSummary -> playing
        stateMachine.addTransition(StateTransition(
            from: .roundSummary,
            to: .playing,
            condition: { gameState in
                // Sanity check: ensure new round can start
                guard validateGameState(gameState) else { return false }
                guard gameState.matchWinner == nil else { return false }
                guard gameState.players.allSatisfy({ $0.hand.count == 3 }) else { return false }
                guard gameState.deck.count >= 0 else { return false }
                return true
            },
            action: { gameState in
                gameState.gamePhase = .playing
                // Reset round state
                gameState.currentHandPlayedCards = []
                gameState.handOutcomes = []
                gameState.roundWinner = nil
                gameState.trucoState = .none
                gameState.trucoCallerId = nil
                gameState.trucoPoints = 0
                gameState.envidoState = .none
                gameState.envidoCallerId = nil
                gameState.envidoPoints = 0
            },
            errorMessage: "Cannot start new round: match is over or invalid game state"
        ))
    }

    public func transition(to newPhase: GamePhase, in gameState: GameState) -> StateMachineError? {
        return stateMachine.transition(to: newPhase, in: gameState)
    }

    public func getCurrentPhase() -> GamePhase {
        return stateMachine.getCurrentState()
    }

    public func reset(to phase: GamePhase) {
        stateMachine.reset(to: phase)
    }
}

// MARK: - Truco State Machine

public class TrucoStateMachine {
    private let stateMachine: StateMachine<TrucoState>

    public init() {
        stateMachine = StateMachine(initialState: .none, stateName: "Truco")
        setupTransitions()
    }

    private func setupTransitions() {
        // Comprehensive sanity checks for game state integrity

        // Validate game state structure
        let validateGameState = { (gameState: GameState) -> Bool in
            // Check that players exist and have valid data
            guard gameState.players.count >= 2 else { return false }
            guard gameState.players.count <= 4 else { return false } // Max 4 players for Truco

            // Validate player data
            for player in gameState.players {
                guard !player.name.isEmpty else { return false }
                guard player.score >= 0 else { return false }
                guard player.score <= 30 else { return false } // Max score in Truco
            }

            // Validate current player index
            guard gameState.currentPlayerIndex >= 0 else { return false }
            guard gameState.currentPlayerIndex < gameState.players.count else { return false }

            // Validate hand outcomes
            guard gameState.handOutcomes.count <= 3 else { return false } // Max 3 hands per round

            // Validate played cards
            guard gameState.currentHandPlayedCards.count <= 2 else { return false } // Max 2 cards per hand

            // Validate betting states
            if gameState.trucoState != .none {
                guard gameState.trucoCallerId != nil else { return false }
                guard gameState.trucoPoints >= 1 else { return false }
                guard gameState.trucoPoints <= 4 else { return false }
            }

            if gameState.envidoState != .none {
                guard gameState.envidoCallerId != nil else { return false }
                guard gameState.envidoPoints >= 1 else { return false }
                guard gameState.envidoPoints <= 30 else { return false }
            }

            return true
        }

        // none -> trucoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .trucoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for truco call
                guard validateGameState(gameState) else { return false }
                guard gameState.envidoState == .none ||
                    gameState.envidoState == .rejected ||
                    gameState.envidoState == .accepted else { return false }
                return true
            },
            action: { gameState in
                gameState.trucoState = .trucoCalled
                gameState.trucoPoints = 2
            },
            errorMessage: "Cannot call Truco while Envido is being resolved"
        ))

        // trucoCalled -> retrucoCalled
        stateMachine.addTransition(StateTransition(
            from: .trucoCalled,
            to: .retrucoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for retruco call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.trucoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                gameState.trucoState = .retrucoCalled
                gameState.trucoPoints = 3
            },
            errorMessage: "Cannot raise your own bet"
        ))

        // retrucoCalled -> valeCuatroCalled
        stateMachine.addTransition(StateTransition(
            from: .retrucoCalled,
            to: .valeCuatroCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for valeCuatro call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.trucoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                gameState.trucoState = .valeCuatroCalled
                gameState.trucoPoints = 4
            },
            errorMessage: "Cannot raise your own bet"
        ))

        // trucoCalled -> accepted
        stateMachine.addTransition(StateTransition(
            from: .trucoCalled,
            to: .accepted,
            condition: { _ in true },
            action: { gameState in
                gameState.trucoState = .accepted
            },
            errorMessage: "Cannot accept Truco"
        ))

        // retrucoCalled -> accepted
        stateMachine.addTransition(StateTransition(
            from: .retrucoCalled,
            to: .accepted,
            condition: { _ in true },
            action: { gameState in
                gameState.trucoState = .accepted
            },
            errorMessage: "Cannot accept Retruco"
        ))

        // valeCuatroCalled -> accepted
        stateMachine.addTransition(StateTransition(
            from: .valeCuatroCalled,
            to: .accepted,
            condition: { _ in true },
            action: { gameState in
                gameState.trucoState = .accepted
            },
            errorMessage: "Cannot accept Vale Cuatro"
        ))

        // trucoCalled -> rejected
        stateMachine.addTransition(StateTransition(
            from: .trucoCalled,
            to: .rejected,
            condition: { _ in true },
            action: { gameState in
                gameState.trucoState = .rejected
                if let callerId = gameState.trucoCallerId,
                   let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
                {
                    let pointsAwarded = gameState.trucoPoints > 1 ? gameState.trucoPoints - 1 : 1
                    gameState.players[callerIndex].score += pointsAwarded
                }
            },
            errorMessage: "Cannot reject Truco"
        ))

        // retrucoCalled -> rejected
        stateMachine.addTransition(StateTransition(
            from: .retrucoCalled,
            to: .rejected,
            condition: { _ in true },
            action: { gameState in
                gameState.trucoState = .rejected
                if let callerId = gameState.trucoCallerId,
                   let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
                {
                    let pointsAwarded = gameState.trucoPoints > 1 ? gameState.trucoPoints - 1 : 1
                    gameState.players[callerIndex].score += pointsAwarded
                }
            },
            errorMessage: "Cannot reject Retruco"
        ))

        // valeCuatroCalled -> rejected
        stateMachine.addTransition(StateTransition(
            from: .valeCuatroCalled,
            to: .rejected,
            condition: { _ in true },
            action: { gameState in
                gameState.trucoState = .rejected
                if let callerId = gameState.trucoCallerId,
                   let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
                {
                    let pointsAwarded = gameState.trucoPoints > 1 ? gameState.trucoPoints - 1 : 1
                    gameState.players[callerIndex].score += pointsAwarded
                }
            },
            errorMessage: "Cannot reject Vale Cuatro"
        ))
    }

    public func transition(to newState: TrucoState, in gameState: GameState) -> StateMachineError? {
        return stateMachine.transition(to: newState, in: gameState)
    }

    public func getCurrentState() -> TrucoState {
        return stateMachine.getCurrentState()
    }

    public func reset() {
        stateMachine.reset(to: .none)
    }
}

// MARK: - Envido State Machine

public class EnvidoStateMachine {
    private let stateMachine: StateMachine<EnvidoState>

    public init() {
        stateMachine = StateMachine(initialState: .none, stateName: "Envido")
        setupTransitions()
    }

    private func setupTransitions() {
        // Comprehensive sanity checks for game state integrity

        // Validate game state structure
        let validateGameState = { (gameState: GameState) -> Bool in
            // Check that players exist and have valid data
            guard gameState.players.count >= 2 else { return false }
            guard gameState.players.count <= 4 else { return false } // Max 4 players for Truco

            // Validate player data
            for player in gameState.players {
                guard !player.name.isEmpty else { return false }
                guard player.score >= 0 else { return false }
                guard player.score <= 30 else { return false } // Max score in Truco
            }

            // Validate current player index
            guard gameState.currentPlayerIndex >= 0 else { return false }
            guard gameState.currentPlayerIndex < gameState.players.count else { return false }

            // Validate hand outcomes
            guard gameState.handOutcomes.count <= 3 else { return false } // Max 3 hands per round

            // Validate played cards
            guard gameState.currentHandPlayedCards.count <= 2 else { return false } // Max 2 cards per hand

            // Validate betting states
            if gameState.trucoState != .none {
                guard gameState.trucoCallerId != nil else { return false }
                guard gameState.trucoPoints >= 1 else { return false }
                guard gameState.trucoPoints <= 4 else { return false }
            }

            if gameState.envidoState != .none {
                guard gameState.envidoCallerId != nil else { return false }
                guard gameState.envidoPoints >= 1 else { return false }
                guard gameState.envidoPoints <= 30 else { return false }
            }

            return true
        }

        // none -> envidoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .envidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for envido call
                guard validateGameState(gameState) else { return false }
                guard gameState.handOutcomes.isEmpty, !gameState.players.isEmpty else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                gameState.envidoState = .envidoCalled
                gameState.envidoPoints = 2
            },
            errorMessage: "Cannot call Envido: hands already played or invalid caller"
        ))

        // envidoCalled -> envidoEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .envidoCalled,
            to: .envidoEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for envidoEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                gameState.envidoState = .envidoEnvidoCalled
                gameState.envidoPoints = 4
            },
            errorMessage: "Cannot raise your own Envido"
        ))

        // none -> realEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .realEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for realEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.handOutcomes.isEmpty, !gameState.players.isEmpty else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                gameState.envidoState = .realEnvidoCalled
                gameState.envidoPoints = 3
            },
            errorMessage: "Cannot call Real Envido: hands already played or invalid caller"
        ))

        // envidoCalled -> realEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .envidoCalled,
            to: .realEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for realEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                let basePoints = gameState.envidoPoints
                gameState.envidoState = .realEnvidoCalled
                gameState.envidoPoints = basePoints + 3
            },
            errorMessage: "Cannot call Real Envido on your own bet"
        ))

        // none -> faltaEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .faltaEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for faltaEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.handOutcomes.isEmpty,
                      gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                gameState.envidoState = .faltaEnvidoCalled
                let opponentScore = gameState.players.first(where: {
                    $0.id != gameState.players[gameState.currentPlayerIndex].id
                })?.score ?? 0
                let faltaPoints = 30 - opponentScore
                gameState.envidoPoints = faltaPoints
            },
            errorMessage: "Cannot call Falta Envido: hands already played or invalid caller"
        ))

        // envidoCalled -> faltaEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .envidoCalled,
            to: .faltaEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for faltaEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                let basePoints = gameState.envidoPoints
                gameState.envidoState = .faltaEnvidoCalled
                let opponentScore = gameState.players.first(where: {
                    $0.id != gameState.players[gameState.currentPlayerIndex].id
                })?.score ?? 0
                let faltaPoints = 30 - opponentScore
                gameState.envidoPoints = basePoints + faltaPoints
            },
            errorMessage: "Cannot call Falta Envido on your own bet"
        ))

        // realEnvidoCalled -> faltaEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .realEnvidoCalled,
            to: .faltaEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for faltaEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                let basePoints = gameState.envidoPoints
                gameState.envidoState = .faltaEnvidoCalled
                let opponentScore = gameState.players.first(where: {
                    $0.id != gameState.players[gameState.currentPlayerIndex].id
                })?.score ?? 0
                let faltaPoints = 30 - opponentScore
                gameState.envidoPoints = basePoints + faltaPoints
            },
            errorMessage: "Cannot call Falta Envido on your own bet"
        ))

        // envidoEnvidoCalled -> faltaEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .envidoEnvidoCalled,
            to: .faltaEnvidoCalled,
            condition: { gameState in
                // Sanity check: ensure game state is valid for faltaEnvido call
                guard validateGameState(gameState) else { return false }
                guard gameState.currentPlayerIndex < gameState.players.count else { return false }
                guard gameState.envidoCallerId != gameState.players[gameState.currentPlayerIndex].id else { return false }
                return true
            },
            action: { gameState in
                let basePoints = gameState.envidoPoints
                gameState.envidoState = .faltaEnvidoCalled
                let opponentScore = gameState.players.first(where: {
                    $0.id != gameState.players[gameState.currentPlayerIndex].id
                })?.score ?? 0
                let faltaPoints = 30 - opponentScore
                gameState.envidoPoints = basePoints + faltaPoints
            },
            errorMessage: "Cannot call Falta Envido on your own bet"
        ))

        // All states -> accepted
        for fromState in [EnvidoState.envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled, .faltaEnvidoCalled] {
            stateMachine.addTransition(StateTransition(
                from: fromState,
                to: .accepted,
                condition: { _ in true },
                action: { gameState in
                    gameState.envidoState = .accepted
                },
                errorMessage: "Cannot accept Envido"
            ))
        }

        // All states -> rejected
        for fromState in [EnvidoState.envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled, .faltaEnvidoCalled] {
            stateMachine.addTransition(StateTransition(
                from: fromState,
                to: .rejected,
                condition: { _ in true },
                action: { gameState in
                    gameState.envidoState = .rejected
                    if let callerId = gameState.envidoCallerId,
                       let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
                    {
                        var pointsToAward = 1
                        if gameState.envidoState == .realEnvidoCalled {
                            pointsToAward = 2
                        }
                        if gameState.envidoState == .envidoEnvidoCalled {
                            pointsToAward = 2
                        }
                        gameState.players[callerIndex].score += pointsToAward
                    }
                },
                errorMessage: "Cannot reject Envido"
            ))
        }
    }

    public func transition(to newState: EnvidoState, in gameState: GameState) -> StateMachineError? {
        return stateMachine.transition(to: newState, in: gameState)
    }

    public func getCurrentState() -> EnvidoState {
        return stateMachine.getCurrentState()
    }

    public func reset() {
        stateMachine.reset(to: .none)
    }
}

// MARK: - Hierarchical State Machine Manager

public class HierarchicalStateMachine {
    public let gamePhaseMachine: GamePhaseStateMachine
    public let trucoMachine: TrucoStateMachine
    public let envidoMachine: EnvidoStateMachine

    public init() {
        gamePhaseMachine = GamePhaseStateMachine()
        trucoMachine = TrucoStateMachine()
        envidoMachine = EnvidoStateMachine()
    }

    public func validateMove(_ move: GameMove, in _: GameState) -> StateMachineError? {
        // Validate that the move is allowed in the current state
        switch move {
        case .playCard:
            guard gamePhaseMachine.getCurrentPhase() == .playing else {
                return .invalidMove(move: "playCard", stateName: "GamePhase")
            }
            return nil

        case .callTruco:
            guard gamePhaseMachine.getCurrentPhase() == .playing else {
                return .invalidMove(move: "callTruco", stateName: "GamePhase")
            }
            return nil

        case .acceptTruco, .rejectTruco:
            guard gamePhaseMachine.getCurrentPhase() == .playing else {
                return .invalidMove(move: "\(move)", stateName: "GamePhase")
            }
            return nil

        case .callEnvido, .callRealEnvido, .callFaltaEnvido:
            guard gamePhaseMachine.getCurrentPhase() == .playing else {
                return .invalidMove(move: "\(move)", stateName: "GamePhase")
            }
            return nil

        case .acceptEnvido, .rejectEnvido:
            guard gamePhaseMachine.getCurrentPhase() == .playing else {
                return .invalidMove(move: "\(move)", stateName: "GamePhase")
            }
            return nil

        case .continueAfterHand:
            guard gamePhaseMachine.getCurrentPhase() == .handOver else {
                return .invalidMove(move: "continueAfterHand", stateName: "GamePhase")
            }
            return nil

        case .continueAfterEnvido:
            guard gamePhaseMachine.getCurrentPhase() == .envidoSummary else {
                return .invalidMove(move: "continueAfterEnvido", stateName: "GamePhase")
            }
            return nil

        default:
            return nil
        }
    }

    public func resetAll() {
        gamePhaseMachine.reset(to: .preGame)
        trucoMachine.reset()
        envidoMachine.reset()
    }
}
