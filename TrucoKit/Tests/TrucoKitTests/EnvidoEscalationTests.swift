@testable import TrucoKit
import XCTest

final class EnvidoEscalationTests: XCTestCase {
    var helper: TrucoEngineTestHelper!

    override func setUp() {
        super.setUp()
        helper = TrucoEngineTestHelper()
    }

    override func tearDown() {
        helper = nil
        super.tearDown()
    }

    // MARK: - Initial Calls

    func test_playerCanCall_realEnvido_directly() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])

        // Act
        helper.engine.handle(move: .callRealEnvido) // P1 calls Real Envido directly

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .realEnvidoCalled)
        XCTAssertEqual(helper.gameState.envidoPoints, 3)
        XCTAssertEqual(helper.gameState.envidoCallerId, helper.player1.id)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 1)
    }

    func test_playerCanCall_faltaEnvido_directly() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [], player2Score: 20)

        // Act
        helper.engine.handle(move: .callFaltaEnvido) // P1 calls Falta Envido directly

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .faltaEnvidoCalled)
        XCTAssertEqual(helper.gameState.envidoPoints, 10, "Falta Envido should be worth 30 - 20 = 10 points.")
        XCTAssertEqual(helper.gameState.envidoCallerId, helper.player1.id)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 1)
    }

    // MARK: - Escalation

    func test_playerCanEscalate_fromEnvido_toEnvidoEnvido() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callEnvido) // P1 calls Envido

        // Act
        helper.engine.handle(move: .callEnvido) // P2 calls Envido again

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .envidoEnvidoCalled)
        XCTAssertEqual(helper.gameState.envidoPoints, 4)
        XCTAssertEqual(helper.gameState.envidoCallerId, helper.player2.id)
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 0)
    }

    func test_playerCanEscalate_fromEnvido_toRealEnvido() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [])
        helper.engine.handle(move: .callEnvido) // P1 calls Envido

        // Act
        helper.engine.handle(move: .callRealEnvido) // P2 calls Real Envido

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .realEnvidoCalled)
        XCTAssertEqual(helper.gameState.envidoPoints, 5, "Envido (2) + Real Envido (3) should be 5 points.")
        XCTAssertEqual(helper.gameState.envidoCallerId, helper.player2.id)
    }

    func test_playerCanEscalate_fromRealEnvido_toFaltaEnvido() {
        // Arrange
        helper.createNewGame(player1Hand: [], player2Hand: [], player1Score: 15)
        helper.engine.handle(move: .callRealEnvido) // P1 calls Real Envido

        // Act
        helper.engine.handle(move: .callFaltaEnvido) // P2 calls Falta Envido

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .faltaEnvidoCalled)
        XCTAssertEqual(helper.gameState.envidoPoints, 18, "Real Envido (3) + Falta (15) should be 18 points.")
        XCTAssertEqual(helper.gameState.envidoCallerId, helper.player2.id)
    }
}
