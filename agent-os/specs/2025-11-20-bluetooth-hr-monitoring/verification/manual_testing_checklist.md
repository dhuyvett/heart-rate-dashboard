# Manual Testing Checklist

## Bluetooth Heart Rate Monitoring Feature

This checklist should be completed on physical devices to verify the feature works correctly in real-world conditions.

---

## Prerequisites

- [ ] Physical Android or iOS device
- [ ] Bluetooth heart rate monitor (optional, demo mode can be used)
- [ ] App installed on device
- [ ] Device Bluetooth enabled

---

## 1. Permission Flow

### Android

- [ ] On first launch, permission explanation screen appears
- [ ] Screen explains why Bluetooth permission is needed
- [ ] Screen explains why Location permission is needed (Android requirement)
- [ ] "Grant Permission" button is visible and tappable
- [ ] Tapping "Grant Permission" shows system permission dialogs
- [ ] After granting all permissions, navigates to device selection screen
- [ ] If permission denied, error message appears with "Retry" button
- [ ] Retry button re-requests permissions

### iOS

- [ ] On first launch, permission explanation screen appears
- [ ] Screen explains why Bluetooth permission is needed
- [ ] "Grant Permission" button shows system permission dialog
- [ ] After granting permission, navigates to device selection screen

---

## 2. Device Selection Screen

### Basic UI

- [ ] App bar shows "Select Heart Rate Monitor"
- [ ] "Scan for Devices" button is prominent and visible
- [ ] Demo Mode device appears as first item in list
- [ ] Demo Mode has distinctive icon (brain/psychology icon)
- [ ] Demo Mode shows excellent signal strength

### Scanning

- [ ] Tapping "Scan for Devices" shows loading indicator
- [ ] Button text changes to "Scanning..."
- [ ] After scan completes (5 seconds), loading indicator disappears
- [ ] Real BLE heart rate monitors appear in list (if available)
- [ ] Each device shows name and signal strength indicator
- [ ] "No heart rate monitors found" message shows if no devices

### Connection

- [ ] Tapping Demo Mode device shows connection loading overlay
- [ ] Connection message shows "Connecting... To Demo Mode"
- [ ] After successful connection, navigates to monitoring screen
- [ ] If connection fails, error message appears with context
- [ ] Error message provides actionable guidance

---

## 3. Heart Rate Monitoring Screen (Demo Mode)

### App Bar

- [ ] Device name "Demo Mode" shown in app bar
- [ ] Connection status indicator shows green dot (connected)
- [ ] Settings icon button visible in top right

### Large BPM Display

- [ ] Current BPM displayed in large font (readable from distance)
- [ ] BPM value updates every 1-2 seconds
- [ ] BPM color changes based on heart rate zone
- [ ] Zone label displayed below BPM (e.g., "Zone 2 - Light")
- [ ] Color transitions are smooth (not jarring)

### Zone Color Verification

- [ ] Blue/light blue appears for lower heart rates (resting/zone 1)
- [ ] Green appears for moderate heart rates (zone 2)
- [ ] Yellow appears for elevated heart rates (zone 3)
- [ ] Orange appears for high heart rates (zone 4)
- [ ] Red appears for maximum heart rates (zone 5)

### Heart Rate Chart

- [ ] Line chart displays below BPM value
- [ ] Chart shows last 30 seconds of data (default)
- [ ] Chart scrolls smoothly as new data arrives
- [ ] Line color matches current zone color
- [ ] Y-axis shows BPM values
- [ ] X-axis shows time labels (0s, 7s, 15s, 22s, 30s approximately)
- [ ] Chart area fills with gradient under line
- [ ] No visible jank or stuttering during updates

### Session Statistics

- [ ] "Session Statistics" section visible
- [ ] Duration displays in HH:MM:SS format
- [ ] Duration updates every second
- [ ] Average HR displays and updates as readings accumulate
- [ ] Minimum HR displays correctly
- [ ] Maximum HR displays correctly
- [ ] All statistics have appropriate icons
- [ ] Cards are arranged in 2x2 grid

---

## 4. Settings Screen

### Navigation

- [ ] Tapping settings icon opens Settings screen
- [ ] Settings screen has back navigation
- [ ] Returning to monitoring screen maintains session

### Age Setting

- [ ] "Your Age" section visible
- [ ] Age input field shows current age (default: 30)
- [ ] Age input accepts only numbers
- [ ] Invalid age shows error message
- [ ] Calculated Max HR updates when age changes
- [ ] Info box shows "Maximum Heart Rate: XXX BPM"

### Chart Window Setting

