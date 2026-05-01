# Tasks: Settings Domain Purify

**Spec**: [../spec.md](../spec.md) (Complete 2026-04-30)
**Plan**: [../plan.md](../plan.md) (Approved 2026-04-30)
**Generated**: 2026-04-30
**Total tasks**: 5
**Status**: All 5 tasks Complete · `/verify` APPROVED 2026-04-30 · ready for `/summarize` → `/finalize`

## Completion Summary

| Metric | Value |
|---|---|
| Tasks executed | 5 of 5 |
| Files changed | 25 (12 source + 9 test + 3 doc + 1 pubspec) |
| Lines net | +428 / -133 across source, +280 generated `*.freezed.dart` |
| Test count | 184 → 196 (+12) |
| `dart analyze` | 0 issues |
| `flutter build apk --debug` | PASS |
| `/review` verdict | security PASS · performance PASS · tests ADEQUATE |
| `/verify` verdict | APPROVED — 16/16 automated ACs PASS; AC-17 manual deferred |
| Defects caught + fixed during execution | 3 (constitution drift in `analysis_options.yaml`; freezed 3.x `abstract` keyword; legacy-int crash in `getThemeMode()`) |

## Dependency Graph

```
001 (codegen pipeline) ──┐
                         ├──→ 003 (cascade migration) ──┬──→ 004 (tests + integration gate)
002 (AppThemeMode enum) ─┘                              └──→ 005 (docs)  [parallel with 004]
```

Tasks 004 and 005 can run in parallel after 003 lands. Tasks 001 and 002
have no dependency on each other but the breakdown sequences them
001→002 so the codegen-pipeline-fail-fast happens first.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Establish freezed/build_runner codegen pipeline | architect | None | **Complete** |
| 002 | Add `AppThemeMode` domain enum + pure-Dart test | architect | None (sequenced after 001 for fail-fast ordering) | **Complete** |
| 003 | Cascade migration — `AppSettings` to `@freezed`, `AppThemeMode` everywhere, string persistence, presentation seam | architect | 001, 002 | **Complete** |
| 004 | Update test fixtures + add new tests + run terminal integration gate | qa-engineer | 003 | **Complete** |
| 005 | Update `docs/features/settings.md` and `docs/architecture.md` | tech-writer | 003 | **Complete** |

## Additions to Spec

The plan and breakdown discovered one file not listed in spec §4's
Affected Areas:

- `test/features/settings/domain/entities/app_settings_test.dart` — created in Task 004. The spec's AC-16 implies it ("a pure-Dart unit test... is added under `test/features/settings/domain/`") but the explicit file path was not in the Affected Areas table.

Additionally, Task 002 creates a sibling test file
`test/features/settings/domain/entities/app_theme_mode_test.dart` for the
new enum's `fromCodeOrDefault` helper. This is also not explicitly listed
in spec §4 but follows from AC-16's pure-Dart-test obligation.

No source files beyond spec §4 are touched by the breakdown.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | High | First codegen pipeline in this codebase; failure mode is "tooling won't even start" — must fail fast before downstream tasks build on it |
| 002 | Low | Pure-Dart enum + 6 unit tests; no upstream dependencies (codegen-free); standard pattern |
| 003 | High | Largest task: 9-file cascade plus committed `*.freezed.dart`; convergence point of two upstream tasks; type-rename across multiple architectural layers; intermediate state leaves `test/` red until Task 004 |
| 004 | Med | Mechanical fixture updates across 7 test files + 2 new test additions; the `flutter test` + `flutter build apk --debug` integration gate either succeeds (everything compiles + behaviorally unchanged) or surfaces a real bug from Task 003 that needs going back |
| 005 | Low | Documentation update; no source code touched; tech-writer agent specialty |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 001 | High risk (first-codegen-pipeline-on-this-codebase) | Verify `pubspec.yaml` lists the three new packages with sensible pinned versions; verify `dart run build_runner build --delete-conflicting-outputs` exited 0 cleanly with no generated files; verify `dart analyze` and `flutter test` are still clean (no regression from the pubspec change) |
| 003 | High risk (largest cascade); convergence point of two upstream tasks; layer-crossing (domain→data→presentation→app seam) | Verify `grep "package:flutter"` returns no matches for `lib/features/settings/domain/` and `lib/features/settings/data/`; verify `lib/features/settings/domain/entities/app_settings.freezed.dart` is generated and committed; verify `lib/app.dart` has 4 `.select(...)` calls; verify NO out-of-scope drift (no `debugPrint` removed; no `try { } on Exception catch` widened; no `@riverpod` migration; no use cases introduced); verify `dart analyze` for `lib/` is clean even though `test/` will be red |

