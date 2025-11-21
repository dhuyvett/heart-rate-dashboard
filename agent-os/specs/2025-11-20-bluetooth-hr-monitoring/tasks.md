# Task Breakdown: Bluetooth Heart Rate Monitoring with Real-Time Display

## Overview
Total Task Groups: 7
Estimated Implementation Time: 3-5 days
Complexity: High (foundational feature with BLE integration, state management, real-time data, and encryption)

## Strategic Implementation Order

This tasks list follows a bottom-up implementation approach:
1. **Foundation First**: Dependencies, project structure, database schema
2. **Data Layer**: Models, DAOs, encryption setup
3. **BLE Layer**: Device scanning, connection, data reading
4. **State Management**: Riverpod providers for BLE state and HR data streams
5. **UI Layer**: Screens and components
6. **Polish**: Demo mode, reconnection logic, error handling
7. **Testing**: Strategic test coverage for critical workflows

## Task List

### Task Group 1: Project Setup & Dependencies
**Dependencies:** None
**Complexity:** Small
**Estimated Time:** 30-60 minutes

- [x] 1.0 Set up project dependencies and architecture foundation
  - [x] 1.1 Add dependencies to pubspec.yaml
    - Add flutter_riverpod: ^2.4.0 (state management)
    - Add sqflite_sqlcipher: ^2.2.0 (encrypted database)
    - Add flutter_blue_plus: ^1.31.0 (Bluetooth Low Energy)
    - Add fl_chart: ^0.66.0 (line chart visualization)
    - Add shared_preferences: ^2.2.0 (settings persistence)
    - Add csv: ^6.0.0 (future export capability)
    - Add permission_handler: ^11.0.0 (permission management)
    - Run flutter pub get
  - [x] 1.2 Create project directory structure
    - Create lib/models/ (data models)
    - Create lib/providers/ (Riverpod providers)
    - Create lib/services/ (BLE, database services)
    - Create lib/screens/ (UI screens)
    - Create lib/widgets/ (reusable widgets)
    - Create lib/utils/ (helpers, constants)
  - [x] 1.3 Define constants and enums
    - Create lib/utils/constants.dart
    - Define BLE_HR_SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb"
    - Define BLE_HR_MEASUREMENT_UUID = "00002a37-0000-1000-8000-00805f9b34fb"
    - Define DEFAULT_AGE = 30
    - Define DEFAULT_CHART_WINDOW_SECONDS = 30
    - Define MAX_RECONNECTION_ATTEMPTS = 10
    - Define HR_SAMPLING_INTERVAL_MS = 1500
    - Create lib/models/heart_rate_zone.dart enum
    - Define zones: Resting, Zone1, Zone2, Zone3, Zone4, Zone5
    - Create lib/utils/theme_colors.dart
    - Define zone colors: blue, lightBlue, green, yellow, orange, red
  - [x] 1.4 Update main.dart to use Riverpod
    - Wrap MyApp with ProviderScope
    - Remove default counter app code
    - Set up MaterialApp with theme including zone colors
    - Configure initial route logic (device selection when no device connected)

**Acceptance Criteria:**
- All dependencies successfully installed (flutter pub get runs without errors)
- Project directory structure created with empty placeholder files
- Constants defined and accessible
- Main.dart compiles with ProviderScope wrapper
- flutter analyze passes with no errors

---

### Task Group 2: Database Layer & Models
**Dependencies:** Task Group 1 (COMPLETED)
**Complexity:** Medium
**Estimated Time:** 2-3 hours

