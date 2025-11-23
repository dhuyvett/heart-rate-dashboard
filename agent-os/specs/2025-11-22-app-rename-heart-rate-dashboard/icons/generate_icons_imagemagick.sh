#!/bin/bash
#
# Heart Rate Dashboard - Icon Generation Script (ImageMagick Native)
#
# This script generates all required icon assets using ImageMagick's
# native drawing commands for maximum compatibility.
#
# Usage:
#   ./generate_icons_imagemagick.sh <option_number>
#
# Options:
#   1 - Flat/Material Design
#   2 - Gradient Style
#   3 - Minimalist Line Art
#   4 - 3D/Skeuomorphic Style

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Function to create Option 1: Flat/Material Design icon
create_option1() {
    local size=$1
    local output=$2
    local stroke_width=$(echo "scale=2; $size * 32 / 1024" | bc)
    local corner_radius=$(echo "scale=0; $size * 192 / 1024" | bc)

    # Scale EKG points
    local scale=$(echo "scale=4; $size / 1024" | bc)

    $CONVERT -size ${size}x${size} xc:none \
        -fill "#4CAF50" \
        -draw "roundrectangle 0,0 $((size-1)),$((size-1)) ${corner_radius},${corner_radius}" \
        -stroke "#FFFFFF" \
        -strokewidth ${stroke_width} \
        -fill none \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "320*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "720*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "512*$scale" | bc)" \
        "$output"
}

# Function to create Option 2: Gradient Style icon
create_option2() {
    local size=$1
    local output=$2
    local stroke_width=$(echo "scale=2; $size * 32 / 1024" | bc)
    local glow_width=$(echo "scale=2; $size * 56 / 1024" | bc)
    local corner_radius=$(echo "scale=0; $size * 192 / 1024" | bc)
    local scale=$(echo "scale=4; $size / 1024" | bc)

    # Create gradient background
    $CONVERT -size ${size}x${size} \
        gradient:"#2E7D32-#81C784" \
        -rotate 45 \
        -gravity center -crop ${size}x${size}+0+0 +repage \
        \( -size ${size}x${size} xc:none \
           -fill white \
           -draw "roundrectangle 0,0 $((size-1)),$((size-1)) ${corner_radius},${corner_radius}" \) \
        -compose DstIn -composite \
        -stroke "rgba(255,255,255,0.3)" \
        -strokewidth ${glow_width} \
        -fill none \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "320*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "720*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "512*$scale" | bc)" \
        -stroke "#FFFFFF" \
        -strokewidth ${stroke_width} \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "320*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "720*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "512*$scale" | bc)" \
        "$output"
}

# Function to create Option 3: Minimalist Line Art icon
create_option3() {
    local size=$1
    local output=$2
    local stroke_width=$(echo "scale=2; $size * 24 / 1024" | bc)
    local border_width=$(echo "scale=2; $size * 4 / 1024" | bc)
    local corner_radius=$(echo "scale=0; $size * 192 / 1024" | bc)
    local scale=$(echo "scale=4; $size / 1024" | bc)

    $CONVERT -size ${size}x${size} xc:none \
        -fill "#FAFAFA" \
        -draw "roundrectangle 0,0 $((size-1)),$((size-1)) ${corner_radius},${corner_radius}" \
        -stroke "#E0E0E0" \
        -strokewidth ${border_width} \
        -fill none \
        -draw "roundrectangle 2,2 $((size-3)),$((size-3)) ${corner_radius},${corner_radius}" \
        -stroke "#4CAF50" \
        -strokewidth ${stroke_width} \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "320*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "720*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "512*$scale" | bc)" \
        "$output"
}

# Function to create Option 4: 3D/Skeuomorphic Style icon
create_option4() {
    local size=$1
    local output=$2
    local stroke_width=$(echo "scale=2; $size * 32 / 1024" | bc)
    local shadow_width=$(echo "scale=2; $size * 36 / 1024" | bc)
    local highlight_width=$(echo "scale=2; $size * 8 / 1024" | bc)
    local corner_radius=$(echo "scale=0; $size * 192 / 1024" | bc)
    local scale=$(echo "scale=4; $size / 1024" | bc)
    local shadow_offset=$(echo "scale=2; $size * 8 / 1024" | bc)

    # Create gradient background with depth
    $CONVERT -size ${size}x${size} \
        gradient:"#66BB6A-#2E7D32" \
        \( -size ${size}x${size} xc:none \
           -fill white \
           -draw "roundrectangle 0,0 $((size-1)),$((size-1)) ${corner_radius},${corner_radius}" \) \
        -compose DstIn -composite \
        -stroke "rgba(0,0,0,0.3)" \
        -strokewidth ${shadow_width} \
        -fill none \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "488*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "552*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "328*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "728*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "488*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "552*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "520*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "520*$scale" | bc)" \
        -stroke "#FFFFFF" \
        -strokewidth ${stroke_width} \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "320*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "720*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "480*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "544*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "512*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "512*$scale" | bc)" \
        -stroke "rgba(255,255,255,0.5)" \
        -strokewidth ${highlight_width} \
        -draw "polyline $(echo "100*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "280*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "340*$scale" | bc),$(echo "474*$scale" | bc) \
                        $(echo "400*$scale" | bc),$(echo "538*$scale" | bc) \
                        $(echo "450*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "500*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "540*$scale" | bc),$(echo "314*$scale" | bc) \
                        $(echo "600*$scale" | bc),$(echo "714*$scale" | bc) \
                        $(echo "660*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "720*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "760*$scale" | bc),$(echo "474*$scale" | bc) \
                        $(echo "820*$scale" | bc),$(echo "538*$scale" | bc) \
                        $(echo "880*$scale" | bc),$(echo "506*$scale" | bc) \
                        $(echo "924*$scale" | bc),$(echo "506*$scale" | bc)" \
        "$output"
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

if [[ ! "$OPTION" =~ ^[1-4]$ ]]; then
    echo "Error: Invalid option number. Use 1, 2, 3, or 4."
    exit 1
fi

echo "Generating icons for Option $OPTION..."
echo ""

# Create output directories
mkdir -p "${GENERATED_DIR}/android"
mkdir -p "${GENERATED_DIR}/ios"
mkdir -p "${GENERATED_DIR}/macos"
mkdir -p "${GENERATED_DIR}/windows"

# Select creation function
case "$OPTION" in
    1) CREATE_FUNC="create_option1" ;;
    2) CREATE_FUNC="create_option2" ;;
    3) CREATE_FUNC="create_option3" ;;
    4) CREATE_FUNC="create_option4" ;;
