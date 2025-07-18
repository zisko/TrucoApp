#!/bin/bash

# Source image path
SOURCE_IMAGE="/Users/jacobmizraji/repos/Truco/app icon/appIcon.png"

# Destination directory for app icons
DEST_DIR="/Users/jacobmizraji/repos/Truco/Truco/Assets.xcassets/AppIcon.appiconset"

# Check if sips command exists
if ! command -v sips &> /dev/null
then
    echo "sips command not found. This script requires macOS."
    exit 1
fi

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

echo "Generating app icons from $SOURCE_IMAGE to $DEST_DIR..."

# Define icon sizes and filenames
declare -a ICON_SIZES=(
    "20x20@2x:40" "20x20@3x:60"
    "29x29@2x:58" "29x29@3x:87"
    "40x40@2x:80" "40x40@3x:120"
    "60x60@2x:120" "60x60@3x:180"
    "20x20@1x:20" "20x20@2x:40" # iPad
    "29x29@1x:29" "29x29@2x:58" # iPad
    "40x40@1x:40" "40x40@2x:80" # iPad
    "76x76@1x:76" "76x76@2x:152" # iPad
    "83.5x83.5@2x:167" # iPad Pro
    "1024x1024:1024" # App Store
)

for entry in "${ICON_SIZES[@]}"; do
    IFS=':' read -r filename_base size_px <<< "$entry"
    FILENAME="AppIcon-${filename_base}.png"
    OUTPUT_PATH="${DEST_DIR}/${FILENAME}"

    echo "  Generating ${FILENAME} (${size_px}x${size_px}px)..."
    sips -z "$size_px" "$size_px" "$SOURCE_IMAGE" --out "$OUTPUT_PATH"
done

echo "App icon generation complete."
