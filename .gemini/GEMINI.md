# Gemini Project Configuration: Truco

This document outlines the established conventions, technical stack, and workflows for the Truco iOS project.

## Project Overview

The project is a SwiftUI-based iOS game named "Truco". It includes:
- A main application target (`Truco`).
- A Swift Package for core game logic (`TrucoKit`).
- An iMessage extension (`TrucoMessages`).

## Swift and SwiftUI Development Preferences

*   **@Observable**: Prefer the new `@Observable` macro for managing observable models in SwiftUI views. This is the primary choice for state management.
*   **Avoid ObservableObject and Combine**: Where possible, avoid using `ObservableObject` and the Combine framework for state management. Prefer `@StateObject` for creating and managing the lifecycle of observable objects within a view.
*   **Avoid MVVM**: The Model-View-ViewModel (MVVM) architectural pattern should be avoided. Favor simpler, more direct approaches.
*   **UI-Agnostic Logic**: Core logic in shared modules like `TrucoKit` should remain completely UI-agnostic and not import SwiftUI.
*   **View Organization**: SwiftUI views should be decomposed into small, single-purpose components and organized into a dedicated `Views` directory (e.g., `Truco/Views`).
*   **Asset Catalogs**: All app icons for all targets **must** be managed directly within their respective Xcode Asset Catalogs (`.xcassets`).

## Development Environment

*   **Operating System**: The development environment is macOS.
*   **Ruby Management**: Ruby-based tooling (like Fastlane) is managed via `rbenv`. The required Ruby version is **3.3.0**.
*   **Ruby Dependencies**: Project-specific gems are managed with a `Gemfile` and installed using `bundle install`.
*   **Shell Scripting**: Scripts may rely on macOS-native tools like `sips` and the command-line JSON processor `jq`.

## Git Workflow

*   **Commits**: Use the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages (e.g., `feat:`, `fix:`, `refactor:`).
*   **Feature Branches**: New features should be developed on dedicated feature branches (e.g., `feature/new-display`).
*   **Start on Main**: When a new feature is requested, ensure you are starting from an up-to-date `main` branch. If the previous feature branch might be relevant, take that into account and ask for clarification.
*   **Squash and Merge**: Once a feature is complete and approved, ask to squash and merge the feature branch into the `main` branch.

## Automation (CI/CD)

*   **Stack**: The project uses **Fastlane** for automation and **GitHub Actions** for CI/CD.
*   **Trigger**: A new release build is automatically triggered for deployment to TestFlight whenever a Git tag matching the pattern `v*` (e.g., `v1.0.1`) is pushed to the repository.
*   **Authentication**: Authentication with App Store Connect is handled via the App Store Connect API Key, with credentials stored in GitHub Actions secrets.

## Agent Interaction Guidelines

*   **Confirm Ambiguity**: Do not take significant actions beyond the clear scope of the request without confirming first.
*   **Explicit Approval for Code Modifications**: Before making any changes to existing code files or creating new ones, always present the proposed changes and await explicit user approval.
