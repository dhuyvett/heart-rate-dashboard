# Manual Testing Guide - Session History Management

## Overview
This guide provides step-by-step instructions for manually testing the Session History Management feature.

## Prerequisites
- Flutter development environment set up
- Application running on a test device or emulator
- Demo mode enabled OR Bluetooth heart rate monitor available

## Test Session 1: Basic Session History Viewing

### Setup
1. Start the application
2. Create at least 3 workout sessions:
   - Start a session (demo mode or with device)
   - Let it run for 1-2 minutes
   - End the session
   - Repeat 3 times

### Test Steps
1. **Open Session History**
   - Tap hamburger menu (three horizontal lines) in top-left
   - Tap "Session History"
   - VERIFY: Session History screen opens
   - VERIFY: Title shows "Session History"

2. **View Session List**
   - VERIFY: All 3 sessions are displayed
   - VERIFY: Sessions sorted newest first (most recent at top)
   - VERIFY: Each session shows:
     - Date and time (format: "Nov 25, 2025 2:30 PM")
     - Duration (format: "01:23:45")
   - VERIFY: No empty state message visible

3. **View Session Detail**
   - Tap on the first (newest) session
   - VERIFY: Session detail screen opens
   - VERIFY: AppBar shows device name
   - VERIFY: Heart rate graph displays
   - VERIFY: Session statistics display:
     - Duration
     - Average HR
     - Minimum HR
     - Maximum HR
   - VERIFY: Three buttons in AppBar:
     - Left arrow (previous session)
     - Right arrow (next session - should be disabled)
     - Delete icon

4. **Navigate Between Sessions**
   - Tap left arrow (previous session)
   - VERIFY: Detail view updates to show previous session
   - VERIFY: Device name changes
   - VERIFY: Graph and statistics update
   - VERIFY: Navigation happens without returning to list
   - Tap left arrow again
   - VERIFY: View updates to third (oldest) session
   - VERIFY: Left arrow is now disabled
   - VERIFY: Right arrow is enabled
   - Tap right arrow
   - VERIFY: View updates to second session

5. **Return to List**
   - Tap back button
   - VERIFY: Return to session history list
   - VERIFY: All sessions still visible

## Test Session 2: Session Deletion

### Setup
- Continue from Test Session 1 with 3 sessions

### Test Steps

1. **Swipe to Delete from List**
   - Open Session History screen
   - Swipe left on the second session in the list
   - VERIFY: Red background with delete icon appears
   - VERIFY: Confirmation dialog appears
   - VERIFY: Dialog message: "Delete this session? This action cannot be undone."
   - VERIFY: Two buttons: "Cancel" and "Delete"

2. **Cancel Deletion**
   - Tap "Cancel"
   - VERIFY: Dialog closes
   - VERIFY: Session remains in list

3. **Confirm Deletion**
   - Swipe left on the second session again
   - Tap "Delete" in confirmation dialog
   - VERIFY: Dialog closes
   - VERIFY: SnackBar appears with message "Session deleted"
   - VERIFY: Session removed from list
   - VERIFY: Only 2 sessions remain
   - VERIFY: List updates immediately

4. **Delete from Detail View**
   - Tap on remaining session to open detail
   - Tap delete icon in AppBar
   - VERIFY: Confirmation dialog appears
   - VERIFY: Dialog message: "Delete this session? This action cannot be undone."
   - Tap "Delete"
   - VERIFY: Navigate back to session list
   - VERIFY: SnackBar shows "Session deleted"
   - VERIFY: Only 1 session remains in list

## Test Session 3: Delete All Sessions

### Setup
- Create 2-3 new sessions

### Test Steps

1. **Delete All Sessions**
   - Open Session History screen
   - Tap menu button (three vertical dots) in top-right
   - VERIFY: Menu appears with "Delete All Sessions" option
   - Tap "Delete All Sessions"
   - VERIFY: Confirmation dialog appears
   - VERIFY: Dialog message: "Delete all workout sessions? This will permanently delete all your session history and cannot be undone."
   - VERIFY: Two buttons: "Cancel" and "Delete All"

2. **Cancel Delete All**
   - Tap "Cancel"
   - VERIFY: Dialog closes
   - VERIFY: All sessions remain in list

3. **Confirm Delete All**
   - Tap menu button again
   - Tap "Delete All Sessions"
   - Tap "Delete All"
   - VERIFY: Dialog closes
   - VERIFY: SnackBar shows "All sessions deleted"
   - VERIFY: Empty state appears:
     - History icon
     - Message: "No workout sessions yet. Start a session to see your history here."
   - VERIFY: No sessions visible in list

## Test Session 4: Retention Settings

### Test Steps

1. **Open Settings**
   - From main screen, tap hamburger menu
   - Tap "Settings"
   - VERIFY: Settings screen opens

2. **Locate Retention Setting**
   - Scroll to "Session Retention" section
   - VERIFY: Card with title "Session Retention"
   - VERIFY: Helper text: "Sessions older than this will be automatically deleted"
   - VERIFY: Text field with label "Session Retention (days)"
   - VERIFY: Default value is "30"

3. **Test Valid Values**
   - Clear the field and enter "60"
   - VERIFY: No error message
   - VERIFY: Value accepted
   - Navigate back to main screen
   - Return to Settings
   - VERIFY: Value persists as "60"

4. **Test Minimum Value**
   - Clear the field and enter "1"
   - VERIFY: No error message
   - VERIFY: Value accepted

