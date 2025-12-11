# Spec Requirements: advanced session management

## Initial Description
When starting a new session, begin with the session paused and show a screen that allows the user to name the session. The default name based on the time and date should be pre-filled. Once the session is named, there should be a way to start the session. There should be a way to rename historical and running sessions. There should be a way to end a session without starting another (returning to the device selection screen). If the app exits with a running session, when the app is restarted, that session should be seen as complete.

## Requirements Discussion

### First Round Questions

**Q1:** I assume the new session flow should open with the session paused and a naming input on the same screen (not a separate modal) with Start available once a name is confirmed—should Start be disabled until a non-empty name is set?  
**Answer:** Start should be disabled if the name is empty, but the name should be pre-filled with the default.

**Q2:** For the default name, is “Session – YYYY-MM-DD HH:MM” using the device’s local time an acceptable format, or do you prefer another pattern (e.g., include activity type or a shorter time)?  
**Answer:** Format OK, local time OK.

**Q3:** When the user taps Start after naming, should the session immediately begin recording from that screen, or should we return to an existing workout view first (e.g., the current real-time display) before recording begins?  
**Answer:** Start should switch to the realtime view and begin recording.

**Q4:** For renaming historical and running sessions, should this be done from the existing session list and session detail views with inline edits, or do you prefer a dedicated rename dialog/screen?  
**Answer:** On existing screens.

**Q5:** Ending a session without starting another: should this stop recording, save the session, and navigate back to the existing device selection screen while keeping the last paired device selected, or should it fully disconnect?  
**Answer:** Keep the last paired device selected, but ensure that if the user selects a different device, the connection is updated correctly.

**Q6:** If the app exits while a session is running, should we auto-complete it using the last recorded timestamp as the end time, or apply a grace period before marking it complete?  
**Answer:** Use the last recorded timestamp.

**Q7:** Are there any flows or edge cases we should explicitly exclude (e.g., multiple concurrent sessions, auto-start on device connect, mandatory notes/tags)?  
**Answer:** Multiple concurrent session should not be possible.

### Existing Code to Reference
No similar existing features identified for reference.

### Follow-up Questions
No follow-up questions were needed.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
- No visuals to analyze.

## Requirements Summary

### Functional Requirements
- New session flow opens paused with a naming input on the same screen; Start remains disabled if the name is empty but pre-fills a default.
- Default session name uses local time in format “Session – YYYY-MM-DD HH:MM.”
- Starting after naming switches to the real-time view and begins recording immediately.
- Renaming available on existing session list/detail screens for both running and historical sessions.
- Ending a session saves and returns to device selection, keeping the last paired device selected; switching devices updates the connection.
- If the app exits with a running session, auto-complete it using the last recorded timestamp.
- Multiple concurrent sessions are disallowed.

### Reusability Opportunities
- None identified yet; await pointers to similar existing components/screens if available.

### Scope Boundaries
**In Scope:**
- Session naming, default naming, start from paused state, rename flows on existing screens, end-without-new-session flow, app-exit auto-complete behavior.

**Out of Scope:**
- Multiple concurrent sessions.
- Auto-start on device connect, mandatory notes/tags (not requested).

### Technical Considerations
- Use existing navigation to real-time workout view when starting.
- Maintain device selection state and ensure device reconnect logic updates when a different device is chosen.
- Persist sessions so that an interrupted running session is marked complete with the last recorded timestamp on app restart.
