@testable import TrucoKit
import XCTest

final class GameEngineRefactoredTests: XCTestCase {
    var gameState: GameState!
    var engine: TrucoEngineRefactored!

    override func setUp() {
        super.setUp()
        gameState = GameState()
        engine = TrucoEngineRefactored(gameState: gameState)
    }

    override func tearDown() {
        gameState = nil
        engine = nil
        super.tearDown()
    }

    // MARK: - Game Initialization Tests

    func testDealInitialCards() {
        let player1Id = UUID()
        let player2Id = UUID()

        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Verify game state
        XCTAssertEqual(gameState.players.count, 2)
        XCTAssertEqual(gameState.players[0].hand.count, 3)
        XCTAssertEqual(gameState.players[1].hand.count, 3)
        XCTAssertEqual(gameState.currentPlayerIndex, 0)
        XCTAssertEqual(gameState.manoPlayerId, player1Id)
        XCTAssertEqual(gameState.gamePhase, .playing)

        // Verify state machines are reset
        XCTAssertEqual(engine.gameState.gamePhase, .playing)
    }

    // MARK: - Card Playing Tests

    func testPlayCardValid() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        let cardToPlay = gameState.players[0].hand[0]

        // Play card
        let error = engine.handle(move: .playCard(cardToPlay))

