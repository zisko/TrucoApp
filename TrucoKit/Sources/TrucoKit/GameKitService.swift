
import Foundation
import GameKit

public class GameKitService: NSObject, MultiplayerService {
    public var moveReceived: ((GameMove) -> Void)?
    
    private var match: GKMatch?
    
    public func findMatch() {
        print("Finding a match with GameKit...")
        // Placeholder for GameKit matchmaking logic
    }
    
    public func send(move: GameMove) {
        print("Sending move: \(move)")
        guard let match = match else { return }
        
        do {
            let data = try JSONEncoder().encode(move)
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    
    public func endMatch() {
        print("Ending the match.")
        match?.disconnect()
    }
}
