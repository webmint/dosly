## Feature Summary: 009 — Theme Settings

### What was built
The Settings screen now lets users control the app theme. A "Use system theme" toggle follows the device setting by default. When turned off, a Light/Dark segmented button lets the user pick manually — pre-selecting whichever theme the device was using for a seamless transition. The choice persists across app restarts via SharedPreferences.

### Changes
- Task 1: Add dependencies and core infrastructure — added `flutter_riverpod`, `shared_preferences`, `fpdart`; created `Failure` sealed class and `SharedPreferencesWithCache` provider
- Task 2: Create settings domain layer — `AppSettings` entity with `useSystemTheme` + `manualThemeMode` fields, `SettingsRepository` abstract interface
- Task 3: Create settings data layer — `SettingsLocalDataSource` wrapping SharedPreferences, `SettingsRepositoryImpl` with Either error handling
- Task 4: Create settings provider and wire app root — Riverpod `SettingsNotifier`, async `main()` with `ProviderScope`, `DoslyApp` converted to `ConsumerWidget`
- Task 5: Add localization keys and build Settings UI — 5 new ARB keys (en/uk/de), `ThemeSelector` widget with SwitchListTile + SegmentedButton
- Task 6: Retire ThemeController and fix all tests — deleted singleton, updated ThemePreviewScreen + 4 test files to use ProviderScope
- Task 7: Write settings feature tests — repository, provider, and widget tests
- UX rework: Replaced 3-segment SegmentedButton with toggle + 2-segment pattern per user feedback
- Review fixes: `.select()` scoping in app.dart, kDebugMode-guarded logging, test gap coverage

### Files changed
- `lib/core/` — 3 files (1 deleted, 2 created: failures.dart, shared_preferences_provider.dart)
- `lib/features/settings/` — 7 files (1 modified, 6 created: domain/data/presentation layers)
- `lib/features/theme_preview/` — 1 file modified (ConsumerWidget migration)
- `lib/` root — 2 files modified (main.dart, app.dart)
- `lib/l10n/` — 7 files modified (3 ARB + 4 generated)
- `test/` — 7 files (3 created, 3 modified, 1 deleted)
- Total: 47 files changed, 2820 insertions, 176 deletions

### Key decisions
- **Codegen deferred**: freezed/riverpod_generator not installed — hand-written Notifier + immutable class for a one-field settings model; adopt codegen with first data-heavy feature
- **SharedPreferencesWithCache**: Blocking init in `main()` before `runApp()` — synchronous reads after init, zero theme flash
- **ThemeController fully retired**: Replaced ValueNotifier singleton with Riverpod, eliminating split state management
- **Toggle + 2-segment UX**: Progressive disclosure — system toggle is the zero-effort default, manual Light/Dark only visible when needed

### Acceptance criteria
- [x] AC-1: Localized "Appearance" subheader with M3 group title styling
- [x] AC-2: SwitchListTile + 2-segment SegmentedButton with localized labels
- [x] AC-3: Default is system theme on fresh install
- [x] AC-4: Theme changes immediately on interaction
- [x] AC-5: Selection persists across app restarts
- [x] AC-6: Extensible AppSettings model with copyWith
- [x] AC-7: Clean Architecture: domain → data → presentation via Riverpod
- [x] AC-8: All strings localized in en/uk/de
- [x] AC-9: dart analyze — zero issues
- [x] AC-10: flutter test — 136 tests pass
- [x] AC-11: flutter build apk --debug succeeds
