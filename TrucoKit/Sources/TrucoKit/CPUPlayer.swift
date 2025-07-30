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
        case .aggressive: return 0.4
        case .cautious: return 0.1
        case .balanced: return 0.2
        }
    }

    /// The chance the CPU will escalate a Truco bet to Retruco or Vale Cuatro.
    public var escalateTrucoChance: Double {
        switch personality {
        case .aggressive: return 0.4
        case .cautious: return 0.1
        case .balanced: return 0.2
        }
    }

    /// The chance the CPU will call Envido when it has a good hand.
    public var callEnvidoChance: Double {
        switch personality {
        case .aggressive: return 0.2
        case .cautious: return 0.05
        case .balanced: return 0.1
        }
    }

    /// The chance the CPU will accept a Truco or Envido bet.
    public var acceptBetChance: Double {
        switch personality {
        case .aggressive: return 0.8
        case .cautious: return 0.4
        case .balanced: return 0.5
        }
    }

    public init(personality: Personality = .balanced) {
        self.personality = personality
    }
}
