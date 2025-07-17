import SwiftUI
import TrucoKit
import Observation

struct ContentView: View {
    var body: some View {
        GameView()
    }
}

struct GameView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        VStack {
            Text("Truco Game")
                .font(.largeTitle)
                .padding()

            Spacer()

            Text("Current Game Phase: \(viewModel.gameState.gamePhase.rawValue)")
                .font(.headline)

            Spacer()

            Button("Start New Game") {
                // This will eventually trigger game setup and dealing cards
                print("Start New Game button tapped")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

@Observable
class GameViewModel {
    var gameState: GameState
    private var gameEngine: TrucoEngine
    private var multiplayerService: MultiplayerService

    init() {
        let initialGameState = GameState()
        self.gameState = initialGameState
        self.gameEngine = TrucoEngine(initialState: initialGameState)
        // For now, we'll use a dummy service until GameKit is fully integrated
        self.multiplayerService = GameKitService() // Placeholder
        
        // Update game state when a move is received
        multiplayerService.moveReceived = { [weak self] move in
            self?.gameEngine.handle(move: move)
            self?.gameState = self?.gameEngine.gameState ?? GameState()
        }
    }
}

#Preview {
    ContentView()
}