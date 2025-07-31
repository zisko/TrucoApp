@testable import TrucoKit
import XCTest

final class StateMachineTests: XCTestCase {
    var gameState: GameState!
    var stateMachine: HierarchicalStateMachine!

    override func setUp() {
        super.setUp()
        gameState = GameState()
        stateMachine = HierarchicalStateMachine()
    }

    override func tearDown() {
        gameState = nil
        stateMachine = nil
        super.tearDown()
    }

    // MARK: - Game Phase State Machine Tests

    func testGamePhaseInitialState() {
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .preGame)
    }

    func testValidGamePhaseTransition() {
        // Test preGame -> playing transition
        let error = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .playing)
    }

    func testInvalidGamePhaseTransition() {
        // Test invalid transition: preGame -> handOver (should fail)
        let error = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState)
        XCTAssertNotNil(error)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .preGame)
    }

    func testPlayingToHandOverTransition() {
        // Setup: transition to playing first
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)

        // Setup: add 2 played cards
        gameState.currentHandPlayedCards = [
            PlayedCardInfo(player: UUID(), card: Card(rank: .ace, suit: .espadas)),
            PlayedCardInfo(player: UUID(), card: Card(rank: .two, suit: .bastos)),
        ]

        // Test transition
        let error = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .handOver)
    }

    func testPlayingToHandOverTransitionFailsWithInsufficientCards() {
        // Setup: transition to playing first
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)

        // Setup: add only 1 played card
        gameState.currentHandPlayedCards = [
            PlayedCardInfo(player: UUID(), card: Card(rank: .ace, suit: .espadas)),
        ]

        // Test transition should fail
        let error = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState)
        XCTAssertNotNil(error)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .playing)
    }

    func testPlayingToRoundSummaryTransition() {
        // Setup: transition to playing first
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)

        // Setup: set round winner
        gameState.roundWinner = UUID()

        // Test transition
        let error = stateMachine.gamePhaseMachine.transition(to: .roundSummary, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .roundSummary)
    }

    func testPlayingToGameOverTransition() {
        // Setup: transition to playing first
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)

        // Setup: set match winner
        gameState.matchWinner = UUID()

        // Test transition
        let error = stateMachine.gamePhaseMachine.transition(to: .gameOver, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .gameOver)
    }

    // MARK: - Truco State Machine Tests

    func testTrucoInitialState() {
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .none)
    }

    func testValidTrucoTransition() {
        // Setup: ensure envido state allows truco
        gameState.envidoState = .none

        // Test none -> trucoCalled
        let error = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .trucoCalled)
        XCTAssertEqual(gameState.trucoPoints, 2)
    }

    func testTrucoTransitionFailsWhenEnvidoActive() {
        // Setup: envido is being resolved
        gameState.envidoState = .envidoCalled

        // Test transition should fail
        let error = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)
        XCTAssertNotNil(error)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .none)
    }

    func testTrucoEscalation() {
        // Setup: start with truco called
        gameState.envidoState = .none
        _ = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)

        // Test trucoCalled -> retrucoCalled
        let error = stateMachine.trucoMachine.transition(to: .retrucoCalled, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .retrucoCalled)
        XCTAssertEqual(gameState.trucoPoints, 3)
    }

    func testTrucoAcceptance() {
        // Setup: start with truco called
        gameState.envidoState = .none
        _ = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)

        // Test trucoCalled -> accepted
        let error = stateMachine.trucoMachine.transition(to: .accepted, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .accepted)
    }

    func testTrucoRejection() {
        // Setup: start with truco called and set caller
        gameState.envidoState = .none
        gameState.trucoCallerId = UUID()
        gameState.trucoPoints = 2
        _ = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)

        // Add a player to award points to
        let player = Player(id: gameState.trucoCallerId!, name: "Test Player", hand: [], score: 0)
        gameState.players = [player]

        // Test trucoCalled -> rejected
        let error = stateMachine.trucoMachine.transition(to: .rejected, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .rejected)
        XCTAssertEqual(gameState.players[0].score, 1) // Should award 1 point
    }

    // MARK: - Envido State Machine Tests

    func testEnvidoInitialState() {
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .none)
    }

    func testValidEnvidoTransition() {
        // Setup: ensure no hands played
        gameState.handOutcomes = []

        // Test none -> envidoCalled
        let error = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .envidoCalled)
        XCTAssertEqual(gameState.envidoPoints, 2)
    }

    func testEnvidoTransitionFailsWhenHandsPlayed() {
        // Setup: hands have been played
        gameState.handOutcomes = [HandOutcome(winnerId: UUID(), winningCard: nil, losingCard: nil)]

        // Test transition should fail
        let error = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)
        XCTAssertNotNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .none)
    }

    func testEnvidoEscalation() {
        // Setup: start with envido called
        gameState.handOutcomes = []
        _ = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)

        // Test envidoCalled -> envidoEnvidoCalled
        let error = stateMachine.envidoMachine.transition(to: .envidoEnvidoCalled, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .envidoEnvidoCalled)
        XCTAssertEqual(gameState.envidoPoints, 4)
    }

    func testRealEnvidoTransition() {
        // Setup: ensure no hands played
        gameState.handOutcomes = []

        // Test none -> realEnvidoCalled
        let error = stateMachine.envidoMachine.transition(to: .realEnvidoCalled, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .realEnvidoCalled)
        XCTAssertEqual(gameState.envidoPoints, 3)
    }

    func testFaltaEnvidoTransition() {
        // Setup: ensure no hands played and add players
        gameState.handOutcomes = []
        let player1 = Player(id: UUID(), name: "Player 1", hand: [], score: 10)
        let player2 = Player(id: UUID(), name: "Player 2", hand: [], score: 5)
        gameState.players = [player1, player2]
        gameState.currentPlayerIndex = 0

        // Test none -> faltaEnvidoCalled
        let error = stateMachine.envidoMachine.transition(to: .faltaEnvidoCalled, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .faltaEnvidoCalled)
        XCTAssertEqual(gameState.envidoPoints, 25) // 30 - 5 = 25
    }

    func testEnvidoAcceptance() {
        // Setup: start with envido called
        gameState.handOutcomes = []
        gameState.players = [Player(id: UUID(), name: "Player 1", hand: [], score: 0)]
        _ = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)

        // Test envidoCalled -> accepted
        let error = stateMachine.envidoMachine.transition(to: .accepted, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .accepted)
    }

    func testEnvidoRejection() {
        // Setup: start with envido called and set caller
        gameState.handOutcomes = []
        let callerId = UUID()
        gameState.envidoCallerId = callerId
        gameState.players = [Player(id: callerId, name: "Test Player", hand: [], score: 0)]
        _ = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)

        // Test envidoCalled -> rejected
        let error = stateMachine.envidoMachine.transition(to: .rejected, in: gameState)
        XCTAssertNil(error)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .rejected)
        XCTAssertEqual(gameState.players[0].score, 1) // Should award 1 point
    }

    // MARK: - Hierarchical State Machine Tests

    func testMoveValidation() {
        // Test valid move in correct state
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)

        let error = stateMachine.validateMove(.playCard(Card(rank: .ace, suit: .espadas)), in: gameState)
        XCTAssertNil(error)
    }

    func testMoveValidationFails() {
        // Test invalid move in wrong state (should be in playing to play card)
        let error = stateMachine.validateMove(.playCard(Card(rank: .ace, suit: .espadas)), in: gameState)
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("playCard"), true)
    }

    func testContinueAfterHandValidation() {
        // Setup: transition to handOver
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
        gameState.currentHandPlayedCards = [
            PlayedCardInfo(player: UUID(), card: Card(rank: .ace, suit: .espadas)),
            PlayedCardInfo(player: UUID(), card: Card(rank: .two, suit: .bastos)),
        ]
        _ = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState)

        // Test valid continue move
        let error = stateMachine.validateMove(.continueAfterHand, in: gameState)
        XCTAssertNil(error)
    }

    func testContinueAfterHandValidationFails() {
        // Test invalid continue move in wrong state
        let error = stateMachine.validateMove(.continueAfterHand, in: gameState)
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("continueAfterHand"), true)
    }

    // MARK: - State Machine Reset Tests

    func testGamePhaseReset() {
        // Setup: transition to playing
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .playing)

        // Test reset
        stateMachine.gamePhaseMachine.reset(to: .preGame)
        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .preGame)
    }

    func testTrucoReset() {
        // Setup: transition to truco called
        gameState.envidoState = .none
        _ = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .trucoCalled)

        // Test reset
        stateMachine.trucoMachine.reset()
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .none)
    }

    func testEnvidoReset() {
        // Setup: transition to envido called
        gameState.handOutcomes = []
        _ = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .envidoCalled)

        // Test reset
        stateMachine.envidoMachine.reset()
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .none)
    }

    func testHierarchicalReset() {
        // Setup: transition all machines to different states
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
        gameState.envidoState = .none
        _ = stateMachine.trucoMachine.transition(to: .trucoCalled, in: gameState)
        gameState.handOutcomes = []
        _ = stateMachine.envidoMachine.transition(to: .envidoCalled, in: gameState)

        // Test reset all
        stateMachine.resetAll()

        XCTAssertEqual(stateMachine.gamePhaseMachine.getCurrentPhase(), .preGame)
        XCTAssertEqual(stateMachine.trucoMachine.getCurrentState(), .none)
        XCTAssertEqual(stateMachine.envidoMachine.getCurrentState(), .none)
    }

    // MARK: - Error Message Tests

    func testErrorMessagesAreDescriptive() {
        // Test invalid transition error message
        let error = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState)
        XCTAssertNotNil(error)
        XCTAssertTrue(error?.localizedDescription.contains("Invalid transition") == true)
        XCTAssertTrue(error?.localizedDescription.contains("GamePhase") == true)

        // Test transition condition failed error message
        _ = stateMachine.gamePhaseMachine.transition(to: .playing, in: gameState)
        gameState.currentHandPlayedCards = [PlayedCardInfo(player: UUID(), card: Card(rank: .ace, suit: .espadas))]
        let conditionError = stateMachine.gamePhaseMachine.transition(to: .handOver, in: gameState)
        XCTAssertNotNil(conditionError)
        XCTAssertTrue(conditionError?.localizedDescription.contains("transition failed") == true)
    }
}
