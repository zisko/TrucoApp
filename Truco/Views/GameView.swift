import Observation
import SwiftUI
import TrucoKit

struct GameView: View {
    @State private var gameState: GameState
    @State private var localPlayerId: UUID
    @State private var isHandWinnersExpanded = false
    @State private var gameEngine: TrucoGameEngine
    @State private var trucoAlertShown = false

    // Help / tooltips
    @State private var showHelp = true
    @State private var explanation: GameExplanation?

    init() {
        let initialGameState = GameState()
        _gameState = State(initialValue: initialGameState)
        _localPlayerId = State(initialValue: UUID())
        gameEngine = GameEngineFactory.createEngine(gameState: initialGameState)
    }

    // MARK: - Derived state

    var isLocalPlayerTurn: Bool {
        guard !gameState.players.isEmpty else { return false }
        return gameState.players[gameState.currentPlayerIndex].id == localPlayerId
    }

    private var opponentHand: [Card] {
        gameState.players.first(where: { $0.id != localPlayerId })?.hand ?? []
    }

    private var myHand: [Card] {
        gameState.players.first(where: { $0.id == localPlayerId })?.hand ?? []
    }

    var matchWinnerName: String? {
        guard let winnerId = gameState.matchWinner else { return nil }
        return PlayerNaming.displayName(for: winnerId, localPlayerId: localPlayerId)
    }

    private var trucoResponsePending: Bool {
        trucoIsCalled && gameState.trucoCallerId != localPlayerId
    }

    private var envidoResponsePending: Bool {
        switch gameState.envidoState {
        case .envidoCalled, .envidoEnvidoCalled, .realEnvidoCalled, .faltaEnvidoCalled:
            return gameState.envidoCallerId != localPlayerId
        default:
            return false
        }
    }

    private var trucoIsCalled: Bool {
        switch gameState.trucoState {
        case .trucoCalled, .retrucoCalled, .valeCuatroCalled: return true
        default: return false
        }
    }

    /// You may only play a card on your turn, during play, and when there is no
    /// pending bet you still need to answer.
    private var canPlayCards: Bool {
        isLocalPlayerTurn
            && gameState.gamePhase == .playing
            && !trucoResponsePending
            && !envidoResponsePending
    }

    private var isBlurred: Bool {
        switch gameState.gamePhase {
        case .handOver, .roundSummary, .gameOver, .envidoSummary: return true
        default: return false
        }
    }

    // MARK: - Actions

