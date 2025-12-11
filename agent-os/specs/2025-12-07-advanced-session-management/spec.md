# Specification: Advanced Session Management

## Goal
Enable users to name sessions before starting, manage running and historical session names, gracefully end sessions without auto-starting another, and ensure interrupted sessions are marked complete on restart while preserving device selection context.

## User Stories
- As a privacy-focused athlete, I want to name a session before it starts so I can distinguish workouts later.
- As a user reviewing my history, I want to rename past or running sessions so I can keep session labels accurate.
- As a device owner, I want to end a session and return to device selection without losing my last paired choice so I can quickly reconnect or switch devices.

## Specific Requirements

**Session naming gate before start**
- New session flow opens in a paused state with a naming input on the same screen; Start is disabled until the name field is non-empty.
- Pre-fill the name with “Session – YYYY-MM-DD HH:MM” using device local time.
- Allow editing the pre-filled name prior to start.

**Start behavior and navigation**
- Tapping Start switches to the real-time monitoring view and immediately begins recording using the chosen device.
- Maintain consistent navigation stack so back navigation returns to expected screens (real-time → device selection/history as today).

**Renaming running and historical sessions**
- Provide rename affordances on existing session list and session detail screens; prefer inline or lightweight dialog aligned with current patterns.
- Persist updated names to storage and refresh visible lists/detail views without app restart.

**End session without auto-start**
- Offer an action to end the current session and navigate back to device selection without starting a new session.
- Preserve the last paired device selection on return; ensure switching devices updates connection state correctly.

**Prevent multiple concurrent sessions**
- Block initiating a new session while another is active; ensure UI reflects active session state and disables redundant starts.

**App exit during active session**
- On app restart, detect previously active session and mark it complete using the last recorded timestamp as end time.
- Persist completion so history shows the session as finished and not active.

**Session persistence and metrics**
- Ensure session name, start/end times, and stats remain in local storage consistent with existing session model and database schema.

**Device state handling**
- Maintain connection or reconnection flows consistent with current device handling; when user selects a different device, update the active connection before starting/continuing sessions.

## Visual Design
No visual assets provided.

## Existing Code to Leverage

**lib/providers/session_provider.dart (SessionNotifier)**
- Manages start/pause/resume/end flows and writes readings; extend to gate start on naming and prevent concurrent starts.

**lib/screens/heart_rate_monitoring_screen.dart**
- Current real-time view and session controls; reuse for post-start navigation and recording initiation.

**lib/screens/session_history_screen.dart & lib/screens/session_detail_screen.dart**
- Existing history and detail UIs; add rename affordances and refresh logic after name updates.

**lib/models/workout_session.dart & lib/services/database_service.dart**
- Session model and persistence; extend to store/overwrite session names and mark incomplete sessions complete on restart.

**lib/models/session_state.dart**
- In-memory session state; ensure naming status and pause/start flags are reflected for UI enable/disable logic.

## Out of Scope
- Multiple concurrent sessions.
- Auto-starting sessions on device connect.
- Adding notes/tags or activity-type metadata beyond naming.
- New visual design system changes or theme overhauls.
- Networked sync or cloud backup. 
