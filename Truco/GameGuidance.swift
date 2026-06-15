import SwiftUI
import TrucoKit

/// A single piece of contextual coaching shown in the hint bar.
struct GuidanceHint {
    var systemImage: String
    var title: String
    var message: String
    var tone: Color = Theme.gold
}

/// Static, longer-form explanation shown in an info sheet.
struct GameExplanation: Identifiable {
    let id = UUID()
    var title: String
    var systemImage: String
    var tint: Color
    var paragraphs: [String]
}

enum GameGuidance {
    // MARK: - Display helpers

    static func trucoName(_ state: TrucoState) -> String {
        switch state {
        case .none: return "Truco"
        case .trucoCalled: return "Truco"
        case .retrucoCalled: return "Retruco"
        case .valeCuatroCalled: return "Vale Cuatro"
        case .accepted: return "Truco"
        case .rejected: return "Truco"
        }
    }

    static func envidoName(_ state: EnvidoState) -> String {
        switch state {
        case .none: return "Envido"
        case .envidoCalled: return "Envido"
        case .envidoEnvidoCalled: return "Envido-Envido"
        case .realEnvidoCalled: return "Real Envido"
        case .faltaEnvidoCalled: return "Falta Envido"
        case .accepted: return "Envido"
        case .rejected: return "Envido"
        }
    }

    private static func trucoIsPending(_ s: TrucoState) -> Bool {
        switch s {
        case .trucoCalled, .retrucoCalled, .valeCuatroCalled: return true
        default: return false
        }
    }

    private static func envidoIsPending(_ s: EnvidoState) -> Bool {
        switch s {
        case .envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled, .faltaEnvidoCalled: return true
        default: return false
        }
    }

    // MARK: - Contextual hint

    /// Builds advice for the current moment of the game.
    static func hint(for gameState: GameState, localPlayerId: UUID) -> GuidanceHint {
        switch gameState.gamePhase {
        case .preGame:
            return GuidanceHint(
                systemImage: "play.circle.fill",
                title: "Ready to play",
                message: "Tap “Deal” to start a new hand. First to 30 points wins the match."
            )
        case .gameOver:
            return GuidanceHint(
                systemImage: "trophy.fill",
                title: "Match over",
                message: "Start a new game to play again."
            )
        case .handOver:
            return GuidanceHint(
                systemImage: "rectangle.stack.fill",
                title: "Trick finished",
                message: "Tap “Continue” on the result to play the next card."
            )
        case .roundSummary:
            return GuidanceHint(
                systemImage: "list.bullet.rectangle.fill",
                title: "Round over",
                message: "Review the points awarded, then start the next round."
            )
        case .envidoSummary:
            return GuidanceHint(
                systemImage: "number.circle.fill",
                title: "Envido resolved",
                message: "See whose points won, then tap “Continue” to keep playing the hand.",
                tone: .purple
            )
        case .playing:
            return playingHint(for: gameState, localPlayerId: localPlayerId)
        }
    }

    private static func playingHint(for gameState: GameState, localPlayerId: UUID) -> GuidanceHint {
        let isLocalTurn = !gameState.players.isEmpty
            && gameState.players[gameState.currentPlayerIndex].id == localPlayerId

        // A bet is on the table waiting for a response.
        if trucoIsPending(gameState.trucoState) {
            let name = trucoName(gameState.trucoState)
            if gameState.trucoCallerId != localPlayerId {
                return GuidanceHint(
                    systemImage: "flame.fill",
                    title: "\(name) called!",
                    message: "Worth \(gameState.trucoPoints). Accept to play on, Reject to concede (they get \(max(gameState.trucoPoints - 1, 1))), or raise to up the stakes.",
                    tone: .orange
                )
            } else {
                return GuidanceHint(
                    systemImage: "hourglass",
                    title: "You called \(name)",
                    message: "Waiting for your opponent to accept, reject, or raise.",
                    tone: .orange
                )
            }
        }

        if envidoIsPending(gameState.envidoState) {
            let name = envidoName(gameState.envidoState)
            if gameState.envidoCallerId != localPlayerId {
                return GuidanceHint(
                    systemImage: "number.circle.fill",
                    title: "\(name) called!",
                    message: "Worth \(gameState.envidoPoints). Accept to compare points, Reject to give them points, or raise.",
                    tone: .purple
                )
            } else {
                return GuidanceHint(
                    systemImage: "hourglass",
                    title: "You called \(name)",
                    message: "Waiting for your opponent to respond.",
                    tone: .purple
                )
            }
        }

        guard isLocalTurn else {
            return GuidanceHint(
                systemImage: "ellipsis.circle",
                title: "Opponent's turn",
                message: "Waiting for your opponent to move…",
                tone: Theme.cream
            )
        }

        // It's your turn with no bet pending.
        let canCallEnvido = gameState.envidoState == .none && gameState.currentHandPlayedCards.isEmpty
        if canCallEnvido {
            return GuidanceHint(
                systemImage: "hand.point.up.left.fill",
                title: "Your turn",
                message: "Lead a card by tapping it. Before the first card you can also call Envido (point race) or Truco (raise the hand's value)."
            )
        }
        return GuidanceHint(
            systemImage: "hand.point.up.left.fill",
            title: "Your turn",
            message: "Play a card, or call Truco to raise what this hand is worth."
        )
    }

    // MARK: - Rules explanations

    static let trucoExplanation = GameExplanation(
        title: "Truco",
        systemImage: "flame.fill",
        tint: .orange,
        paragraphs: [
            "Truco is a bet on who will win the hand (the best of three tricks).",
            "Calling “Truco” raises the hand from 1 point to 2. Your opponent can Accept (play on for 2), Reject (you score 1 and the hand ends), or raise.",
            "Raises escalate the stakes: Truco (2) → Retruco (3) → Vale Cuatro (4). Answering a call with a raise also accepts the previous level.",
            "Rejecting a raise concedes the previous value: rejecting Retruco gives the caller 2, rejecting Vale Cuatro gives 3.",
            "Tip: bluff with weak cards, or pounce when you hold the highest cards.",
        ]
    )

    static let envidoExplanation = GameExplanation(
        title: "Envido",
        systemImage: "number.circle.fill",
        tint: .purple,
        paragraphs: [
            "Envido is a side bet on who holds the most “envido points,” only available before the first card of the hand is played.",
            "Your points: two cards of the same suit = their values added together + 20 (face cards count 0). No pair of a suit = your single highest card value.",
            "Levels stack the wager: Envido (2), Envido-Envido (4), Real Envido (+3), Falta Envido (enough to win the match).",
            "Accept to compare hands — the higher envido wins the points (ties go to the player who is “mano”). Reject and the caller takes a smaller amount.",
            "Envido is resolved first, then play continues normally for the Truco.",
        ]
    )
}
