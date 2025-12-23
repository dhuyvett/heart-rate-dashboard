# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: app code (`main.dart` entrypoint, `screens/`, `widgets/`, `models/`, `services/`, `utils/`).
- `test/`: widget tests (`widgets/`, `screens/`), integration flows (`integration/`), shared fakes in `test/mocks/`.
- Platform scaffolding: `android/`, `ios/`, `linux/`, `macos/`, `windows/`; docs and product briefs under `agent-os/`.

## Build, Test, and Development Commands
- Install deps: `flutter pub get`.
- Whenever pubspec.yaml is modified, run `flutter pub upgrade --major-versions`
- Analyze + format: `flutter analyze` and `dart format .`.
- Run app: `flutter run -d <device>` (use `flutter devices` to list; Chrome/desktop targets supported).
- Tests: `flutter test` (all), `flutter test test/widgets test/screens test/widget_test.dart` (widget), `flutter test test/integration` (integration), coverage via `flutter test --coverage`.
- Builds: `flutter build apk`, `flutter build appbundle`, `flutter build ios`, `flutter build linux|macos|windows`, `flutter build web`.

## Coding Style & Naming Conventions
- Dart style with `flutter_lints`; 2-space indent; keep lines near 80 chars.
- File names in `snake_case.dart`; one major widget per file.
- Use Riverpod patterns already present; prefer pure functions and immutable models.
- Add brief comments only for non-obvious logic; avoid dead code and unused imports.

## Testing Guidelines
- Framework: `flutter_test`; keep tests isolated, deterministic, and fast.
- Timeouts required: widget (≤10s), integration (≤30s); use `pumpAndSettle(const Duration(...))` instead of sleeps.
- Mock external systems: use fakes/mocks in `test/mocks/`; no real BLE or network in tests.
- Name tests descriptively (`feature_behavior_expectation`) and place alongside related modules (`test/widgets/xyz_test.dart`, `test/integration/...`).

## Commit & Pull Request Guidelines
- Commit messages: imperative, `type: summary` (types: feat, fix, docs, style, refactor, test, chore).
- Before pushing: `flutter analyze`, `dart format .`, `flutter test` (add coverage when touching critical logic).
- PRs: include what/why, linked issue (if any), test results, and screenshots/gifs for UI changes or new flows.
- Keep changes scoped; avoid mixing refactors with features unless necessary and noted.

## Security & Configuration Tips
- App is privacy-first: avoid adding telemetry or network calls without explicit approval.
- Desktop builds need platform deps (e.g., `libsecret-1-dev` on Linux for secure storage).
- Prefer env-agnostic code; guard platform-specific paths with appropriate checks.***
