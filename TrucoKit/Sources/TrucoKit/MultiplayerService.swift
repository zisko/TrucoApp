
import Foundation

// Represents a move in the game that can be sent over the network.
public enum GameMove: Codable {
    case playCard(Card)
    case cantarTruco
    case cantarEnvido
    case respondToTruco(Bool)
    case respondToEnvido(Bool)
    case dealNewHand
    case quit
}

// The protocol that any networking backend must conform to.
public protocol MultiplayerService {
    var moveReceived: ((GameMove) -> Void)? { get set }
    
    func findMatch()
    func send(move: GameMove)
    func endMatch()
}
