#!/bin/bash

# Source image path
SOURCE_IMAGE="/Users/jacobmizraji/repos/Truco/App Icon/appIcon.png"

# Destination directory for iMessage icons
DEST_DIR="/Users/jacobmizraji/repos/Truco/TrucoMessages/Assets.xcassets/Messages Icon.stickersiconset"

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

echo "Generating iMessage icons from $SOURCE_IMAGE to $DEST_DIR..."

# Define icon sizes and filenames
declare -a ICON_SPECS=(
    "29x29@2x:58x58"
    "29x29@3x:87x87"
    "60x45@2x:120x90"
    "60x45@3x:180x135"
    "29x29@2x:58x58:ipad"
    "67x50@2x:134x100:ipad"
    "74x55@2x:148x110:ipad"
    "1024x1024:1024x1024:ios-marketing"
    "27x20@2x:54x40:universal"
    "27x20@3x:81x60:universal"
    "32x24@2x:64x48:universal"
    "32x24@3x:96x72:universal"
    "1024x768:1024x768:ios-marketing"
)

# Update Contents.json
cat > "${DEST_DIR}/Contents.json" <<EOF
{
  "images" : [
    { "idiom" : "iphone", "scale" : "2x", "size" : "29x29", "filename" : "icon-29x29@2x.png" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "29x29", "filename" : "icon-29x29@3x.png" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "60x45", "filename" : "icon-60x45@2x.png" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "60x45", "filename" : "icon-60x45@3x.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "29x29", "filename" : "icon-29x29@2x~ipad.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "67x50", "filename" : "icon-67x50@2x~ipad.png" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "74x55", "filename" : "icon-74x55@2x~ipad.png" },
    { "idiom" : "ios-marketing", "scale" : "1x", "size" : "1024x1024", "filename" : "icon-1024x1024.png" },
    { "idiom" : "universal", "platform" : "ios", "scale" : "2x", "size" : "27x20", "filename" : "icon-27x20@2x.png" },
    { "idiom" : "universal", "platform" : "ios", "scale" : "3x", "size" : "27x20", "filename" : "icon-27x20@3x.png" },
    { "idiom" : "universal", "platform" : "ios", "scale" : "2x", "size" : "32x24", "filename" : "icon-32x24@2x.png" },
    { "idiom" : "universal", "platform" : "ios", "scale" : "3x", "size" : "32x24", "filename" : "icon-32x24@3x.png" },
    { "idiom" : "ios-marketing", "platform" : "ios", "scale" : "1x", "size" : "1024x768", "filename" : "icon-1024x768.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF

for spec in "${ICON_SPECS[@]}"; do
    IFS=':' read -r size_scale dimensions idiom <<< "$spec"
    IFS='x' read -r width height <<< "$dimensions"
    
    filename="icon-${size_scale}.png"
    if [[ "$idiom" == "ipad" ]]; then
        filename="icon-${size_scale}~ipad.png"
    fi

    OUTPUT_PATH="${DEST_DIR}/${filename}"

    echo "  Generating ${filename} (${width}x${height}px)..."
    sips -z "$height" "$width" "$SOURCE_IMAGE" --out "$OUTPUT_PATH"
done

echo "iMessage icon generation complete."
