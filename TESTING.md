# Testing Standards and Principles
**Heart Rate Dashboard Application**

## Testing Principles

### 1. Timeout Protection
**Every test MUST have explicit timeouts to prevent hung tests.**

```dart
// ✅ GOOD: Explicit timeout
testWidgets('screen renders', (tester) async {
  // Timeout set at test level
}, timeout: const Timeout(Duration(seconds: 10)));

// ✅ GOOD: Timeout for async operations
await tester.pumpWidget(widget).timeout(
  const Duration(seconds: 5),
  onTimeout: () => throw TimeoutException('Widget failed to pump'),
);

// ❌ BAD: No timeout
testWidgets('screen renders', (tester) async {
  await someAsyncOperation(); // Could hang forever!
});
```

**Default Timeouts:**
- Widget tests: 10 seconds per test
- Integration tests: 30 seconds per test
- Async operations: 5 seconds max
- Animations: Use `pumpAndSettle(timeout)`, not arbitrary sleeps

### 2. Avoid Sleep/Wait Anti-Patterns

```dart
// ❌ BAD: Arbitrary sleeps
await Future.delayed(Duration(seconds: 2)); // Fragile!
await tester.pump(Duration(seconds: 1)); // Why 1 second?

// ✅ GOOD: Event-driven waiting
await tester.pumpAndSettle(const Duration(seconds: 10)); // Wait for animations with timeout
await tester.pump(); // Single frame
await tester.pump(Duration.zero); // Process microtasks

// ✅ GOOD: Wait for specific conditions
await tester.pumpWidget(widget);
expect(find.text('Loading'), findsOneWidget);
await tester.pumpAndSettle(const Duration(seconds: 10)); // Wait for loading with timeout
expect(find.text('Content'), findsOneWidget);

// ✅ GOOD: Finite retry with timeout
Future<void> waitForCondition(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  while (tester.any(finder) == false) {
    if (stopwatch.elapsed > timeout) {
      throw TimeoutException('Condition not met: $finder');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
```

### 3. Deterministic Test Execution

**Tests must be:**
- **Idempotent**: Same result every run
- **Isolated**: No shared state between tests
- **Fast**: Complete in seconds, not minutes
- **Reliable**: 95%+ success rate

```dart
// ✅ GOOD: Clean state before each test
setUp(() async {
  // Reset singletons
  await DatabaseService.instance.closeForTesting();
  BluetoothService.instance.dispose();

  // Clear providers
  container = ProviderContainer();
});

tearDown(() async {
  // Clean up
  container.dispose();
  await DatabaseService.instance.closeForTesting();
});
```

### 4. Mock External Dependencies

**Never rely on real external systems in tests.**

```dart
// ✅ GOOD: Mock BLE adapter
class MockBluetoothAdapter implements BluetoothAdapter {
  @override
  Stream<BluetoothAdapterState> get state =>
    Stream.value(BluetoothAdapterState.on);
}

// ✅ GOOD: Mock database
await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);

// ✅ GOOD: Mock time-sensitive operations
class FakeClock {
  DateTime _now = DateTime(2025, 1, 1);
  DateTime now() => _now;
  void advance(Duration duration) => _now = _now.add(duration);
}
```

---

## Running Tests

- Full suite: `flutter test`
- Widget-only: `flutter test test/widgets test/widget_test.dart`
- Integration subset: `flutter test test/integration`
- Coverage: `flutter test --coverage` (outputs to `coverage/lcov.info`)
- Unit/service/provider: `flutter test test/services test/providers test/models test/utils`

## Widget Tests 

- Location: `test/widgets`, `test/screens`, and `test/widget_test.dart`
- Command: `flutter test test/widgets test/screens test/widget_test.dart`
- Expectations: obey default timeouts (10s per test), avoid sleeps, keep tests hermetic (no filesystem/network)
- Common patterns: prefer `pumpAndSettle(timeout)` for animations, use fakes/mocks from `test/mocks`, reset providers/singletons in `setUp`/`tearDown`


## Integration Tests 

### Test Isolation Strategy

**Each integration test MUST:**
1. Start from a clean state (no leftover data)
2. Set up its own mocks/fixtures
3. Clean up completely in tearDown
4. Be runnable independently

### How to Run

- Location: `test/integration`
- Command: `flutter test test/integration`
- Environment: runs headless; no real BLE hardware required—use provided mocks/fakes; ensure demo-mode paths are covered when device hardware is unavailable
- Timeouts: keep per-test timeout ≤30s and add explicit timeouts to async waits (e.g., `pumpAndSettle(timeout)`)

## Unit Tests

- Location: `test/services`, `test/providers`, `test/models`, `test/utils`
- Command: `flutter test test/services test/providers test/models test/utils`
- Expectations: deterministic and isolated; no real BLE or database I/O—use in-memory fakes (e.g., `FakeSettingsNotifier`), `sqflite_common_ffi` test helpers, and stream timeouts instead of sleeps
