# Task 002: Add SettingsScreen widget test and router integration test

**Agent**: mobile-engineer
**Files**:
- `test/features/settings/presentation/screens/settings_screen_test.dart` (create)
- `test/core/routing/app_router_test.dart` (modify)

**Depends on**: 001
**Blocks**: None
**Review checkpoint**: Yes (terminal task — full integration gate)
**Context docs**: None

## Description

Add two test files: (1) a new `settings_screen_test.dart` following the exact same pattern as `meds_screen_test.dart` (locale switching across en/uk/de/unsupported, AppBar shape checks), and (2) a new Test 6 in `app_router_test.dart` following the Test 5 pattern (`/theme-preview` renders without shell) but for `/settings`.

## Change Details

### `test/features/settings/presentation/screens/settings_screen_test.dart` (create)
- Create directory `test/features/settings/presentation/screens/`
- Pattern: identical to `test/features/meds/presentation/screens/meds_screen_test.dart`
- `_resolveLocale` top-level function — same as in `meds_screen_test.dart`
- `_harness({required Locale locale})` — same as meds but wraps `const SettingsScreen()` instead of `const MedsScreen()`
- Group `'SettingsScreen locale switching'`:
  - `renders "Settings" under Locale("en")` → `expect(find.text('Settings'), findsOneWidget)`
  - `renders "Einstellungen" under Locale("de")` → `expect(find.text('Einstellungen'), findsOneWidget)`
  - `renders "Налаштування" under Locale("uk")` → `expect(find.text('Налаштування'), findsOneWidget)`
  - `falls back to "Settings" for unsupported Locale("fr")` → `expect(find.text('Settings'), findsOneWidget)`
- Group `'SettingsScreen AppBar shape'`:
  - `AppBar has no actions` — same assertion as meds test
  - `1-px Divider is a descendant of the AppBar` — same assertion as meds test

### `test/core/routing/app_router_test.dart`
- Add import: `import 'package:dosly/features/settings/presentation/screens/settings_screen.dart';`
- Add Test 6 after Test 5, following the same pattern:
  - Title: `'Test 6 (AC-5, AC-7): /settings renders without the shell bottom nav and back returns to home'`
  - Start at `/`: verify `HomeScreen` + `AppBottomNav` present
  - Navigate to `/settings` via `GoRouter.of(...).push('/settings')` (note: `push`, not `go`, because `/settings` is a push route)
  - Verify `SettingsScreen` renders, `AppBottomNav` is NOT in the tree
  - Navigate back: `GoRouter.of(tester.element(find.byType(SettingsScreen))).pop()`
  - Verify `HomeScreen` + `AppBottomNav` reappear
  - AC-7 coverage: back navigation restores Home

## Contracts

### Expects
- `lib/features/settings/presentation/screens/settings_screen.dart` exports `class SettingsScreen extends StatelessWidget` with a `const SettingsScreen` constructor
- `lib/core/routing/app_router.dart` contains `GoRoute(path: '/settings'` as a sibling route
- `lib/features/home/presentation/screens/home_screen.dart` contains `onPressed: () => context.push('/settings')`
- `lib/l10n/app_en.arb` contains `"settingsTitle": "Settings"`, `app_uk.arb` contains `"settingsTitle": "Налаштування"`, `app_de.arb` contains `"settingsTitle": "Einstellungen"`
- `test/core/routing/app_router_test.dart` exists with Tests 1–5 and `_pumpRouter` helper

### Produces
- `test/features/settings/presentation/screens/settings_screen_test.dart` exists with 6 test cases (4 locale + 2 AppBar shape)
- `test/core/routing/app_router_test.dart` contains `'Test 6'` that verifies `/settings` renders without shell and back returns to home
- All tests pass: `flutter test` reports zero failures

## Done when
- [x] `dart analyze` reports zero issues on all changed/created files
- [x] `flutter test` passes — all existing tests + new tests (zero failures)
- [x] `flutter build apk --debug` succeeds
- [x] Settings screen test covers locale switching (en/uk/de/unsupported) and AppBar shape (no actions, 1-px divider)
- [x] Router test verifies `/settings` renders without bottom nav and back returns to Home

## Spec criteria addressed
AC-9, AC-10, AC-11, AC-12

## Completion Notes

**Completed**: 2026-04-25
**Status**: Complete
**Files changed**: test/features/settings/presentation/screens/settings_screen_test.dart (new), test/core/routing/app_router_test.dart (modified)
**Contract**: Expects 5/5 verified | Produces 3/3 verified
**Notes**: 112/112 tests pass (was 105 before feature, +7 new: 6 settings screen + 1 router). APK build success. No deviations from plan.
