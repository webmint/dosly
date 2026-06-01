# Task 002: Add HomeScreen gear-tap navigation test

**Agent**: qa-engineer
**Status**: Complete
**Files**: `test/features/home/presentation/screens/home_screen_test.dart`
**Depends on**: None
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-05-27
**Files changed**: test/features/home/presentation/screens/home_screen_test.dart (new)
**Contract**: Expects [4/4 verified] | Produces [2/2 verified]
**Notes**: Direct approach worked — the real `SettingsScreen` mounts with only
`settingsRepositoryProvider` overridden by an always-success `_FakeSettingsRepository`;
no OQ-1 route-observer fallback needed. Gear located via `find.byIcon(LucideIcons.settings)`.
Code review APPROVE-with-warnings: removed a fragile post-tap
`find.byType(HomeScreen), findsNothing` assertion (push doesn't contractually
unmount the route below) — kept the meaningful pre-tap (Home present / Settings
absent) + post-tap (`SettingsScreen` findsOneWidget) assertions. Icon-coupling
warning accepted (finder targets the real production gear icon).

**Description**:
Create the missing widget test for `HomeScreen` (Bug 016 sub-item 3). The
settings gear's navigation (`home_screen.dart:34`, `context.push('/settings')`)
is currently never exercised end-to-end — `app_router_test.dart` Test 6 pushes
`/settings` programmatically, not via the gear. Mount `HomeScreen` in a minimal
two-route `GoRouter` (`/` → `HomeScreen`, `/settings` → the real
`SettingsScreen`), tap the gear, and assert the real `SettingsScreen` mounts
(plan decision OQ-1). Override `settingsRepositoryProvider` with an
always-success fake so the test never touches real prefs — reuse the
`_FakeSettingsRepository` pattern from
`test/features/settings/presentation/screens/settings_screen_test.dart:18`.

**Change details**:
- Create `test/features/home/presentation/screens/home_screen_test.dart`:
  - Define (or copy) a minimal `_FakeSettingsRepository implements SettingsRepository` returning success for `load()` and all setters.
  - Build a `GoRouter` with routes `/` → `HomeScreen()` and `/settings` → `SettingsScreen()`.
  - Wrap in `ProviderScope(overrides: [settingsRepositoryProvider.overrideWithValue(fake)])` + `MaterialApp.router` with `AppLocalizations.localizationsDelegates`, `supportedLocales`, and `localeResolutionCallback: resolveAppLocale`.
  - `await tester.pumpAndSettle()`; locate the gear via `find.byTooltip(...)` or `find.byIcon(LucideIcons.settings)`; `await tester.tap(...)`; `await tester.pumpAndSettle()`.
  - Assert `find.byType(SettingsScreen)` is `findsOneWidget`.
  - If mounting the real `SettingsScreen` proves disproportionately heavy (extra provider overrides cascade), fall back to asserting the pushed route resolves to `/settings` via a router observer and note the deviation.

**Done when**:
- [ ] The test taps the gear (not a programmatic push) and asserts `find.byType(SettingsScreen)` (or the OQ-1 route-observer fallback, documented).
- [ ] No real prefs are used; `settingsRepositoryProvider` is overridden with a fake.
- [ ] No `await Future.delayed`; the test is isolated.
- [ ] `flutter test test/features/home/presentation/screens/home_screen_test.dart` passes.
- [ ] `dart analyze` passes on the changed file.

**Spec criteria addressed**: AC-5

## Contracts

### Expects
- `lib/features/home/presentation/screens/home_screen.dart` exports `HomeScreen` with a gear `IconButton` calling `context.push('/settings')` and `tooltip: context.l10n.settingsTooltip`, icon `LucideIcons.settings`.
- `lib/features/settings/presentation/screens/settings_screen.dart` exports `SettingsScreen`.
- `settingsRepositoryProvider` is overridable (exists in `settings_provider.dart`); `SettingsRepository` is the interface a fake can implement.
- `resolveAppLocale` is exported from `lib/core/l10n/locale_resolver.dart`.

### Produces
- `test/features/home/presentation/screens/home_screen_test.dart` exists and imports `package:dosly/features/home/presentation/screens/home_screen.dart`.
- The file taps a finder resolving the settings gear and asserts on `SettingsScreen` (or, in the documented fallback, the `/settings` route).
