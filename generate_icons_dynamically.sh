#!/bin/bash

# This script dynamically generates all required icons for an asset catalog
# by reading its Contents.json file.
#
# Usage: ./generate_icons_dynamically.sh <path_to_source_image> <path_to_iconset_directory>
#
# Example:
# ./generate_icons_dynamically.sh "App Icon/appIcon.png" "Truco/Assets.xcassets/AppIcon.appiconset"

# --- Configuration ---
SOURCE_IMAGE="$1"
ICONSET_DIR="$2"
CONTENTS_JSON="${ICONSET_DIR}/Contents.json"

# --- Pre-flight Checks ---
if [ -z "$SOURCE_IMAGE" ] || [ -z "$ICONSET_DIR" ]; then
    echo "Usage: $0 <path_to_source_image> <path_to_iconset_directory>"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it to continue (e.g., 'brew install jq')."
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at '$SOURCE_IMAGE'"
    exit 1
fi

if [ ! -f "$CONTENTS_JSON" ]; then
    echo "Error: Contents.json not found in '$ICONSET_DIR'"
    exit 1
fi

echo "Starting icon generation for: ${ICONSET_DIR}"

# --- Main Logic ---
# Clean the directory of any existing .png files to ensure a fresh start
find "${ICONSET_DIR}" -name "*.png" -type f -delete
echo "Cleaned existing PNG files from target directory."

# Read the Contents.json and generate each icon
jq -r '.images[] | select(.size and .scale and .filename) | .filename + ";" + .size + ";" + .scale' "$CONTENTS_JSON" | while IFS=';' read -r filename size scale; do
    
    # Extract base width and height (e.g., "60x45" -> width=60, height=45)
    base_width=$(echo "$size" | cut -d'x' -f1)
    base_height=$(echo "$size" | cut -d'x' -f2)
    
    # Extract scale multiplier (e.g., "2x" -> 2)
    scale_multiplier=$(echo "$scale" | tr -d 'x')
    
    # Calculate final pixel dimensions using bc for floating point math
    pixel_width=$(echo "$base_width * $scale_multiplier" | bc | awk '{print int($1+0.5)}')
    pixel_height=$(echo "$base_height * $scale_multiplier" | bc | awk '{print int($1+0.5)}')
    
    OUTPUT_PATH="${ICONSET_DIR}/${filename}"
    
    if [ "$pixel_width" -gt 0 ] && [ "$pixel_height" -gt 0 ]; then
        echo "  -> Generating ${filename} (${pixel_width}x${pixel_height}px)..."
        sips -z "$pixel_height" "$pixel_width" "$SOURCE_IMAGE" --out "$OUTPUT_PATH" > /dev/null 2>&1
    else
        echo "  -> Skipping ${filename} due to invalid dimensions."
    fi
done

# Handle marketing icons that might not have a 'scale'
jq -r '.images[] | select(.size and .scale == null and .filename) | .filename + ";" + .size' "$CONTENTS_JSON" | while IFS=';' read -r filename size; do
    
    pixel_width=$(echo "$size" | cut -d'x' -f1)
    pixel_height=$(echo "$size" | cut -d'x' -f2)
    
    OUTPUT_PATH="${ICONSET_DIR}/${filename}"
    
    if [ "$pixel_width" -gt 0 ] && [ "$pixel_height" -gt 0 ]; then
        echo "  -> Generating ${filename} (${pixel_width}x${pixel_height}px)..."
        sips -z "$pixel_height" "$pixel_width" "$SOURCE_IMAGE" --out "$OUTPUT_PATH" > /dev/null 2>&1
    else
        echo "  -> Skipping ${filename} due to invalid dimensions."
    fi
done


echo "Icon generation complete for: ${ICONSET_DIR}"
echo ""