esac

# Generate master 1024x1024 PNG first
echo "Generating master 1024x1024 PNG..."
$CREATE_FUNC 1024 "${GENERATED_DIR}/icon_1024.png"

# ============================================
# ANDROID ASSETS
# ============================================
echo ""
echo "Generating Android mipmap assets..."

$CREATE_FUNC 48 "${GENERATED_DIR}/android/ic_launcher_mdpi.png"
$CREATE_FUNC 72 "${GENERATED_DIR}/android/ic_launcher_hdpi.png"
$CREATE_FUNC 96 "${GENERATED_DIR}/android/ic_launcher_xhdpi.png"
$CREATE_FUNC 144 "${GENERATED_DIR}/android/ic_launcher_xxhdpi.png"
$CREATE_FUNC 192 "${GENERATED_DIR}/android/ic_launcher_xxxhdpi.png"

echo "  Created Android mipmap assets"

# ============================================
# iOS ASSETS
# ============================================
echo ""
echo "Generating iOS icon assets..."

$CREATE_FUNC 20 "${GENERATED_DIR}/ios/Icon-App-20x20@1x.png"
$CREATE_FUNC 40 "${GENERATED_DIR}/ios/Icon-App-20x20@2x.png"
$CREATE_FUNC 60 "${GENERATED_DIR}/ios/Icon-App-20x20@3x.png"
$CREATE_FUNC 29 "${GENERATED_DIR}/ios/Icon-App-29x29@1x.png"
$CREATE_FUNC 58 "${GENERATED_DIR}/ios/Icon-App-29x29@2x.png"
$CREATE_FUNC 87 "${GENERATED_DIR}/ios/Icon-App-29x29@3x.png"
$CREATE_FUNC 40 "${GENERATED_DIR}/ios/Icon-App-40x40@1x.png"
$CREATE_FUNC 80 "${GENERATED_DIR}/ios/Icon-App-40x40@2x.png"
$CREATE_FUNC 120 "${GENERATED_DIR}/ios/Icon-App-40x40@3x.png"
$CREATE_FUNC 120 "${GENERATED_DIR}/ios/Icon-App-60x60@2x.png"
$CREATE_FUNC 180 "${GENERATED_DIR}/ios/Icon-App-60x60@3x.png"
$CREATE_FUNC 76 "${GENERATED_DIR}/ios/Icon-App-76x76@1x.png"
$CREATE_FUNC 152 "${GENERATED_DIR}/ios/Icon-App-76x76@2x.png"
$CREATE_FUNC 167 "${GENERATED_DIR}/ios/Icon-App-83.5x83.5@2x.png"
cp "${GENERATED_DIR}/icon_1024.png" "${GENERATED_DIR}/ios/Icon-App-1024x1024@1x.png"

echo "  Created iOS icon assets"

# ============================================
# macOS ASSETS
# ============================================
echo ""
echo "Generating macOS icon assets..."

$CREATE_FUNC 16 "${GENERATED_DIR}/macos/app_icon_16.png"
$CREATE_FUNC 32 "${GENERATED_DIR}/macos/app_icon_32.png"
$CREATE_FUNC 64 "${GENERATED_DIR}/macos/app_icon_64.png"
$CREATE_FUNC 128 "${GENERATED_DIR}/macos/app_icon_128.png"
$CREATE_FUNC 256 "${GENERATED_DIR}/macos/app_icon_256.png"
$CREATE_FUNC 512 "${GENERATED_DIR}/macos/app_icon_512.png"
cp "${GENERATED_DIR}/icon_1024.png" "${GENERATED_DIR}/macos/app_icon_1024.png"

echo "  Created macOS icon assets"

# ============================================
# WINDOWS ICO FILE
# ============================================
echo ""
echo "Generating Windows ICO file..."

$CREATE_FUNC 16 "${GENERATED_DIR}/windows/icon_16.png"
$CREATE_FUNC 24 "${GENERATED_DIR}/windows/icon_24.png"
$CREATE_FUNC 32 "${GENERATED_DIR}/windows/icon_32.png"
$CREATE_FUNC 48 "${GENERATED_DIR}/windows/icon_48.png"
$CREATE_FUNC 64 "${GENERATED_DIR}/windows/icon_64.png"
$CREATE_FUNC 128 "${GENERATED_DIR}/windows/icon_128.png"
$CREATE_FUNC 256 "${GENERATED_DIR}/windows/icon_256.png"

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

echo "  Created Windows ICO file"

# ============================================
# SUMMARY
# ============================================
echo ""
echo "============================================"
echo "Icon generation complete!"
echo "============================================"
echo ""
echo "To install the icons, run:"
echo "  ./install_icons.sh"
