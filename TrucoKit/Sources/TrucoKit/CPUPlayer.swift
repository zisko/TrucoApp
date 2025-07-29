import Foundation

public struct CPUPlayer {
    public enum Personality {
        case aggressive
        case cautious
        case balanced
    }

    public let personality: Personality

    // MARK: - Probabilities

    /// The chance the CPU will call Truco when it has a good hand.
    public var callTrucoChance: Double {
        switch personality {
        case .aggressive: return 0.8
        case .cautious: return 0.4
        case .balanced: return 0.6
        }
    }

    /// The chance the CPU will escalate a Truco bet to Retruco or Vale Cuatro.
    public var escalateTrucoChance: Double {
        switch personality {
        case .aggressive: return 0.7
        case .cautious: return 0.3
        case .balanced: return 0.5
        }
    }

    /// The chance the CPU will call Envido when it has a good hand.
    public var callEnvidoChance: Double {
        switch personality {
        case .aggressive: return 0.9
        case .cautious: return 0.5
        case .balanced: return 0.7
        }
    }

    /// The chance the CPU will accept a Truco or Envido bet.
    public var acceptBetChance: Double {
        switch personality {
        case .aggressive: return 0.85
        case .cautious: return 0.6
        case .balanced: return 0.75
        }
    }

    public init(personality: Personality = .balanced) {
        self.personality = personality
    }
}
