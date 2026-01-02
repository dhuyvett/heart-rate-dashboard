# Code Review Findings

## Highest Priority

1. **BLE connection may fail for newly scanned devices**
   - `BluetoothService.connectToDevice` looks up devices via `_findDeviceById`, but `_findDeviceById` only checks `FlutterBluePlus.connectedDevices` and `FlutterBluePlus.systemDevices` and does not track the scan results used to populate the device list. On platforms where scanned devices are not already bonded/system devices, taps from the scan list can fail with “Device not found.”
   - Affected code: `lib/services/bluetooth_service.dart:235`, `lib/services/bluetooth_service.dart:611`
   - Recommendation: store the last scan results in the service and look up by ID there, or construct a `BluetoothDevice` from the `remoteId` if the SDK supports it.
   - Test gaps: add a unit test that simulates a scanned device not present in `connectedDevices/systemDevices` and verifies `connectToDevice` can still connect; add integration coverage for connecting from the scan list on a fresh (non-bonded) device.
   - Status: addressed scan-cache lookup and added unit test for scan-cache resolution in `lib/services/bluetooth_service.dart` and `test/services/bluetooth_service_test.dart`.

2. **Session start failures block retries**
   - `_sessionStarted` is set to `true` before `startSession` completes. If `startSession` throws, the flag remains true and the screen will not attempt to start a session again without a full navigation reset.
   - Affected code: `lib/screens/heart_rate_monitoring_screen.dart:266`
   - Recommendation: set `_sessionStarted` only after a successful start or reset it in the `catch`/`finally` path so users can retry.
   - Test gaps: add a widget test that forces `SessionNotifier.startSession` to throw, then retries and verifies a second start attempt occurs.
   - Status: reset `_sessionStarted` on start failure and added retry widget test in `lib/screens/heart_rate_monitoring_screen.dart` and `test/screens/heart_rate_monitoring_screen_test.dart`.

3. **Android permission gating is too strict for Android 12+**
   - `_checkPermissions` and `_requestPermissions` require `locationWhenInUse` alongside `bluetoothScan`/`bluetoothConnect` for Android. On Android 12+, BLE scanning no longer requires location permission; denying location will incorrectly block app entry even when BT permissions are granted.
   - Affected code: `lib/main.dart:175`
   - Recommendation: gate location permission on Android SDK version or only require it on pre-Android 12 devices.
   - Test gaps: add platform-versioned permission tests (mocking Android 11 vs 12+) to ensure `PermissionCheckState.granted` on 12+ when BT permissions are granted and location is denied.

## Medium Priority

4. **Manual disconnect flow preserves `last_connected_device_id`**
   - `_endSessionAndNavigateToDeviceSelection` re-saves `last_connected_device_id` after calling `disconnect()` (which clears it). This undermines the manual disconnect intent and can cause auto-reconnect attempts to a device the user just abandoned after failure.
   - Affected code: `lib/screens/heart_rate_monitoring_screen.dart:166`
   - Recommendation: avoid restoring the ID on manual disconnect (or make it conditional on a user choice to retry that device).
   - Test gaps: add an integration test that triggers reconnection failure -> select “Choose another device” and assert `last_connected_device_id` is cleared afterward.

5. **Database query on every heart-rate tick**
   - `_listenToHeartRate` triggers `_loadRecentReadings` on every BPM update. `_loadRecentReadings` performs a DB query and `setState`, which can cause unnecessary IO and UI churn during long sessions (BPM updates at 1.5s intervals).
   - Affected code: `lib/screens/heart_rate_monitoring_screen.dart:358`, `lib/screens/heart_rate_monitoring_screen.dart:312`
   - Recommendation: maintain an in-memory ring buffer for recent readings, or throttle/debounce DB refreshes to reduce IO and rebuilds.
   - Test gaps: add a performance-focused widget test to assert recent-reading updates are throttled (e.g., one DB call per N seconds) and do not trigger excessive rebuilds.

6. **GPS tracking runs at high accuracy even when speed/distance stats are hidden**
   - `_startGpsTracking` starts a high-accuracy position stream for all mobile sessions regardless of whether distance/speed stats are enabled. This keeps the GPS active even if the UI never uses the data, increasing battery drain on longer sessions.
   - Affected code: `lib/screens/heart_rate_monitoring_screen.dart:375`
   - Recommendation: only start GPS tracking when the selected statistics include speed/distance, and consider lowering accuracy or using a larger distance filter when the screen is off or session is paused.
   - Test gaps: add a widget test that toggles visible stats and asserts GPS tracking is not started when distance/speed stats are disabled.

7. **BLE scanning can keep running after leaving the device selection screen**
   - `deviceScanProvider` starts a scan via `BluetoothService.scanForDevices` but there is no explicit stop on provider disposal. If the scan stream outlives the screen (or if the provider remains alive), scanning can continue until the 30s timeout, consuming power unnecessarily.
   - Affected code: `lib/providers/device_scan_provider.dart:10`, `lib/services/bluetooth_service.dart:167`
   - Recommendation: call `BluetoothService.stopScan()` in a `ref.onDispose` handler for `deviceScanProvider` to ensure scanning stops when the screen is not active.
   - Test gaps: add a provider test that asserts `stopScan` is called on disposal.
