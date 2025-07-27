#!/bin/bash

# Set paths
SOURCE_IMAGE="/Users/jacobmizraji/repos/Truco/App Icon/appIcon.png"
ICONSET_DIR="/Users/jacobmizraji/repos/Truco/Truco/Assets.xcassets/AppIcon.appiconset"
CONTENTS_JSON="${ICONSET_DIR}/Contents.json"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Source image not found: $SOURCE_IMAGE"
    exit 1
fi

# Check if Contents.json exists
if [ ! -f "$CONTENTS_JSON" ]; then
    echo "Contents.json not found: $CONTENTS_JSON"
    exit 1
fi

echo "Checking for missing icons..."

# Remove duplicate file if it exists
DUPLICATE_FILE="${ICONSET_DIR}/AppIcon-40x40@3x 1.png"
if [ -f "$DUPLICATE_FILE" ]; then
    echo "Removing duplicate file: AppIcon-40x40@3x 1.png"
    rm "$DUPLICATE_FILE"
fi

# Use jq to parse the JSON file for required filenames and sizes
# This requires jq to be installed. If not available, a more complex grep/sed approach would be needed.
if ! command -v jq &> /dev/null
then
    echo "jq command not found. Please install jq to run this script."
    echo "On macOS, you can use: brew install jq"
    exit 1
fi

jq -r '.images[] | select(.filename != null) | .filename + ":" + .size + ":" + .scale' "$CONTENTS_JSON" | while IFS=':' read -r filename size scale; do
    TARGET_FILE="${ICONSET_DIR}/${filename}"

    if [ ! -f "$TARGET_FILE" ]; then
        echo "Missing icon found: ${filename}. Generating..."

        # Extract width from size (e.g., "60x60" -> 60)
        width=$(echo "$size" | cut -d'x' -f1)
        
        # Calculate pixel dimension based on size and scale
        # Scale can be "2x", "3x", etc.
        scale_multiplier=$(echo "$scale" | sed 's/x//')
        
        # Handle non-numeric width (e.g., 83.5) and scale
        if [[ "$width" == "83.5" ]]; then
            pixel_dim=167
        else
            # Use integer arithmetic
            pixel_dim=$(echo "$width * $scale_multiplier" | bc)
            pixel_dim=${pixel_dim%.*} # Remove fractional part if any
        fi
        
        if [ "$pixel_dim" -gt 0 ]; then
            echo "  Generating ${filename} (${pixel_dim}x${pixel_dim}px)..."
            sips -z "$pixel_dim" "$pixel_dim" "$SOURCE_IMAGE" --out "$TARGET_FILE"
        else
            # Handle cases like 1024x1024 where scale is not used
            pixel_dim=$(echo "$size" | cut -d'x' -f1)
            if [ "$pixel_dim" -gt 0 ]; then
                echo "  Generating ${filename} (${pixel_dim}x${pixel_dim}px)..."
                sips -z "$pixel_dim" "$pixel_dim" "$SOURCE_IMAGE" --out "$TARGET_FILE"
            else
                echo "  Could not determine size for ${filename}. Skipping."
            fi
        fi
    fi
done

echo "Icon generation check complete."
