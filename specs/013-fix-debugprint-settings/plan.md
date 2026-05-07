# Plan: Remove `debugPrint` calls from `SettingsNotifier` (bug 002 fix)

**Date**: 2026-05-01
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Surgical removal of four `debugPrint` sites in `lib/features/settings/presentation/providers/settings_provider.dart`. Each Left-branch closure becomes an empty body holding only a one-line comment that cross-references bug 003 (the deferred UI surface) and bug 017 (the deferred typed logger). The `package:flutter/foundation.dart` import is removed because `kDebugMode` and `debugPrint` were its only consumers. No state shape, repository, data source, or selector widget is touched.

## Technical Context

**Architecture**: Single layer affected — `presentation/providers/`. Domain and data layers unchanged.
**Error Handling**: Unchanged. The `Either<Failure, void>` return from `SettingsRepository.saveX(...)` keeps its current shape; only the Left-branch handler body changes (from a `kDebugMode`-guarded `debugPrint` to an empty closure with a comment).
**State Management**: Unchanged. `SettingsNotifier extends Notifier<AppSettings>` is preserved (spec §6 explicitly forbids the `AsyncNotifier` migration — that's bug 003's scope).

## Constitution Compliance

| Rule | Status | Note |
|------|--------|------|
| §4.2.1 — never use `debugPrint`/`print` in committed code | **Becomes compliant** (this is the rule the fix satisfies) | All four sites removed; no replacement uses either function. |
| §4.2 — never swallow errors silently | **Unchanged** (already non-compliant before this fix; bug 003 owns the proper fix) | Spec §6 explicitly defers; risk acknowledged in spec §9 row 1 and below. |
| §6.1 — minimal changes | **Compliant** | Only the four sites + one import + dartdoc / docs cross-references. No refactor, no helper extraction. |
| §3.4 — testing requirements | **Compliant** | Existing 13 tests in `settings_provider_test.dart` continue to assert the unchanged "state stays old on failure" contract. Optional rename of four test names. |
| §2.1 — layer boundaries | **Compliant** | Only `presentation/` is touched. No domain/data import added or removed (Flutter/foundation removal is presentation-internal). |
| §3.5 — no debug artifacts in committed code | **Becomes compliant** | This is the rule being enforced. |

No NON-NEGOTIABLE rule is violated by the planned approach.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing) |
|-------|------|------------------|
| Presentation | Remove `debugPrint` calls + their `kDebugMode` guards + the `flutter/foundation.dart` import; replace each Left-branch body with a single comment cross-referencing bug 003 + bug 017. | `lib/features/settings/presentation/providers/settings_provider.dart` |
| Test | Existing tests remain green without assertion changes. Optionally rename four test descriptions for clarity (Q-A in spec §8 — implementation judgment call). | `test/features/settings/presentation/providers/settings_provider_test.dart` |
| Documentation | Update one stale code-snippet comment in feature docs (line ~85). Mark bug 002 as Closed in front matter. | `docs/features/settings.md`, `bugs/002-debugprint-in-settings-provider.md` |

