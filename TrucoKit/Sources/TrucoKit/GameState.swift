
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
    case ten = 10   // Sota (Jack)
    case eleven = 11 // Caballo (Knight)
    case twelve = 12 // Rey (King)
}

extension Rank: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ace: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .ten: return "10"
        case .eleven: return "11"
        case .twelve: return "12"
        }
    }
}

public struct Card: Codable, Hashable, Identifiable {
    public var id: String { "\(rank)-\(suit)" }
    public let rank: Rank
    public let suit: Suit

    /// The power of the card for the 'Truco' part of the game. Lower is better.
    public var trucoValue: Int {
        switch (rank, suit) {
        case (.ace, .espadas): return 1
        case (.ace, .bastos): return 2
        case (.seven, .espadas): return 3
        case (.seven, .oros): return 4
        case (.three, _): return 5
        case (.two, _): return 6
        case (.ace, .copas), (.ace, .oros): return 7
        case (.twelve, _): return 8
        case (.eleven, _): return 9
        case (.ten, _): return 10
        case (.seven, .copas), (.seven, .bastos): return 11
        case (.six, _): return 12
        case (.five, _): return 13
        case (.four, _): return 14
        default: return 15 // Should not happen
        }
    }

    /// The value of the card for the 'Envido' part of the game.
    public var envidoValue: Int {
        switch rank {
        case .ten, .eleven, .twelve: return 0
        default: return rank.rawValue
        }
    }
}

public struct Player: Codable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public var hand: [Card]
    public var score: Int
}

public struct PlayedCardInfo: Codable, Identifiable {
    public let id = UUID()
    public let player: UUID
    public let card: Card
}

// MARK: - Game State

public struct GameState: Codable {
    public var players: [Player]
    public var deck: [Card]
    public var currentPlayerIndex: Int
    public var gamePhase: GamePhase
    public var roundWinner: UUID?
    public var playedCards: [PlayedCardInfo]

    public init() {
        self.players = []
        self.deck = GameState.newDeck()
        self.currentPlayerIndex = 0
        self.gamePhase = .preGame
        self.roundWinner = nil
        self.playedCards = []
    }

    public static func newDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        return deck
    }
}

public enum GamePhase: String, Codable {
    case preGame
    case playing
    case roundOver
    case gameOver
}
