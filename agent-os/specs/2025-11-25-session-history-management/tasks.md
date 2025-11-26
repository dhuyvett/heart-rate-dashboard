# Task Breakdown: Session History Management

## Overview
Total Tasks: 40 sub-tasks across 5 major task groups

## Task List

### Database Layer

#### Task Group 1: Database Query Methods and Retention Logic
**Dependencies:** None

- [x] 1.0 Complete database layer enhancements
  - [x] 1.1 Write 2-8 focused tests for new database query methods
    - Limit to 2-8 highly focused tests maximum
    - Test only critical database operations (e.g., getAllCompletedSessions returns correct sessions, deleteSession removes session and readings, retention calculation)
    - Skip exhaustive coverage of all edge cases
  - [x] 1.2 Add getAllCompletedSessions() method to DatabaseService
    - Query workout_sessions where end_time IS NOT NULL
    - Sort by start_time DESC (newest first)
    - Return List<WorkoutSession>
    - Reuse pattern from existing getSessionById method
  - [x] 1.3 Add deleteSession(int sessionId) method to DatabaseService
    - Use database transaction for consistency
    - Delete all heart_rate_readings with matching session_id
    - Delete workout_session record
    - Follow pattern from existing database transaction methods
  - [x] 1.4 Add deleteAllSessions() method to DatabaseService
    - Use database transaction
    - Delete all records from heart_rate_readings table
    - Delete all records from workout_sessions table
    - Ensure atomic operation
  - [x] 1.5 Add getSessionsOlderThan(DateTime cutoffDate) method to DatabaseService
    - Query workout_sessions where end_time < cutoff timestamp
    - Convert DateTime to Unix milliseconds for comparison
    - Return List<WorkoutSession>
    - Used for auto-deletion feature
  - [x] 1.6 Add getPreviousSession(int currentSessionId) method to DatabaseService
    - Query for session with start_time less than current session's start_time
    - Order by start_time DESC, limit 1
    - Return WorkoutSession? (nullable)
  - [x] 1.7 Add getNextSession(int currentSessionId) method to DatabaseService
    - Query for session with start_time greater than current session's start_time
    - Order by start_time ASC, limit 1
    - Return WorkoutSession? (nullable)
  - [x] 1.8 Ensure database layer tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify queries return correct data
    - Verify deletions work correctly
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- All new query methods return correct data
- Deletion methods properly cascade to related records
- Transaction handling ensures data consistency

### Settings & Auto-Deletion

#### Task Group 2: Retention Settings and Auto-Deletion Implementation
**Dependencies:** Task Group 1

- [x] 2.0 Complete retention settings and auto-deletion
  - [x] 2.1 Write 2-8 focused tests for retention settings and auto-deletion
    - Limit to 2-8 highly focused tests maximum
    - Test only critical behaviors (e.g., retention setting saves/loads correctly, auto-deletion removes old sessions, validation catches invalid input)
    - Skip exhaustive testing of all validation scenarios
  - [x] 2.2 Add sessionRetentionDays field to AppSettings model
    - Add field with default value of 30
    - Update toMap/fromMap serialization methods
    - Follow pattern from existing AppSettings fields
  - [x] 2.3 Add retention days setting to SettingsScreen
    - Add Card widget in settings screen body
    - Create TextField with numeric keyboard (keyboardType: TextInputType.number)
    - Add label "Session Retention (days)"
    - Add helper text: "Sessions older than this will be automatically deleted"
    - Implement validation: 1-3650 days range
    - Show error message for invalid values
    - Follow pattern from existing age field in SettingsScreen
  - [x] 2.4 Update SettingsNotifier to handle retention setting
    - Load retention days from database on initialization
    - Implement saveRetentionDays method
    - Store value using DatabaseService.setSetting with key "session_retention_days"
    - Update AppSettings state when value changes
  - [x] 2.5 Implement auto-deletion check in InitialRouteResolver
    - Add cleanup method in _InitialRouteResolverState.initState
    - Load retention days from SettingsNotifier
    - Calculate cutoff date: DateTime.now().subtract(Duration(days: retentionDays))
    - Call DatabaseService.getSessionsOlderThan to find expired sessions
    - Delete each expired session using DatabaseService.deleteSession
    - Perform cleanup silently (no user confirmation or notification)
    - Ensure cleanup completes before navigation proceeds
  - [x] 2.6 Ensure settings and auto-deletion tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify retention setting saves and loads correctly
    - Verify auto-deletion removes correct sessions
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- Retention setting accepts valid input (1-3650 days)
- Retention setting rejects invalid input with clear error message
- Auto-deletion runs on app startup
- Sessions older than retention period are deleted automatically

