# Task 004: Wire AppBootstrap, rewrite main(), add bootstrap tests

**Agent**: mobile-engineer
**Files**: `lib/app_bootstrap.dart` (new), `lib/main.dart`, `test/app_bootstrap_test.dart` (new)
**Depends on**: 002, 003
**Blocks**: 005
**Context docs**: `docs/architecture.md` (Bootstrap section)
**Review checkpoint**: Yes
**Status**: Complete

## Description

The integration + convergence point. Make `main()` non-blocking and introduce `AppBootstrap` as the new root widget that gates the real app on async prefs hydration. This is the highest-risk task (spec Risk #1 — double-`MaterialApp` nesting; main rewrite; async test timing), so it carries a review checkpoint.

**`AppBootstrap`** (a `ConsumerWidget`) watches `sharedPreferencesInitProvider` and renders three mutually exclusive branches:
- **loading** → a bootstrap `MaterialApp` shell wrapping `SplashScreen`.
- **error** → the same shell wrapping `PrefsLoadErrorScreen(onRetry: () => ref.invalidate(sharedPreferencesInitProvider))`.
- **data(prefs)** → `ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const DoslyApp())` — no shell, because `DoslyApp` brings its own `MaterialApp.router`. Only one `MaterialApp` is ever mounted at a time.

The **bootstrap shell** is a plain `MaterialApp` (not `.router`) carrying `AppLocalizations.localizationsDelegates`, `supportedLocales`, `localeResolutionCallback: resolveAppLocale`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: ThemeMode.system`, `debugShowCheckedModeBanner: false`, and `home:` set to the splash or error widget. `ThemeMode.system` makes the splash respect device brightness (minimizes theme flash, spec Risk #3).

**`main()`** becomes synchronous: `WidgetsFlutterBinding.ensureInitialized()` then `runApp(const ProviderScope(child: AppBootstrap()))`. No `async`, no `await`, no override (the override moved into `AppBootstrap`'s data branch).

## Change details

- Create `lib/app_bootstrap.dart`:
  - Library dartdoc explaining the non-blocking startup flow and why the data branch nests a `ProviderScope` (preserves the synchronous `sharedPreferencesProvider` contract for the settings tree).
  - `class AppBootstrap extends ConsumerWidget`; `build` does `ref.watch(sharedPreferencesInitProvider).when(loading:, error:, data:)` as described above.
  - Extract the shell into a small private helper (e.g. `_bootstrapShell(Widget home)`) to avoid duplicating the `MaterialApp` config between the loading and error branches.
- In `lib/main.dart`:
  - Remove `async`; drop the `await SharedPreferencesWithCache.create(...)` and the `sharedPreferencesProvider.overrideWithValue` override.
  - Body: `WidgetsFlutterBinding.ensureInitialized();` then `runApp(const ProviderScope(child: AppBootstrap()));`.
  - Update imports (remove `shared_preferences`/provider import if now unused; add `app_bootstrap.dart`).
- Create `test/app_bootstrap_test.dart` (flutter_test + ProviderScope overrides):
  - **error branch**: override `sharedPreferencesInitProvider` with a failing future (`overrideWith((ref) => Future<SharedPreferencesWithCache>.error(Exception('boom')))`); pump; assert `PrefsLoadErrorScreen` / the localized error text and Retry button are shown, and no exception escapes to a black screen.
  - **retry recovery**: start failing, tap Retry, then with a succeeding override assert the app proceeds (no error screen). (Use a mutable override or a second pump with a success override per the project's test conventions.)
  - **normal launch**: override with a succeeding `SharedPreferencesWithCache` (or a real instance via `SharedPreferences.setMockInitialValues({})`); pump-and-settle; assert `DoslyApp` / `MaterialApp` reaches the data branch.
  - **splash**: in the loading frame assert a `CircularProgressIndicator` is present (single pump, before settle).
  - Assert exactly one `MaterialApp`/`Navigator` is mounted in each phase (defuses the double-`MaterialApp` risk).

## Contracts

### Expects
- `lib/core/providers/shared_preferences_provider.dart` (via `.g.dart`) exposes `sharedPreferencesInitProvider` (Task 002) and the synchronous `sharedPreferencesProvider`.
- `lib/core/l10n/locale_resolver.dart` exports `resolveAppLocale` (Task 002).
- `lib/core/widgets/splash_screen.dart` exports `SplashScreen`; `lib/core/widgets/prefs_load_error_screen.dart` exports `PrefsLoadErrorScreen` with a required `onRetry` (Task 003).
- `lib/app.dart` exports `DoslyApp`.

### Produces
- `lib/app_bootstrap.dart` declares `class AppBootstrap extends ConsumerWidget`; its `build` calls `ref.watch(sharedPreferencesInitProvider)`, the data branch returns a `ProviderScope` with `sharedPreferencesProvider.overrideWithValue`, the error branch builds `PrefsLoadErrorScreen` with `onRetry: () => ref.invalidate(sharedPreferencesInitProvider)`, the loading branch builds `SplashScreen`, and the shell `MaterialApp` passes `localeResolutionCallback: resolveAppLocale`.
- `lib/main.dart` declares `void main()` (no `async`) whose body calls `runApp(const ProviderScope(child: AppBootstrap()))` and contains no `await`.
- `test/app_bootstrap_test.dart` exists and overrides `sharedPreferencesInitProvider`.

## Done when
- [x] `main()` has no `await` (and no `async`) before `runApp`; it runs `AppBootstrap` inside a `ProviderScope`.
- [x] Failing `sharedPreferencesInitProvider` renders `PrefsLoadErrorScreen` (localized message + Retry) — never a frozen/blank screen.
- [x] Tapping Retry re-invokes the initializer; with a succeeding override the app reaches `DoslyApp`.
- [x] Normal launch reaches the data branch with settings applied as before.
- [x] Exactly one `MaterialApp` is mounted per phase (asserted in test).
- [x] No `print`/`debugPrint` introduced.
- [x] `dart analyze` passes; `flutter test` passes; `flutter build apk --debug` succeeds (integration verification point).

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-8, AC-9

## Completion Notes
**Completed**: 2026-05-23
**Files changed**: lib/app_bootstrap.dart (new), lib/main.dart (rewrite), test/app_bootstrap_test.dart (new)
**Contract**: Expects [5/5 verified] | Produces [3/3 verified]
**Notes**: main() synchronous, no await before runApp. Mutually-exclusive `.when()` branches keep exactly one MaterialApp mounted; data branch nests a ProviderScope override so lib/features/settings/** is untouched. Tests use InMemorySharedPreferencesAsync (not setMockInitialValues) for a real prefs instance, and override settingsRepositoryProvider (inherited by nested scope) so DoslyApp inflates. Independently verified: dart analyze clean, 230 tests pass, apk built. Code review: APPROVE with warnings — one warning (retry test weak negative assertion) fixed in-task by adding `expect(find.byType(DoslyApp), findsOneWidget)`.
