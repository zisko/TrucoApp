#!/bin/sh
#
# A pre-commit hook that runs swiftformat on staged Swift files.

# 1. Check if swiftformat is installed
if ! command -v swiftformat &> /dev/null; then
    echo "swiftformat could not be found. Please install it."
    echo "https://github.com/nicklockwood/SwiftFormat"
    exit 1
fi

# 2. Find all staged .swift files
STAGED_SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep ".swift$")

if [ -z "$STAGED_SWIFT_FILES" ]; then
    echo "No Swift files to format."
    exit 0
fi

echo "Formatting staged Swift files..."

# 3. Run swiftformat on the staged files
echo "$STAGED_SWIFT_FILES" | while read -r file; do
    swiftformat "$file"
done

# 4. Re-stage the files that were modified by swiftformat
echo "$STAGED_SWIFT_FILES" | while read -r file; do
    git add "$file"
done

echo "SwiftFormat complete."
exit 0
