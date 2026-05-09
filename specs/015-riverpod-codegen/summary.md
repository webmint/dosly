## Feature Summary: 015 — Adopt `@riverpod` Codegen Across All Manual Providers

### What was built

Brings the codebase into compliance with constitution §4.1.1 by migrating all four hand-rolled Riverpod providers (`sharedPreferencesProvider`, `settingsRepositoryProvider`, `settingsProvider`, `settingsErrorsProvider`) to `@riverpod` codegen, and wires the missing `riverpod_annotation` / `riverpod_generator` packages into `pubspec.yaml`. Pure compile-time refactor — no runtime behavior change. Closes bug 004.

### Changes

- **Task 001**: Added `riverpod_annotation: ^4.0.2` (runtime) and `riverpod_generator: ^4.0.3` (dev) via `flutter pub add`; smoke-tested the codegen pipeline on the unchanged codebase.
- **Task 002**: Migrated `sharedPreferencesProvider` to `@Riverpod(keepAlive: true)` function form; verified `lib/main.dart`'s startup override continues to compile against the codegen-emitted symbol without any edit.
- **Task 003**: Migrated the three settings providers (`settingsRepository`, `SettingsNotifier` class form, `settingsErrors`) to `@riverpod`; renamed `settingsProvider` → `settingsNotifierProvider` across all production widgets, the theme-preview screen, the domain-entity dartdoc, and ~20 test sites.
- **Task 004**: Renamed 8 stale `settingsProvider` references in `docs/architecture.md`, refreshed the provider-wiring table to reflect codegen-emitted types, added a `### Riverpod codegen` subsection documenting the `build_runner` invocation and the `Notifier`-suffix-stripping quirk, and closed bug 004 with a Resolution section.

### Files changed

- `pubspec.yaml`, `pubspec.lock` — 2 deps added; 4 transitives + 3 analyzer-stack downgrades resolved by pub
- `lib/core/providers/` — 1 file modified, 1 generated `.g.dart` added
- `lib/features/settings/presentation/providers/` — 1 file modified, 1 generated `.g.dart` added
- `lib/features/settings/{presentation/widgets,domain/entities}/` — 3 files (rename + 1 dartdoc-only)
- `lib/{app.dart,features/theme_preview/presentation/screens/}` — 2 files (rename only)
- `test/features/settings/presentation/providers/` — 1 file (~20 rename sites)
- `docs/{architecture.md,features/i18n.md,features/settings.md,features/theme.md}` — 4 markdown files (rename + table refresh + new subsection)
- `bugs/004-manual-providers-missing-riverpod-codegen.md` — Status: Fixed; Resolution section
- `specs/015-riverpod-codegen/` — spec, plan, 4 task files, README, review, verify, summary
- `research/2026-05-08-bug-004-riverpod-codegen.md` — pre-spec research report

Total: 29 files changed, 1670 insertions, 133 deletions.

### Key decisions

- **`SettingsNotifier` lifetime**: `@Riverpod(keepAlive: true)` (NOT default autoDispose) — preserves the implicit non-autoDispose semantics of the original `NotifierProvider<>` and keeps the `_errors` `StreamController` alive across sequential test reads.
- **`settingsErrorsProvider` lifetime**: default `@riverpod` (autoDispose) — re-subscribes to the broadcast stream on the kept-alive notifier when `SettingsScreen` mounts; failures emitted while no listener is subscribed are intentionally not buffered (event-driven, not state).
- **Symbol naming**: `settingsNotifierProvider` (not `settingsProvider`) — required by the canonical class-form codegen idiom; the `name: 'settingsNotifierProvider'` annotation parameter is load-bearing because Riverpod codegen strips the `Notifier` suffix from class names before appending `Provider`.
- **`sharedPreferencesProvider` lifetime**: explicit `@Riverpod(keepAlive: true)` — documents intent for the startup-injected singleton, even though the override holds it alive transitively.

### Deviations from plan

- **Task 003 — `SettingsNotifier` annotation**: Plan recommended default `@riverpod` (autoDispose). Implementation uses `@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')` for two reasons surfaced during execution: (1) default autoDispose breaks "multiple sequential emissions" tests by closing/recreating the `StreamController` between reads; (2) codegen strips `Notifier` suffix, so the `name:` parameter is required to emit the canonical symbol. Verified appropriate by code review.
- **Task 004 — doc rename scope**: Tech-writer agent additionally renamed `settingsProvider` → `settingsNotifierProvider` in `docs/features/{i18n,settings,theme}.md` (3 files beyond the named scope). Code review verified this was the right call — leaving them stale would have created the doc-vs-code drift the project explicitly flags as a pitfall.

### Acceptance criteria

- [x] AC-1: `pubspec.yaml` declares `riverpod_annotation` + `riverpod_generator`
- [x] AC-2: `shared_preferences_provider.dart` uses `@Riverpod(keepAlive: true)`
- [x] AC-3: `settings_provider.dart` declares 3 providers via `@riverpod`
- [x] AC-4: Both `.g.dart` files generated and committed
- [x] AC-5: All production consumers renamed to `settingsNotifierProvider`
- [x] AC-6: All test consumers renamed
- [x] AC-7: `app_settings.dart` line 24 dartdoc references `settingsNotifierProvider`
- [x] AC-8: `lib/main.dart` semantics preserved (file unchanged)
- [x] AC-9: `SettingsNotifier` public surface byte-equivalent
- [x] AC-10: `dart analyze` clean
- [x] AC-11: `flutter test` passes (203/203)
- [x] AC-12: `flutter build apk` succeeds (52.9 MB release APK)
- [x] AC-13: Bug 004 closed (Status: Fixed, Fixed: 2026-05-09)
- [x] AC-14: `docs/architecture.md` codegen note added
