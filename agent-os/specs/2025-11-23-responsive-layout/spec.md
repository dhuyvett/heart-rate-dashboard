# Specification: Responsive Layout for HeartRateMonitoringScreen

## Goal
Implement a responsive layout for the HeartRateMonitoringScreen that adapts to different screen sizes and orientations, ensuring all elements are visible without scrolling on standard screens while keeping the BPM display as the most prominent element.

## User Stories
- As a user, I want the heart rate monitoring screen to fit entirely within my viewport so that I can see all information without scrolling during workouts.
- As a user on a tablet or wide screen, I want the layout to use horizontal space efficiently with elements arranged side-by-side so that I can see more data at once.

## Specific Requirements

**Orientation Detection and Layout Switching**
- Use LayoutBuilder to detect available width and height of the viewport
- Switch to landscape layout when width > height (aspect ratio > 1)
- Use portrait (vertical stacking) layout when height >= width
- Base layout decisions on actual visible viewport size, not device orientation alone

**Portrait Layout (Vertical Stacking)**
- Maintain current vertical arrangement: BPM display, chart, statistics, buttons
- Use Flexible/Expanded widgets instead of fixed heights to fill available space
- Remove SingleChildScrollView and use a single Column with space distribution
- Allocate space proportionally: BPM display gets priority, chart can shrink

**Landscape Layout (Side-by-Side)**
- Use Row as primary container with two columns
- LEFT column: BPM display (top) and heart rate chart (bottom)
- RIGHT column: Session statistics (top) and action buttons (bottom)
- Both columns should use Expanded to split available width appropriately

**BPM Display Sizing**
- Minimum font size of 72px to ensure readability at 3 feet distance
- In portrait: can scale up to current 120px when space allows
- In landscape: may need to use slightly smaller size (80-100px) to fit layout
- Use FittedBox with constraints to scale text within safe bounds
- Always remain the largest/most prominent element on screen

**Statistics Cards Adaptive Layout**
- When sufficient space: display as 2x2 grid with separate cards (current behavior)
- When constrained: combine into a compact horizontal row or 2x2 with smaller aspect ratio
- Create a new CompactStatsRow widget for condensed display
- Use LayoutBuilder to determine which variant to show based on available height

**Chart Sizing**
- Allow chart height to shrink to minimum of 100px in constrained layouts
- In portrait: use Flexible with flex factor lower than BPM display
- In landscape: chart fills remaining vertical space in left column below BPM
- HeartRateChart widget already handles content responsively

**Button Sizing**
- Fixed compact height of approximately 44px (matching touch-friendly minimum)
- Remove Expanded wrappers; buttons should not grow based on available space
- Maintain horizontal Row layout with fixed spacing between buttons
- Same visual appearance in both portrait and landscape orientations

## Visual Design

No visual mockups provided.

## Existing Code to Leverage

**`lib/screens/heart_rate_monitoring_screen.dart`**
- Contains all UI elements that need responsive treatment
- _buildBpmDisplay() method handles BPM rendering with animations
- GridView.count used for statistics can be replaced with responsive alternative
- Button styling and behavior should be preserved

**`lib/widgets/session_stats_card.dart`**
- Individual stat card widget with icon, label, and value
- Can be reused as-is for separate cards mode
- May need companion CompactStatsRow widget for condensed mode

**`lib/widgets/heart_rate_chart.dart`**
- Chart widget that adapts to parent container size
- No modifications needed; just provide appropriate parent constraints
- Already uses Padding internally

**Flutter framework responsive patterns**
- LayoutBuilder: primary tool for detecting available constraints
- MediaQuery: backup for screen-level information if needed
- Flexible/Expanded: for proportional space allocation
- FittedBox: for scaling text within bounds

## Out of Scope
- Changes to other screens (DeviceSelectionScreen, SettingsScreen, etc.)
- Modifications to the AppBar or its contents
- New UI features or functionality beyond layout changes
- Changes to the reconnection overlay behavior
- Tablet-specific layouts or breakpoints beyond portrait/landscape
- Animations or transitions when switching between layouts
- Persisting user layout preferences
- Supporting extremely small screens (smartwatches)
- Split-screen or multi-window support
- Landscape-specific keyboard handling