### Session History List Screen

#### Task Group 3: Session List View and Navigation
**Dependencies:** Task Group 1, Task Group 2

- [x] 3.0 Complete session history list screen
  - [x] 3.1 Write 2-8 focused tests for session history list screen
    - Limit to 2-8 highly focused tests maximum
    - Test only critical UI behaviors (e.g., list renders sessions, empty state displays, navigation to detail works, delete confirmation shown)
    - Skip exhaustive testing of all UI states and interactions
  - [x] 3.2 Create SessionHistoryScreen stateful widget
    - Create new file: lib/screens/session_history_screen.dart
    - Use ConsumerStatefulWidget to access Riverpod providers
    - Add AppBar with title "Session History" and back button
    - Follow pattern from existing screens (SettingsScreen, AboutScreen)
  - [x] 3.3 Create session list provider using Riverpod
    - Create sessionHistoryProvider in lib/providers/session_history_provider.dart
    - Use StateNotifierProvider pattern
    - Load sessions from DatabaseService.getAllCompletedSessions
    - Expose methods: loadSessions, deleteSession, deleteAllSessions
    - Follow pattern from existing providers (settingsProvider, sessionProvider)
  - [x] 3.4 Implement session list ListView.builder
    - Load sessions using ref.watch(sessionHistoryProvider)
    - Use ListView.builder for efficient rendering
    - Create ListTile for each session
    - Format date/time: "MMM dd, yyyy h:mm a" (e.g., "Nov 25, 2025 2:30 PM")
    - Display session duration as subtitle
    - Make tiles tappable to navigate to detail view
    - Add dividers between list items
  - [x] 3.5 Implement empty state view
    - Check if session list is empty
    - Display centered message: "No workout sessions yet. Start a session to see your history here."
    - Use Icon and Text widgets with appropriate styling
    - Follow Material Design empty state patterns
  - [x] 3.6 Implement swipe-to-delete with Dismissible widget
    - Wrap each ListTile with Dismissible widget
    - Use unique key for each session (Key(session.id.toString()))
    - Set background to red with delete icon
    - On dismiss, show confirmation dialog
    - Dialog message: "Delete this session? This action cannot be undone."
    - On confirmation, call sessionHistoryProvider.deleteSession
    - Show SnackBar: "Session deleted"
    - Update list automatically (reactive state management)
  - [x] 3.7 Add "Delete All Sessions" action to AppBar
    - Add actions property to AppBar
    - Create PopupMenuButton with "Delete All Sessions" option
    - On selection, show confirmation dialog
    - Dialog message: "Delete all workout sessions? This will permanently delete all your session history and cannot be undone."
    - Provide "Cancel" and "Delete All" buttons
    - On confirmation, call sessionHistoryProvider.deleteAllSessions
    - Show SnackBar: "All sessions deleted"
    - Navigate back or update to show empty state
  - [x] 3.8 Add "Session History" menu item to HeartRateMonitoringScreen
    - Open lib/screens/heart_rate_monitoring_screen.dart
    - Locate existing PopupMenuButton in AppBar
    - Add "Session History" menu item
    - Navigate to SessionHistoryScreen using MaterialPageRoute
    - Follow pattern from existing menu items (Settings, About)
  - [x] 3.9 Ensure session history list tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify list renders and navigates correctly
    - Verify deletion features work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- Session history list displays all completed sessions
- Sessions are sorted newest first
- Empty state shows helpful message
- Swipe-to-delete works with confirmation
- Delete all sessions works with confirmation
- Navigation from hamburger menu works

### Session Detail Screen

#### Task Group 4: Session Detail View with Navigation
**Dependencies:** Task Group 1, Task Group 3

