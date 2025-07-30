
# Proposal: Active Bet and Action Button State Management

## 1. Overview

This document outlines the plan to introduce an `activeBet` property to the `GameEngine` and enhance the UI to disable invalid action buttons. This will provide clearer visual cues to the user about the current game state and the actions available to them.

## 2. Core-Logic (`TrucoKit`)

### 2.1. `GameEngine.swift`

- **Introduce `activeBet`:** Add a new `@Published` property to the `GameEngine` to track the current bet type.
  ```swift
  @Published public var activeBet: BetType?
  ```
  - `BetType` will be a new `enum` that represents the possible bet types (e.g., `truco`, `envido`, `realEnvido`, `faltaEnvido`).

- **Update Game Logic:** Modify the existing game logic to update the `activeBet` property whenever a bet is made.

### 2.2. `GameState.swift`

- **Add `BetType` enum:** Define the `BetType` enum to represent the different types of bets available in the game.
  ```swift
  public enum BetType {
      case truco
      case envido
      case realEnvido
      case faltaEnvido
  }
  ```

## 3. UI (`Truco/Views`)

### 3.1. `GameView.swift`

- **Button Disabling Logic:** Implement logic to disable action buttons based on the `activeBet` and other game state conditions.
  - The "Truco" button should be disabled if `activeBet` is not `nil`.
  - The "Envido" related buttons should be disabled if `active-bet` is not `nil` or if the conditions for "Envido" are not met.

- **Animation:** Animate the appearance and disappearance of the bet information in the UI.

## 4. Implementation Steps

1.  **Create a new branch:** `feature/bet-state-enhancements` (already done).
2.  **Modify `GameState.swift`:** Add the `BetType` enum.
3.  **Modify `GameEngine.swift`:** Add the `activeBet` property and update the game logic.
4.  **Modify `GameView.swift`:** Implement the button disabling logic and animations.
5.  **Testing:** Thoroughly test the new functionality to ensure that the button states are correctly managed and the animations are smooth.
6.  **Commit and Merge:** Commit the changes with a descriptive message and merge the branch into `main`.