- [x] 2.0 Implement encrypted database and data models
  - [x] 2.1 Write 2-8 focused tests for database layer
    - Limit to 2-8 highly focused tests maximum
    - Test only critical behaviors: database initialization, session creation, reading insertion, query by session
    - Skip exhaustive coverage of all methods and edge cases
    - Create test/services/database_service_test.dart
  - [x] 2.2 Create heart rate reading model
    - Create lib/models/heart_rate_reading.dart
    - Fields: id (int), sessionId (int), timestamp (DateTime), bpm (int)
    - Add toMap() and fromMap() methods for database serialization
    - Add validation: bpm must be 30-250 range
  - [x] 2.3 Create session model
    - Create lib/models/workout_session.dart
    - Fields: id (int), startTime (DateTime), endTime (DateTime?), deviceName (String), avgHr (int?), minHr (int?), maxHr (int?)
    - Add toMap() and fromMap() methods
    - Add calculateStatistics() method to compute avg/min/max from readings
    - Add getDuration() method returning Duration
  - [x] 2.4 Create database service with encryption
    - Create lib/services/database_service.dart
    - Implement singleton pattern
    - Use sqflite_sqlcipher for encryption (password: hardcoded for now, "hr_monitor_db_key")
    - Create database initialization with migrations support
    - Database file: workout_tracker.db in app documents directory
  - [x] 2.5 Define database schema
    - Create table: heart_rate_readings
      - Columns: id (INTEGER PRIMARY KEY), session_id (INTEGER), timestamp (INTEGER), bpm (INTEGER)
      - Index on session_id for fast querying
      - Index on timestamp for time-based queries
    - Create table: workout_sessions
      - Columns: id (INTEGER PRIMARY KEY), start_time (INTEGER), end_time (INTEGER), device_name (TEXT), avg_hr (INTEGER), min_hr (INTEGER), max_hr (INTEGER)
      - Index on start_time for chronological ordering
    - Create table: app_settings
      - Columns: key (TEXT PRIMARY KEY), value (TEXT)
      - Store: user_age, chart_window_seconds, last_connected_device_id
  - [x] 2.6 Implement database CRUD operations
    - createSession(deviceName): Create new session, return session ID
    - endSession(sessionId, avgHr, minHr, maxHr): Update session end time and stats
    - insertHeartRateReading(sessionId, timestamp, bpm): Insert reading
    - getReadingsBySession(sessionId): Return all readings for session
    - getReadingsBySessionAndTimeRange(sessionId, startTime, endTime): Return readings in time window
    - getCurrentSession(): Return most recent session without end_time
    - getSetting(key): Get setting value
    - setSetting(key, value): Store/update setting
  - [x] 2.7 Ensure database layer tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify database initializes with encryption
    - Verify sessions and readings can be created and retrieved
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- Database initializes successfully with encryption
- Models properly serialize to/from database format
- CRUD operations work correctly for sessions and readings
- Settings can be stored and retrieved
- Database file is encrypted and not readable without password

---

### Task Group 3: Heart Rate Zone Calculation Utilities
**Dependencies:** Task Group 1, Task Group 2
**Complexity:** Small
**Estimated Time:** 1 hour

- [x] 3.0 Implement heart rate zone calculation logic
  - [x] 3.1 Write 2-8 focused tests for zone calculation
    - Limit to 2-8 highly focused tests maximum
    - Test only critical calculations: max HR calculation, zone boundaries, color assignment
    - Skip exhaustive testing of all ages and BPM values
    - Create test/utils/heart_rate_zone_calculator_test.dart
  - [x] 3.2 Create heart rate zone calculator
    - Create lib/utils/heart_rate_zone_calculator.dart
    - Implement calculateMaxHeartRate(age): return 220 - age
    - Implement getZoneForBpm(bpm, age): return HeartRateZone enum
      - Below 50% max: Resting (blue)
      - 50-60% max: Zone1 (light blue)
      - 60-70% max: Zone2 (green)
      - 70-80% max: Zone3 (yellow)
      - 80-90% max: Zone4 (orange)
      - 90-100% max: Zone5 (red)
    - Implement getColorForZone(zone): return Color from theme
    - Implement getZoneRanges(age): return Map<HeartRateZone, (int, int)> with BPM ranges
    - Implement getZoneLabel(zone): return user-friendly string
  - [x] 3.3 Ensure zone calculation tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify calculations match Hopkins Medicine methodology
    - Verify correct zone assignment for edge cases (boundary values)
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- Max heart rate correctly calculated as 220 - age
- Zone boundaries correctly determined for various ages
- Correct colors returned for each zone
- Edge cases handled (e.g., HR above calculated max)

---

### Task Group 4: Bluetooth Service Layer
**Dependencies:** Task Group 1 (COMPLETED), Task Group 2 (COMPLETED)
**Complexity:** High
**Estimated Time:** 4-5 hours