No domain layer changes. No data layer changes. No new files.

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| What replaces the `debugPrint` body? | Empty closure body with a single-line `//` comment referencing bug 003 + bug 017. | Smallest possible diff. Production behavior is bit-identical to today (Left branch was a no-op in release because `kDebugMode == false`). The comment makes the deferral visible to future readers and audit passes. | (a) **Add a `print` / `log` / `developer.log` call**: re-introduces a §4.2.1 violation in a new costume. Rejected. (b) **Throw the failure**: changes the public contract (mutators currently return `Future<void>` and never throw); ripples into widget callers. Rejected — out of scope per spec §6. (c) **Add an error-state field on `AppSettings`**: bug 003's job; explicitly out of scope per spec §6 row 4. Rejected. (d) **Extract an `_ignoreFailure(Failure)` helper**: premature DRY (§3.6 says wait for the third occurrence; bug 003 will refactor this whole shape anyway). Rejected. |
| Should the comment be one combined `//` line or four identical site-local comments? | One identical site-local comment per closure (four total). | The point of the comment is to be visible AT the call site so an auditor opening that closure understands why the body is empty. A single shared comment elsewhere requires the auditor to follow a pointer. | A const `_kDeferredBecause` string at the top of the file: adds a top-level identifier that nobody references at runtime; lint may flag as unused. Rejected. |
| Should we rename the four "does not update state when save fails" tests? | Optional — leave to the implementing agent's judgment. Acceptable to keep as-is OR rename to "leaves state unchanged on failure (no logging until bug 003)". Not gated by an AC. | The test bodies are unchanged; the rename is purely a hint to the next reader. Auto-approve either choice. | Hard-coding a rename as an AC: forces churn that doesn't change behavior. Rejected. |
| Should we touch the `_FakeSettingsRepository` test fixture? | No. | The fixture's `failOnSaveX` flags drive the four "fail path" assertions which still apply unchanged. | (a) Add a "log was called" verifier: there's no log to verify post-fix. Rejected. (b) Delete the failure-path tests: would lose the contract assertion that state stays old on failure — the most important thing this notifier promises. Rejected, would be a regression in test coverage. |
| `git mv` or in-place edit on `settings_provider.dart`? | In-place edit. | Filename is unchanged; only body changes. | A rename would create needless churn for reviewers. |
| Touch other `bugs/*.md` front matters? | Only `bugs/002-...md`. | Bug 003 and bug 017 stay Open — this spec doesn't fix them. | Marking bug 003 as "in progress" would lie about reality. Rejected. |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/settings/presentation/providers/settings_provider.dart` | Modify | (1) Remove `import 'package:flutter/foundation.dart';` (line 8). (2) For each of the four mutators (`setThemeMode` line ~50, `setUseSystemTheme` line ~69, `setUseSystemLanguage` line ~88, `setManualLanguage` line ~106): replace the `(failure) { if (kDebugMode) { debugPrint('Settings: persistence failed — $failure'); } }` body with `(_) { /* Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger). */ }`. The Left-branch parameter is renamed `failure` → `_` because the parameter is now unused (Dart convention; satisfies `unused_local_variable` if any future lint enables it). (3) No other line moves. Library-level dartdoc unchanged unless verification finds it implies logging (it does not). |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Modify (optional rename only) | No assertion shape changes. The four `setX does not update state when save fails` tests continue to pass byte-for-byte. The implementing agent may rename them per Q-A — acceptable, not required. The `_FakeSettingsRepository` fixture is untouched. |
| `docs/features/settings.md` | Modify | Line ~85, the snippet's failure-branch comment currently reads `(failure) { /* log, leave state unchanged */ }`. Change to `(_) { /* leave state unchanged — bug 003 will surface to UI */ }` so the doc snippet matches the post-fix code shape (parameter `_`, no "log" word). |
| `bugs/002-debugprint-in-settings-provider.md` | Modify | Front matter: `**Status**: Open` → `**Status**: Closed`. Add `**Fixed**: 2026-05-01 (spec 013)` line. No body changes. |
| `bugs/017-typed-logger-missing.md` | NOT modified | Created by /specify run, intentionally stays Open. Just verify it exists. |
| `bugs/003-silent-error-swallowing-fold.md` | NOT modified | Stays Open. |

