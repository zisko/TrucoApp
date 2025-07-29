@testable import TrucoKit
import XCTest

final class EnvidoTests: XCTestCase {
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

    func test_playerWhoIsNotMano_CanCallEnvido_BeforePlayingCard() {
        // Arrange
        let player1Hand = [Card(rank: .ace, suit: .espadas), Card(rank: .two, suit: .bastos), Card(rank: .three, suit: .oros)]
        let player2Hand = [Card(rank: .four, suit: .copas), Card(rank: .five, suit: .espadas), Card(rank: .six, suit: .bastos)]
        helper.createNewGame(player1Hand: player1Hand, player2Hand: player2Hand)

        // Player 1 (mano) plays a card
        helper.engine.handle(move: .playCard(player1Hand[0]))

        // It is now Player 2's turn
        XCTAssertEqual(helper.gameState.currentPlayerIndex, 1)

        // Act: Player 2 calls Envido
        helper.engine.handle(move: .callEnvido)

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .envidoCalled, "Player 2 should be able to call Envido on their turn.")
        XCTAssertEqual(helper.gameState.envidoCallerId, helper.player2.id, "The envido caller should be Player 2.")
    }

    func test_player_cannotCallEnvido_afterFirstHandIsOver() {
        // Arrange
        let player1Hand = [Card(rank: .ace, suit: .espadas), Card(rank: .two, suit: .bastos), Card(rank: .three, suit: .oros)]
        let player2Hand = [Card(rank: .four, suit: .copas), Card(rank: .five, suit: .espadas), Card(rank: .six, suit: .bastos)]
        helper.createNewGame(player1Hand: player1Hand, player2Hand: player2Hand)

        // Play out the first hand
        helper.engine.handle(move: .playCard(player1Hand[0]))
        helper.engine.handle(move: .playCard(player2Hand[0]))

        // First hand is over
        XCTAssertEqual(helper.gameState.handOutcomes.count, 1)

        // Act: Try to call Envido now
        helper.engine.handle(move: .callEnvido)

        // Assert
        XCTAssertEqual(helper.gameState.envidoState, .none, "Envido should not be callable after the first hand is complete.")
    }
}
