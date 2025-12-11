# Task Breakdown: Advanced Session Management

## Overview
Total Tasks: 18

## Task List

### Data & State Layer

#### Task Group 1: Session data model and lifecycle handling  
**Dependencies:** None

- [x] 1.0 Define feature-focused tests (2-6) for session lifecycle updates  
  - Cover: name persistence, preventing concurrent sessions, end-on-exit completion timestamp, rename flow persistence.  
- [x] 1.1 Extend session model/state to support naming gate and rename updates  
  - Ensure session names are stored and editable for running and completed sessions.  
- [x] 1.2 Add persistence hooks for session naming and rename flows  
  - Update database service to save/overwrite names; guard against concurrent session creation.  
- [x] 1.3 Handle interrupted sessions on restart  
  - On app launch, detect active session and mark it complete using last recorded timestamp.  
- [x] 1.4 Verify data/state tests from 1.0 pass  
  - Run only the targeted tests authored in this group.

**Acceptance Criteria:**  
- Session names persist for running and historical sessions; concurrent sessions are blocked; interrupted sessions are auto-completed with last timestamp; targeted tests pass.

### UI / UX

#### Task Group 2: Session start flow & real-time transition  
**Dependencies:** Task Group 1

- [x] 2.0 Define UI tests (2-6) for start gating and navigation  
  - Cover: Start disabled on empty name; default name pre-filled; Start triggers recording + real-time view.  
- [x] 2.1 Implement naming screen/state before start  
  - Paused initial state; inline name input; default “Session – YYYY-MM-DD HH:MM” (local time).  
- [x] 2.2 Wire Start action to real-time view and recording  
  - Navigation to existing monitoring screen; ensure recording begins immediately on start.  
- [x] 2.3 Prevent concurrent start attempts in UI  
  - Disable/guard UI triggers when a session is active.  
- [x] 2.4 Verify UI tests from 2.0 pass  
  - Run only the targeted tests authored in this group.

**Acceptance Criteria:**  
- Users can edit pre-filled name; Start is disabled when empty; Start transitions to real-time view and begins recording; UI blocks concurrent session starts; targeted tests pass.

### Session Management UX

#### Task Group 3: Renaming and end-without-new-session  
**Dependencies:** Task Group 1, Task Group 2

- [x] 3.0 Define UI/logic tests (2-6) for rename and end flows  
  - Cover: renaming running/historical sessions on existing screens; end-session returns to device selection preserving last device.  
- [x] 3.1 Add rename affordances on existing session list/detail screens  
  - Inline or dialog aligned with current patterns; ensure state refresh.  
- [x] 3.2 Implement end-without-new-session action  
  - Ends recording, saves session, navigates to device selection; keep last paired device selected; ensure device switch reconnects correctly.  
- [x] 3.3 Verify tests from 3.0 pass  
- [x] 3.4 Confirm device selection state persists and reconnection works when switching devices.

**Acceptance Criteria:**  
- Rename works for running and historical sessions on existing screens; end-without-new-session returns to device selection keeping last paired device; switching devices updates connection; targeted tests pass.

### Testing & Coverage Review

#### Task Group 4: Feature test gap review  
**Dependencies:** Task Groups 1-3

- [x] 4.0 Review tests from groups 1-3; identify critical gaps only.  
- [x] 4.1 Add up to 6 additional integration-focused tests if needed  
  - Prioritize start gating, rename persistence, end-without-new-session, interrupted-session completion.  
- [x] 4.2 Run only feature-specific tests from all groups (expected total ≤ 24).  

**Acceptance Criteria:**  
- Critical user flows for this feature are covered; no more than 6 additional tests added; all feature-specific tests pass.
