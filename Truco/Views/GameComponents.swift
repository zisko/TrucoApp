import SwiftUI
import TrucoKit

// MARK: - Stakes badges

/// A compact strip showing what's currently at stake (Truco level / Envido).
struct StakesBadgeRow: View {
    let gameState: GameState

    private var trucoActive: Bool { gameState.trucoState != .none && gameState.trucoState != .rejected }
    private var envidoActive: Bool {
        switch gameState.envidoState {
        case .none, .rejected: return false
        default: return true
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            if trucoActive {
                StakeBadge(
                    text: "\(GameGuidance.trucoName(gameState.trucoState)) · \(gameState.trucoPoints)",
                    systemImage: "flame.fill",
                    tint: .orange
                )
            }
            if envidoActive {
                StakeBadge(
                    text: "\(GameGuidance.envidoName(gameState.envidoState)) · \(gameState.envidoPoints)",
                    systemImage: "number.circle.fill",
                    tint: .purple
                )
            }
            if !trucoActive && !envidoActive {
                StakeBadge(text: "Hand worth 1", systemImage: "rosette", tint: Theme.goldDim)
            }
        }
        .animation(.easeInOut, value: gameState.trucoState)
        .animation(.easeInOut, value: gameState.envidoState)
    }
}

struct StakeBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage).font(.caption2)
            Text(text).font(.caption.weight(.semibold))
        }
        .foregroundStyle(Theme.cream)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(
            Capsule().fill(tint.opacity(0.28))
                .overlay(Capsule().stroke(tint.opacity(0.6), lineWidth: 1))
        )
    }
}

// MARK: - Response prompt (accept / reject / raise)

/// Centered glass panel used for answering a Truco or Envido call.
struct ResponsePrompt<Buttons: View>: View {
    let title: String
    let subtitle: String
    var tint: Color
    @ViewBuilder var buttons: () -> Buttons

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.opacity(0.85))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                buttons()
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
        .glassPanel(accent: tint)
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Explanation sheet

struct ExplanationSheet: View {
    let explanation: GameExplanation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: explanation.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(explanation.tint)
                        Text(explanation.title)
                            .font(.largeTitle.weight(.bold))
                    }
                    .padding(.bottom, 4)

                    ForEach(Array(explanation.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("How to play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
