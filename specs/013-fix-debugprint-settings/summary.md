# Feature Summary: 013 — Remove `debugPrint` calls from `SettingsNotifier` (bug 002 fix)

## What was built

Closed a constitution §4.2.1 violation: removed four `kDebugMode`-guarded `debugPrint` calls from the `SettingsNotifier` mutators. Each Left-branch closure body now holds a single comment cross-referencing the deferred follow-ups (bug 003 — UI surfacing, bug 017 — typed logger). Production behavior is bit-identical to the pre-fix release build (the `kDebugMode` guard already made the branch a no-op); debug-mode console output for these specific failures is intentionally lost and will return when bug 003 lands an observable UI surface.

## Changes

- **Task 001** (mobile-engineer): Removed four `debugPrint` invocations + their `kDebugMode` guards + the now-unused `package:flutter/foundation.dart` import from `lib/features/settings/presentation/providers/settings_provider.dart`. Replaced each Left-branch with `(_) { // Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger). }`. All 13 existing failure-path tests continued to pass byte-for-byte without assertion changes.
- **Task 002** (tech-writer): Updated the stale doc snippet at `docs/features/settings.md:85` (replaced misleading `(failure) { /* log, leave state unchanged */ }` with `(_) { /* leave state unchanged — bug 003 will surface to UI */ }`) and flipped `bugs/002-debugprint-in-settings-provider.md` front matter to `Status: Closed` + `Fixed: 2026-05-01 (spec 013)`.

## Files changed

| Area | Files | Change |
|------|-------|--------|
| `lib/features/settings/presentation/providers/` | 1 | source modified (8 +, 17 -) |
| `docs/features/` | 1 | doc snippet updated (1 +, 1 -) |
| `bugs/` | 2 | bug 002 closed (front matter); bug 017 created (new file, 91 lines) — tracks the typed logger gap that bug 002's description had named without filing |
| `specs/013-fix-debugprint-settings/` | 7 | full feature artifact (spec, plan, tasks/, review, verify) |
| `.claude/memory/MEMORY.md` | 1 | 3 new entries under "What Worked" |

Net delta on production code: **8 insertions, 17 deletions in 1 source file**. Everything else is documentation, bug tracking, and project artifacts.

## Key decisions

- **Empty closure with deferral comment over any logging-style replacement**: until bug 017 (typed logger) lands, no compliant `log()` alternative exists. Choosing `developer.log` / `print` / `debugPrint` would re-violate §4.2.1 in a new costume. Surfacing to UI now would expand into bug 003's `AsyncNotifier` migration. Empty closure preserves the production-no-op contract that already existed.
- **Bug 017 filed during `/specify` clarification, not deferred to `/finalize`**: bug 002's description name-checked the missing typed logger as "a separate gap" without filing it. Created `bugs/017-typed-logger-missing.md` BEFORE writing the spec so the deferral chain became concrete (named bug files) instead of vague (TODOs). spec §6 then cross-referenced both bug 003 and bug 017 by file path.
- **Two-task source-then-docs breakdown over one bundled task**: kept the per-agent boundary clean (mobile-engineer for `lib/`, tech-writer for `docs/` + `bugs/`), let the integration gate run on the source task only, and made bookkeeping a low-risk doc-only second task. Total wall-clock ~5 minutes; both code reviews APPROVE with zero findings.
- **Right-branch byte preservation as an explicit AC** (AC-9): the four `state = state.copyWith(<field>: <value>)` lines were pinned as untouchable so the agent couldn't "improve" them. Spec §6 also explicitly forbade DRY extraction of the four near-identical mutators (constitution §3.6: wait for the third occurrence; bug 003 will refactor anyway).

## Acceptance criteria

- [x] AC-1: Zero `debugPrint` in `settings_provider.dart`
- [x] AC-2: Zero `kDebugMode` in `settings_provider.dart`
- [x] AC-3: No `package:flutter/foundation.dart` import in `settings_provider.dart`
- [x] AC-4: Each of four Left branches contains a comment with both `bug 003` and `bug 017`
- [x] AC-5: Lib-wide grep for `debugPrint`/`print(` returns zero
- [x] AC-6: `dart analyze` exits clean
- [x] AC-7: All 13 existing `SettingsNotifier` tests pass without production-assertion changes
- [x] AC-8: `flutter build apk --debug` succeeds
- [x] AC-9: Right branch byte-identical to pre-fix shape
- [x] AC-10: bug 002 marked Closed + Fixed line
- [x] AC-11: `docs/features/settings.md:85` snippet no longer says "log"
- [x] AC-12: Library-level dartdoc does not imply logging

**12/12 PASS.** `/review` returned clean across security, performance, and test coverage. `/verify` verdict: APPROVED.