**Files in plan but not in spec §4**: `bugs/017-typed-logger-missing.md` was created during /specify but is read-only here. Otherwise the file impact set is identical to spec §4.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/settings.md` | Update | Line ~85 snippet comment — see File Impact table. |
| `docs/architecture.md` | No change | The Clean Architecture description and §"settings module" subsection are untouched by this fix. |
| `docs/api/*.md` | No change | No API surface affected. |
| `docs/overview.md` | No change | High-level overview unaffected. |
| New `docs/features/*.md` | None | No new feature docs needed. |

The `tech-writer` pass during `/finalize` will re-verify all `docs/features/settings.md` snippets still match the source post-fix.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Removal of debug breadcrumb makes a real persistence failure invisible to a developer until bug 003 ships | Med | Low | Production behavior unchanged (Left branch was already a no-op in release). Debug-mode breadcrumb loss is intentional; bug 003 will replace it with a snackbar (observable in BOTH modes). Until then, breakpoint at the Left branch in DevTools is the diagnostic path. Documented in spec §9 row 1. |
| `dart analyze` flags a new warning after the import removal (e.g. dependent code transitively relied on the symbol) | Low | Low | Verify with grep before edit: `kDebugMode` and `debugPrint` appear nowhere else in `settings_provider.dart`. Post-edit, run `dart analyze` and confirm clean. |
| `docs/features/settings.md` line numbers shift between now and execution, so the "line ~85" target becomes stale | Low | Low | Use grep against the snippet string `/* log, leave state unchanged */` rather than line numbers when locating the edit site. |
| Implementation agent broadens scope into bug 003 (e.g. starts an `AsyncNotifier` migration) | Low | High | Spec §6 enumerates deferrals exhaustively; this plan repeats the boundaries; task file in `/breakdown` will repeat them again; code-reviewer will flag any out-of-scope edit. Same discipline pattern that worked for spec 012's bundling (per MEMORY.md "Multi-task /execute-task all" lesson). |
| The four-tests-stay-byte-identical contract slips because the agent decides to "improve" them | Low | Med | Plan §"Key Design Decisions" row 3 marks the rename as optional. Code-reviewer + qa-engineer pass during `/execute-task` Phase 4 will flag any assertion-shape change. AC-7 of spec §5 requires all 13 tests to pass without modification to production-call expectations. |
| Bug 003 / bug 017 stagnate forever because they're "deferred to themselves" | Med | Med | Both are filed as numbered bug files; both are referenced in the new code's site-local comments; recurring `/audit` runs surface unfixed bugs. Visibility chain is intact. |

No `AC-N has no clear implementation path` items. Every AC in spec §5 maps to a concrete edit listed in File Impact above (cross-check below).

## Dependencies

None. No `flutter pub add`, no service config, no environment variable. The fix is a pure source edit + comment update.

## Plan-Spec Cross-Reference

Verifying every AC in spec §5 has a clear implementation path in this plan:

| AC | Implementation locus in plan |
|----|------------------------------|
| AC-1 (zero `debugPrint` in `settings_provider.dart`) | File Impact row 1 step (2) — replaces all four Left-branch bodies. |
| AC-2 (zero `kDebugMode` in `settings_provider.dart`) | File Impact row 1 step (2) — `kDebugMode` only appears inside the four Left-branch guards being removed. |
| AC-3 (no `flutter/foundation.dart` import) | File Impact row 1 step (1). |
| AC-4 (each Left branch is an empty closure with a comment referencing bug 003 + bug 017) | File Impact row 1 step (2) — comment text spelled out. |
| AC-5 (`grep -rn "debugPrint\|print(" lib/` returns zero matches) | Implied by AC-1; confirmed by current grep (only the four targeted sites exist project-wide). |
| AC-6 (`dart analyze` clean) | Risk row 2 mitigation — confirm post-edit. |
| AC-7 (13 existing tests pass without production-assertion changes) | File Impact row 2 + Key Design Decision row 3 — assertion shape preserved. |
| AC-8 (`flutter build apk --debug` succeeds) | Standard end-of-task gate. No source changes affect build. |
| AC-9 (Right branch byte-identical) | File Impact row 1 step (2) explicitly says "no other line moves" and Right-branch is untouched. |
| AC-10 (bug 002 marked Closed + Fixed line) | File Impact row 4. |
| AC-11 (`docs/features/settings.md` snippet no longer says "log") | File Impact row 3. |
| AC-12 (library-level dartdoc not implying logging) | File Impact row 1 step (3) — verify-only step (current dartdoc does not imply logging; if a verification scan finds wording that does, fix it inline). |

Every AC has a clear path. No items punted to `/breakdown` for clarification.

## Supporting Documents

- `research.md` — not generated; no signals detected (single-feature, single-file, well-understood scope).
- `data-model.md` — not generated; no entity changes (spec §6 forbids).
- `contracts.md` — not generated; no API changes.