- [x] 4.0 Complete session detail screen
  - [x] 4.1 Write 2-8 focused tests for session detail screen
    - Limit to 2-8 highly focused tests maximum
    - Test only critical component behaviors (e.g., detail screen renders session data, graph displays readings, next/previous navigation works, delete button functions)
    - Skip exhaustive testing of all component states
  - [x] 4.2 Create SessionDetailScreen stateful widget
    - Create new file: lib/screens/session_detail_screen.dart
    - Use ConsumerStatefulWidget pattern
    - Accept WorkoutSession as constructor parameter
    - Add AppBar with device name as title and back button
    - Follow HeartRateMonitoringScreen layout structure
  - [x] 4.3 Load heart rate readings for session
    - Use DatabaseService.getReadingsBySession to load all readings
    - Store readings in state
    - Handle loading state with CircularProgressIndicator
    - Handle error state with error message
  - [x] 4.4 Implement responsive layout (portrait and landscape)
    - Use OrientationBuilder or LayoutBuilder
    - Portrait: Vertical stacking (chart at top, stats below)
    - Landscape: Side-by-side layout (chart on left, stats on right)
    - Follow HeartRateMonitoringScreen layout pattern exactly
    - Reuse layout calculations and threshold constants
  - [x] 4.5 Display session heart rate graph
    - Reuse HeartRateChart widget
    - Pass all session readings (not just recent readings)
    - Configure time range to span entire session duration
    - Time range: session.start_time to session.end_time
    - Maintain same visual styling with heart rate zone colors
    - Do NOT display current/live BPM value (historical view only)
  - [x] 4.6 Display session statistics using SessionStatsCard
    - Reuse SessionStatsCard widget from HeartRateMonitoringScreen
    - Display: Duration, Average HR, Minimum HR, Maximum HR
    - Use session.avgHr, session.minHr, session.maxHr
    - Use session.getDuration() for duration
    - Use same grid layout as monitoring screen
    - Follow responsive layout pattern (grid vs compact row)
  - [x] 4.7 Add delete button to AppBar
    - Add IconButton with delete icon to AppBar actions
    - On tap, show confirmation dialog
    - Dialog message: "Delete this session? This action cannot be undone."
    - On confirmation, delete session using DatabaseService.deleteSession
    - Navigate back to SessionHistoryScreen after deletion
    - Show SnackBar: "Session deleted"
  - [x] 4.8 Implement next/previous session navigation
    - Add left and right arrow IconButtons to AppBar or as floating buttons
    - Use DatabaseService.getPreviousSession and getNextSession
    - Disable previous button if no previous session exists
    - Disable next button if no next session exists
    - On button press, load new session data and update UI
    - Update all displayed data (readings, stats, graph) without popping navigation
    - Maintain navigation state using setState
  - [x] 4.9 Handle edge cases for session detail
    - Handle session with no heart rate readings (show message)
    - Handle incomplete session statistics (show N/A or 0)
    - Handle navigation when only one session exists (disable both buttons)
    - Ensure proper error handling throughout
  - [x] 4.10 Ensure session detail tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify detail screen renders correctly
    - Verify navigation and deletion work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- Session detail screen resembles HeartRateMonitoringScreen layout
- Heart rate graph displays complete session data
- Session statistics display correctly
- Next/previous navigation works without returning to list
- Delete button works with confirmation
- Responsive layout works in portrait and landscape

### Testing & Integration

#### Task Group 5: Test Review, Gap Analysis & Integration Verification
**Dependencies:** Task Groups 1-4