- [x] 4.0 Implement BLE device discovery and connection
  - [x] 4.1 Write 2-8 focused tests for BLE service
    - Limit to 2-8 highly focused tests maximum
    - Test only critical behaviors: device scanning, connection state changes, HR data parsing
    - Use mocks for flutter_blue_plus to avoid requiring physical hardware
    - Skip exhaustive testing of all BLE scenarios
    - Create test/services/bluetooth_service_test.dart
  - [x] 4.2 Create Bluetooth service
    - Create lib/services/bluetooth_service.dart
    - Implement singleton pattern
    - Initialize FlutterBluePlus instance
    - Define ConnectionState enum: disconnected, connecting, connected, reconnecting
  - [x] 4.3 Implement device scanning
    - scanForDevices(): Start BLE scan for devices advertising HR service (0x180D)
    - Return Stream<List<BluetoothDevice>>
    - Filter devices to only show those with Heart Rate Service
    - Include signal strength (RSSI) with each device
    - Stop scan when user selects device
    - Handle "Bluetooth not available" error
    - Handle "Location permission required" error on Android
  - [x] 4.4 Implement device connection
    - connectToDevice(deviceId): Initiate connection to selected device
    - Set connection timeout: 15 seconds
    - Discover services after connection
    - Verify Heart Rate Service (0x180D) is present
    - Return success or throw specific error (timeout, service not found, etc.)
    - Save connected device ID to settings for reconnection
  - [x] 4.5 Implement heart rate data reading
    - subscribeToHeartRate(): Enable notifications on HR Measurement characteristic (0x2A37)
    - Return Stream<int> of BPM values
    - Parse BLE heart rate measurement format (handle both uint8 and uint16 formats)
    - Heart Rate Measurement format:
      - Byte 0: Flags (bit 0 = 0 for uint8, 1 for uint16)
      - Byte 1: HR value (uint8) OR Bytes 1-2: HR value (uint16 little-endian)
    - Handle parsing errors gracefully
  - [x] 4.6 Implement disconnection handling
    - disconnect(): Clean disconnect from device
    - Stop notifications
    - Close connection
    - Clear saved device if manual disconnect
    - monitorConnectionState(): Return Stream<ConnectionState>
  - [x] 4.7 Ensure BLE service tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify scanning returns mocked devices
    - Verify connection state changes are emitted
    - Verify HR data parsing handles both uint8 and uint16 formats
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- BLE scanning discovers devices with HR service
- Connection successfully established with timeout handling
- HR data stream provides real-time BPM values
- Connection state changes properly tracked
- Disconnection cleans up resources
- Errors are thrown with specific, actionable messages

---

### Task Group 5: State Management with Riverpod
**Dependencies:** Task Group 2 (COMPLETED), Task Group 3 (COMPLETED), Task Group 4 (COMPLETED)
**Complexity:** Medium
**Estimated Time:** 2-3 hours

- [x] 5.0 Create Riverpod providers for app state
  - [x] 5.1 Write 2-8 focused tests for providers
    - Limit to 2-8 highly focused tests maximum
    - Test only critical provider behaviors: state updates, stream emissions, settings persistence
    - Use ProviderContainer for testing
    - Skip exhaustive testing of all state combinations
    - Create test/providers/app_providers_test.dart
  - [x] 5.2 Create settings provider
    - Create lib/providers/settings_provider.dart
    - Implement NotifierProvider<SettingsNotifier, AppSettings>
    - AppSettings model: age (int), chartWindowSeconds (int)
    - Load settings from database on initialization
    - Persist settings changes immediately to database
    - Expose methods: updateAge(age), updateChartWindow(seconds)
  - [x] 5.3 Create Bluetooth state provider
    - Create lib/providers/bluetooth_provider.dart
    - Implement StreamProvider<BluetoothConnectionInfo>
    - Expose BluetoothService connection state stream
    - Track: current device name, connection state, error messages
  - [x] 5.4 Create heart rate data provider
    - Create lib/providers/heart_rate_provider.dart
    - Implement StreamProvider<HeartRateData> for real-time BPM stream
    - Expose BluetoothService heart rate stream
    - Transform stream to include zone calculation based on current age setting
  - [x] 5.5 Create session provider
    - Create lib/providers/session_provider.dart
    - Implement NotifierProvider<SessionNotifier, SessionState>
    - SessionState: currentSessionId, startTime, duration, avgHr, minHr, maxHr, readings count
    - Expose methods: startSession(deviceName), endSession()
    - Listen to HR stream and automatically insert readings to database
    - Calculate statistics in real-time from accumulated readings
  - [x] 5.6 Create device scanning provider
    - Create lib/providers/device_scan_provider.dart
    - Implement StreamProvider<List<ScannedDevice>>
    - Expose BluetoothService scan stream
    - ScannedDevice model: id, name, rssi, isDemo (bool)
    - Insert "Demo Mode" device as first item in list
  - [x] 5.7 Ensure provider tests pass
    - Run ONLY the 2-8 tests written in 5.1
    - Verify settings load and persist correctly
    - Verify HR stream provides BPM values with zone information
    - Verify session state updates when HR readings arrive
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 5.1 pass
- Settings provider loads from database and persists changes
- Bluetooth state provider accurately reflects connection state
- Heart rate provider streams real-time BPM with zone calculation
- Session provider automatically records data and calculates statistics
- Device scanning provider includes demo mode device