        XCTAssertNil(error)
        XCTAssertEqual(gameState.currentHandPlayedCards.count, 1)
        XCTAssertEqual(gameState.players[0].hand.count, 2)
        XCTAssertEqual(gameState.currentPlayerIndex, 1) // Turn should switch
    }

    func testPlayCardInvalidState() {
        // Try to play card without dealing cards first
        let card = Card(rank: .ace, suit: .espadas)
        let error = engine.handle(move: .playCard(card))

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("playCard"), true)
    }

    func testPlayCardNotInHand() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Create a card that's definitely not in the player's hand
        let cardNotInHand = Card(rank: .twelve, suit: .oros)

        // Try to play card not in hand
        let error = engine.handle(move: .playCard(cardNotInHand))

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("CardNotInHand"), true)
    }

    func testCompleteHand() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        let card1 = gameState.players[0].hand[0]
        let card2 = gameState.players[1].hand[0]

        // Play first card
        var error = engine.handle(move: .playCard(card1))
        XCTAssertNil(error)
        XCTAssertEqual(gameState.gamePhase, .playing)

        // Play second card
        error = engine.handle(move: .playCard(card2))
        XCTAssertNil(error)
        XCTAssertEqual(gameState.gamePhase, .handOver)
        XCTAssertEqual(gameState.handOutcomes.count, 1)
    }

    // MARK: - Truco Tests

    func testCallTrucoValid() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Call Truco
        let error = engine.handle(move: .callTruco)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.trucoState, .trucoCalled)
        XCTAssertEqual(gameState.trucoPoints, 2)
        XCTAssertEqual(gameState.trucoCallerId, player1Id)
        XCTAssertEqual(gameState.currentPlayerIndex, 1) // Turn should switch
    }

    func testCallTrucoInvalidState() {
        // Try to call Truco without dealing cards first
        let error = engine.handle(move: .callTruco)

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("callTruco"), true)
    }

    func testAcceptTruco() {
        // Setup: deal cards and call Truco
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)
        _ = engine.handle(move: .callTruco)

        // Accept Truco
        let error = engine.handle(move: .acceptTruco)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.trucoState, .accepted)
        XCTAssertEqual(gameState.currentPlayerIndex, 0) // Turn should go back to caller
    }

    func testRejectTruco() {
        // Setup: deal cards and call Truco
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)
        _ = engine.handle(move: .callTruco)

        // Reject Truco
        let error = engine.handle(move: .rejectTruco)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.trucoState, .rejected)
        XCTAssertEqual(gameState.gamePhase, .roundSummary)
        XCTAssertEqual(gameState.players[0].score, 1) // Caller should get 1 point
    }

    // MARK: - Envido Tests

    func testCallEnvidoValid() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Call Envido
        let error = engine.handle(move: .callEnvido)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.envidoState, .envidoCalled)
        XCTAssertEqual(gameState.envidoPoints, 2)
        XCTAssertEqual(gameState.envidoCallerId, player1Id)
        XCTAssertEqual(gameState.currentPlayerIndex, 1) // Turn should switch
    }

    func testCallEnvidoInvalidState() {
        // Try to call Envido without dealing cards first
        let error = engine.handle(move: .callEnvido)

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("callEnvido"), true)
    }

    func testAcceptEnvido() {
        // Setup: deal cards and call Envido
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)
        _ = engine.handle(move: .callEnvido)

        // Accept Envido
        let error = engine.handle(move: .acceptEnvido)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.envidoState, .accepted)
        XCTAssertEqual(gameState.gamePhase, .envidoSummary)
        XCTAssertNotNil(gameState.player1EnvidoPoints)
        XCTAssertNotNil(gameState.player2EnvidoPoints)
    }

    func testRejectEnvido() {
        // Setup: deal cards and call Envido
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)
        _ = engine.handle(move: .callEnvido)

        // Reject Envido
        let error = engine.handle(move: .rejectEnvido)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.envidoState, .rejected)
        XCTAssertEqual(gameState.players[0].score, 1) // Caller should get 1 point
    }

    // MARK: - Continue Tests

    func testContinueAfterHand() {
        // Setup: complete a hand
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        let card1 = gameState.players[0].hand[0]
        let card2 = gameState.players[1].hand[0]

        _ = engine.handle(move: .playCard(card1))
        _ = engine.handle(move: .playCard(card2))

        // Continue after hand
        let error = engine.handle(move: .continueAfterHand)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.gamePhase, .playing)
        XCTAssertEqual(gameState.currentHandPlayedCards.count, 0)
    }

    func testContinueAfterEnvido() {
        // Setup: deal cards, call and accept Envido
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)
        _ = engine.handle(move: .callEnvido)
        _ = engine.handle(move: .acceptEnvido)

        // Continue after Envido
        let error = engine.handle(move: .continueAfterEnvido)

        XCTAssertNil(error)
        XCTAssertEqual(gameState.gamePhase, .playing)
        XCTAssertNil(gameState.player1EnvidoPoints)
        XCTAssertNil(gameState.player2EnvidoPoints)
        XCTAssertNil(gameState.envidoWinnerId)
    }

    // MARK: - Round Management Tests

    func testStartNewRound() {
        // Setup: complete a round
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Complete 3 hands to end round
        for _ in 0 ..< 3 {
            let card1 = gameState.players[gameState.currentPlayerIndex].hand[0]
            _ = engine.handle(move: .playCard(card1))

            let card2 = gameState.players[gameState.currentPlayerIndex].hand[0]
            _ = engine.handle(move: .playCard(card2))

            _ = engine.handle(move: .continueAfterHand)
        }

        // Start new round
        engine.startNewRound()

        // Verify new round state
        XCTAssertEqual(gameState.players[0].hand.count, 3)
        XCTAssertEqual(gameState.players[1].hand.count, 3)
        XCTAssertEqual(gameState.currentHandPlayedCards.count, 0)
        XCTAssertEqual(gameState.handOutcomes.count, 0)
        XCTAssertNil(gameState.roundWinner)
        XCTAssertEqual(gameState.manoPlayerId, player2Id) // Should alternate
        XCTAssertEqual(gameState.gamePhase, .playing)
    }

    // MARK: - Match End Tests

    func testMatchEnd() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Award enough points to end match
        gameState.players[0].score = 30

        // Check match end directly
        engine.checkMatchEnd()

        XCTAssertEqual(gameState.gamePhase, .gameOver)
        XCTAssertEqual(gameState.matchWinner, player1Id)
    }

    // MARK: - CPU Player Tests

    func testMakeOpponentMove() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Make opponent move
        engine.makeOpponentMove()

        // Should have played a card or made a call
        XCTAssertTrue(gameState.currentHandPlayedCards.count > 0 ||
            gameState.trucoState != .none ||
            gameState.envidoState != .none)
    }

    // MARK: - Error Handling Tests

    func testInvalidMoveInWrongState() {
        // Try to continue after hand when not in handOver state
        let error = engine.handle(move: .continueAfterHand)

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("continueAfterHand"), true)
    }

    func testInvalidMoveInWrongState2() {
        // Try to continue after Envido when not in envidoSummary state
        let error = engine.handle(move: .continueAfterEnvido)

        XCTAssertNotNil(error)
        XCTAssertEqual(error?.localizedDescription.contains("continueAfterEnvido"), true)
    }

    // MARK: - Integration Tests

    func testCompleteGameFlow() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Play a hand
        let card1 = gameState.players[0].hand[0]
        let card2 = gameState.players[1].hand[0]

        _ = engine.handle(move: .playCard(card1))
        _ = engine.handle(move: .playCard(card2))
        _ = engine.handle(move: .continueAfterHand)

        // Call and accept Truco
        _ = engine.handle(move: .callTruco)
        _ = engine.handle(move: .acceptTruco)

        // Play another hand
        let card3 = gameState.players[0].hand[0]
        let card4 = gameState.players[1].hand[0]

        _ = engine.handle(move: .playCard(card3))
        _ = engine.handle(move: .playCard(card4))
        _ = engine.handle(move: .continueAfterHand)

        // Verify game state is consistent
        XCTAssertEqual(gameState.players.count, 2)
        XCTAssertEqual(gameState.handOutcomes.count, 2)
        XCTAssertEqual(gameState.gamePhase, .playing)
    }

    // MARK: - CPU Response Tests

    func testCPURespondsToAllTrucoStates() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Test CPU response to Truco
        _ = engine.handle(move: .callTruco)
        engine.makeOpponentMove()

        // Should have either accepted or rejected
        XCTAssertTrue(gameState.trucoState == .accepted || gameState.trucoState == .rejected)
    }

    func testCPURespondsToAllEnvidoStates() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Test CPU response to Envido
        _ = engine.handle(move: .callEnvido)
        engine.makeOpponentMove()

        // Should have either accepted or rejected
        XCTAssertTrue(gameState.envidoState == .accepted || gameState.envidoState == .rejected)
    }

    func testTurnManagementAfterTrucoAcceptance() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        let initialPlayerIndex = gameState.currentPlayerIndex
        let callerId = gameState.players[initialPlayerIndex].id

        // Call Truco
        _ = engine.handle(move: .callTruco)

        // Accept Truco
        _ = engine.handle(move: .acceptTruco)

        // Turn should go back to the caller
        XCTAssertEqual(gameState.currentPlayerIndex, initialPlayerIndex)
        XCTAssertEqual(gameState.trucoCallerId, callerId)
    }

    func testTurnManagementAfterEnvidoAcceptance() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        let initialPlayerIndex = gameState.currentPlayerIndex
        let callerId = gameState.players[initialPlayerIndex].id

        // Call Envido
        _ = engine.handle(move: .callEnvido)

        // Accept Envido
        _ = engine.handle(move: .acceptEnvido)

        // Continue after Envido
        _ = engine.handle(move: .continueAfterEnvido)

        // Turn should go back to the caller
        XCTAssertEqual(gameState.currentPlayerIndex, initialPlayerIndex)
        XCTAssertEqual(gameState.envidoCallerId, callerId)
    }

    func testBettingEscalation() {
        // Setup: deal cards
        let player1Id = UUID()
        let player2Id = UUID()
        engine.dealInitialCards(player1Id: player1Id, player2Id: player2Id)

        // Call Truco
        _ = engine.handle(move: .callTruco)
        XCTAssertEqual(gameState.trucoState, .trucoCalled)
        XCTAssertEqual(gameState.trucoPoints, 2)

        // Accept Truco
        _ = engine.handle(move: .acceptTruco)
        XCTAssertEqual(gameState.trucoState, .accepted)
        XCTAssertEqual(gameState.trucoPoints, 2)

        // Call Retruco (should become Retruco)
        _ = engine.handle(move: .callTruco)
        XCTAssertEqual(gameState.trucoState, .retrucoCalled)
        XCTAssertEqual(gameState.trucoPoints, 3)

        // Accept Retruco
        _ = engine.handle(move: .acceptTruco)
        XCTAssertEqual(gameState.trucoState, .accepted)
        XCTAssertEqual(gameState.trucoPoints, 3)

        // Call Vale Cuatro (should become Vale Cuatro)
        _ = engine.handle(move: .callTruco)
        XCTAssertEqual(gameState.trucoState, .valeCuatroCalled)
        XCTAssertEqual(gameState.trucoPoints, 4)
    }
}
