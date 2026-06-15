import SwiftUI

struct MainMenuView: View {
    var onNewGame: () -> Void

    // Animation states
    @State private var isTitleVisible = false
    @State private var isIconVisible = false
    @State private var areButtonsVisible = false
    @State private var iconRotation = 0.0

    var body: some View {
        ZStack {
            // Background
            Theme.tableBackground

            VStack(spacing: 20) {
                Spacer()

                // Title
                Text("Truco Argentino")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.gold)
                    .shadow(radius: 10)
                    .opacity(isTitleVisible ? 1 : 0)
                    .animation(.easeIn(duration: 1.0), value: isTitleVisible)

                Spacer()

                // App Icon
                Image("MainMenuIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(radius: 10)
                    .rotationEffect(.degrees(iconRotation))
                    .opacity(isIconVisible ? 1 : 0)
                    .scaleEffect(isIconVisible ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.5), value: isIconVisible)
                    .onAppear {
                        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                            iconRotation = 360
                        }
                    }

                Spacer()

                // Buttons
                VStack(spacing: 15) {
                    Button(action: onNewGame) {
                        Text("New Game")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Theme.gold)

                    Button(action: {}) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(true)
                    .tint(.white)

                    Button(action: {}) {
                        Text("Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(true)
                    .tint(.white)
                }
                .padding(.horizontal, 40)
                .opacity(areButtonsVisible ? 1 : 0)
                .animation(.easeIn(duration: 1.0).delay(1.0), value: areButtonsVisible)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            isTitleVisible = true
            isIconVisible = true
            areButtonsVisible = true
        }
    }
}

#Preview {
    MainMenuView(onNewGame: {})
}
