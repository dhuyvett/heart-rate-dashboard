# Specification: Critical and High Priority Bug Fixes

## Goal
Fix 10 critical and high-priority bugs identified in the code review that pose security risks, create race conditions, cause memory leaks, and degrade user experience. These fixes will eliminate production-blocking issues while maintaining backward compatibility and existing functionality.

## User Stories
- As a developer, I want all race conditions and memory leaks fixed so that the application is stable and performant in production
- As a user, I want proper error feedback during connection timeouts so that I understand what went wrong and can take appropriate action

## Specific Requirements

**Fix Connection Timeout Exception Propagation (bluetooth_service.dart:213-216)**
- Refactor timeout mechanism from Timer callback to Completer pattern
- Timeout exceptions must propagate to caller and trigger proper error handling
- Cancel timeout timer immediately after successful connection
- Maintain existing 15-second timeout duration
- Add logging for timeout events
- Ensure connection state updates to disconnected on timeout
- Preserve existing error message format for UI consistency

**Fix Settings Provider Async Loading (settings_provider.dart:36-41)**
- Convert SettingsNotifier from sync Notifier to async AsyncNotifier
- Return loading state initially instead of default values
- UI must show loading indicator while settings load from database
- Settings must not flash incorrect values (age 30, male) during startup
- Heart rate zone calculations must wait for actual settings before computing
- Maintain all existing settings properties and update methods
- Ensure database read happens exactly once on initialization

**Fix Stream Subscription Memory Leak (bluetooth_service.dart:375)**
- Cancel previous heart rate subscription before creating new one
- Add null check before attempting to cancel subscription
- Track subscription lifecycle with clear logging
- Verify cleanup happens on disconnection and error paths
- Apply same pattern to all stream subscriptions in BluetoothService
- Add unit tests to verify subscriptions are cancelled on reconnection

**Fix Race Condition in Reconnection Handler (reconnection_handler.dart:200-210)**
- Add boolean flag to track if reconnection is already in progress
- Check flag before starting new reconnection attempt
- Set flag when starting reconnection, clear when complete or failed
- Ensure exponential backoff timing is not corrupted by concurrent attempts
- Prevent multiple simultaneous connection attempts to same device
- Maintain existing reconnection attempt limits and backoff intervals
- Add logging to detect and report race condition attempts

**Replace XOR Cipher with AES-GCM (secure_key_manager.dart:316-327)**
- Replace XOR encryption in backup key encryption with AES-GCM
- Use encrypt package for cryptographically secure AES-256-GCM implementation
- Generate random IV for each encryption operation
- Store IV alongside encrypted data (prepend to ciphertext)
- Maintain existing key derivation using device-specific deterministic key
- Ensure backward compatibility: attempt XOR decryption if AES fails
- Add migration path for existing encrypted backups

**Add Desktop Database Encryption Warning (database_service.dart:98-112)**
- Display one-time warning dialog on first launch on Linux/Windows/macOS platforms
- Warning must clearly state that database is stored unencrypted on desktop
- Provide option to acknowledge and not show again
- Store warning acknowledgement in SharedPreferences
- Do not block app functionality if user dismisses warning
- Warning should appear before device selection screen
- Desktop detection should use existing Platform.isLinux/isMacOS/isWindows checks

**Distinguish Permission Check Failure from Denial (main.dart:136-154)**
- Wrap permission check in try-catch to detect check failures
- Create separate error state for permission check failure vs permission denied
- Show different UI messages for check failure vs explicit denial
- Permission check failure should show error with retry option
- Permission denial should show standard permission request flow
- Log permission check failures with full stack trace for debugging
- Maintain existing permission flow for successful checks

**Fix Timeout After Successful Connection Race (bluetooth_service.dart:213-235)**
- Move timeout timer cancellation to immediately after device.connect() succeeds
- Cancel timer before starting service discovery
- Add null check before timer cancellation
- Ensure timeout cannot fire during or after service discovery
- Maintain existing timeout for connection establishment only
- Service discovery should have no timeout (rely on BLE stack timeout)
- Add logging to track connection and discovery phases separately

**Handle Empty Session Statistics (session_provider.dart:115-133, 204-235)**
- Delete sessions with zero readings when endSession() is called
- Add check in endSession() for readingsCount > 0 before saving statistics
- If readingsCount is 0, call deleteSession() instead of saving stats
- Maintain existing behavior for sessions with readings
- Update session history to handle deleted sessions gracefully
- Add logging when empty sessions are deleted
- Ensure database foreign key constraints properly delete orphaned readings

**Close Stream Controller in Error Paths (bluetooth_service.dart:134-145)**
- Wrap demo mode stream controller creation in try-catch-finally
- Ensure controller is closed in finally block if errors occur
- Add null check before closing controller
- Apply same pattern to all stream controller cleanup in BluetoothService
- Track controller lifecycle with defensive null checks
- Add unit tests for error path resource cleanup
- Maintain existing happy path behavior

## Existing Code to Leverage

**AppLogger utility (lib/utils/app_logger.dart)**
- Use for all new logging statements
- Provides structured logging with log levels (debug, info, warning, error)
- Automatically includes stack traces for errors
- Follow existing pattern: final _logger = AppLogger.getLogger('ClassName')

**Completer pattern in DatabaseService (lib/services/database_service.dart:31-76)**
- Shows proper implementation of Completer for async initialization
- Use same pattern for connection timeout handling
- Thread-safe concurrent access handling
- Proper error propagation through completer.completeError()

**Stream subscription cleanup in SessionNotifier (lib/providers/session_provider.dart:72-77)**
- Shows proper pattern: _subscription?.close() before creating new subscription
- Apply this pattern to BluetoothService subscription management
- Demonstrates defensive null checking before cleanup

**AsyncNotifier usage in existing providers**
- Research Riverpod AsyncNotifier pattern for settings provider refactor
- Settings should return AsyncValue<AppSettings> instead of AppSettings
- UI components should handle AsyncValue.loading, .data, and .error states

**Platform detection in DatabaseService (lib/services/database_service.dart:80-81)**
- Use existing _isDesktop getter for desktop platform detection
- Leverages Platform.isLinux || Platform.isMacOS || Platform.isWindows
- Apply same pattern for desktop encryption warning

## Out of Scope
- Refactoring HeartRateMonitoringScreen to reduce file size
- Implementing CSV export functionality
- Extracting BPM display widgets into separate files
- Adding session naming or tagging features
- Centralizing magic strings into constants
- Optimizing database queries with pagination
- Implementing proper database migration system
- Adding historical analytics or trends
- Implementing backup/restore functionality
- Refactoring settings storage to use JSON blob instead of individual keys
