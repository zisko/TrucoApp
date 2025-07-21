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
        }
    }

    /// The value of the card for the 'Envido' part of the game.
    public var envidoValue: Int {
        switch rank {
        case .ten, .eleven, .twelve: return 0
        default: return rank.rawValue
        }
    }
    
    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }
}

public struct Player: Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var hand: [Card]
    public var score: Int

    public init(id: UUID, name: String, hand: [Card], score: Int) {
        self.id = id
        self.name = name
        self.hand = hand
        self.score = score
    }
}

public struct PlayedCardInfo: Codable, Identifiable {
    public var id = UUID()
    public var player: UUID
    public let card: Card
}

public struct HandOutcome: Codable, Hashable {
    public var winnerId: UUID?
    public let winningCard: Card?
    public let losingCard: Card?

    public init(winnerId: UUID?, winningCard: Card?, losingCard: Card?) {
        self.winnerId = winnerId
        self.winningCard = winningCard
        self.losingCard = losingCard
    }
}

// MARK: - Game State

@Observable public class GameState: Codable {
    public var players: [Player]
    public var deck: [Card]
    public var currentPlayerIndex: Int
    public var gamePhase: GamePhase
    public var roundWinner: UUID?
    public var currentHandPlayedCards: [PlayedCardInfo]
    public var handOutcomes: [HandOutcome]
    public var manoPlayerId: UUID?

    // Truco State
    public var trucoState: TrucoState
    public var trucoCallerId: UUID?

    // Envido State
    public var envidoState: EnvidoState
    public var envidoCallerId: UUID?
    public var envidoPoints: Int // The points value of the current envido call

    enum CodingKeys: String, CodingKey {
        case players, deck, currentPlayerIndex, gamePhase, roundWinner, currentHandPlayedCards, handOutcomes, manoPlayerId, trucoState, trucoCallerId, envidoState, envidoCallerId, envidoPoints
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.players = try container.decode([Player].self, forKey: .players)
        self.deck = try container.decode([Card].self, forKey: .deck)
        self.currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        self.gamePhase = try container.decode(GamePhase.self, forKey: .gamePhase)
        self.roundWinner = try container.decode(UUID?.self, forKey: .roundWinner)
        self.currentHandPlayedCards = try container.decode([PlayedCardInfo].self, forKey: .currentHandPlayedCards)
        self.handOutcomes = try container.decode([HandOutcome].self, forKey: .handOutcomes)
        self.manoPlayerId = try container.decode(UUID?.self, forKey: .manoPlayerId)
        self.trucoState = try container.decode(TrucoState.self, forKey: .trucoState)
        self.trucoCallerId = try container.decode(UUID?.self, forKey: .trucoCallerId)
        self.envidoState = try container.decode(EnvidoState.self, forKey: .envidoState)
        self.envidoCallerId = try container.decode(UUID?.self, forKey: .envidoCallerId)
        self.envidoPoints = try container.decode(Int.self, forKey: .envidoPoints)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(players, forKey: .players)
        try container.encode(deck, forKey: .deck)
        try container.encode(currentPlayerIndex, forKey: .currentPlayerIndex)
        try container.encode(gamePhase, forKey: .gamePhase)
        try container.encode(roundWinner, forKey: .roundWinner)
        try container.encode(currentHandPlayedCards, forKey: .currentHandPlayedCards)
        try container.encode(handOutcomes, forKey: .handOutcomes)
        try container.encode(manoPlayerId, forKey: .manoPlayerId)
        try container.encode(trucoState, forKey: .trucoState)
        try container.encode(trucoCallerId, forKey: .trucoCallerId)
        try container.encode(envidoState, forKey: .envidoState)
        try container.encode(envidoCallerId, forKey: .envidoCallerId)
        try container.encode(envidoPoints, forKey: .envidoPoints)
    }

    public init() {
        self.players = []
        self.deck = GameState.newDeck()
        self.currentPlayerIndex = 0
        self.gamePhase = .preGame
        self.roundWinner = nil
        self.currentHandPlayedCards = []
        self.handOutcomes = []
        self.manoPlayerId = nil
        self.trucoState = .none
        self.trucoCallerId = nil
        self.envidoState = .none
        self.envidoCallerId = nil
        self.envidoPoints = 0
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

public enum TrucoState: String, Codable {
    case none
    case trucoCalled
    case retrucoCalled
    case valeCuatroCalled
    case accepted
    case rejected
}

public enum EnvidoState: String, Codable {
    case none
    case envidoCalled
    case realEnvidoCalled
    case faltaEnvidoCalled
    case accepted
    case rejected
    case envidoEnvidoCalled
}
