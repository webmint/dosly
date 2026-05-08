# Task 003: Convert `SettingsScreen` to `ConsumerWidget` + listen for errors + show SnackBar

**Agent**: mobile-engineer
**Status**: Complete
**Files**: `lib/features/settings/presentation/screens/settings_screen.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart`
**Depends on**: 001, 002
**Blocks**: 004
**Context docs**: `specs/014-surface-settings-errors/research.md`, `docs/features/settings.md`
**Review checkpoint**: Yes — convergence point (depends on tasks 001 and 002). Before starting, verify: (a) `context.l10n.settingsPersistenceError` compiles (Task 001 produced); (b) `settingsErrorsProvider` is exported from `settings_provider.dart` (Task 002 produced).

## Completion Notes

**Completed**: 2026-05-07
**Files changed**: lib/features/settings/presentation/screens/settings_screen.dart, test/features/settings/presentation/screens/settings_screen_test.dart
**Contract**: Expects 6/6 verified | Produces 9/9 verified
**Code review**: APPROVE with warnings
- **Warning** (test robustness): The new SnackBar test uses a single `pump()` between `tap` and `pump(Duration(milliseconds: 100))`. This works today because the fake's `saveUseSystemTheme` async body has no internal `await`, so one microtask drain is sufficient. If the fake ever adds an internal `await`, the test would silently fail. Reviewer suggested adding a second `pump()` to drain async completions explicitly. Not fixed in this task — current test passes; can be addressed in a follow-up hardening pass if needed.
- 8 info-level observations confirming compliance: `ref.listen` first statement, `whenData` correctly skips loading, `ScaffoldMessenger.of` safe (no async boundary), no new `!` sites, dartdoc updated, body unchanged, scope clean.

**Integration gate**: 88 settings tests pass; 203 full suite tests pass; `flutter build apk --debug` succeeds.

**Notes**: Terminal source-edit task complete. Source is final and tested. Ready for Task 004 (docs + bug close).

## Description

Convert `SettingsScreen` from a `StatelessWidget` to a `ConsumerWidget`. Add
a `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, ...)` block at
the top of `build` that, on each emission, shows a localized M3 floating
SnackBar via `ScaffoldMessenger.of(context).showSnackBar(...)`. The Scaffold
body (AppBar, ListView, ThemeSelector, LanguageSelector) is unchanged.

Add a widget test asserting that when `setUseSystemTheme` fails, the
SnackBar with the localized error text appears. The screen test file's
existing `_FakeSettingsRepository` (currently always-success with
`Either<Never, void>`) is replaced with a richer fake that has per-method
`failOnSaveX` flags. Existing locale-resolution tests must continue to pass
unmodified.

This is the terminal source-edit task — its done-when conditions include
the full integration gate (`flutter test`, `flutter build apk --debug`).

## Change details

- In `lib/features/settings/presentation/screens/settings_screen.dart`:
  - Add imports:
    - `package:flutter_riverpod/flutter_riverpod.dart`
    - `../../../../core/error/failures.dart`
    - `../providers/settings_provider.dart`
  - Replace `class SettingsScreen extends StatelessWidget` with `class SettingsScreen extends ConsumerWidget`.
  - Update `build` signature from `Widget build(BuildContext context)` to `Widget build(BuildContext context, WidgetRef ref)`.
  - Add the listener block as the **first** statement inside `build`, before `final theme = Theme.of(context);`:
    ```dart
    ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, (prev, next) {
      next.whenData((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.settingsPersistenceError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    });
    ```
  - Update the class-level dartdoc to mention the SnackBar contract:
    insert a paragraph between the existing description and the AppBar
    description: "Listens to [settingsErrorsProvider] and shows a localized
    floating SnackBar each time a preference fails to persist (e.g.
    SharedPreferences write failure)."
  - Do NOT change the AppBar, the `Scaffold.body`, the two `Padding +
    Header + Selector` groups, or any other rendering. The `_GroupHeader`
    pattern (if present — currently the file uses inline `Text` widgets)
    stays unchanged.

