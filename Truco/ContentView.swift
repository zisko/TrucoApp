import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        switch appState.currentScreen {
        case .mainMenu:
            MainMenuView {
                appState.currentScreen = .inGame
            }
        case .inGame:
            GameView()
        }
    }
}

#Preview {
    ContentView()
}
