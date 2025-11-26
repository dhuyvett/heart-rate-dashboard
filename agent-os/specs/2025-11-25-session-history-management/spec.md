# Specification: Session History Management

## Goal
Enable users to view and manage their workout session history with configurable auto-deletion based on retention days, providing a complete historical view of heart rate data while maintaining privacy and local storage control.

## User Stories
- As a user, I want to view a list of all my past workout sessions so that I can review my training history
- As a user, I want to view detailed heart rate graphs and statistics for any past session so that I can analyze my performance
- As a user, I want to configure how long sessions are retained so that I can manage storage and privacy according to my preferences

## Specific Requirements

**Session History Screen Navigation**
- Add "Session History" menu item to the hamburger menu on HeartRateMonitoringScreen
- Navigate to new SessionHistoryScreen when menu item is tapped
- Screen should have app bar with "Session History" title and back button
- Follow existing navigation patterns using MaterialPageRoute

**Session List View**
- Display all completed workout sessions (where end_time IS NOT NULL) in a scrollable list
- Sort sessions by start_time descending (newest first)
- Show date and time for each session in list tile format
- Display helpful empty state message when no sessions exist ("No workout sessions yet. Start a session to see your history here.")
- Each list item should be tappable to navigate to session detail view
- Include "Delete All Sessions" button in app bar actions menu
- Use ListView.builder for efficient rendering of potentially long lists
- Format date/time consistently with existing app patterns (e.g., "Nov 25, 2025 2:30 PM")

**Individual Session Deletion from List**
- Add swipe-to-delete gesture using Dismissible widget on each list tile
- Show confirmation dialog before deleting: "Delete this session? This action cannot be undone."
- On confirmation, delete session and all associated heart rate readings from database
- Update list view to reflect deletion without requiring screen refresh
- Show brief SnackBar message: "Session deleted"

**Session Detail View Screen**
- Create SessionDetailScreen that resembles HeartRateMonitoringScreen layout
- Display complete session heart rate graph spanning entire session duration (from start_time to end_time)
- Reuse HeartRateChart widget but configure to show all readings for the session
- Show session statistics in grid format: Duration, Average HR, Minimum HR, Maximum HR
- Reuse SessionStatsCard widget from monitoring screen
- Do NOT display current/live heart rate value (historical view only)
- Include device name in app bar or as metadata on screen
- Add delete icon button in app bar to delete current session
- Provide next/previous navigation buttons to adjacent sessions without returning to list

**Next/Previous Session Navigation**
- Add left/right arrow buttons or swipe gestures to navigate between sessions chronologically
- Query database for previous session (older start_time) and next session (newer start_time)
- Disable previous button if viewing oldest session, disable next button if viewing newest session
- Update all displayed data when navigating to different session
- Maintain navigation state without popping back to list view

**Session Retention Settings**
- Add "Session Retention (days)" setting to SettingsScreen
- Use TextField with numeric keyboard for open number entry
- Default value: 30 days
- Valid range: 1-3650 days (validate and show error for invalid values)
- Store retention value in database using DatabaseService.setSetting with key "session_retention_days"
- Display helper text: "Sessions older than this will be automatically deleted"
- Follow existing settings pattern from SettingsNotifier

**Auto-Deletion Background Process**
- Implement session cleanup check on app startup in main.dart InitialRouteResolver
- Calculate cutoff date: DateTime.now().subtract(Duration(days: retentionDays))
- Query and delete sessions where end_time < cutoff timestamp
- Delete associated heart rate readings using CASCADE logic or explicit deletion
- Perform deletion silently without user confirmation dialog
- Log deletion operation for debugging but do not surface to UI
- Ensure cleanup completes before navigation to main screen

**Delete All Sessions Feature**
- Add "Delete All Sessions" action to hamburger menu in SessionHistoryScreen app bar
- Show confirmation dialog: "Delete all workout sessions? This will permanently delete all your session history and cannot be undone."
- Provide "Cancel" and "Delete All" buttons in dialog
- On confirmation, delete all sessions and all heart rate readings from database
- Navigate back to list view showing empty state after deletion completes
- Show SnackBar: "All sessions deleted"

**Database Query Methods**
- Add getAllCompletedSessions() method to DatabaseService returning List of WorkoutSession sorted by start_time DESC
- Add deleteSession(int sessionId) method to delete session and cascade delete all heart_rate_readings with matching session_id
- Add deleteAllSessions() method to delete all sessions and all heart_rate_readings
- Add getSessionsOlderThan(DateTime cutoffDate) method for auto-deletion queries
- Ensure proper indexing on start_time and end_time for query performance
- Use transaction for multi-table deletions to ensure data consistency

## Visual Design
No visual mockups provided. Follow existing Material Design patterns and HeartRateMonitoringScreen layout conventions.

## Existing Code to Leverage

**HeartRateMonitoringScreen Layout**
- Reuse the portrait and landscape layout structure for SessionDetailScreen
- Adapt the statistics grid display (SessionStatsCard widgets)
- Use similar styling and theme patterns for consistency
- Reference the hamburger menu PopupMenuButton pattern for adding Session History menu item

**HeartRateChart Widget**
- Reuse for displaying session detail graphs
- Configure with full session time range instead of rolling window
- Pass all readings for the session instead of recent readings
- Maintain same visual styling with heart rate zone colors

**DatabaseService Patterns**
- Extend existing query methods (getReadingsBySession, getSessionById)
- Follow established patterns for database operations and transactions
- Use existing table names and schema (workout_sessions, heart_rate_readings)
- Leverage existing indexes on session_id and timestamp

**SettingsScreen and SettingsNotifier**
- Follow the same pattern for adding session retention setting
- Use TextField with validation like age field
- Persist to database using setSetting/getSetting pattern
- Include Card widget layout consistent with other settings sections

**WorkoutSession and HeartRateReading Models**
- Use existing toMap/fromMap serialization methods
- Leverage getDuration() method for displaying session duration
- Use timestamp fields for retention calculations
- Follow existing data validation patterns

## Out of Scope
- Session filtering by date range, duration, or other criteria beyond showing completed sessions
- Aggregate statistics across multiple sessions or session trends
- Session export functionality (separate CSV export feature in roadmap)
- Session editing or modification capabilities
- Session categorization or tagging by activity type
- Partial data retention or archiving
- Cloud backup or synchronization
- Undo functionality for deletions
- Session comparison views or side-by-side analysis
- Search functionality within session history
