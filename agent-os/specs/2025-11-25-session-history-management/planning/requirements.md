# Spec Requirements: Session History Management

## Initial Description
For previous session viewing and management. This feature should allow users to view all previous sessions, and manage retention of previous sessions (with a default retention of 30 days). There should be an option to delete all previous sessions.

## Requirements Discussion

### First Round Questions

**Q1: Where should users access the session history feature?**
**Answer:** Main navigation (hamburger menu)

**Q2: For the list view showing previous sessions, what information should be displayed for each session?**
**Answer:** Show date/time in a list, tapping a selection allows viewing the complete session graph along with all details

**Q3: Should users be able to view individual session details (heart rate graph, duration, avg/max HR)?**
**Answer:** Yes (same as Q2 - users can tap a session to view the complete graph and details)

**Q4: For auto-deletion based on retention settings, should users get a confirmation dialog, or should sessions delete automatically according to the setting?**
**Answer:** Configurable in Settings, auto-delete according to setting with no confirmation dialog

**Q5: Should there be a "Delete All Sessions" button, and if so, should it require confirmation?**
**Answer:** Yes, button in the history screen with a confirmation dialog

**Q6: Should users be able to delete individual sessions? If so, from which screens?**
**Answer:** Yes, available in both list view and detail view

**Q7: Should session filtering be provided (e.g., by date range, duration, or activity type)?**
**Answer:** Completed sessions only (no filtering by other criteria)

**Q8: Are there any features you explicitly want to exclude from this spec?**
**Answer:** No exclusions

### Follow-up Questions

**Follow-up 1: For the auto-deletion timeframe setting, should this be a dropdown with preset options (7, 14, 30, 60, 90 days) or an open text/number field?**
**Answer:** Open data entry for any number of days with a default of 30

**Follow-up 2: When a session is deleted (either manually or auto-deletion), should all associated data be deleted (heart rate readings, timestamps, etc.), or should we keep some aggregate data?**
**Answer:** Delete all data associated with the session

**Follow-up 3: For the list view, how should sessions be sorted (newest first, oldest first, or user preference)?**
**Answer:** By date, newest first

**Follow-up 4: In the session detail view, should users be able to navigate to the next/previous session without returning to the list, or should they need to go back to the list each time?**
**Answer:** Yes (navigate to next/previous session without returning to list)

**Follow-up 5: For the empty state (when there are no sessions), what should be displayed?**
**Answer:** A helpful message

**Follow-up 6: Are there existing features in the codebase with similar patterns we should reference?**
**Answer:** Session detail page should resemble the HR monitoring page with differences: no current HR display, and the graph time frame covers the whole session

### Existing Code to Reference

**Similar Features Identified:**
- Feature: HR Monitoring Page - The main workout screen showing live heart rate data
- Purpose: Session detail view should use similar layout and styling as the HR monitoring page
- Key Differences:
  - No current/live heart rate display in session detail
  - Graph time frame should span the entire session duration (not just recent data)
  - Historical data display instead of live data stream

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
No visuals to analyze.

## Requirements Summary

### Functional Requirements

**Navigation & Access:**
- Add "Session History" menu item to main navigation (hamburger menu)
- Provide access to session history management from main app navigation

**Session List View:**
- Display all completed workout sessions in a list format
- Show date/time for each session in the list
- Sort sessions by date, newest first
- Enable tap-to-view functionality for session details
- Provide individual session deletion from list view
- Include "Delete All Sessions" button in list view header/toolbar
- Display helpful empty state message when no sessions exist

**Session Detail View:**
- Display complete session graph showing heart rate over the full session duration
- Show all session details (duration, average heart rate, max heart rate, etc.)
- Resemble the HR monitoring page layout and styling
- Exclude live/current heart rate display (historical view only)
- Graph time frame should cover entire session duration
- Enable individual session deletion from detail view
- Provide next/previous session navigation without returning to list

**Data Retention Settings:**
- Add retention setting in app Settings screen
- Provide open number input field for days (any positive integer)
- Set default retention to 30 days
- Auto-delete sessions older than retention setting automatically (no confirmation dialog)
- Store retention preference using shared_preferences

**Delete All Sessions:**
- Provide "Delete All Sessions" button in session history screen
- Show confirmation dialog before deleting all sessions
- Delete all session data when confirmed

**Data Management:**
- Delete all associated data when a session is deleted (heart rate readings, timestamps, metadata)
- No partial data retention or aggregate data when sessions are deleted
- Apply retention settings automatically in background

### Reusability Opportunities

**Components to Reference:**
- HR Monitoring Page (main.dart or equivalent) - for session detail view layout
- Heart rate graphing component - reuse for session detail graph (adjust time frame to full session)
- Connection status indicators - may inform session status display patterns
- Navigation drawer/hamburger menu - add Session History menu item

**Backend Patterns:**
- Sqflite database queries for fetching session data
- Existing session data schema and models
- Heart rate reading data structures
- Date/time formatting patterns used in existing features

### Scope Boundaries

**In Scope:**
- Session list view with date/time display
- Session detail view with full session graph and statistics
- Individual session deletion from both list and detail views
- Delete all sessions with confirmation
- Configurable auto-deletion based on retention days
- Settings screen integration for retention configuration
- Next/previous session navigation in detail view
- Empty state messaging
- Local data deletion (all associated session data)

**Out of Scope:**
- Session filtering by date range, duration, or other criteria (only show completed sessions)
- Aggregate or summary statistics across multiple sessions
- Session export functionality (covered by separate CSV export feature in roadmap)
- Session editing or modification
- Session categorization by activity type (future roadmap item)
- Partial data retention or archiving
- Cloud backup or sync (violates privacy-first principle)
- Undo functionality for deletions
- Session comparison views

### Technical Considerations

**Database Integration:**
- Query existing Sqflite database for session data
- Implement efficient queries for session list (date sorted)
- Create deletion logic for sessions and all associated heart rate readings
- Add retention setting storage using shared_preferences
- Implement background job or app lifecycle hook for auto-deletion check

**UI Components:**
- Reuse Material Design patterns consistent with existing app
- Leverage existing heart rate graph component from HR monitoring page
- Maintain clean, simple interface aligned with "simplicity over features" principle
- Consider ListView or similar scrollable widget for session list
- Use Navigator for session detail navigation

**State Management:**
- Use Riverpod (or Provider) consistent with app architecture
- Manage session list state
- Handle session deletion updates to list
- Manage navigation state for next/previous session

**Privacy & Offline-First:**
- All data operations remain local (no network calls)
- No data leaves device when sessions are deleted
- Maintain encrypted storage for session data
- No analytics or telemetry for deletion events

**Testing Requirements:**
- Widget tests for list view and detail view
- Unit tests for deletion logic
- Unit tests for retention calculation and auto-deletion
- Test empty state display
- Test navigation between sessions
- Test confirmation dialog for delete all

**Code Organization:**
- Follow existing Flutter project structure
- Place session history screens in appropriate lib/ subdirectory
- Keep business logic separate from UI components
- Use clear, descriptive naming for components and functions
- Document retention and deletion logic clearly