- [ ] "Chart Time Window" section visible
- [ ] Chips for 15s, 30s, 45s, 60s options
- [ ] Current selection is highlighted
- [ ] Tapping different option changes selection immediately
- [ ] Setting persists after leaving and returning

### Zone Display

- [ ] "Heart Rate Zones" section visible
- [ ] All 6 zones displayed (Resting + Zones 1-5)
- [ ] Each zone shows colored circle
- [ ] Each zone shows percentage range
- [ ] Each zone shows calculated BPM range
- [ ] Changing age updates all zone BPM ranges immediately

---

## 5. Settings Change Verification

- [ ] Change age from 30 to 40 in settings
- [ ] Return to monitoring screen
- [ ] Verify zone colors change appropriately for new age
- [ ] Same BPM that was Zone 3 for age 30 may be Zone 4 for age 40
- [ ] Change chart window to 60s
- [ ] Verify chart now shows 60 seconds of history
- [ ] Change chart window to 15s
- [ ] Verify chart now shows 15 seconds of history

---

## 6. Reconnection Logic (Simulated)

> Note: Demo mode does not disconnect, so these tests require a real device or manual simulation

### Reconnection Display

- [ ] During reconnection, status indicator turns yellow
- [ ] Status indicator pulses/animates
- [ ] "Reconnecting..." message appears
- [ ] Last known BPM shown in dimmed/gray style
- [ ] Attempt counter shown (e.g., "Attempt 3 of 10")

### Reconnection Success

- [ ] After successful reconnection, status returns to green
- [ ] BPM display returns to normal color
- [ ] Session continues (duration keeps counting)
- [ ] Statistics maintain previous values

### Reconnection Failure

- [ ] After 10 failed attempts, dialog appears
- [ ] Dialog shows "Connection Failed" message
- [ ] "Retry" button restarts reconnection attempts
- [ ] "Select Device" button ends session and returns to device selection

---

## 7. Responsive Layout Testing

### Portrait Orientation

- [ ] All elements fit on screen without overflow
- [ ] BPM display centered and readable
- [ ] Chart takes appropriate space
- [ ] Statistics cards fit in 2x2 grid
- [ ] Scrolling works if content exceeds screen

### Landscape Orientation

- [ ] Screen rotates correctly
- [ ] Content adapts to wider aspect ratio
- [ ] BPM still readable (may be slightly smaller)
- [ ] Chart widens appropriately
- [ ] No layout overflow or clipping

### Different Screen Sizes

- [ ] Test on small phone (if available)
- [ ] Test on large phone (if available)
- [ ] Test on tablet (if available)
- [ ] All text remains readable
- [ ] Touch targets remain accessible

---

## 8. Accessibility Checks

### Color Contrast

- [ ] White/light text readable on colored backgrounds
- [ ] Dark text readable on light backgrounds
- [ ] Zone colors distinguishable from each other
- [ ] Error states clearly indicated

### Touch Targets

- [ ] All buttons large enough to tap easily (min 48x48dp)
- [ ] Sufficient spacing between touch targets
- [ ] No accidental taps on adjacent elements

### Font Sizes

- [ ] BPM value easily readable from arm's length
- [ ] Statistics values readable without straining
- [ ] Labels readable but appropriately smaller
- [ ] No text truncation or overlap

---

## 9. Error Handling

### Bluetooth Disabled

- [ ] If Bluetooth disabled, appropriate message shown
- [ ] Message suggests enabling Bluetooth
- [ ] "Enable Bluetooth" or similar action provided

### Permission Denied

- [ ] If permission denied, helpful message shown
- [ ] Retry option available
- [ ] Explains why permission is needed

### No Devices Found

- [ ] After scan with no devices, message shown
- [ ] Suggests troubleshooting steps
- [ ] "Scan Again" button available

---

## 10. Real Device Testing (Optional)

> Only complete if physical heart rate monitor available

- [ ] Real BLE heart rate monitor discovered in scan
- [ ] Device name displayed correctly
- [ ] Signal strength indicator reflects proximity
- [ ] Connection to real device successful
- [ ] Real heart rate data displayed
- [ ] Data matches actual heart rate (approximately)
- [ ] Session records data continuously
- [ ] All features work identically to Demo Mode

---

## Test Completion

**Tester Name:** ___________________________

**Date:** ___________________________

**Device Model:** ___________________________

**OS Version:** ___________________________

**App Version:** 1.0.0+1

**Overall Result:** [ ] PASS / [ ] FAIL

**Notes/Issues Found:**

```
(Record any issues, bugs, or observations here)
```
