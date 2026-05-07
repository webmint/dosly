# Task 002: Update settings docs and close bug 002

**Status**: Complete
**Agent**: tech-writer
**Files**:
- `docs/features/settings.md` (modify — one snippet comment)
- `bugs/002-debugprint-in-settings-provider.md` (modify — front matter only)

**Depends on**: 001
**Blocks**: None
**Context docs**: `bugs/002-debugprint-in-settings-provider.md` itself (read first to understand the closure record being created); `lib/features/settings/presentation/providers/settings_provider.dart` (read after Task 001 to confirm the post-fix code shape that the doc snippet must accurately describe)
**Review checkpoint**: No

## Description

After Task 001 removes the `debugPrint` calls, two text artifacts still claim that failures are "logged":

1. `docs/features/settings.md` line ~85 contains a code snippet whose Left-branch comment reads `(failure) { /* log, leave state unchanged */ }`. The post-fix code does not log. Update the snippet to match reality.
2. `bugs/002-debugprint-in-settings-provider.md` front matter still says `**Status**: Open` even though the bug is now fixed. Flip to Closed and record the fix date.

This task is pure documentation maintenance. It does not touch source code, does not change tests, and does not affect build or analyze output.

## Change details

- In `docs/features/settings.md`:
  - **Locate the snippet** by grep for the literal string `/* log, leave state unchanged */` (do not rely on line numbers — use grep so the edit is robust against line drift).
  - **Replace the snippet's failure-branch line**
    ```dart
    (failure) { /* log, leave state unchanged */ },
    ```
    with
    ```dart
    (_) { /* leave state unchanged — bug 003 will surface to UI */ },
    ```
    The parameter rename `failure` → `_` and the comment text update mirror the post-fix source code shape. After this edit, `grep -n "log, leave state unchanged" docs/features/settings.md` must return zero matches and the word "log" must not appear inside that snippet's failure-branch comment.
  - **No other changes** to `docs/features/settings.md`. Section headings, narrative prose, ARB key tables, and other snippets remain untouched.

- In `bugs/002-debugprint-in-settings-provider.md`:
  - **Change line 3** from `**Status**: Open` to `**Status**: Closed`.
  - **Change line 7** from `**Fixed**:` to `**Fixed**: 2026-05-01 (spec 013)`.
  - **No body changes**. The Description, File(s), Evidence, and Fix Notes sections stay verbatim — they are the historical record of what the bug was.

## Out of scope (explicit guards — do not do these)

- Do **NOT** modify any source file in `lib/` — Task 001 owns all source edits.
- Do **NOT** modify any test file — no test asserts on doc content.
- Do **NOT** modify `bugs/003-silent-error-swallowing-fold.md` or `bugs/017-typed-logger-missing.md` — they remain Open.
- Do **NOT** rewrite or restructure `docs/features/settings.md` beyond the single snippet line edit.
- Do **NOT** add a "Changelog" or "Recent fixes" section to `docs/features/settings.md` — feature docs are organized by topic, not by date (per CLAUDE.md storage rules).
- Do **NOT** edit any other file in `bugs/`, `docs/`, or `specs/`.

## Done when

- [x] `grep -n "log, leave state unchanged" docs/features/settings.md` returns zero matches.
- [x] The replacement comment `leave state unchanged — bug 003 will surface to UI` appears exactly once inside the failure-branch line of the relevant snippet in `docs/features/settings.md`.
- [x] The snippet's failure-branch parameter is `_` (not `failure`).
- [x] `bugs/002-debugprint-in-settings-provider.md` line 3 reads `**Status**: Closed`.
- [x] `bugs/002-debugprint-in-settings-provider.md` line 7 reads `**Fixed**: 2026-05-01 (spec 013)`.
- [x] `bugs/002-debugprint-in-settings-provider.md` body sections (Description, File(s), Evidence, Fix Notes) are unchanged.
- [x] `bugs/003-silent-error-swallowing-fold.md` and `bugs/017-typed-logger-missing.md` are unchanged.
- [x] No file under `lib/` or `test/` is modified.
- [x] `dart analyze` still passes (sanity check — should be unaffected by doc-only edits).

## Completion Notes

**Completed**: 2026-05-01
**Files changed**: `docs/features/settings.md` (1 line, snippet at line 85), `bugs/002-debugprint-in-settings-provider.md` (front-matter Status + Fixed, 2 lines)
**Contract**: Expects 5/5 verified | Produces 6/6 verified
**Notes**: Em-dash U+2014 used per spec — matches both surrounding doc style and the source-code comment from Task 001. Bug 003 and bug 017 confirmed unchanged at `**Status**: Open` (deferral chain stays visible). Code review APPROVE with zero findings.

## Spec criteria addressed

AC-10, AC-11

## Contracts

### Expects (preconditions)

- Task 001 is complete: `lib/features/settings/presentation/providers/settings_provider.dart` no longer contains `debugPrint`, `kDebugMode`, or the `package:flutter/foundation.dart` import; the four Left-branch closures use parameter `_` and a comment referencing bug 003 + bug 017.
- `docs/features/settings.md` exists and contains a snippet with the literal substring `/* log, leave state unchanged */`.
- `bugs/002-debugprint-in-settings-provider.md` exists with front matter `**Status**: Open` (line 3) and `**Fixed**:` (line 7, no value).
- `bugs/003-silent-error-swallowing-fold.md` exists with `**Status**: Open`.
- `bugs/017-typed-logger-missing.md` exists with `**Status**: Open`.

### Produces (postconditions)

- `docs/features/settings.md` contains zero occurrences of the literal substring `log, leave state unchanged`.
- `docs/features/settings.md` contains exactly one occurrence of the literal substring `leave state unchanged — bug 003 will surface to UI`.
- `bugs/002-debugprint-in-settings-provider.md` contains the literal line `**Status**: Closed`.
- `bugs/002-debugprint-in-settings-provider.md` contains the literal line `**Fixed**: 2026-05-01 (spec 013)`.
- `bugs/003-silent-error-swallowing-fold.md` and `bugs/017-typed-logger-missing.md` each still contain `**Status**: Open` (unchanged).
- No file under `lib/` is modified; no file under `test/` is modified.
