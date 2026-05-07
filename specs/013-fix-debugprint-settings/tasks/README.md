# Tasks: Remove `debugPrint` calls from `SettingsNotifier` (bug 002 fix)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-05-01
**Total tasks**: 2
**Verified**: 2026-05-01 — APPROVED (12/12 ACs PASS, 0 review findings)

## Dependency Graph

```
001 (source: remove debugPrint + verify) ──→ 002 (docs: snippet + bug 002 close)
```

Linear chain. Task 002 depends on Task 001 because the doc snippet's post-fix wording must match the actual source code shape that Task 001 produces.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Remove `debugPrint` calls from `SettingsNotifier` | mobile-engineer | None | Complete |
| 002 | Update settings docs and close bug 002 | tech-writer | 001 | Complete |

## Additions to Spec

None. Every file in the breakdown is listed in spec §4 (Affected Areas). The plan also explicitly noted `bugs/017-typed-logger-missing.md` as a created-by-/specify file that is **not** modified by either task — it stays Open as a forward-looking placeholder for the deferred typed-logger work.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Surgical edit to a single file. The four `debugPrint` sites are visually identical. The Right branches are preserved byte-for-byte. The 13 existing tests already exercise the failure path with `failOnSaveX` flags — they pin the contract Task 001 must not break. The only behavioral change is the loss of the debug-mode console line, accepted per spec §9 row 1. |
| 002 | Low | Pure doc/bookkeeping edits. One snippet line in `docs/features/settings.md`, two front-matter lines in `bugs/002-...md`. Zero source code, zero tests, zero build/analyze impact. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| (none) | No task in this breakdown matches the auto-placement criteria: no convergence point (the chain is linear), no layer-boundary crossing (Task 001 stays in presentation, Task 002 stays in docs/bookkeeping), and both tasks are rated Low risk. The per-task `code-reviewer` pass that runs in `/execute-task` Phase 4 is sufficient coverage. |

If you want a manual checkpoint before Task 001 anyway (because it is the only source-code change in the feature), say so during approval and I will mark it.

## Contract Chain Integrity

| Producer | Postcondition | Consumer |
|----------|---------------|----------|
| (codebase before T001) | `settings_provider.dart` contains four `debugPrint` sites and the `flutter/foundation.dart` import | T001.Expects |
| (codebase before T001) | `_FakeSettingsRepository` exposes four `failOnSaveX` flags, 13 tests assert the failure-state contract | T001.Expects |
| (codebase before T001) | `bugs/003-...md` and `bugs/017-...md` exist | T001.Expects, T002.Expects |
| T001.Produces | `settings_provider.dart` has zero `debugPrint` / `kDebugMode` / `flutter/foundation.dart` import | spec AC-1, AC-2, AC-3, AC-5 |
| T001.Produces | Four Left branches each contain a comment with `bug 003` and `bug 017` literals; parameter renamed to `_` | spec AC-4 + T002.Expects (mirror in doc snippet) |
| T001.Produces | Right branches contain `state = state.copyWith(` byte-identical | spec AC-9 |
| T001.Produces | `dart analyze` clean, `flutter test` 100%, `flutter build apk --debug` succeeds | spec AC-6, AC-7, AC-8 |
| T001.Produces | `SettingsNotifier` public surface unchanged (4 mutators, `Notifier<AppSettings>` shape) | spec AC-12 + bug 003's future migration starts from a known shape |
| T002.Produces | `docs/features/settings.md` snippet no longer says `log, leave state unchanged` | spec AC-11 |
| T002.Produces | `bugs/002-...md` front matter shows Closed + Fixed line | spec AC-10 |
| T002.Produces | `bugs/003-...md` and `bugs/017-...md` unchanged (Open) | confirms bug 002 deferral chain stays visible |

**Orphans**: none. Every Produces item maps to either a downstream Expects or a spec AC.

**Unsatisfied**: none. Every Expects item traces to either prior codebase state or an upstream Produces.

## AC Coverage Matrix

| AC | Task | Coverage type |
|----|------|---------------|
| AC-1 (no `debugPrint` in provider) | 001 | grep + Done condition |
| AC-2 (no `kDebugMode` in provider) | 001 | grep + Done condition |
| AC-3 (no `flutter/foundation.dart` import) | 001 | grep + Done condition |
| AC-4 (Left branch is empty closure with bug 003 + bug 017 reference) | 001 | grep + structural inspection |
| AC-5 (project-wide grep returns zero `debugPrint` / `print(` matches in `lib/`) | 001 | grep at task end |
| AC-6 (`dart analyze` clean) | 001 | Done condition |
| AC-7 (13 tests pass without production-assertion changes) | 001 | `flutter test` Done condition + explicit out-of-scope guard against changing assertions |
| AC-8 (`flutter build apk --debug` succeeds) | 001 | Done condition |
| AC-9 (Right branch byte-identical) | 001 | Out-of-scope guard + grep for `state = state.copyWith(` |
| AC-10 (bug 002 marked Closed + Fixed line) | 002 | Done condition |
| AC-11 (`docs/features/settings.md` snippet no longer says "log") | 002 | grep at task end |
| AC-12 (library-level dartdoc not implying logging) | 001 | Verify-only step in change details + Done implicit (no dartdoc edit needed) |

All 12 ACs are covered. No AC is split across multiple tasks (each AC has a single task owner).
