#!/bin/bash
#
# Heart Rate Dashboard - Icon Generation Script
#
# This script generates all required icon assets for Android, iOS, macOS, and Windows
# from a selected SVG source icon design.
#
# Usage:
#   ./generate_icons.sh <option_number>
#
# Options:
#   1 - Flat/Material Design
#   2 - Gradient Style
#   3 - Minimalist Line Art
#   4 - 3D/Skeuomorphic Style
#
# Requirements:
#   - ImageMagick (convert-im7 or convert command)
#   - librsvg2-bin (for SVG to PNG conversion with rsvg-convert) OR Inkscape
#
# Output directories:
#   - generated/android/  - Android mipmap assets
#   - generated/ios/      - iOS icon assets
#   - generated/macos/    - macOS icon assets
#   - generated/windows/  - Windows .ico file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIGNS_DIR="${SCRIPT_DIR}/designs"
GENERATED_DIR="${SCRIPT_DIR}/generated"

# Detect ImageMagick binary
if command -v convert-im7 &> /dev/null; then
    CONVERT="convert-im7"
elif command -v convert &> /dev/null; then
    CONVERT="convert"
elif command -v magick &> /dev/null; then
    CONVERT="magick"
else
    echo "Error: ImageMagick not found. Please install ImageMagick."
    exit 1
fi

echo "Using ImageMagick: $CONVERT"

# Detect SVG converter
if command -v rsvg-convert &> /dev/null; then
    SVG_CONVERTER="rsvg-convert"
elif command -v inkscape &> /dev/null; then
    SVG_CONVERTER="inkscape"
else
    echo "Warning: Neither rsvg-convert nor inkscape found."
    echo "Will attempt direct ImageMagick SVG conversion (may have reduced quality)"
    SVG_CONVERTER="imagemagick"
fi

echo "Using SVG converter: $SVG_CONVERTER"

# Function to convert SVG to PNG
svg_to_png() {
    local input_svg="$1"
    local output_png="$2"
    local size="$3"

    case "$SVG_CONVERTER" in
        "rsvg-convert")
            rsvg-convert -w "$size" -h "$size" "$input_svg" -o "$output_png"
            ;;
        "inkscape")
            inkscape "$input_svg" -w "$size" -h "$size" -o "$output_png"
            ;;
        "imagemagick")
            $CONVERT -background none -density 300 "$input_svg" -resize "${size}x${size}" "$output_png"
            ;;
    esac
}

# Function to resize PNG
resize_png() {
    local input_png="$1"
    local output_png="$2"
    local size="$3"

    $CONVERT "$input_png" -resize "${size}x${size}" "$output_png"
}

# Validate input
if [ -z "$1" ]; then
    echo "Usage: $0 <option_number>"
    echo ""
    echo "Options:"
    echo "  1 - Flat/Material Design"
    echo "  2 - Gradient Style"
    echo "  3 - Minimalist Line Art"
    echo "  4 - 3D/Skeuomorphic Style"
    exit 1
fi

OPTION="$1"

case "$OPTION" in
    1) SOURCE_SVG="${DESIGNS_DIR}/option1_flat_material.svg" ;;
    2) SOURCE_SVG="${DESIGNS_DIR}/option2_gradient.svg" ;;
    3) SOURCE_SVG="${DESIGNS_DIR}/option3_minimalist.svg" ;;
    4) SOURCE_SVG="${DESIGNS_DIR}/option4_skeuomorphic.svg" ;;
    *)
        echo "Error: Invalid option number. Use 1, 2, 3, or 4."
        exit 1
        ;;
esac

if [ ! -f "$SOURCE_SVG" ]; then
    echo "Error: Source SVG not found: $SOURCE_SVG"
    exit 1
fi

echo "Generating icons from: $SOURCE_SVG"
echo ""

# Create output directories
mkdir -p "${GENERATED_DIR}/android"
mkdir -p "${GENERATED_DIR}/ios"
mkdir -p "${GENERATED_DIR}/macos"
mkdir -p "${GENERATED_DIR}/windows"

# Generate master 1024x1024 PNG first
echo "Generating master 1024x1024 PNG..."
MASTER_PNG="${GENERATED_DIR}/icon_1024.png"
svg_to_png "$SOURCE_SVG" "$MASTER_PNG" 1024

# ============================================
# ANDROID ASSETS
# ============================================
echo ""
echo "Generating Android mipmap assets..."

# Android mipmap sizes
# mdpi: 48x48
# hdpi: 72x72
# xhdpi: 96x96
# xxhdpi: 144x144
# xxxhdpi: 192x192

resize_png "$MASTER_PNG" "${GENERATED_DIR}/android/ic_launcher_mdpi.png" 48
resize_png "$MASTER_PNG" "${GENERATED_DIR}/android/ic_launcher_hdpi.png" 72
resize_png "$MASTER_PNG" "${GENERATED_DIR}/android/ic_launcher_xhdpi.png" 96
resize_png "$MASTER_PNG" "${GENERATED_DIR}/android/ic_launcher_xxhdpi.png" 144
resize_png "$MASTER_PNG" "${GENERATED_DIR}/android/ic_launcher_xxxhdpi.png" 192

echo "  Created: ic_launcher_mdpi.png (48x48)"
echo "  Created: ic_launcher_hdpi.png (72x72)"
echo "  Created: ic_launcher_xhdpi.png (96x96)"
echo "  Created: ic_launcher_xxhdpi.png (144x144)"
echo "  Created: ic_launcher_xxxhdpi.png (192x192)"

