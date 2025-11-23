# Heart Rate Dashboard - Icon Design Documentation

## Overview

This document describes the 4 icon design options created for the Heart Rate Dashboard app. Each design features an EKG/pulse line motif representing heart rate monitoring functionality.

## Icon Design Options

### Option 1: Flat/Material Design

**File:** `designs/option1_flat_material.svg`

**Description:**
- Square icon with rounded corners following Material Design guidelines
- Solid green background (#4CAF50 - Material Green 500)
- White simplified EKG/heartbeat line in center
- Clean, minimalist aesthetic with no gradients or shadows
- Line thickness: 32px at 1024px resolution (scales proportionally)

**Visual Characteristics:**
- Background: Solid #4CAF50 (Material Green 500)
- EKG Line: White (#FFFFFF)
- Corner Radius: 192px at 1024px (18.75%)
- Stroke Width: 32px at 1024px

**Best For:**
- Modern Android apps following Material Design
- Apps that need to blend with other Material-style icons
- Maximum legibility at small sizes

---

### Option 2: Gradient Style

**File:** `designs/option2_gradient.svg`

**Description:**
- Square icon with rounded corners
- Gradient background transitioning from dark green (#2E7D32) to light green (#81C784)
- White EKG/pulse line with subtle glow effect
- Modern, vibrant appearance
- Gradient direction: top-left to bottom-right diagonal

**Visual Characteristics:**
- Background Gradient: #2E7D32 (Material Green 800) to #81C784 (Material Green 300)
- EKG Line: White (#FFFFFF) with soft glow
- Glow Effect: Semi-transparent white blur behind main line
- Corner Radius: 192px at 1024px (18.75%)

**Best For:**
- Apps seeking a more dynamic, modern look
- Standing out in app launchers
- Creating visual depth and interest

---

### Option 3: Minimalist Line Art

**File:** `designs/option3_minimalist.svg`

**Description:**
- Square icon with rounded corners
- Pure white/very light gray background (#FAFAFA)
- Green (#4CAF50) EKG line as the sole visual element
- Ultra-clean, modern aesthetic
- Thin stroke weight (24px at 1024px) for elegant appearance

**Visual Characteristics:**
- Background: Light gray (#FAFAFA)
- Border: Subtle gray (#E0E0E0) for definition
- EKG Line: Material Green (#4CAF50)
- Stroke Width: 24px at 1024px (thinner for elegance)
- Corner Radius: 192px at 1024px (18.75%)

**Best For:**
- Minimalist UI themes
- Light mode app launchers
- Professional, understated aesthetic
- Health/medical contexts preferring clinical appearance

---

### Option 4: 3D/Skeuomorphic Style

**File:** `designs/option4_skeuomorphic.svg`

**Description:**
- Square icon with rounded corners
- Green gradient background with subtle depth and lighting
- EKG line with 3D effect (shadow, highlight, depth)
- Heart shape subtly integrated in the background
- Glossy finish with light reflection at top

**Visual Characteristics:**
- Background Gradient: #66BB6A to #4CAF50 to #2E7D32 (vertical depth)
- Glossy Overlay: Semi-transparent white gradient at top
- EKG Line: White with drop shadow and highlight
- Heart Watermark: 15% opacity white heart shape behind EKG
- Corner Radius: 192px at 1024px (18.75%)

**Best For:**
- Premium/luxury app feel
- Standing out with a polished look
- iOS apps (skeuomorphism has iOS heritage)
- Users who appreciate detailed iconography

---

## EKG Line Pattern

All icons use the same EKG/pulse line pattern, representing a typical heartbeat waveform:

```
Pattern: flat -> small P-wave bump -> flat -> tall QRS spike -> deep S-wave dip -> return to baseline
```

The SVG path coordinates (at 1024x1024):
```
M 100,512           - Start left edge, centered
L 280,512           - Flat baseline
L 340,480           - P-wave rise
L 400,544           - P-wave fall
L 450,512           - Return to baseline
L 500,512           - Continue baseline
L 540,320           - QRS spike up
L 600,720           - QRS spike down (S-wave)
L 660,512           - Return to baseline
L 720,512           - Continue baseline
L 760,480           - Secondary small bump
L 820,544           - Secondary small dip
L 880,512           - Return to baseline
L 924,512           - End near right edge
```

---

## Color Palette

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Material Green 500 | #4CAF50 | Primary green, solid backgrounds |
| Material Green 300 | #81C784 | Light green, gradient end |
| Material Green 800 | #2E7D32 | Dark green, gradient start |
| Material Green 400 | #66BB6A | Highlight green, skeuomorphic |
| White | #FFFFFF | EKG lines, highlights |
| Light Gray | #FAFAFA | Minimalist background |
| Border Gray | #E0E0E0 | Subtle borders |

---

## Platform Asset Specifications

### Android (mipmap)

| Density | Size | File |
|---------|------|------|
| mdpi | 48x48 | ic_launcher.png |
| hdpi | 72x72 | ic_launcher.png |
| xhdpi | 96x96 | ic_launcher.png |
| xxhdpi | 144x144 | ic_launcher.png |
| xxxhdpi | 192x192 | ic_launcher.png |

### iOS (AppIcon.appiconset)

| Name | Size | Actual Pixels |
|------|------|---------------|
| Icon-App-20x20@1x | 20x20 | 20 |
| Icon-App-20x20@2x | 20x20 | 40 |
| Icon-App-20x20@3x | 20x20 | 60 |
| Icon-App-29x29@1x | 29x29 | 29 |
| Icon-App-29x29@2x | 29x29 | 58 |
| Icon-App-29x29@3x | 29x29 | 87 |
| Icon-App-40x40@1x | 40x40 | 40 |
| Icon-App-40x40@2x | 40x40 | 80 |
| Icon-App-40x40@3x | 40x40 | 120 |
| Icon-App-60x60@2x | 60x60 | 120 |
| Icon-App-60x60@3x | 60x60 | 180 |
| Icon-App-76x76@1x | 76x76 | 76 |
| Icon-App-76x76@2x | 76x76 | 152 |
| Icon-App-83.5x83.5@2x | 83.5x83.5 | 167 |
| Icon-App-1024x1024@1x | 1024x1024 | 1024 |

### macOS (AppIcon.appiconset)

| Name | Size | Actual Pixels |
|------|------|---------------|
| app_icon_16 | 16x16 | 16 |
| app_icon_32 | 32x32 | 32 |
| app_icon_64 | 64x64 | 64 |
| app_icon_128 | 128x128 | 128 |
| app_icon_256 | 256x256 | 256 |
| app_icon_512 | 512x512 | 512 |
| app_icon_1024 | 1024x1024 | 1024 |

### Windows (app_icon.ico)

Multi-resolution ICO file containing:
- 16x16
- 24x24
- 32x32
- 48x48
- 64x64
- 128x128
- 256x256

---

## Usage Instructions

### Prerequisites

Install one of the following for SVG conversion:
```bash
# Option A: librsvg (recommended)
sudo apt install librsvg2-bin

# Option B: Inkscape
sudo apt install inkscape
```

ImageMagick is also required:
```bash
sudo apt install imagemagick
```

### Generate Icons

1. Choose your preferred design option (1-4)
2. Run the generation script:
```bash
cd agent-os/specs/2025-11-22-app-rename-heart-rate-dashboard/icons
chmod +x generate_icons.sh install_icons.sh
./generate_icons.sh 1   # Replace 1 with your chosen option
```

3. Install the generated icons to the Flutter project:
```bash
./install_icons.sh
```

4. Rebuild the app:
```bash
flutter clean && flutter pub get && flutter run
```

---

## Recommendations

**For Android apps:** Option 1 (Flat/Material Design) or Option 2 (Gradient Style)
- These align with Material Design guidelines

**For iOS apps:** Option 2 (Gradient Style) or Option 4 (3D/Skeuomorphic)
- iOS users appreciate polished, detailed icons

**For cross-platform consistency:** Option 2 (Gradient Style)
- Modern look that works well on all platforms

**For maximum legibility at small sizes:** Option 1 (Flat/Material Design)
- Simple design scales down cleanly

---

## File Structure

```
icons/
├── designs/
│   ├── option1_flat_material.svg      # Design Option 1
│   ├── option2_gradient.svg           # Design Option 2
│   ├── option3_minimalist.svg         # Design Option 3
│   └── option4_skeuomorphic.svg       # Design Option 4
├── generated/
│   ├── android/                       # Android mipmap assets
│   ├── ios/                           # iOS icon assets
│   ├── macos/                         # macOS icon assets
│   └── windows/                       # Windows ICO file
├── generate_icons.sh                  # Icon generation script
├── install_icons.sh                   # Icon installation script
└── ICON_DESIGNS.md                    # This documentation
```
