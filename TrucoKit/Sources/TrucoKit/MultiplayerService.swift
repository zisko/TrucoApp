import Foundation

// Represents a move in the game that can be sent over the network.
public enum GameMove: Codable {
    case playCard(Card)
    case callTruco
    case acceptTruco
    case rejectTruco
    case callEnvido
    case acceptEnvido
    case rejectEnvido
    case dealNewHand
    case continueAfterHand
    case continueAfterEnvido
    case quit
}

// The protocol that any networking backend must conform to.
public protocol MultiplayerService: AnyObject {
    var moveReceived: ((GameMove) -> Void)? { get set }
    func findMatch()
    func send(move: GameMove)
    func endMatch()
}