---

### Task Group 6: UI Screens & Components
**Dependencies:** Task Group 3 (COMPLETED), Task Group 5 (COMPLETED)
**Complexity:** High
**Estimated Time:** 5-6 hours

- [ ] 6.0 Build user interface screens
  - [ ] 6.1 Write 2-8 focused tests for UI components
    - Limit to 2-8 highly focused tests maximum
    - Test only critical UI behaviors: navigation flow, device selection, HR display updates
    - Use widget tests with mocked providers
    - Skip exhaustive testing of all UI states and interactions
    - Create test/screens/device_selection_screen_test.dart
    - Create test/screens/monitoring_screen_test.dart
  - [ ] 6.2 Create permission explanation screen
    - Create lib/screens/permission_explanation_screen.dart
    - Display simple explanation: "This app needs Bluetooth access to connect to your heart rate monitor"
    - On Android, also explain: "Location permission is required by Android for Bluetooth scanning"
    - "Grant Permission" button that triggers permission request
    - Use permission_handler package for permission request
    - Navigate to device selection on permission granted
    - Show error message with "Retry" button if permission denied
    - Check if permissions already granted on screen load, auto-navigate if yes
  - [ ] 6.3 Create device selection screen
    - Create lib/screens/device_selection_screen.dart
    - App bar title: "Select Heart Rate Monitor"
    - "Scan for Devices" button (prominent, primary color)
    - Show loading indicator with "Scanning..." text during scan
    - List of discovered devices:
      - Demo Mode device first (with distinctive icon, different color)
      - Real devices below with device name and signal strength bars
    - Tap device to connect (show loading overlay during connection)
    - Show "No devices found" message if scan returns empty list
    - Show Bluetooth disabled state with "Enable Bluetooth" button (opens system settings)
    - Use ConsumerWidget to access device_scan_provider
  - [ ] 6.4 Create main heart rate monitoring screen
    - Create lib/screens/heart_rate_monitoring_screen.dart
    - App bar:
      - Title: device name
      - Connection status indicator (dot icon: green=connected, yellow=reconnecting, red=disconnected)
      - Settings icon button (top-right)
    - Large BPM display (center, hero element):
      - Current BPM value (120sp font size, bold)
      - Color changes based on zone (use getColorForZone)
      - Animate color transitions smoothly (AnimatedDefaultTextStyle)
      - Show "---" when no data yet or disconnected
    - Zone label below BPM (e.g., "Zone 3 - Moderate")
    - Real-time line chart:
      - Use fl_chart LineChart widget
      - X-axis: time (last N seconds from settings)
      - Y-axis: BPM (30-200 range, dynamic scaling)
      - Line color matches current zone
      - Smooth scrolling as new data arrives
      - Show grid lines for readability
    - Session statistics panel (bottom):
      - Duration: HH:MM:SS format, updates every second
      - Average HR: calculated from all readings in session
      - Min HR: lowest BPM in session
      - Max HR: highest BPM in session
      - Display in card layout with icons
    - Use ConsumerWidget to access heart_rate_provider, session_provider, settings_provider
  - [ ] 6.5 Create settings screen
    - Create lib/screens/settings_screen.dart
    - App bar title: "Settings"
    - Age input field:
      - Label: "Your Age"
      - TextField with numeric keyboard
      - Validation: 10-100 range
      - Show calculated max heart rate below (220 - age)
    - Chart time window slider:
      - Label: "Chart Time Window"
      - Options: 15s, 30s, 45s, 60s (discrete values)
      - Show selected value
    - Heart rate zones information panel:
      - Display calculated zone ranges based on current age
      - Show each zone with color indicator and BPM range
      - Format: "Zone 1 (50-60%): 95-114 BPM" with colored circle
    - Use ConsumerWidget to access and update settings_provider
    - All changes save immediately (no save button needed)
  - [ ] 6.6 Create reusable widgets
    - Create lib/widgets/connection_status_indicator.dart
      - Circle dot with color based on connection state
      - Animated pulsing effect when reconnecting
    - Create lib/widgets/heart_rate_chart.dart
      - Encapsulate fl_chart LineChart configuration
      - Props: readings (List<HeartRateReading>), windowSeconds, currentZoneColor
      - Handle empty data state gracefully
    - Create lib/widgets/session_stats_card.dart
      - Display single statistic with icon, label, and value
      - Reusable for duration, avg/min/max HR
    - Create lib/widgets/device_list_tile.dart
      - Display device name, RSSI signal strength bars
      - Different styling for demo mode device
  - [ ] 6.7 Implement navigation flow
    - Update main.dart to handle initial routing:
      - Check if Bluetooth permissions granted
      - If not: show permission explanation screen
      - If yes but no saved device: show device selection screen
      - If yes with saved device: attempt auto-connect, show monitoring screen
    - Navigation between screens:
      - Permission -> Device Selection -> Monitoring
      - Monitoring -> Settings (and back)
      - Monitoring -> Device Selection (on disconnect/connection failure)
    - Use Navigator.pushReplacement for screen transitions (no back stack)
  - [ ] 6.8 Ensure UI tests pass
    - Run ONLY the 2-8 tests written in 6.1
    - Verify device selection screen shows devices
    - Verify monitoring screen displays BPM and updates chart
    - Verify navigation flow works correctly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 6.1 pass
