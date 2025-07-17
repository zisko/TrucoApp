
import Foundation

// MARK: - Core Data Models

public enum Suit: String, CaseIterable, Codable {
    case espadas // Swords
    case bastos  // Clubs
    case oros    // Golds
    case copas   // Cups
}

public enum Rank: Int, CaseIterable, Codable {
    case ace = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case ten = 10
    case eleven = 11
    case twelve = 12
}

public struct Card: Codable, Hashable {
    public let rank: Rank
    public let suit: Suit
}

public struct Player: Codable, Hashable {
    public let id: UUID
    public var name: String
    public var hand: [Card]
    public var score: Int
}

// MARK: - Game State

public struct GameState: Codable {
    public var players: [Player]
    public var deck: [Card]
    public var currentPlayerIndex: Int
    public var gamePhase: GamePhase
    public var roundWinner: UUID?

    public init() {
        self.players = []
        self.deck = []
        self.currentPlayerIndex = 0
        self.gamePhase = .preGame
        self.roundWinner = nil
    }
}

public enum GamePhase: String, Codable {
    case preGame
    case playing
    case roundOver
    case gameOver
}