# ============================================
# iOS ASSETS
# ============================================
echo ""
echo "Generating iOS icon assets..."

# iOS icon sizes (as per Contents.json)
# 20x20@1x = 20, @2x = 40, @3x = 60
# 29x29@1x = 29, @2x = 58, @3x = 87
# 40x40@1x = 40, @2x = 80, @3x = 120
# 60x60@2x = 120, @3x = 180
# 76x76@1x = 76, @2x = 152
# 83.5x83.5@2x = 167
# 1024x1024@1x = 1024

resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-20x20@1x.png" 20
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-20x20@2x.png" 40
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-20x20@3x.png" 60
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-29x29@1x.png" 29
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-29x29@2x.png" 58
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-29x29@3x.png" 87
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-40x40@1x.png" 40
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-40x40@2x.png" 80
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-40x40@3x.png" 120
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-60x60@2x.png" 120
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-60x60@3x.png" 180
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-76x76@1x.png" 76
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-76x76@2x.png" 152
resize_png "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-83.5x83.5@2x.png" 167
cp "$MASTER_PNG" "${GENERATED_DIR}/ios/Icon-App-1024x1024@1x.png"

echo "  Created: Icon-App-20x20@1x.png (20x20)"
echo "  Created: Icon-App-20x20@2x.png (40x40)"
echo "  Created: Icon-App-20x20@3x.png (60x60)"
echo "  Created: Icon-App-29x29@1x.png (29x29)"
echo "  Created: Icon-App-29x29@2x.png (58x58)"
echo "  Created: Icon-App-29x29@3x.png (87x87)"
echo "  Created: Icon-App-40x40@1x.png (40x40)"
echo "  Created: Icon-App-40x40@2x.png (80x80)"
echo "  Created: Icon-App-40x40@3x.png (120x120)"
echo "  Created: Icon-App-60x60@2x.png (120x120)"
echo "  Created: Icon-App-60x60@3x.png (180x180)"
echo "  Created: Icon-App-76x76@1x.png (76x76)"
echo "  Created: Icon-App-76x76@2x.png (152x152)"
echo "  Created: Icon-App-83.5x83.5@2x.png (167x167)"
echo "  Created: Icon-App-1024x1024@1x.png (1024x1024)"

# ============================================
# macOS ASSETS
# ============================================
echo ""
echo "Generating macOS icon assets..."

# macOS icon sizes
# 16x16@1x = 16, @2x = 32
# 32x32@1x = 32, @2x = 64
# 128x128@1x = 128, @2x = 256
# 256x256@1x = 256, @2x = 512
# 512x512@1x = 512, @2x = 1024

resize_png "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_16.png" 16
resize_png "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_32.png" 32
resize_png "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_64.png" 64
resize_png "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_128.png" 128
resize_png "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_256.png" 256
resize_png "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_512.png" 512
cp "$MASTER_PNG" "${GENERATED_DIR}/macos/app_icon_1024.png"

echo "  Created: app_icon_16.png (16x16)"
echo "  Created: app_icon_32.png (32x32)"
echo "  Created: app_icon_64.png (64x64)"
echo "  Created: app_icon_128.png (128x128)"
echo "  Created: app_icon_256.png (256x256)"
echo "  Created: app_icon_512.png (512x512)"
echo "  Created: app_icon_1024.png (1024x1024)"

# ============================================
# WINDOWS ICO FILE
# ============================================
echo ""
echo "Generating Windows ICO file..."

# Windows ICO should contain multiple sizes: 16, 24, 32, 48, 64, 128, 256
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_16.png" 16
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_24.png" 24
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_32.png" 32
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_48.png" 48
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_64.png" 64
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_128.png" 128
resize_png "$MASTER_PNG" "${GENERATED_DIR}/windows/icon_256.png" 256

# Create ICO file with all sizes
$CONVERT "${GENERATED_DIR}/windows/icon_16.png" \
         "${GENERATED_DIR}/windows/icon_24.png" \
         "${GENERATED_DIR}/windows/icon_32.png" \
         "${GENERATED_DIR}/windows/icon_48.png" \
         "${GENERATED_DIR}/windows/icon_64.png" \
         "${GENERATED_DIR}/windows/icon_128.png" \
         "${GENERATED_DIR}/windows/icon_256.png" \
         "${GENERATED_DIR}/windows/app_icon.ico"

# Clean up temporary Windows PNGs
rm -f "${GENERATED_DIR}/windows/icon_"*.png

echo "  Created: app_icon.ico (multi-resolution)"

# ============================================
# SUMMARY
# ============================================
echo ""
echo "============================================"
echo "Icon generation complete!"
echo "============================================"
echo ""
echo "Generated files:"
echo ""
echo "Android (${GENERATED_DIR}/android/):"
ls -la "${GENERATED_DIR}/android/"
echo ""
echo "iOS (${GENERATED_DIR}/ios/):"
ls -la "${GENERATED_DIR}/ios/"
echo ""
echo "macOS (${GENERATED_DIR}/macos/):"
ls -la "${GENERATED_DIR}/macos/"
echo ""
echo "Windows (${GENERATED_DIR}/windows/):"
ls -la "${GENERATED_DIR}/windows/"
echo ""
echo "To install the icons, run:"
echo "  ./install_icons.sh"
