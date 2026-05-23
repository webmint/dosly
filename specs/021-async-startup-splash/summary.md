## Feature Summary: 021 — Async Startup Splash & Prefs-Failure Recovery

### What was built
App startup is now non-blocking: instead of freezing on a black launch screen while preferences load (and staying frozen forever if that load stalled or the prefs store was corrupt), the app shows a themed splash while it hydrates and a recoverable "couldn't load preferences" screen with a Retry button if hydration fails. Satisfies constitution §4.2.1 ("never block `main()` on async work") and closes Bug 013.

### Changes
- Task 001: Add l10n strings — added `splashLoading`, `prefsLoadErrorMessage`, `prefsLoadRetry` to en/de/uk and regenerated gen_l10n.
- Task 002: Init provider + locale resolver — added async `sharedPreferencesInitProvider`; extracted the English-fallback locale policy into a shared `resolveAppLocale`.
- Task 003: Splash + error widgets — built `SplashScreen` (surface-colored, spinner) and `PrefsLoadErrorScreen` (message + Retry callback).
- Task 004: AppBootstrap + main — made `main()` synchronous; added `AppBootstrap` that gates the real app on async prefs load and nests a `ProviderScope` override on success; 4 widget tests.
- Task 005: Docs + bug closure — updated the architecture Bootstrap section + provider table; marked Bug 013 Fixed.

### Files changed
- `lib/` (entry/root) — `main.dart` rewritten, `app.dart` updated, `app_bootstrap.dart` added
- `lib/core/` — `providers/shared_preferences_provider.dart` (+ async provider), `l10n/locale_resolver.dart` added, `widgets/` 2 added (splash, error)
- `lib/l10n/` — 3 ARBs updated + regenerated localizations
- `test/` — `app_bootstrap_test.dart` added (4 tests)
- `docs/`, `bugs/` — architecture doc updated, Bug 013 closed
- [Total: 32 files changed, 1429 insertions, 94 deletions — incl. specs/generated]

### Key decisions
- Async seam: a separate function-form `@riverpod` `sharedPreferencesInitProvider` (Future), leaving the synchronous throwing `sharedPreferencesProvider` untouched — preserves the settings tree's sync-read contract and gives a clean test seam (no static mocking).
- Override relocation: `sharedPreferencesProvider.overrideWithValue(prefs)` moved from `main()` into `AppBootstrap`'s data branch (nested `ProviderScope`) — zero changes to `lib/features/settings/**`.
- Single `MaterialApp` invariant: loading/error use a plain themed `MaterialApp` shell, data uses `DoslyApp`'s `MaterialApp.router`; mutually exclusive branches avoid any double-Navigator hazard.
- Splash theming: bootstrap shell uses `ThemeMode.system` + `AppTheme` so the splash respects device brightness (minimizes light→dark flash).

### Deviations from plan
- Task 002: `build_runner` also regenerated `app_router.g.dart`'s provider hash (benign, unrelated to the change).
- Task 004: tests use `InMemorySharedPreferencesAsync` (the async platform mock) rather than `setMockInitialValues` to build a real `SharedPreferencesWithCache`; code review added a positive `find.byType(DoslyApp)` assertion to the retry test.

### Acceptance criteria
- [x] AC-1: `main()` has no await before `runApp`
- [x] AC-2: normal launch reaches `DoslyApp` with settings applied
- [x] AC-3: hydration failure shows the error screen, never a frozen/blank screen
- [x] AC-4: Retry recovers to `DoslyApp` when the failure clears
- [x] AC-5: splash shows a progress indicator on a `colorScheme.surface` background
- [x] AC-6: theme/locale behavior unchanged once prefs resolve
- [x] AC-7: 3 new strings present in en/de/uk, read via `context.l10n`
- [x] AC-8: `lib/features/settings/**` unchanged
- [x] AC-9: no `print`/`debugPrint`; `dart analyze` clean; `flutter test` passes (230)
- [x] AC-10: architecture docs updated, Bug 013 marked Fixed
