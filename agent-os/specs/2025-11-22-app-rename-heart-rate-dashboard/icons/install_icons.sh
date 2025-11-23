#!/bin/bash
#
# Heart Rate Dashboard - Icon Installation Script
#
# This script installs the generated icon assets to the appropriate
# platform-specific directories in the Flutter project.
#
# Usage:
#   ./install_icons.sh
#
# Prerequisites:
#   - Run generate_icons.sh first to create the icon assets
#
# Target directories:
#   - Android: android/app/src/main/res/mipmap-*/
#   - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
#   - macOS: macos/Runner/Assets.xcassets/AppIcon.appiconset/
#   - Windows: windows/runner/resources/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="${SCRIPT_DIR}/generated"
PROJECT_ROOT="${SCRIPT_DIR}/../../../.."

# Verify generated assets exist
if [ ! -d "${GENERATED_DIR}/android" ] || [ ! -d "${GENERATED_DIR}/ios" ] || [ ! -d "${GENERATED_DIR}/macos" ] || [ ! -d "${GENERATED_DIR}/windows" ]; then
    echo "Error: Generated assets not found. Please run generate_icons.sh first."
    exit 1
fi

echo "Installing icon assets..."
echo "Project root: ${PROJECT_ROOT}"
echo ""

# ============================================
# ANDROID INSTALLATION
# ============================================
echo "Installing Android mipmap assets..."

ANDROID_RES="${PROJECT_ROOT}/android/app/src/main/res"

if [ -d "$ANDROID_RES" ]; then
    cp "${GENERATED_DIR}/android/ic_launcher_mdpi.png" "${ANDROID_RES}/mipmap-mdpi/ic_launcher.png"
    cp "${GENERATED_DIR}/android/ic_launcher_hdpi.png" "${ANDROID_RES}/mipmap-hdpi/ic_launcher.png"
    cp "${GENERATED_DIR}/android/ic_launcher_xhdpi.png" "${ANDROID_RES}/mipmap-xhdpi/ic_launcher.png"
    cp "${GENERATED_DIR}/android/ic_launcher_xxhdpi.png" "${ANDROID_RES}/mipmap-xxhdpi/ic_launcher.png"
    cp "${GENERATED_DIR}/android/ic_launcher_xxxhdpi.png" "${ANDROID_RES}/mipmap-xxxhdpi/ic_launcher.png"
    echo "  Installed Android mipmap assets"
else
    echo "  Warning: Android resource directory not found: ${ANDROID_RES}"
fi

# ============================================
# iOS INSTALLATION
# ============================================
echo "Installing iOS icon assets..."

IOS_ICONS="${PROJECT_ROOT}/ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ -d "$IOS_ICONS" ]; then
    cp "${GENERATED_DIR}/ios/Icon-App-20x20@1x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-20x20@2x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-20x20@3x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-29x29@1x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-29x29@2x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-29x29@3x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-40x40@1x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-40x40@2x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-40x40@3x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-60x60@2x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-60x60@3x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-76x76@1x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-76x76@2x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-83.5x83.5@2x.png" "${IOS_ICONS}/"
    cp "${GENERATED_DIR}/ios/Icon-App-1024x1024@1x.png" "${IOS_ICONS}/"
    echo "  Installed iOS icon assets"
else
    echo "  Warning: iOS icon directory not found: ${IOS_ICONS}"
fi

# ============================================
# macOS INSTALLATION
# ============================================
echo "Installing macOS icon assets..."

MACOS_ICONS="${PROJECT_ROOT}/macos/Runner/Assets.xcassets/AppIcon.appiconset"

if [ -d "$MACOS_ICONS" ]; then
    cp "${GENERATED_DIR}/macos/app_icon_16.png" "${MACOS_ICONS}/"
    cp "${GENERATED_DIR}/macos/app_icon_32.png" "${MACOS_ICONS}/"
    cp "${GENERATED_DIR}/macos/app_icon_64.png" "${MACOS_ICONS}/"
    cp "${GENERATED_DIR}/macos/app_icon_128.png" "${MACOS_ICONS}/"
    cp "${GENERATED_DIR}/macos/app_icon_256.png" "${MACOS_ICONS}/"
    cp "${GENERATED_DIR}/macos/app_icon_512.png" "${MACOS_ICONS}/"
    cp "${GENERATED_DIR}/macos/app_icon_1024.png" "${MACOS_ICONS}/"
    echo "  Installed macOS icon assets"
else
    echo "  Warning: macOS icon directory not found: ${MACOS_ICONS}"
fi

# ============================================
# WINDOWS INSTALLATION
# ============================================
echo "Installing Windows icon..."

WINDOWS_RES="${PROJECT_ROOT}/windows/runner/resources"

if [ -d "$WINDOWS_RES" ]; then
    cp "${GENERATED_DIR}/windows/app_icon.ico" "${WINDOWS_RES}/"
    echo "  Installed Windows icon"
else
    echo "  Warning: Windows resources directory not found: ${WINDOWS_RES}"
fi

# ============================================
# SUMMARY
# ============================================
echo ""
echo "============================================"
echo "Icon installation complete!"
echo "============================================"
echo ""
echo "Installed icons to:"
echo "  - Android: ${ANDROID_RES}/mipmap-*/"
echo "  - iOS: ${IOS_ICONS}/"
echo "  - macOS: ${MACOS_ICONS}/"
echo "  - Windows: ${WINDOWS_RES}/"
echo ""
echo "Please rebuild the app to see the new icons:"
echo "  flutter clean && flutter pub get && flutter run"
