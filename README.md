# Truco - A Swift-based Card Game for iOS

This repository contains the source code for a mobile implementation of the popular card game "Truco". This project is built with Swift and SwiftUI, and it is designed to be a fun and engaging experience for players.

## Purpose

This project was developed to showcase modern iOS development practices, including SwiftUI, Swift Packages, and iMessage extensions. It is also a personal project to create a playable Truco game for the iOS platform.

## Features

The project is divided into three main components:

*   **Truco (Main App):** The primary iOS application where users can play the game.
*   **TrucoKit (Swift Package):** A reusable Swift Package that contains the core game logic, including the game engine, state machine, and card models. This package is designed to be independent of the UI, allowing it to be used in other contexts.
*   **TrucoMessages (iMessage Extension):** An iMessage extension that allows players to interact with the game directly from their conversations.

## How to Run

To run this project, you will need a Mac with Xcode installed.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/Truco.git
    ```
2.  **Open the project in Xcode:**
    ```bash
    cd Truco
    open Truco.xcodeproj
    ```
3.  **Select the "Truco" scheme and a simulator or a physical device.**
4.  **Run the project (Cmd + R).**

## Project Structure

-   `Truco/`: Contains the main application source code, including SwiftUI views, assets, and the app's entry point.
-   `TrucoKit/`: The core game logic as a Swift Package. This includes the game engine, card and player models, and the game state machine.
-   `TrucoMessages/`: The source code for the iMessage extension.
-   `Truco.xcodeproj/`: The Xcode project file.

## Dependencies

This project uses Swift Package Manager to manage its dependencies. The primary dependency is the `TrucoKit` local package.

## Repository Management

This repository is managed by Gemini, a large language model from Google. Gemini helps with code generation, refactoring, and project management tasks.

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## License

This project is currently not licensed.