- Permission explanation screen explains clearly and requests permissions
- Device selection screen lists devices and initiates connection
- Monitoring screen displays large, color-coded BPM value
- Line chart updates in real-time with correct time window
- Session statistics update continuously
- Settings screen allows age and chart window configuration
- Zone ranges display correctly based on age
- Navigation flow works smoothly between screens
- UI follows Material Design guidelines

---

### Task Group 7: Demo Mode, Reconnection, and Error Handling
**Dependencies:** Task Group 4 (COMPLETED), Task Group 5 (COMPLETED), Task Group 6
**Complexity:** Medium
**Estimated Time:** 3-4 hours

- [ ] 7.0 Implement demo mode, auto-reconnection, and error handling
  - [ ] 7.1 Write 2-8 focused tests for demo mode and reconnection
    - Limit to 2-8 highly focused tests maximum
    - Test only critical behaviors: demo data generation, reconnection attempts, error message display
    - Skip exhaustive testing of all error scenarios
    - Create test/services/demo_mode_service_test.dart
    - Create test/services/reconnection_handler_test.dart
  - [ ] 7.2 Create demo mode service
    - Create lib/services/demo_mode_service.dart
    - Implement singleton pattern
    - startDemoMode(): Begin generating simulated HR data
    - Generate realistic BPM values:
      - Base range: 60-180 BPM
      - Natural variability: ±2-5 BPM per sample
      - Gradual trends: increase/decrease over 30-60 second periods
      - Use sine wave with noise for realistic patterns
    - Emit values at 1.5 second intervals (matching real device sampling rate)
    - getDemoModeStream(): Return Stream<int> of simulated BPM values
    - stopDemoMode(): Clean up stream
    - Demo mode behaves identically to real device from UI perspective
  - [ ] 7.3 Integrate demo mode into device scanning
    - Update BluetoothService to include createDemoModeDevice()
    - Add "Demo Mode" as first item in scanned device list
    - Set device ID: "DEMO_MODE_DEVICE"
    - Set device name: "Demo Mode"
    - Give demo device 5-bar signal strength (always "excellent")
    - When demo device selected, use DemoModeService instead of BLE
  - [ ] 7.4 Implement auto-reconnection logic
    - Create lib/services/reconnection_handler.dart
    - Monitor BluetoothService connection state
    - On unexpected disconnect (not manual):
      - Save current session ID to resume recording
      - Start reconnection attempts immediately
      - Display "Reconnecting... (attempt X of 10)" message
    - Retry logic:
      - Attempt 1-3: 2s, 4s, 8s delays (exponential backoff)
      - Attempt 4+: 30s delays
      - Maximum 10 attempts total
    - On successful reconnection:
      - Resume recording to same session
      - Update UI to show "Connected" state
    - On failure after 10 attempts:
      - Show dialog: "Connection Failed" with message
      - Two action buttons: "Retry" (restart 10 attempts), "Select Device" (end session, navigate to device selection)
    - During reconnection, show last received BPM value in gray/dimmed style
  - [ ] 7.5 Implement comprehensive error handling
    - Create lib/utils/error_messages.dart with user-friendly messages:
      - Bluetooth disabled: "Bluetooth is turned off. Please enable it in your device settings."
      - Permission denied: "Bluetooth permission is required to connect to heart rate monitors."
      - No devices found: "No heart rate monitors found. Make sure your device is turned on and in range."
      - Connection timeout: "Could not connect to [Device Name]. Make sure it's turned on and nearby."
      - Service not found: "This device doesn't support heart rate monitoring."
      - Generic error: "Something went wrong. Please try again."
    - Create lib/widgets/error_dialog.dart
      - Reusable error dialog with message and action buttons
      - Props: title, message, actions (list of buttons)
    - Add error handling in BluetoothService:
      - Catch and wrap all BLE exceptions
      - Throw custom exceptions with user-friendly messages
    - Add error handling in providers:
      - Catch service exceptions
      - Update state with error information
      - UI displays errors using error_dialog widget
  - [ ] 7.6 Add loading and empty states
    - Create lib/widgets/loading_overlay.dart
      - Full-screen semi-transparent overlay with spinner
      - Show during connection attempts
    - Update device selection screen:
      - Show loading state during scan
      - Show empty state with message when no devices found
      - Show loading overlay during connection
    - Update monitoring screen:
      - Show "Waiting for data..." when connected but no HR readings yet
      - Show "Reconnecting..." overlay with attempt count during reconnection
      - Dim/gray out BPM display when reconnecting
  - [ ] 7.7 Ensure demo mode and reconnection tests pass
    - Run ONLY the 2-8 tests written in 7.1
    - Verify demo mode generates realistic data
    - Verify reconnection attempts follow correct timing
    - Verify error messages are user-friendly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 7.1 pass
