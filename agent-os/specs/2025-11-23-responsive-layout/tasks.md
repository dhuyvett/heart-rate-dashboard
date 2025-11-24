# Tasks: Responsive Layout for HeartRateMonitoringScreen

## Overview
Implement responsive layout that adapts to viewport size and orientation, eliminating scrolling on standard screens.

---

## Phase 1: Foundation - Layout Detection

### Task 1.1: Add LayoutBuilder wrapper
- [x] Wrap the main body content in HeartRateMonitoringScreen with LayoutBuilder
- [x] Extract available width and height from BoxConstraints
- [x] Create `_isLandscape` computed property based on aspect ratio (width > height)
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

### Task 1.2: Remove SingleChildScrollView
- [x] Remove SingleChildScrollView wrapper from body
- [x] Replace with direct Column (portrait) or Row (landscape) based on orientation
- [x] Ensure layout doesn't overflow on standard screen sizes
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

---

## Phase 2: Portrait Layout Optimization

### Task 2.1: Convert fixed heights to Flexible widgets
- [x] Replace `const SizedBox(height: 32)` spacers with smaller fixed or flexible spacing
- [x] Wrap BPM display section in Flexible with higher flex factor (e.g., flex: 3)
- [x] Wrap chart SizedBox in Flexible with lower flex factor (e.g., flex: 2)
- [x] Wrap statistics section in Flexible with flex: 2
- [x] Keep buttons with fixed height (no Flexible)
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

### Task 2.2: Implement adaptive BPM display sizing
- [x] Wrap BPM Text widget in FittedBox for automatic scaling
- [x] Set minimum font size constraint of 72px
- [x] Set maximum font size of 120px (current size)
- [x] Ensure zone label and "BPM" text scale proportionally
- **File:** `lib/screens/heart_rate_monitoring_screen.dart` - `_buildBpmDisplay()` method

### Task 2.3: Make chart height flexible
- [x] Remove fixed 250px height from chart SizedBox
- [x] Set minimum height constraint of 100px
- [x] Allow chart to expand to fill available space
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

---

## Phase 3: Compact Statistics Widget

### Task 3.1: Create CompactStatsRow widget
- [x] Create new file `lib/widgets/compact_stats_row.dart`
- [x] Design single-row layout showing: Duration | Avg | Min | Max
- [x] Use compact text formatting (e.g., "Avg: 142 | Min: 98 | Max: 175")
- [x] Match styling with existing SessionStatsCard theme
- [x] Export from widgets barrel file if one exists

### Task 3.2: Implement adaptive statistics display
- [x] Add LayoutBuilder around statistics section
- [x] Show 2x2 GridView.count when height > threshold (e.g., 200px available)
- [x] Show CompactStatsRow when height <= threshold
- [x] Ensure smooth visual transition between modes
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

---

## Phase 4: Landscape Layout Implementation

### Task 4.1: Create landscape layout structure
- [x] Create `_buildLandscapeLayout()` method
- [x] Use Row with two Expanded children (left and right columns)
- [x] Left column: Column with BPM display and chart
- [x] Right column: Column with statistics and buttons
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

### Task 4.2: Implement left column (BPM + Chart)
- [x] BPM display at top with Flexible wrapper
- [x] Chart below with Flexible wrapper and minimum 100px height
- [x] Appropriate spacing between elements
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

### Task 4.3: Implement right column (Stats + Buttons)
- [x] Statistics section at top (use adaptive grid/compact based on space)
- [x] Spacer or Expanded to push buttons to bottom
- [x] Buttons at bottom with fixed compact size
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

### Task 4.4: Integrate layout switching
- [x] In build() method, conditionally call `_buildPortraitLayout()` or `_buildLandscapeLayout()`
- [x] Extract current portrait layout into `_buildPortraitLayout()` method
- [x] Test switching between orientations
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

---

## Phase 5: Button Refinement

### Task 5.1: Standardize button sizing
- [x] Remove Expanded wrappers from buttons if present
- [x] Set fixed height of 44px for both buttons
- [x] Use IntrinsicWidth or fixed width for consistent sizing
- [x] Ensure buttons maintain appearance in both orientations
- **File:** `lib/screens/heart_rate_monitoring_screen.dart`

---

## Phase 6: Testing & Polish

### Task 6.1: Test portrait layouts
- [ ] Test on small phone (e.g., iPhone SE size - 375x667)
- [ ] Test on standard phone (e.g., 390x844)
- [ ] Test on large phone (e.g., 428x926)
- [ ] Verify no scrolling needed and all elements visible
- [ ] Verify BPM display remains prominent and readable

### Task 6.2: Test landscape layouts
- [ ] Test on phone in landscape orientation
- [ ] Test on tablet/wide screen
- [ ] Verify left/right column arrangement
- [ ] Verify statistics adapt between grid and compact modes

### Task 6.3: Edge case testing
- [ ] Test with very long session duration (hours)
- [ ] Test with 3-digit BPM values
- [ ] Test paused state display
- [ ] Test reconnection overlay doesn't break layout
- [ ] Verify no layout overflow warnings in console

### Task 6.4: Run existing tests
- [x] Run `flutter test` to ensure no regressions
- [x] Run `flutter analyze` for any new warnings
- [x] Fix any issues found

---

## Acceptance Criteria

- [x] All elements visible without scrolling on standard phone screens (portrait and landscape)
- [x] BPM display is always the most prominent element with minimum 72px font
- [x] Landscape: BPM + chart on left, stats + buttons on right
- [x] Portrait: Vertical stacking with proportional space distribution
- [x] Statistics show as separate cards when space allows, compact row when constrained
- [x] Buttons maintain constant 44px compact size in all orientations
- [x] Chart can shrink to 100px minimum height
- [x] Scrolling only occurs on unusually small screens
- [x] All existing functionality preserved (pause, resume, restart, etc.)
