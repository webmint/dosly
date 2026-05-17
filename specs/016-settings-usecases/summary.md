# Feature Summary: 016 — Settings use cases

## What was built

Introduced a `lib/features/settings/domain/usecases/` layer with five callable use cases that mediate every Settings mutation between `SettingsNotifier` and `SettingsRepository`. The cross-cutting "switch-to-manual must pre-fill from device" rule moves out of two selector widgets and into atomic use cases, the triplicated `AppLanguage.values.firstWhere(orElse: en)` literal collapses to a single `AppLanguage.fromLanguageCodeOrDefault` helper, and the `theme_preview` cycle rule moves to a `CycleThemeMode` use case so no presentation file owns Settings business rules. Closes bugs 005 and 011 with no user-visible behavior change.

## Changes

- **Task 001** — `AppLanguage.fromLanguageCodeOrDefault` static factory + adopted in `settings_local_data_source.dart` (collapses 3 `firstWhere` literals to 1)
- **Task 002** — `SetThemeMode` + `SetManualLanguage` pass-through use cases (mirroring constitution §7's `AddMedication` template)
- **Task 003** — `SetUseSystemTheme` + `SetUseSystemLanguage` atomic two-write use cases (pre-fill manual override, then toggle, short-circuit on first Left)
- **Task 004** — `CycleThemeMode` use case encoding `system → light → dark → system`; Right carries a `({bool useSystemTheme, AppThemeMode manualThemeMode})` Dart record so the notifier can `state.copyWith(...)` without re-deriving the rule
- **Task 005** — Wired 5 `@riverpod` function-form use case providers; rewrote `SettingsNotifier`'s 4 mutators to delegate exclusively through them; added `cycleThemeMode()` notifier method
- **Task 006** — Simplified `theme_selector.dart` + `language_selector.dart` toggle callbacks to single notifier calls; `theme_preview_screen.dart` cycle delegated to notifier; widget tests adapted; full integration gate (`flutter test` 227/227 + `flutter build apk --debug`)
- **Task 007** — Docs updated (`docs/features/settings.md` Use cases subsection + simplified selector subsections); bugs 005 + 011 closed
- **Post-/review followup** — Narrow `ref.watch(provider.select((s) => s.field))` in the three widgets touched by Task 006 (resolves 3 Medium performance findings)

## Files changed

- `lib/features/settings/domain/usecases/` — 5 files added (185 lines net)
- `lib/features/settings/domain/entities/` — 1 file modified (helper added)
- `lib/features/settings/data/datasources/` — 1 file modified
- `lib/features/settings/presentation/providers/` — 1 file modified + 1 regenerated `.g.dart`
- `lib/features/settings/presentation/widgets/` — 2 files modified
- `lib/features/theme_preview/presentation/screens/` — 1 file modified
- `test/features/settings/domain/usecases/` — 5 test files added
- `test/features/settings/domain/entities/` — 1 test file added
- `test/features/settings/presentation/providers/` — 1 test file modified
- `pubspec.yaml` + `pubspec.lock` — `mocktail: ^1.0.4` dev dependency added
- `docs/features/settings.md` — Use cases subsection + selector cleanup + spec 016 link
- `bugs/005-...md`, `bugs/011-...md` — Status: Closed, Fixed: 2026-05-10
- `specs/016-settings-usecases/` — spec, plan, 7 tasks, README, research link, review.md, verify.md

Total: 40 files changed, 2948 insertions, 142 deletions (specs + research + docs included)

## Key decisions

- **Use case wiring shape**: callable `class FooUseCase { const FooUseCase(this._repo); ... Future<Either<Failure, T>> call(...) }` exposed via function-form `@riverpod` providers — mirrors constitution §7's `AddMedication` example and the project's post-spec-015 codegen standard
- **Atomic pre-fill ordering**: pre-fill manual override BEFORE flipping the toggle, short-circuit on first Left — verified by `verifyInOrder` in unit tests. Reverse order would leave a half-applied state on persistence failure
- **`CycleThemeMode` return type**: refined from spec §3.1's `Future<Either<Failure, void>>` to `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>` so the notifier applies cycled state via `state.copyWith` without re-deriving the cycle rule (which would have duplicated bug 011 in a new location)
- **Notifier signature change**: `setUseSystemTheme` / `setUseSystemLanguage` gained `required` named parameters (`currentDeviceMode` / `currentDeviceLanguage`) — widgets resolve device values from `MediaQuery` / `Localizations` and pass them through. Avoids putting `BuildContext` in the notifier

## Deviations from plan

- **`CycleThemeMode` return type refined** (Task 004): from `void` to a `({bool useSystemTheme, AppThemeMode manualThemeMode})` Dart record on Right. Documented in `/plan` "Key Design Decisions", `/breakdown` "Additions to Spec", and the task's completion notes. Behavioral contract (AC-7's three transitions) preserved
- **`mocktail` dev dep added inline** (Task 002): edited `pubspec.yaml` directly rather than `flutter pub add --dev mocktail` (constitution §2.3 prefers the latter). End state identical
- **AC-19 / Affected Areas date corrected** (Task 007): spec was drafted 2026-05-09 anticipating same-day completion; multi-task run extended into 2026-05-10. Bug front-matter follows real fix-landing date; spec text was aligned forward during the docs/bookkeeping task

## Acceptance criteria

- [x] AC-1: `usecases/` contains exactly 5 files
- [x] AC-2: No `package:flutter`/`flutter_riverpod`/`drift` imports in `usecases/`
- [x] AC-3: Each use case is callable with `const` ctor + `Future<Either<Failure, T>>`
- [x] AC-4: `SetUseSystemTheme(false, X)` writes `saveThemeMode` then `saveUseSystemTheme`, short-circuits
- [x] AC-5: `SetUseSystemTheme(true, X)` writes only `saveUseSystemTheme`
- [x] AC-6: `SetUseSystemLanguage` symmetric
- [x] AC-7: `CycleThemeMode` produces `system → light → dark → system`
- [x] AC-8: Notifier mutators reach repo only via use case providers (Implementation Deviation note for the grep-count prescription — see verify.md)
- [x] AC-9: `theme_selector.dart` toggle `onChanged` has 1 notifier call
- [x] AC-10: `language_selector.dart` toggle `onChanged` has 1 notifier call
- [x] AC-11: `theme_preview_screen.dart` cycle `onPressed` has 1 call, no if/else
- [x] AC-12: `AppLanguage.fromLanguageCodeOrDefault` covers known/unknown/empty codes
- [x] AC-13: `AppLanguage.values.firstWhere` appears exactly once (in helper)
- [x] AC-14: `dart analyze` exits 0
- [x] AC-15: `flutter test` passes (227/227)
- [x] AC-16: `flutter build apk --debug` exits 0
- [x] AC-17: User-visible pre-fill behavior unchanged
- [x] AC-18: Persistence-failure surface unchanged (errors → SnackBar)
- [x] AC-19: Bugs 005 + 011 closed, Fixed: 2026-05-10
- [x] AC-20: `docs/features/settings.md` describes use case layer; selector subsections cleaned