- Demo Mode device appears in device list and generates realistic HR data
- Auto-reconnection attempts up to 10 times with correct delays
- Reconnection UI shows attempt count and last known BPM
- After 10 failed attempts, dialog offers Retry or Select Device
- All error messages are user-friendly and actionable
- Loading states show during async operations
- Empty states guide users when no data available

---

### Task Group 8: Integration Testing & Polish
**Dependencies:** All previous task groups
**Complexity:** Medium
**Estimated Time:** 2-3 hours

- [ ] 8.0 End-to-end testing and final polish
  - [ ] 8.1 Review tests from Task Groups 2-7
    - Review the 2-8 tests written by each task group
    - Estimated total existing tests: 12-48 tests
    - Verify all tests pass
  - [ ] 8.2 Analyze test coverage gaps for THIS feature only
    - Identify critical user workflows that lack test coverage
    - Focus ONLY on gaps related to this spec's feature requirements
    - Do NOT assess entire application test coverage
    - Prioritize end-to-end workflows over unit test gaps
    - Key workflows to verify:
      - Permission request -> Device scan -> Connection -> HR monitoring flow
      - Settings changes immediately affect zone calculation and display
      - Session recording captures data continuously
      - Demo mode functions identically to real device
      - Reconnection logic handles disconnects gracefully
  - [ ] 8.3 Write up to 10 additional strategic tests maximum
    - Add maximum of 10 new tests to fill identified critical gaps
    - Focus on integration points and end-to-end workflows
    - Create test/integration/complete_workflow_test.dart
    - Do NOT write comprehensive coverage for all scenarios
    - Skip performance tests and accessibility tests unless business-critical
    - Example critical tests:
      - Full flow: scan -> connect -> receive data -> display updates
      - Settings change updates zone colors immediately
      - Session statistics calculate correctly from readings
      - Reconnection resumes same session successfully
      - Demo mode data flows through same pipeline as real device
  - [ ] 8.4 Perform manual testing checklist
    - Install on physical Android device
    - Grant Bluetooth and location permissions
    - Scan for devices (verify real HR monitor appears if available)
    - Connect to Demo Mode device
    - Verify large BPM display updates every 1-2 seconds
    - Verify color changes as simulated HR moves through zones
    - Verify chart scrolls smoothly showing last 30 seconds
    - Verify session statistics update in real-time
    - Change age in settings, verify zone colors update immediately
    - Change chart window, verify chart adjusts time range
    - Force disconnect (turn off device or go out of range)
    - Verify reconnection attempts display correctly
    - Let reconnection fail, verify dialog appears with options
    - Test on iOS device (if available)
    - Test on different screen sizes (phone, tablet)
  - [ ] 8.5 Polish UI details
    - Ensure all text is readable and properly sized
    - Verify color contrast ratios meet accessibility standards (WCAG AA)
    - Add smooth animations for BPM value changes (AnimatedSwitcher)
    - Add smooth color transitions for zone changes (AnimatedContainer)
    - Ensure chart renders smoothly without jank
    - Add haptic feedback (optional) for connection events
    - Verify responsive layout on different screen sizes
    - Test landscape orientation
  - [ ] 8.6 Run feature-specific tests only
    - Run ONLY tests related to this spec's feature
    - Expected total: approximately 22-58 tests maximum
    - Do NOT run the entire application test suite (there isn't one yet)
    - Verify critical workflows pass
    - Run flutter analyze to check for linting issues
    - Fix any linting warnings or errors
  - [ ] 8.7 Create basic usage documentation
    - Update README.md with feature overview
    - Document how to use demo mode for testing
    - Document required permissions (Bluetooth, Location on Android)
    - List supported platforms (Android, iOS minimum; others untested)
    - Note database encryption is enabled
    - Document dependencies added

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 22-58 tests total)
- Critical user workflows for this feature are covered
- No more than 10 additional tests added when filling in testing gaps
- Manual testing checklist completed successfully on at least one physical device
- UI is polished with smooth animations and transitions
- flutter analyze passes with no errors or warnings
- README.md documents the feature and usage instructions
- Feature is ready for real-world use

