#!/bin/sh
#
# This script installs the project's Git hooks by creating symbolic links
# from the .git/hooks directory to the version-controlled scripts.

# Get the root directory of the Git repository
GIT_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$GIT_ROOT/.git/hooks"
SCRIPTS_DIR="$GIT_ROOT/scripts"

echo "Installing Git hooks..."

# Create a symbolic link for the pre-commit hook
ln -sf "$SCRIPTS_DIR/pre-commit.sh" "$HOOKS_DIR/pre-commit"

# Make the hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "Hooks installed successfully."
