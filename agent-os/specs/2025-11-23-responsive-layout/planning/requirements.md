# Spec Requirements: Responsive Layout

## Initial Description
"all elements of the main page should be visible without scrolling. If the window is wider than it is tall, lay out the elements side by side to use the space. In all cases, the numeric display should be the most prominant element."

## Requirements Discussion

### First Round Questions

**Q1:** For "visible without scrolling" - should the layout adapt to fit all content in the visible viewport, or should we set minimum sizes and allow scrolling on very small screens?
**Answer:** Layout should adapt so scrolling is only needed on unusually small screens. In all other cases, layout based on actual visible viewport.

**Q2:** For landscape/wide layouts, what arrangement makes sense? I'm assuming BPM display and chart on one side, statistics and controls on the other.
**Answer:** BPM display and chart on the LEFT side, statistics and buttons on the RIGHT side.

**Q3:** The current BPM display is quite large. Should it maintain a minimum size for readability, or can it shrink significantly in constrained layouts?
**Answer:** Maintain a minimum size to allow easy reading from a phone at 3 ft distance.

**Q4:** For the statistics cards (Average BPM, Max BPM, Min BPM, Session Duration), should they remain as separate cards or can they be combined into a more compact layout when space is constrained?
**Answer:** Can be combined when space is constrained, but should be separate cards if space allows.

**Q5:** How important is the chart relative to other elements? Can it shrink significantly or should it maintain a minimum useful size?
**Answer:** Allow the chart to shrink to quite small if needed.

**Q6:** For the action buttons (Connect/Disconnect, Demo Mode, Reset), should they maintain their current size or can they become more compact?
**Answer:** Buttons should have a constant compact size regardless of orientation.

**Q7:** Are there any elements that could be hidden or moved to a menu/drawer in very constrained layouts?
**Answer:** All elements should always be visible.

**Q8:** Does this responsive layout apply only to the main HeartRateMonitoringScreen, or should it extend to any other screens or dialogs?
**Answer:** This work only applies to the main page with the BPM display (HeartRateMonitoringScreen).

### Existing Code to Reference

No similar existing features identified for reference.

### Follow-up Questions

No follow-up questions were needed.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A

## Requirements Summary

### Functional Requirements
- All UI elements must be visible without scrolling on standard screen sizes
- Layout adapts based on aspect ratio (portrait vs landscape/wide)
- BPM numeric display remains the most prominent element in all layouts
- Landscape layout: BPM display + chart on LEFT, statistics + buttons on RIGHT
- Portrait layout: vertical stacking (existing behavior, refined for no-scroll)

### Layout Specifications

**BPM Display:**
- Must maintain minimum size for readability at 3 ft distance
- Remains the most prominent/largest element regardless of layout

**Statistics Cards (Average, Max, Min, Duration):**
- Separate cards when space allows
- Combined/condensed layout when space is constrained

**Heart Rate Chart:**
- Can shrink significantly to accommodate layout constraints
- Lower priority for space allocation than BPM display

**Action Buttons (Connect/Disconnect, Demo Mode, Reset):**
- Constant compact size in all orientations
- Size does not change based on available space

### Scope Boundaries

**In Scope:**
- HeartRateMonitoringScreen responsive layout
- Portrait orientation layout optimization
- Landscape/wide orientation layout with side-by-side arrangement
- Adaptive element sizing based on viewport

**Out of Scope:**
- Other screens or dialogs
- New UI elements or features
- Changes to functionality (only layout/presentation)

### Technical Considerations
- Target screen: HeartRateMonitoringScreen in `lib/main.dart`
- Use Flutter's LayoutBuilder or MediaQuery for responsive behavior
- Aspect ratio detection to switch between portrait/landscape layouts
- Flexible/Expanded widgets for adaptive sizing
- Maintain minimum BPM display size constraint