---

## Execution Notes

### Testing Strategy
This feature follows a focused, incremental testing approach:
- Each implementation task group (2-7) writes 2-8 focused tests covering critical behaviors only
- Tests run only for that specific task group, not the entire suite
- Final integration testing phase (Task Group 8) reviews existing tests and adds up to 10 additional strategic tests to fill critical gaps
- Total expected tests: approximately 22-58 tests maximum
- Focus on testing behavior and critical workflows, not implementation details

### Dependencies Management
- Task Groups 2-4 can be worked on in parallel after Task Group 1 completes
- Task Group 5 requires completion of Task Groups 2, 3, and 4
- Task Group 6 requires completion of Task Groups 3 and 5
- Task Group 7 requires completion of Task Groups 4, 5, and 6
- Task Group 8 requires completion of all previous task groups

### Development Tips
- Use hot reload extensively during UI development for rapid iteration
- Test with Demo Mode first before requiring physical BLE device
- Use flutter_blue_plus example app as reference for BLE implementation patterns
- Use fl_chart example app as reference for chart customization
- Keep database service as singleton to avoid multiple database instances
- Use Riverpod's ProviderObserver for debugging state changes during development
- Test on physical device early and often (BLE doesn't work in emulators)
- Consider using flutter_logs or similar for debugging BLE issues

### Platform-Specific Considerations
- **Android**: Location permission required for BLE scanning (OS requirement)
- **iOS**: Bluetooth permission required, add usage description to Info.plist
- **Web/Desktop**: BLE support limited or unavailable, focus on mobile platforms
- Test demo mode on all platforms, real BLE connection on mobile only

### Performance Considerations
- Database writes every 1-2 seconds: ensure writes are async and non-blocking
- Chart rendering: limit data points displayed to avoid performance issues
- BLE stream: ensure proper stream subscription cleanup to avoid memory leaks
- Riverpod providers: use .autoDispose where appropriate to clean up resources

### Future Enhancements (Out of Scope)
- Historical session browsing UI
- Session export to CSV
- Custom heart rate zones (not age-based)
- Multiple device connections
- Advanced analytics (HRV, VO2 max)
- Workout planning and goal setting
- Audio/haptic feedback for zone changes
- Cloud backup and sync