Tasks 002, 004, 005 do not require review checkpoints (low/med risk; no convergence; no high-risk file changes).

## Contract Chain Integrity

Verified — every "Produces" item from each task is consumed by a downstream task's "Expects" or maps directly to a spec acceptance criterion:

- 001's "freezed_annotation/freezed/build_runner in pubspec" → 003's "Expects" (codegen pipeline available) and AC-11
- 002's "AppThemeMode exists with fromCodeOrDefault" → 003's "Expects" (AppThemeMode used as field type) and AC-3
- 003's "AppSettings is @freezed with manualThemeMode: AppThemeMode" → 004's "Expects" (test fixtures use new shape)
- 003's "no Flutter imports in domain/data" → AC-1, AC-2 (verified directly)
- 003's "no effectiveThemeMode/effectiveLocale" → AC-5 + 005's doc update obligation
- 003's "saveThemeMode(AppThemeMode)" → AC-6 + 004's mock setup
- 003's "getString/setString in data source" → AC-7
- 003's "lib/app.dart has 4 .select() calls + _toFlutterThemeMode" → AC-9, AC-10
- 004's "AC-8 legacy-int test exists" → AC-8 (directly verified)
- 004's "app_settings_test.dart exists with copyWith + equality" → AC-16 (the AppSettings half; AppThemeMode half satisfied by Task 002)
- 004's "flutter test exits 0" → AC-13
- 004's "flutter build apk --debug exits 0" → AC-14
- 004's "dart analyze 0 issues across workspace" → AC-12 (full)
- 005's "docs/features/settings.md updated" → AC-15

**No orphans, no unsatisfied expectations.** AC-17 (manual real-device run) is intentionally not bound to a task; it is a manual `/verify`-time check — the user runs `flutter run` and confirms the legacy-theme reset behavior on their physical device.

## Out-of-Scope Boundaries (carried forward from spec §6)

The following audit findings are explicitly NOT addressed by these 5 tasks and remain open as separate bug files:

- **Bug 002** (`debugPrint` × 4 sites) — Task 003 explicitly preserves the current `debugPrint` lines.
- **Bug 003** (silent error swallowing in fold left branches) — Task 003 explicitly preserves the current behavior.
- **Bug 004** (manual `Provider`/`NotifierProvider` → `@riverpod`) — Task 003 only updates parameter types; the hand-rolled provider declarations stay. (Codegen tooling lands via Task 001, making bug 004 trivial mechanical work later.)
- **Bug 005** (missing `domain/usecases/`) — no use cases are introduced.
- **Bug 006** (`Failure` hierarchy completion) — only `CacheFailure` exists; no new variants added.
- **Bug 007** (GoRouter never disposed) — `appRouter` lifecycle untouched.
- **Bug 008** (no errorBuilder) — router config untouched.
- **Bug 009** (cross-feature import in theme_preview) — Task 003 modifies `theme_preview_screen.dart` for the type cascade but does NOT remove the cross-feature import or delete the screen.
- **Bug 010** (`on Exception catch` lets `Error` escape) — Task 003 explicitly preserves the current `try { } on Exception catch` shape in `settings_repository_impl.dart`.
- **Bug 011** (DRY in selector widgets) — Task 003 modifies `theme_selector.dart` for the type cascade but does NOT extract any helpers; `language_selector.dart` is not touched at all.
- **Bug 012** (app_router doc-vs-code drift) — `lib/core/routing/app_router.dart` is not in any task's file list.
- **Bug 013** (main blocks on async) — `lib/main.dart` is not touched.
- **Bug 014** (`load()` "never fails" doc lie) — repository contract dartdoc is updated for the `MaterialApp` reference removal in Task 003 but the `load()` "Never fails" claim is preserved.
- **Bug 015** (`AppBottomNav` in core) — not touched.
- **Bug 016** (test gap consolidation) — Task 004 closes 3 of 10 sub-items (AC-8 = sub-item 1; AC-16 AppSettings = sub-item 4; partial sub-item 10 by adding the domain test directory). The other 7 sub-items remain open.
