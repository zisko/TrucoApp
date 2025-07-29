import SwiftUI

struct MainMenuView: View {
    var onNewGame: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Truco Argentino")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            VStack(spacing: 15) {
                Button(action: onNewGame) {
                    Text("New Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: {}) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(true)

                Button(action: {}) {
                    Text("Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(true)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    MainMenuView(onNewGame: {})
}
