# TrucoKit Game Engine Architecture

This document provides an in-depth explanation of the `TrucoEngine` and its underlying state machine design. The engine is the core of the `TrucoKit` framework, responsible for managing the game's state, validating moves, and enforcing the rules of Truco.

## Core Components

The engine is built around three key components:

-   **`GameState`**: An `@Observable` class that acts as the single source of truth for the entire game. It holds all the data that defines the current state, including players' hands, scores, the deck, and the current game phase.
-   **`GameMove`**: An enum that represents every possible action a player can take. This includes playing a card, calling Truco, or accepting Envido. Using a strict enum for moves ensures that only valid actions can be processed by the engine.
-   **`TrucoEngine`**: The engine itself. It is a stateless class that takes the current `GameState` and a `GameMove` and computes the resulting `GameState`. It contains all the game's rules and logic.

## The State Machine

The game's flow is managed by a state machine, with the `GamePhase` enum defining the possible states. This design ensures that the game can only be in one well-defined state at any given time, which prevents a wide range of bugs and makes the game flow predictable.

### The States (`GamePhase`)

-   **`.preGame`**: The initial state before the game begins. The UI should display a "Start Game" button.
-   **`.playing`**: The main active state where players take turns playing cards and making calls like Truco or Envido. The UI is fully interactive.
-   **`.handOver`**: A temporary, paused state that occurs immediately after a hand is completed (i.e., both players have played a card). In this state, the UI should display the `HandOutcomeView` to show the user who won the hand. The game is waiting for the user to press "Continue".
-   **`.roundSummary`**: A paused state that occurs after a round has a definitive winner. The UI should display the `RoundSummaryView`, which provides a detailed breakdown of all points awarded in that round. The game is waiting for the user to press "Start Next Round".
-   **`.gameOver`**: The final state, reached when a player's score exceeds the winning threshold (e.g., 30 points). The UI should display a "Game Over" message and a "Play Again" button.

### State Transitions

Transitions between states are triggered by the `TrucoEngine` in response to specific `GameMove` actions. The engine's logic is the sole authority on when and how a state transition occurs.

| Current State    | Triggering Action (`GameMove`) | Next State       | Description                                                                                                                            |
| ---------------- | ------------------------------ | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `.preGame`       | `dealInitialCards()`           | `.playing`       | The game starts, cards are dealt, and the first player's turn begins.                                                                  |
| `.playing`       | `.playCard` (second card)      | `.handOver`      | A hand is completed. The engine determines the winner and pauses the game to show the outcome.                                         |
| `.handOver`      | `.continueAfterHand`           | `.playing`       | The user continues after seeing the hand result. The engine determines the round is not over and starts the next hand.                 |
| `.handOver`      | `.continueAfterHand`           | `.roundSummary`  | The user continues, and the engine determines that the round *is* over. It calculates points and moves to the round summary.          |
| `.roundSummary`  | `startNewRound()`              | `.playing`       | The user is ready to proceed. The engine resets the board for a new round and deals new cards.                                         |
| Any State        | Score reaches 30               | `.gameOver`      | A player's score reaches the winning threshold at the end of a round.                                                                  |
| `.gameOver`      | `dealInitialCards()`           | `.playing`       | The user chooses to play again, resetting the entire game state.                                                                       |

## Design Decisions and Principles

The architecture of the `TrucoEngine` was guided by several key state machine principles:

1.  **Centralized and Predictable State**: By consolidating all state into the `GameState` class, we ensure there is a single source of truth. The engine itself is stateless; its output is purely a function of its inputs (`GameState` and `GameMove`). This makes the engine highly predictable and easy to test—given the same state and the same move, it will *always* produce the same result.

2.  **Explicit Actions**: Using the `GameMove` enum prevents invalid or ambiguous actions from ever reaching the engine's logic. This is a core principle of state machine design: the machine can only change its state in response to a predefined, valid event. This eliminates the need for complex validation logic scattered throughout the codebase.

3.  **Clear and Enforced Game Flow**: The `GamePhase` state machine makes the game's flow robust. It is impossible, for example, for a player to play a card when the game is in the `.roundSummary` phase. The UI can simply use the `gamePhase` to decide which controls to show or hide, ensuring the user can only perform valid actions at any given time.

## Potential Issues and Future Improvements

-   **Simplistic AI**: The current opponent AI is very basic. It plays a random card and accepts any Truco or Envido call. A significant future improvement would be to create a more strategic AI that can evaluate its hand and make intelligent decisions.
-   **Lack of Input Validation for Calls**: While the state machine prevents actions at the wrong *time*, the engine doesn't yet have robust logic to prevent a player from making a call they are not allowed to make (e.g., calling "Retruco" when it's not their turn to do so). This logic should be added to the `handle(move:)` function.
-   **Synchronous Engine**: The engine currently runs synchronously on the main thread. For a local game, this is perfectly fine. However, if multiplayer capabilities were expanded, the engine's design would need to be adapted to handle asynchronous events and potential network latency.
-   **Error Handling**: The engine currently prints errors to the console. A more robust solution would be to introduce a proper error-handling mechanism, perhaps by having the `handle(move:)` function throw specific errors that the UI can catch and respond to.
