@testable import TrucoKit
import XCTest

final class TrucoTests: XCTestCase {
    var helper: TrucoEngineTestHelper!

    override func setUp() {
        super.setUp()
        helper = TrucoEngineTestHelper()
    }

    override func tearDown() {
        helper = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func test_playerCanEscalate_fromTruco_toRetruco() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])

        // Act
        helper.engine.handle(move: .callTruco) // P1 calls Truco
        helper.engine.handle(move: .callTruco) // P2 calls Retruco

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .retrucoCalled)
        XCTAssertEqual(helper.gameState.trucoPoints, 3)
        XCTAssertEqual(helper.gameState.trucoCallerId, helper.player2.id)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 0) // Turn should pass back to P1
    }

    func test_playerCanEscalate_fromRetruco_toValeCuatro() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco
        helper.engine.handle(move: .callTruco) // P2 calls Retruco

        // Act
        helper.engine.handle(move: .callTruco) // P1 calls Vale Cuatro

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .valeCuatroCalled)
        XCTAssertEqual(helper.gameState.trucoPoints, 4)
        XCTAssertEqual(helper.gameState.trucoCallerId, helper.player1.id)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 1) // Turn should pass to P2
    }

    func test_playerCannotEscalate_theirOwnBet() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco

        // Act: P1 tries to escalate their own bet immediately
        // We need to manually switch the turn back to P1 for this test
        helper.gameState.currentPlayerIndex = 0
        helper.engine.handle(move: .callTruco)

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .trucoCalled, "A player cannot escalate their own bet.")
        XCTAssertEqual(helper.gameState.trucoPoints, 2)
    }

    func test_pointsAreAwardedCorrectly_forRejectedRetruco() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco
        helper.engine.handle(move: .callTruco) // P2 calls Retruco

        // Act
        helper.engine.handle(move: .rejectTruco) // P1 rejects

        // Assert
        XCTAssertEqual(helper.player2.score, 2, "Player 2 should get 2 points for the rejected Retruco.")
    }

    func test_playerCanAccept_retruco() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco
        helper.engine.handle(move: .callTruco) // P2 calls Retruco

        // Act
        helper.engine.handle(move: .acceptTruco) // P1 accepts

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .accepted)
        XCTAssertEqual(helper.gameState.trucoPoints, 3)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 1, "Turn should return to the last caller (P2).")
    }

    func test_playerCanAccept_valeCuatro() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco
        helper.engine.handle(move: .callTruco) // P2 calls Retruco
        helper.engine.handle(move: .callTruco) // P1 calls Vale Cuatro

        // Act
        helper.engine.handle(move: .acceptTruco) // P2 accepts

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .accepted)
        XCTAssertEqual(helper.gameState.trucoPoints, 4)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 0, "Turn should return to the last caller (P1).")
    }

    func test_pointsAreAwardedCorrectly_forRejectedValeCuatro() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco
        helper.engine.handle(move: .callTruco) // P2 calls Retruco
        helper.engine.handle(move: .callTruco) // P1 calls Vale Cuatro

        // Act
        helper.engine.handle(move: .rejectTruco) // P2 rejects

        // Assert
        XCTAssertEqual(helper.player1.score, 3, "Player 1 should get 3 points for the rejected Vale Cuatro.")
    }

    func test_trucoCanBeCalled_atAnyPointInTheHand() {
        // Arrange
        let player1Hand = [Card(rank: .ace, suit: .espadas), Card(rank: .two, suit: .bastos), Card(rank: .three, suit: .oros)]
        let player2Hand = [Card(rank: .four, suit: .copas), Card(rank: .five, suit: .espadas), Card(rank: .six, suit: .bastos)]
        helper.createNewGame(player1Hand: player1Hand, player2Hand: player2Hand)

        // Act
        helper.engine.handle(move: .playCard(player1Hand[0])) // P1 plays a card
        helper.engine.handle(move: .callTruco) // P2 calls truco

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .trucoCalled, "Truco should be callable after a card has been played.")
    }

    func test_playerCanAccept_truco() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco

        // Act
        helper.engine.handle(move: .acceptTruco) // P2 accepts

        // Assert
        XCTAssertEqual(helper.gameState.trucoState, .accepted)
        XCTAssertEqual(helper.gameState.trucoPoints, 2)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 0, "Turn should return to the last caller (P1).")
    }

    func test_pointsAreAwardedCorrectly_forRejectedTruco() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callTruco) // P1 calls Truco

        // Act
        helper.engine.handle(move: .rejectTruco) // P2 rejects

        // Assert
        XCTAssertEqual(helper.player1.score, 1, "Player 1 should get 1 point for the rejected Truco.")
    }
}