    func dealInitialCards() {
        gameEngine.dealInitialCards(player1Id: localPlayerId, player2Id: UUID())
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func playCard(_ card: Card) {
        guard canPlayCards else { return }
        gameEngine.handle(move: .playCard(card))
        if !isLocalPlayerTurn {
            gameEngine.makeOpponentMove()
        }
    }

    func startNewRound() {
        gameEngine.startNewRound()
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func continueAfterHand() {
        gameEngine.handle(move: .continueAfterHand)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    func continueAfterEnvido() {
        gameEngine.handle(move: .continueAfterEnvido)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    /// Applies a player move, then lets the CPU respond if the turn has passed
    /// to it while play continues.
    func handleMove(_ move: GameMove) {
        gameEngine.handle(move: move)
        if !isLocalPlayerTurn && gameState.gamePhase == .playing {
            gameEngine.makeOpponentMove()
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.tableBackground

            VStack(spacing: 10) {
                topBar
                scoreBar
                if showHelp { hintBar }
                tableArea
                bottomBar
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .blur(radius: isBlurred ? 12 : 0)
            .allowsHitTesting(!isBlurred)

            overlays
        }
        .onChange(of: gameState.trucoState) { newValue in
            if newValue == .accepted || newValue == .rejected {
                withAnimation { trucoAlertShown = true }
            }
        }
        .sheet(item: $explanation) { item in
            ExplanationSheet(explanation: item)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Truco")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.gold)
            Spacer()
            Button {
                withAnimation(.easeInOut) { showHelp.toggle() }
            } label: {
                Image(systemName: showHelp ? "questionmark.circle.fill" : "questionmark.circle")
                    .font(.title2)
                    .foregroundStyle(Theme.cream)
            }
            .accessibilityLabel(showHelp ? "Hide tips" : "Show tips")
        }
    }

    // MARK: - Scoreboard

    private var scoreBar: some View {
        HStack(spacing: 12) {
            scorePill(name: "You", score: myScore, isTurn: isLocalPlayerTurn, isMano: manoIsLocal)
            Text("vs").font(.caption.weight(.bold)).foregroundStyle(Theme.cream.opacity(0.6))
            scorePill(name: "Opponent", score: opponentScore, isTurn: !isLocalPlayerTurn && !gameState.players.isEmpty, isMano: !manoIsLocal && gameState.manoPlayerId != nil)
        }
    }

    private var myScore: Int { gameState.players.first(where: { $0.id == localPlayerId })?.score ?? 0 }
    private var opponentScore: Int { gameState.players.first(where: { $0.id != localPlayerId })?.score ?? 0 }
    private var manoIsLocal: Bool { gameState.manoPlayerId == localPlayerId }

    private func scorePill(name: String, score: Int, isTurn: Bool, isMano: Bool) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(name).font(.subheadline.weight(.bold))
                    if isMano {
                        Text("MANO")
                            .font(.system(size: 8, weight: .heavy))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Capsule().fill(Theme.gold.opacity(0.3)))
                    }
                }
                if isTurn {
                    Text("Turn").font(.caption2).foregroundStyle(Theme.gold)
                }
            }
            Spacer()
            Text("\(score)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.cream)
                .contentTransition(.numericText())
        }
        .foregroundStyle(Theme.cream)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isTurn ? Theme.gold.opacity(0.8) : .white.opacity(0.08), lineWidth: isTurn ? 2 : 1)
                )
        )
        .animation(.easeInOut, value: isTurn)
    }

    // MARK: - Hint bar

    private var hintBar: some View {
        let hint = GameGuidance.hint(for: gameState, localPlayerId: localPlayerId)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: hint.systemImage)
                    .font(.title3)
                    .foregroundStyle(hint.tone)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hint.title).font(.subheadline.weight(.bold)).foregroundStyle(Theme.cream)
                    Text(hint.message).font(.caption).foregroundStyle(Theme.cream.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button("What's Truco?") { explanation = GameGuidance.trucoExplanation }
                    .buttonStyle(SecondaryActionButtonStyle(tint: .orange))
                Button("What's Envido?") { explanation = GameGuidance.envidoExplanation }
                    .buttonStyle(SecondaryActionButtonStyle(tint: .purple))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 16, accent: hint.tone)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Table area (scrolls)

    private var tableArea: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Opponent
                VStack(spacing: 6) {
                    Text("Opponent")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.cream.opacity(0.8))
                    HandView(cards: opponentHand, faceDown: true, cardWidth: 50)
                }

                // Stakes badges (Truco / Envido)
                StakesBadgeRow(gameState: gameState)

                // Table
                PlayedCardsView(playedCards: gameState.currentHandPlayedCards, localPlayerId: localPlayerId)

                HandWinnersDisplayView(
                    isExpanded: $isHandWinnersExpanded,
                    handOutcomes: gameState.handOutcomes,
                    players: gameState.players,
                    localPlayerId: localPlayerId
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Bottom bar (pinned)

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Text("Your Hand")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.cream.opacity(0.8))

            HandView(
                cards: myHand,
                highlighted: canPlayCards,
                cardWidth: 74
            ) { card in
                playCard(card)
            }

            if gameState.gamePhase == .preGame || gameState.gamePhase == .gameOver {
                Button(gameState.gamePhase == .preGame ? "Deal" : "Play Again") {
                    dealInitialCards()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }

            if isLocalPlayerTurn && gameState.gamePhase == .playing && !trucoResponsePending && !envidoResponsePending {
                actionButtons
            }
        }
        .padding(.bottom, 6)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if gameState.envidoState == .none && gameState.currentHandPlayedCards.isEmpty {
                Button("Envido") { handleMove(.callEnvido) }
                    .buttonStyle(PrimaryActionButtonStyle(tint: .purple))
                    .disabled(gameState.trucoState != .none)
                    .opacity(gameState.trucoState != .none ? 0.5 : 1)
            }
            if gameState.trucoState == .none {
                let envidoBlocks = gameState.envidoState != .none
                    && gameState.envidoState != .accepted && gameState.envidoState != .rejected
                Button("Truco") { handleMove(.callTruco) }
                    .buttonStyle(PrimaryActionButtonStyle(tint: .orange))
                    .disabled(envidoBlocks)
                    .opacity(envidoBlocks ? 0.5 : 1)
            }
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlays: some View {
        if trucoResponsePending {
            trucoResponseOverlay
        } else if envidoResponsePending {
            envidoResponseOverlay
        }

        if (gameState.trucoState == .accepted || gameState.trucoState == .rejected), trucoAlertShown {
            trucoFeedbackOverlay
        }

        if gameState.gamePhase == .handOver, let lastOutcome = gameState.handOutcomes.last {
            HandOutcomeView(outcome: lastOutcome, players: gameState.players, localPlayerId: localPlayerId) {
                continueAfterHand()
            }
            .padding(.horizontal, 24)
        }

        if gameState.gamePhase == .roundSummary {
            RoundSummaryView(gameState: gameState, localPlayerId: localPlayerId) {
                startNewRound()
            }
            .padding(.horizontal, 24)
        }

        if gameState.gamePhase == .envidoSummary {
            EnvidoSummaryView(gameState: gameState, localPlayerId: localPlayerId) {
                continueAfterEnvido()
            }
            .padding(.horizontal, 24)
        }

        if gameState.gamePhase == .gameOver {
            gameOverOverlay
        }
    }

    private var trucoResponseOverlay: some View {
        let name = GameGuidance.trucoName(gameState.trucoState)
        let raiseLabel: String? = {
            switch gameState.trucoState {
            case .trucoCalled: return "Retruco"
            case .retrucoCalled: return "Vale Cuatro"
            default: return nil
            }
        }()
        return ResponsePrompt(
            title: "\(name) called!",
            subtitle: "Worth \(gameState.trucoPoints) points",
            tint: .orange
        ) {
            Button("Accept") { handleMove(.acceptTruco) }
                .buttonStyle(PrimaryActionButtonStyle(tint: Theme.positive))
            Button("Reject") { handleMove(.rejectTruco) }
                .buttonStyle(SecondaryActionButtonStyle(tint: Theme.danger))
            if let raiseLabel {
                Button(raiseLabel) { handleMove(.callTruco) }
                    .buttonStyle(SecondaryActionButtonStyle(tint: .orange))
            }
        }
    }

    private var envidoResponseOverlay: some View {
        ResponsePrompt(
            title: "\(GameGuidance.envidoName(gameState.envidoState)) called!",
            subtitle: "Worth \(gameState.envidoPoints) points",
            tint: .purple
        ) {
            Button("Accept") { handleMove(.acceptEnvido) }
                .buttonStyle(PrimaryActionButtonStyle(tint: Theme.positive))
            Button("Reject") { handleMove(.rejectEnvido) }
                .buttonStyle(SecondaryActionButtonStyle(tint: Theme.danger))
            if gameState.envidoState == .envidoCalled {
                Button("Real Envido") { handleMove(.callRealEnvido) }
                    .buttonStyle(SecondaryActionButtonStyle(tint: .green))
            }
            if gameState.envidoState != .faltaEnvidoCalled {
                Button("Falta Envido") { handleMove(.callFaltaEnvido) }
                    .buttonStyle(SecondaryActionButtonStyle(tint: .yellow))
            }
        }
    }

    private var trucoFeedbackOverlay: some View {
        let accepted = gameState.trucoState == .accepted
        return VStack(spacing: 10) {
            Image(systemName: accepted ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(accepted ? Theme.positive : Theme.danger)
            Text(accepted ? "Truco Accepted" : "Truco Rejected")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.cream)
        }
        .padding(28)
        .glassPanel(accent: accepted ? Theme.positive : Theme.danger)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation { trucoAlertShown = false }
            }
        }
    }

    private var gameOverOverlay: some View {
        VStack(spacing: 18) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.gold)
            Text("Match Over")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Theme.cream)
            if let winnerName = matchWinnerName {
                Text("\(winnerName) win\(winnerName == "You" ? "" : "s")!")
                    .font(.title2)
                    .foregroundStyle(Theme.cream.opacity(0.9))
            }
            Button("Play Again") { dealInitialCards() }
                .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.7))
        .ignoresSafeArea()
    }
}

#Preview {
    GameView()
}
