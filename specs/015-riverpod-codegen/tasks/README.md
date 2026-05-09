# Tasks: Adopt `@riverpod` Codegen Across All Manual Providers

**Spec**: `specs/015-riverpod-codegen/spec.md`
**Plan**: `specs/015-riverpod-codegen/plan.md`
**Generated**: 2026-05-08
**Total tasks**: 4
**Status**: All tasks Complete (4/4) | Verified 2026-05-09 — all 14 ACs PASS, all gates green, APPROVED
**Closes**: bug 004

## Dependency Graph

```
001 (pubspec deps) ──→ 002 (shared_prefs migration) ──→ 003 (settings cluster + rename) ──→ 004 (docs + bug close)
```

Strictly linear — each task depends on the previous one. Task 002 needs Task 001's deps to run `build_runner` against `@riverpod` annotations. Task 003 needs Task 002's pattern as the exemplar to copy and needs the shared-prefs migration done so the `settingsRepository` function can `ref.watch(sharedPreferencesProvider)` against the codegen symbol. Task 004 needs the post-migration source state to document.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add `riverpod_annotation` + `riverpod_generator` to pubspec | architect | None | Complete |
| 002 | Migrate `sharedPreferencesProvider` to `@Riverpod(keepAlive: true)` | architect | 001 | Complete |
| 003 | Migrate settings cluster + rename `settingsProvider` → `settingsNotifierProvider` | mobile-engineer | 001, 002 | Complete |
| 004 | Update `docs/architecture.md` and close bug 004 | tech-writer | 001, 002, 003 | Complete |

## Additions to Spec

- `docs/architecture.md` rename scope expanded beyond what the spec's AC-14 explicitly captured. Spec AC-14 reads: "`docs/architecture.md` includes a brief codegen-pattern note that mentions the `build_runner` invocation and points to the new providers as the exemplars." Plan and Task 004 expand this to also include rename of 8 existing `settingsProvider` references in the doc (prose + code snippet + provider-wiring table) — necessary to keep documentation honest with the renamed source. This is captured in the plan's "Documentation Impact" section as a discovered scope addition. AC-14's spirit is "docs match code"; Task 004 satisfies it fully.
- `lib/features/settings/domain/entities/app_settings.dart` line 24 dartdoc rename was named in Spec AC-7; included in Task 003 (mechanical alongside the source-code consumer renames since the file is in the rename radius).
- No new files outside the spec's Affected Areas were discovered.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Two `flutter pub add` invocations + smoke test. The only real risk is version compatibility between `riverpod_annotation`/`riverpod_generator` and the pinned `flutter_riverpod ^3.3.1` — same maintainer publishes the trio in lockstep, so this is unlikely. Mitigation is in the task: stop and reconcile if pub resolution conflicts. |
| 002 | Low | First `@riverpod` exemplar — but the throwing-placeholder pattern is documented in Riverpod 3.x docs (Context7-verified in research) and is one of the simplest possible migrations (a single function with a `throw`). The `lib/main.dart` `overrideWithValue` mechanism survives because the codegen-emitted symbol name is identical. |
| 003 | Med | Largest task — touches 8 files (mostly mechanical rename, one file with substantive provider-class migration). First class-form `@riverpod` notifier in the codebase. Integration-gate task (full `flutter test` + `flutter build apk --debug`). Risk surfaces: (a) `_$SettingsNotifier` superclass behavioral parity with `Notifier<AppSettings>` — codegen 3.x is well-documented; (b) widespread rename across production + tests — `grep -rn "settingsProvider\b"` post-rename catches misses. |
| 004 | Low | Pure markdown edits. Front-matter flip + 1-paragraph doc addition + table refresh + 8-site rename. No compile or test surface. |

## Review Checkpoints

| Before Task | Reason | What to Verify |
|-------------|--------|----------------|
| 001 | Pre-task — first `riverpod_generator` integration; version compatibility is the highest-likelihood risk | (a) `flutter_riverpod` version pin in `pubspec.yaml` is on the 3.x line; (b) `build_runner` toolchain exists from feature 012; (c) `analysis_options.yaml` already excludes `**/*.g.dart` |
| 002 | First `@riverpod` exemplar — Task 003 copies this pattern, so it must be right before downstream | (a) Task 001's `pubspec.yaml` deps resolved; (b) `lib/main.dart`'s `sharedPreferencesProvider.overrideWithValue(prefs)` shape is known and unchanged |
| 003 | Convergence point (depends on 001 + 002); first class-form `@riverpod` notifier; integration gate | (a) Task 002's `shared_preferences_provider.g.dart` exists and exports `sharedPreferencesProvider`; (b) the throwing-placeholder pattern from Task 002 generalizes correctly to class-form via codegen; (c) `SettingsNotifier`'s public surface (build, four setX methods, errors getter) is enumerated in this task's Contracts so the migration preserves byte-equivalence |
| 004 | Final convergence — gates the feature for `/review` → `/verify` | (a) `grep -rn "settingsProvider\b" lib/ test/` returns zero matches (Task 003's verification); (b) `dart analyze` and `flutter test` are clean; (c) source code is final (no pending edits) |

## Contract Chain Integrity

- **Task 001 Produces** → consumed by Task 002 Expects: `pubspec.yaml` lists `riverpod_annotation` + `riverpod_generator`. ✓
- **Task 001 Produces** → maps to spec AC-1. ✓
- **Task 002 Produces** → consumed by Task 003 Expects: `lib/core/providers/shared_preferences_provider.g.dart` exports `sharedPreferencesProvider` (referenced by Task 003's `settingsRepository` function). ✓
- **Task 002 Produces** → maps to spec ACs 2, 8 (and partial 4, 10, 11). ✓
- **Task 003 Produces** → consumed by Task 004 Expects: source state final, all `settingsProvider` references renamed in `lib/` and `test/`. ✓
- **Task 003 Produces** → maps to spec ACs 3, 4 (full), 5, 6, 7, 9, 10, 11, 12. ✓
- **Task 004 Produces** → maps to spec ACs 13, 14. ✓
- **No orphaned Produces, no unsatisfied Expects.**

## Spec Acceptance Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 (deps in pubspec) | 001 |
| AC-2 (`shared_preferences_provider.dart` migrated) | 002 |
| AC-3 (`settings_provider.dart` migrated) | 003 |
| AC-4 (both `.g.dart` files generated and committed) | 002 (shared_prefs `.g.dart`), 003 (settings `.g.dart`) |
| AC-5 (production rename `settingsProvider` → `settingsNotifierProvider`) | 003 |
| AC-6 (test rename) | 003 |
| AC-7 (`app_settings.dart` dartdoc rename) | 003 |
| AC-8 (`main.dart` semantics preserved) | 002 (verifies; no edit) |
| AC-9 (`SettingsNotifier` public surface unchanged) | 003 (preserved verbatim during migration) |
| AC-10 (`dart analyze` clean) | 001, 002, 003 (each task verifies) |
| AC-11 (`flutter test` passes) | 001, 002, 003 (each task verifies) |
| AC-12 (`flutter build apk` succeeds) | 003 (integration gate) |
| AC-13 (bug 004 closed) | 004 |
| AC-14 (`docs/architecture.md` codegen note) | 004 |

All 14 ACs are covered by at least one task.
