
import Foundation

public class TrucoEngine {
    private(set) var gameState: GameState
    
    public init(initialState: GameState = GameState()) {
        self.gameState = initialState
    }
    
    public func handle(move: GameMove) {
        // This is where the core game logic will go.
        // We'll update the gameState based on the move.
        print("Handling move: \(move)")
        
        switch move {
        case .playCard(let card):
            // Placeholder logic
            print("Player played \(card.rank) of \(card.suit)")
        default:
            break
        }
    }
}