- [x] 5.0 Review existing tests and fill critical gaps only
  - [x] 5.1 Review tests from Task Groups 1-4
    - Review the 2-8 tests written by database engineer (Task 1.1)
    - Review the 2-8 tests written by settings engineer (Task 2.1)
    - Review the 2-8 tests written by UI engineer for list screen (Task 3.1)
    - Review the 2-8 tests written by UI engineer for detail screen (Task 4.1)
    - Total existing tests: approximately 8-32 tests
  - [x] 5.2 Analyze test coverage gaps for Session History Management feature only
    - Identify critical user workflows that lack test coverage
    - Focus ONLY on gaps related to this feature's requirements
    - Do NOT assess entire application test coverage
    - Prioritize end-to-end workflows over unit test gaps
    - Key workflows to consider:
      - Complete flow: View list -> Tap session -> View detail -> Navigate next/previous
      - Complete flow: Swipe to delete from list -> Confirm -> List updates
      - Complete flow: Delete all sessions -> Empty state shows
      - Integration: Auto-deletion runs on app startup
      - Integration: Retention setting persists and applies
  - [x] 5.3 Write up to 10 additional strategic tests maximum
    - Add maximum of 10 new tests to fill identified critical gaps
    - Focus on integration points and end-to-end workflows
    - Do NOT write comprehensive coverage for all scenarios
    - Skip edge cases unless business-critical
    - Example strategic tests:
      - Integration test: Session list refreshes after deletion
      - Integration test: Session detail navigation maintains state
      - Integration test: Auto-deletion removes correct sessions on startup
      - Widget test: Empty state displays when no sessions exist
      - Integration test: Delete all sessions clears database completely
  - [x] 5.4 Run feature-specific tests only
    - Run ONLY tests related to Session History Management feature
    - Expected total: approximately 18-42 tests maximum
    - Do NOT run the entire application test suite
    - Verify critical workflows pass:
      - Database queries return correct data
      - Retention settings save and load correctly
      - Auto-deletion removes old sessions
      - Session list displays and navigates correctly
      - Session detail displays and navigates correctly
      - Deletion features work correctly
  - [x] 5.5 Verify integration with existing features
    - Verify hamburger menu navigation works from HeartRateMonitoringScreen
    - Verify session history loads completed sessions from database
    - Verify auto-deletion runs during app startup flow
    - Verify retention setting integrates with SettingsScreen
    - Verify Material theme styling is consistent
    - Verify Riverpod providers integrate correctly
    - Test on multiple device orientations (portrait and landscape)
  - [x] 5.6 Perform manual testing of complete user journeys
    - Test complete workflow: Start session -> End session -> View in history
    - Test complete workflow: View history -> Tap session -> Navigate next/previous -> Delete
    - Test complete workflow: Configure retention -> Restart app -> Verify auto-deletion
    - Test complete workflow: Delete all sessions -> Verify empty state
    - Test swipe-to-delete gesture on various devices
    - Test responsive layout in portrait and landscape modes
    - Test with no sessions, one session, and many sessions
  - [x] 5.7 Verify privacy and data handling
    - Verify all session deletions remove data completely from database
    - Verify auto-deletion runs silently without user notification
    - Verify no data leaves the device (local-only operations)
    - Verify SQLCipher encryption remains enabled for all operations
    - Verify no logging of sensitive session data
  - [x] 5.8 Performance verification
    - Test session list performance with 100+ sessions
    - Verify ListView.builder efficiently handles long lists
    - Verify session detail loads quickly with large reading datasets
    - Verify auto-deletion completes within reasonable time on startup
    - Verify no memory leaks in navigation between screens

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 18-42 tests total)
- Critical user workflows for Session History Management are covered
- No more than 10 additional tests added when filling in testing gaps
- Testing focused exclusively on this feature's requirements
- Integration with existing features verified
- Privacy and data handling verified
- Performance acceptable with large datasets

## Execution Order

Recommended implementation sequence:
1. Database Layer (Task Group 1) - Foundation for all other features
2. Settings & Auto-Deletion (Task Group 2) - Core retention logic
3. Session History List Screen (Task Group 3) - Primary UI for viewing sessions
4. Session Detail Screen (Task Group 4) - Detailed view and navigation
5. Testing & Integration (Task Group 5) - Verification and quality assurance

## Technical Notes

### Flutter/Riverpod Architecture Patterns
- Use ConsumerStatefulWidget for screens that need state and Riverpod
- Use StateNotifierProvider pattern for session history state management
- Follow existing provider patterns from settingsProvider and sessionProvider
- Use ref.watch for reactive UI updates, ref.read for one-time reads

### Database Patterns
- Use transactions for multi-table operations (deletion)
- Leverage existing indexes on session_id and timestamp for performance
- Follow existing query method patterns (toMap/fromMap)
- Ensure CASCADE deletion or explicit deletion of related records

### UI/UX Patterns
- Reuse HeartRateMonitoringScreen layout structure for consistency
- Reuse existing widgets: HeartRateChart, SessionStatsCard
- Follow Material Design patterns for lists, dialogs, navigation
- Maintain responsive layout for portrait and landscape orientations
- Use Dismissible widget for swipe-to-delete gesture

### Privacy & Security
- All operations remain local (no network calls)
- Maintain SQLCipher encryption for mobile platforms
- Perform auto-deletion silently without user interruption
- Delete all associated data when sessions are removed

### Testing Strategy
- Write minimal focused tests during development (2-8 per task group)
- Focus on critical paths and primary user workflows
- Add maximum 10 strategic tests for integration coverage
- Test privacy and data handling explicitly
- Verify performance with large datasets
