# Swift and SwiftUI Development Preferences

This document outlines the preferred conventions and patterns for Swift and SwiftUI development within this project, based on discussions and feedback.

## SwiftUI State Management

*   **`@Observable`**: Prefer the new `@Observable` macro for managing observable models in SwiftUI views. This is the primary choice for state management.
*   **Avoid `ObservableObject` and `Combine`**: Where possible, avoid using `ObservableObject` and the `Combine` framework for state management. The `@Observable` macro is preferred for its simplicity and performance benefits.

## Architectural Patterns

*   **Avoid MVVM**: The Model-View-ViewModel (MVVM) architectural pattern should be avoided. Instead, favor simpler, more direct approaches to connect views with data and logic, leveraging SwiftUI's native capabilities and the `@Observable` macro.

## General Swift Practices

*   **UI-Agnostic Logic**: Core logic, especially in shared modules or Swift Packages (like `TrucoKit`), should remain completely UI-agnostic. It should not import SwiftUI or GameKitUI, nor should it contain any UI-related types or presentation logic.
*   **Clear Separation of Concerns**: Maintain a clear separation between UI code and business logic. UI components should be responsible for presentation, while underlying models and engines handle data and game rules.
