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

// MARK: - Shared Validation

/// Lightweight structural sanity check shared by the machines.
///
/// The state machines are responsible for *transition legality* (which phase
/// can follow which). Deep gameplay invariants (e.g. exactly two players, full
/// hands) are the engine's responsibility, so this check only guards against
/// structurally impossible states and stays permissive enough to be testable
/// in isolation.
private func isStructurallyValid(_ gameState: GameState) -> Bool {
    guard gameState.players.count <= 4 else { return false }
    guard gameState.currentPlayerIndex >= 0 else { return false }
    guard gameState.handOutcomes.count <= 3 else { return false }
    guard gameState.currentHandPlayedCards.count <= 2 else { return false }
    return true
}

/// Whether a Truco bet may be opened/raised right now. Truco cannot interrupt
/// an Envido exchange that is still being resolved.
private func envidoAllowsTruco(_ gameState: GameState) -> Bool {
    switch gameState.envidoState {
    case .none, .accepted, .rejected:
        return true
    default:
        return false
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
        // preGame -> playing
        stateMachine.addTransition(StateTransition(
            from: .preGame,
            to: .playing,
            condition: { isStructurallyValid($0) },
            action: { $0.gamePhase = .playing },
            errorMessage: "Cannot start game: invalid game state"
        ))

        // playing -> handOver
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .handOver,
            condition: { gameState in
                isStructurallyValid(gameState) &&
                    gameState.currentHandPlayedCards.count == 2
            },
            action: { $0.gamePhase = .handOver },
            errorMessage: "Cannot transition to handOver: hand is not complete"
        ))

        // playing -> roundSummary
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .roundSummary,
            condition: { gameState in
                guard isStructurallyValid(gameState) else { return false }
                return gameState.roundWinner != nil
            },
            action: { $0.gamePhase = .roundSummary },
            errorMessage: "Cannot transition to roundSummary: no round winner"
        ))

        // playing -> envidoSummary
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .envidoSummary,
            condition: { gameState in
                guard isStructurallyValid(gameState) else { return false }
                guard gameState.envidoState == .accepted else { return false }
                return gameState.envidoWinnerId != nil
            },
            action: { $0.gamePhase = .envidoSummary },
            errorMessage: "Cannot transition to envidoSummary: envido not resolved"
        ))

        // playing -> gameOver
        stateMachine.addTransition(StateTransition(
            from: .playing,
            to: .gameOver,
            condition: { gameState in
                guard isStructurallyValid(gameState) else { return false }
                return gameState.matchWinner != nil
            },
            action: { $0.gamePhase = .gameOver },
            errorMessage: "Cannot transition to gameOver: no match winner"
        ))

        // handOver -> playing
        stateMachine.addTransition(StateTransition(
            from: .handOver,
            to: .playing,
            condition: { gameState in
                guard isStructurallyValid(gameState) else { return false }
                return gameState.roundWinner == nil && gameState.handOutcomes.count < 3
            },
            action: { gameState in
                gameState.gamePhase = .playing
                gameState.currentHandPlayedCards = []
            },
            errorMessage: "Cannot continue hand: round is over"
        ))

        // handOver -> roundSummary
        stateMachine.addTransition(StateTransition(
            from: .handOver,
            to: .roundSummary,
            condition: { gameState in
                guard isStructurallyValid(gameState) else { return false }
                return gameState.roundWinner != nil
            },
            action: { $0.gamePhase = .roundSummary },
            errorMessage: "Cannot transition to roundSummary: no round winner"
        ))

        // envidoSummary -> playing
        stateMachine.addTransition(StateTransition(
            from: .envidoSummary,
            to: .playing,
            condition: { isStructurallyValid($0) },
            action: { $0.gamePhase = .playing },
            errorMessage: "Cannot continue after envido"
        ))

        // roundSummary -> playing
        stateMachine.addTransition(StateTransition(
            from: .roundSummary,
            to: .playing,
            condition: { gameState in
                guard isStructurallyValid(gameState) else { return false }
                return gameState.matchWinner == nil
            },
            action: { $0.gamePhase = .playing },
            errorMessage: "Cannot start new round: match is over"
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

/// Models the Truco betting ladder with "raise-in-response" semantics:
/// a player answers a call by raising to the next level (Truco -> Retruco ->
/// Vale Cuatro), which implicitly accepts the lower bet. The caller and the
/// current stake live on `GameState` (`trucoCallerId` / `trucoPoints`); the
/// machine only owns the legal ordering of states and the side effects.
public class TrucoStateMachine {
    private let stateMachine: StateMachine<TrucoState>

    public init() {
        stateMachine = StateMachine(initialState: .none, stateName: "Truco")
        setupTransitions()
    }

    private func setupTransitions() {
        // Opening a bet / raising. These set the stake; the engine records the
        // caller and advances the turn after a successful transition.
        let openOrRaise: [(from: TrucoState, to: TrucoState, points: Int)] = [
            (.none, .trucoCalled, 2),
            (.trucoCalled, .retrucoCalled, 3),
            (.retrucoCalled, .valeCuatroCalled, 4),
        ]
        for step in openOrRaise {
            stateMachine.addTransition(StateTransition(
                from: step.from,
                to: step.to,
                condition: { isStructurallyValid($0) && envidoAllowsTruco($0) },
                action: { gameState in
                    gameState.trucoState = step.to
                    gameState.trucoPoints = step.points
                },
                errorMessage: "Cannot call Truco while Envido is being resolved"
            ))
        }

        // Accepting at any level just locks in the current stake.
        for called in [TrucoState.trucoCalled, .retrucoCalled, .valeCuatroCalled] {
            stateMachine.addTransition(StateTransition(
                from: called,
                to: .accepted,
                condition: { _ in true },
                action: { $0.trucoState = .accepted },
                errorMessage: "Cannot accept Truco"
            ))
        }

        // Rejecting awards the rejected bet's value (stake minus one) to the
        // last caller. Computed from the *current* stake before it is cleared.
        for called in [TrucoState.trucoCalled, .retrucoCalled, .valeCuatroCalled] {
            stateMachine.addTransition(StateTransition(
                from: called,
                to: .rejected,
                condition: { _ in true },
                action: { gameState in
                    let award = max(gameState.trucoPoints - 1, 1)
                    if let callerId = gameState.trucoCallerId,
                       let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
                    {
                        gameState.players[callerIndex].score += award
                    }
                    gameState.trucoState = .rejected
                },
                errorMessage: "Cannot reject Truco"
            ))
        }
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

    public func reset(to state: TrucoState) {
        stateMachine.reset(to: state)
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
        // Envido can only be called before any hand has been played.
        let canOpen = { (gameState: GameState) -> Bool in
            isStructurallyValid(gameState) && gameState.handOutcomes.isEmpty
        }

        // Falta is worth whatever the opponent needs to reach 30, added on top
        // of any points already on the table.
        let faltaPoints = { (gameState: GameState) -> Int in
            let currentId = gameState.currentPlayerIndex < gameState.players.count
                ? gameState.players[gameState.currentPlayerIndex].id
                : nil
            let opponentScore = gameState.players.first(where: { $0.id != currentId })?.score ?? 0
            return 30 - opponentScore
        }

        // none -> envidoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .envidoCalled,
            condition: { canOpen($0) },
            action: { gameState in
                gameState.envidoState = .envidoCalled
                gameState.envidoPoints = 2
            },
            errorMessage: "Cannot call Envido: hands already played"
        ))

        // envidoCalled -> envidoEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .envidoCalled,
            to: .envidoEnvidoCalled,
            condition: { isStructurallyValid($0) },
            action: { gameState in
                gameState.envidoState = .envidoEnvidoCalled
                gameState.envidoPoints = 4
            },
            errorMessage: "Cannot raise Envido"
        ))

        // none -> realEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .realEnvidoCalled,
            condition: { canOpen($0) },
            action: { gameState in
                gameState.envidoState = .realEnvidoCalled
                gameState.envidoPoints = 3
            },
            errorMessage: "Cannot call Real Envido: hands already played"
        ))

        // envidoCalled -> realEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .envidoCalled,
            to: .realEnvidoCalled,
            condition: { isStructurallyValid($0) },
            action: { gameState in
                gameState.envidoState = .realEnvidoCalled
                gameState.envidoPoints += 3
            },
            errorMessage: "Cannot raise to Real Envido"
        ))

        // none -> faltaEnvidoCalled
        stateMachine.addTransition(StateTransition(
            from: .none,
            to: .faltaEnvidoCalled,
            condition: { canOpen($0) },
            action: { gameState in
                gameState.envidoState = .faltaEnvidoCalled
                gameState.envidoPoints = faltaPoints(gameState)
            },
            errorMessage: "Cannot call Falta Envido: hands already played"
        ))

        // {envidoCalled, envidoEnvidoCalled, realEnvidoCalled} -> faltaEnvidoCalled
        for from in [EnvidoState.envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled] {
            stateMachine.addTransition(StateTransition(
                from: from,
                to: .faltaEnvidoCalled,
                condition: { isStructurallyValid($0) },
                action: { gameState in
                    gameState.envidoState = .faltaEnvidoCalled
                    gameState.envidoPoints += faltaPoints(gameState)
                },
                errorMessage: "Cannot raise to Falta Envido"
            ))
        }

        // All call states -> accepted
        for from in [EnvidoState.envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled, .faltaEnvidoCalled] {
            stateMachine.addTransition(StateTransition(
                from: from,
                to: .accepted,
                condition: { _ in true },
                action: { $0.envidoState = .accepted },
                errorMessage: "Cannot accept Envido"
            ))
        }

        // All call states -> rejected (award computed from the *current* level
        // before it is cleared).
        for from in [EnvidoState.envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled, .faltaEnvidoCalled] {
            stateMachine.addTransition(StateTransition(
                from: from,
                to: .rejected,
                condition: { _ in true },
                action: { gameState in
                    let award: Int
                    switch gameState.envidoState {
                    case .realEnvidoCalled, .envidoEnvidoCalled, .faltaEnvidoCalled:
                        award = 2
                    default:
                        award = 1
                    }
                    if let callerId = gameState.envidoCallerId,
                       let callerIndex = gameState.players.firstIndex(where: { $0.id == callerId })
                    {
                        gameState.players[callerIndex].score += award
                    }
                    gameState.envidoState = .rejected
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

    public func reset(to state: EnvidoState) {
        stateMachine.reset(to: state)
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
        // Validate that the move is allowed in the current phase.
        switch move {
        case .playCard, .callTruco, .acceptTruco, .rejectTruco,
             .callEnvido, .callRealEnvido, .callFaltaEnvido,
             .acceptEnvido, .rejectEnvido:
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

    /// Aligns the machines' cached state with the authoritative values held on
    /// `GameState`. Call this whenever `GameState` is mutated outside a
    /// transition (e.g. when constructing an engine around an existing state).
    public func synchronize(with gameState: GameState) {
        gamePhaseMachine.reset(to: gameState.gamePhase)
        trucoMachine.reset(to: gameState.trucoState)
        envidoMachine.reset(to: gameState.envidoState)
    }

    public func resetAll() {
        gamePhaseMachine.reset(to: .preGame)
        trucoMachine.reset()
        envidoMachine.reset()
    }
}