- In `test/features/settings/presentation/screens/settings_screen_test.dart`:
  - Replace the existing `_FakeSettingsRepository` (lines 13–33) with a
    richer fake that has the same shape as the one in
    `settings_provider_test.dart`:
    ```dart
    class _FakeSettingsRepository implements SettingsRepository {
      AppSettings _settings = const AppSettings();

      bool failOnSaveThemeMode = false;
      bool failOnSaveUseSystemTheme = false;
      bool failOnSaveUseSystemLanguage = false;
      bool failOnSaveManualLanguage = false;

      @override
      AppSettings load() => _settings;

      @override
      Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async {
        if (failOnSaveThemeMode) return const Left(CacheFailure('mock failure'));
        _settings = _settings.copyWith(manualThemeMode: mode);
        return const Right(null);
      }
      // ... three more save methods, same shape ...
    }
    ```
    Add the import `package:dosly/core/error/failures.dart`.
  - Update `_harness` to accept an optional `_FakeSettingsRepository`
    parameter so individual tests can configure failures while existing
    locale tests pass through the default (always-success) instance.
    Signature: `Widget _harness({required Locale locale, _FakeSettingsRepository? fakeRepo})`. Default to `fakeRepo ??= _FakeSettingsRepository()`.
  - Add a new `group('SettingsScreen error SnackBar', () { ... })` with
    one test:
    ```dart
    testWidgets('shows localized error SnackBar when setUseSystemTheme fails', (tester) async {
      final fakeRepo = _FakeSettingsRepository()..failOnSaveUseSystemTheme = true;
      await tester.pumpWidget(_harness(locale: const Locale('en'), fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Tap the "Use system theme" SwitchListTile to trigger setUseSystemTheme.
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });
    ```
    Note: do not use `pumpAndSettle()` for the SnackBar phase — its enter
    animation never settles within a single frame, and `pumpAndSettle`
    waits indefinitely.
  - Existing groups (`SettingsScreen locale switching`,
    `SettingsScreen appearance header`, `SettingsScreen AppBar shape`,
    `SettingsScreen language header`) must continue to pass without
    modification.

## Done when

- [x] `settings_screen.dart` declares `class SettingsScreen extends ConsumerWidget`.
- [x] `settings_screen.dart`'s `build` has signature `Widget build(BuildContext context, WidgetRef ref)`.
- [x] `settings_screen.dart` imports `flutter_riverpod`, `core/error/failures.dart`, and the local `settings_provider.dart`.
- [x] `settings_screen.dart` contains the literal expression `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider`.
- [x] `settings_screen.dart` contains `behavior: SnackBarBehavior.floating`.
- [x] `settings_screen.dart` contains `Text(context.l10n.settingsPersistenceError)`.
- [x] `settings_screen_test.dart` has a `group('SettingsScreen error SnackBar', ...)` with at least 1 `testWidgets` block.
- [x] `settings_screen_test.dart`'s `_FakeSettingsRepository` declares 4 `failOnSaveX` boolean fields.
- [x] `flutter test test/features/settings/` passes (all existing tests + 6 new tests from Task 002 + 1 new test from Task 003).
- [x] `flutter test` passes (full suite, no regressions in other features).
- [x] `flutter build apk --debug` succeeds.
- [x] `dart analyze` passes on the two changed files with zero issues.
- [x] No new `!` null-assertion sites introduced (grep `lib/features/settings/presentation/screens/settings_screen.dart` for `!` and confirm no new uses).

## Spec criteria addressed

AC-9, AC-10, AC-11, AC-12, AC-13, AC-14.

## Contracts

### Expects
- (from Task 001) `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` contain `settingsPersistenceError` with the values specified in spec §3.
- (from Task 001) `lib/l10n/app_localizations.dart` declares the abstract getter `String get settingsPersistenceError;`.
- (from Task 002) `lib/features/settings/presentation/providers/settings_provider.dart` exports the top-level constant `settingsErrorsProvider` of type `StreamProvider<Failure>`.
- (from Task 002) The expression `ref.watch(settingsProvider.notifier).errors` returns `Stream<Failure>`.
- `lib/l10n/l10n_extensions.dart` exposes `BuildContext.l10n` returning `AppLocalizations` (already true — used in existing screen).
- `MaterialApp` already wires `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales` (already true via `lib/app.dart`).

### Produces
- `class SettingsScreen extends ConsumerWidget` is declared in `settings_screen.dart`.
- The `build` method has the literal signature `Widget build(BuildContext context, WidgetRef ref)`.
- The literal substring `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider` appears in `settings_screen.dart`.
- The literal substring `SnackBarBehavior.floating` appears in `settings_screen.dart`.
- The literal substring `context.l10n.settingsPersistenceError` appears in `settings_screen.dart`.
- `settings_screen_test.dart` declares a private class `_FakeSettingsRepository` with fields `failOnSaveThemeMode`, `failOnSaveUseSystemTheme`, `failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage`, all `bool` defaulting to `false`.
- `settings_screen_test.dart` contains a `group` whose first argument is the literal string `'SettingsScreen error SnackBar'`.
- `flutter test` passes.
- `flutter build apk --debug` exits 0.