5. **Test Maximum Value**
   - Clear the field and enter "3650"
   - VERIFY: No error message
   - VERIFY: Value accepted

6. **Test Invalid Values (Below Minimum)**
   - Clear the field and enter "0"
   - VERIFY: Error message appears
   - VERIFY: Error text indicates minimum is 1

7. **Test Invalid Values (Above Maximum)**
   - Clear the field and enter "3651"
   - VERIFY: Error message appears
   - VERIFY: Error text indicates maximum is 3650

8. **Test Non-Numeric Input**
   - Try to enter letters
   - VERIFY: Only numeric input accepted
   - VERIFY: Keyboard shows numeric layout

## Test Session 5: Auto-Deletion on Startup

### Setup
This test requires database manipulation, so it's primarily covered by automated tests.
For manual verification:

1. **Configure Short Retention**
   - Set retention to 1 day
   - Create a session
   - Wait 24+ hours
   - Restart app
   - VERIFY: Old session no longer in history

2. **Configure Long Retention**
   - Set retention to 30 days
   - Create sessions
   - Restart app
   - VERIFY: Sessions still present

## Test Session 6: Responsive Layout

### Portrait Mode

1. **Session List in Portrait**
   - Hold device in portrait orientation
   - Open Session History
   - VERIFY: List displays vertically
   - VERIFY: Each list item shows date, time, and duration
   - VERIFY: No horizontal scrolling needed

2. **Session Detail in Portrait**
   - Tap a session
   - VERIFY: Layout is vertical:
     - Heart rate graph at top
     - Statistics grid below
   - VERIFY: All content visible without scrolling (except graph scroll)
   - VERIFY: Navigation buttons accessible

### Landscape Mode

1. **Session List in Landscape**
   - Rotate device to landscape
   - VERIFY: List still displays correctly
   - VERIFY: More sessions visible at once

2. **Session Detail in Landscape**
   - Tap a session
   - VERIFY: Layout adapts:
     - Graph on left or full width
     - Statistics on right or below
   - VERIFY: All content visible
   - VERIFY: No overlap or cutoff

## Test Session 7: Edge Cases

### No Sessions
1. **Empty State**
   - Delete all sessions
   - Open Session History
   - VERIFY: Empty state displays
   - VERIFY: Icon and message clearly visible
   - VERIFY: Message is helpful

### Single Session
1. **Single Session Navigation**
   - Create one session
   - Open session detail
   - VERIFY: Both arrow buttons disabled
   - VERIFY: Delete button still works

### Session with No Readings
This scenario should not occur in normal usage but worth checking:
1. If database has session with no readings:
   - VERIFY: Detail screen handles gracefully
   - VERIFY: Graph shows empty or message
   - VERIFY: Statistics show 0 or N/A

### Very Long Session
1. **Long Duration Session**
   - Create session lasting 3+ hours
   - VERIFY: Duration displays correctly (HH:MM:SS)
   - VERIFY: Graph scales appropriately
   - VERIFY: All readings load

### Many Sessions (Performance)
1. **Large Dataset**
   - Create 20+ sessions
   - Open Session History
   - VERIFY: List loads quickly (< 2 seconds)
   - VERIFY: Smooth scrolling
   - VERIFY: No lag when tapping sessions

## Test Session 8: Theme and Styling

### Light Mode
1. **Visual Consistency**
   - Ensure app is in light mode
   - Open Session History
   - VERIFY: Colors match app theme
   - VERIFY: Text readable
   - VERIFY: Icons visible
   - Open session detail
   - VERIFY: Graph colors match theme
   - VERIFY: Statistics cards styled consistently

### Dark Mode
1. **Visual Consistency**
   - Enable dark mode in device settings
   - Open Session History
   - VERIFY: Dark theme applied
   - VERIFY: Colors match app dark theme
   - VERIFY: Text readable on dark background
   - VERIFY: Icons visible
   - Open session detail
   - VERIFY: Graph readable in dark mode
   - VERIFY: Statistics cards styled for dark mode

## Test Session 9: Data Privacy

### Local-Only Operations
1. **Network Monitoring** (if possible)
   - Enable network monitoring
   - Perform all session operations:
     - View sessions
     - Delete session
     - Delete all sessions
   - VERIFY: No network requests made
   - VERIFY: All data remains local

### Complete Deletion
1. **Database Verification**
   - Create session with many readings (50+)
   - Delete session
   - VERIFY: Session no longer appears anywhere
   - VERIFY: No way to recover deleted session
   - If database access available:
     - VERIFY: No orphaned heart rate readings

## Test Results Template

Use this template to record test results:

```
Test Session: [Number and Name]
Date: [Date]
Tester: [Name]
Device: [Device/Platform]
App Version: [Version]

Test Results:
- Test 1: [PASS/FAIL] - [Notes]
- Test 2: [PASS/FAIL] - [Notes]
- Test 3: [PASS/FAIL] - [Notes]
...

Issues Found:
1. [Description] - Severity: [High/Medium/Low]
2. [Description] - Severity: [High/Medium/Low]

Overall Assessment: [PASS/FAIL]
```

## Success Criteria

All tests should PASS with:
- No crashes or errors
- All UI elements displayed correctly
- All interactions work as expected
- Data persists correctly
- Deletions complete successfully
- Performance acceptable
- Responsive layout works in both orientations
- Theme styling consistent

Any failures should be documented and addressed before release.
