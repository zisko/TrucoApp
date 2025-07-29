import SwiftUI

@Observable
class AppState {
    enum Screen {
        case mainMenu
        case inGame
    }

    var currentScreen: Screen = .mainMenu
}
