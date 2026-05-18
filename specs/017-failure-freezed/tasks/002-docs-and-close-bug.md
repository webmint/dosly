# Task 002: Update architecture docs + close bug 006

**Agent**: tech-writer
**Files**:
- `docs/architecture.md` (modify — §Failure handling code snippet)
- `bugs/006-failure-hierarchy-incomplete.md` (modify — status header only)

**Depends on**: 001
**Blocks**: None
**Context docs**: `docs/architecture.md` (the section being updated); `bugs/006-failure-hierarchy-incomplete.md` (the bug being closed)
**Review checkpoint**: Yes — verifies that Task 001's byte-identical claim and codegen output landed correctly before the spec stamps "done" via docs and bug-status.

## Description

Update the `docs/architecture.md` §Failure handling section's code snippet to reflect the 6-variant freezed shape that landed in Task 001. Preserve the surrounding prose verbatim — the "side-channel error-stream pattern" paragraph and the "never forward `failure.message` to UI" guidance remain accurate after this spec.

Also close `bugs/006-failure-hierarchy-incomplete.md` by stamping `Status: Closed` and `Fixed: 2026-05-17 (spec 017)` in the bug's header block.

## Change details

### `docs/architecture.md` (§Failure handling)

Locate the §Failure handling section (currently around lines 131–142). The current code snippet shows:
```dart
sealed class Failure { const Failure(); }

class CacheFailure extends Failure {
  const CacheFailure(this.message);
  final String message;
}
```

Replace **only the fenced code block** with the new 6-variant freezed shape (matching what landed in `lib/core/error/failures.dart` — note: `sealed` is implicitly `abstract` in Dart 3 so `abstract` is omitted, matching constitution §3.2 verbatim):
```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.notFound({String? id}) = NotFoundFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.permissionDenied(String permission) = PermissionDeniedFailure;
  const factory Failure.notificationSchedule(String reason) = NotificationScheduleFailure;
  const factory Failure.validation({required String field, required String message}) = ValidationFailure;
  const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;
}
```

In the paragraph immediately following the code block, the existing sentence is:

> "Sealed classes let callers pattern-match exhaustively. `SettingsNotifier` follows the 'optimistic-write, no-update-on-failure' pattern: in-memory state is only updated when persistence succeeds."

Append one sentence to this paragraph that names the public subclasses now usable in pattern matches and `isA<>()` assertions:

> "Each redirect target (`NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`) is a public concrete class, so callers can pattern-match (`case CacheFailure(:final message)`) or assert (`isA<CacheFailure>()`) on the redirect name directly."

**Do not** modify:
- The "Side-channel error-stream pattern" paragraph (currently around line 146) — still accurate.
- The "never forward `failure.message` to UI text" guidance — still binding.
- The `ThemeController` blockquote that follows.
- Any other section of `architecture.md`.

### `bugs/006-failure-hierarchy-incomplete.md` (status close)

Update the header block (lines 3–7) only:
- Change `**Status**: Open` → `**Status**: Closed`
- Change `**Fixed**:` → `**Fixed**: 2026-05-17 (spec 017)`

Leave the Description, File(s), Evidence, and Fix Notes sections **unchanged** — they remain accurate historical record.

### Out of scope guards (do NOT touch)

- `docs/features/*.md` — none reference `Failure` directly.
- `docs/overview.md`, `docs/api/`, `docs/guides/` — unaffected by this spec.
- `bugs/010-...md`, `bugs/014-...md`, `bugs/017-...md` — explicitly deferred per spec §6.

## Done when

- [x] `docs/architecture.md` §Failure handling code block matches the 6-variant `@freezed sealed class Failure` form (AC-11). Verified by reading the file.
- [x] `docs/architecture.md` paragraph following the code block contains the new sentence naming the 6 public redirect classes (AC-11).
- [x] `docs/architecture.md` "Side-channel error-stream pattern" paragraph is unchanged. Verified by `git diff` showing edits confined to the §Failure handling subsection.
- [x] `bugs/006-failure-hierarchy-incomplete.md` header shows `Status: Closed` and `Fixed: 2026-05-17 (spec 017)` (AC-12).
- [x] `bugs/006-failure-hierarchy-incomplete.md` body (Description, File(s), Evidence, Fix Notes) is unchanged from its pre-task content.
- [x] No other doc or bug file is modified by this task. Verified by `git status` showing only `docs/architecture.md` and `bugs/006-failure-hierarchy-incomplete.md` as changed.
- [x] Linter passes on changed files (Markdown — N/A for `dart analyze` but `git diff --check` shows no trailing whitespace).

**Spec criteria addressed**: AC-11, AC-12.

## Completion Notes

**Completed**: 2026-05-17
**Status**: Complete
**Agent**: tech-writer
**Code review verdict**: APPROVE WITH WARNINGS (1 self-inconsistency warning in this task file itself, fixed in-place; 0 critical, 0 source issues)

**Files changed**:
- `docs/architecture.md` — §Failure handling code block + one appended sentence in following paragraph
- `bugs/006-failure-hierarchy-incomplete.md` — header `Status` → Closed, `Fixed` → 2026-05-17 (spec 017)

**Contract**: Expects 4/4 verified | Produces 3/3 verified

**Notes / Deviations**:

1. Pre-flight orchestrator amendments: spec.md AC-1 amendment from Task 001 propagated forward; the Change details code snippet + Expects section were updated to match Task 001's actual produced shape (`@freezed sealed class` without `abstract`). Two stale `abstract sealed` references in Done-when (line 76) and Produces (line 97) of this task file were missed in the pre-flight pass but caught by code-reviewer and corrected before commit.

2. Scope discipline confirmed by code-reviewer: only the targeted §Failure handling code block + one appended sentence changed in `docs/architecture.md`; "Side-channel error-stream pattern" paragraph and `ThemeController` blockquote are byte-identical. `bugs/006` body unchanged.

3. Bug closure format matches convention from prior closed bugs (002, 005, 011).

4. Bug 006 title's "missing 6 of 7" overcount is pre-existing (documented in `spec.md §2` and pre-spec `research/2026-05-17-bug-006-failure-hierarchy.md`). Out of scope for this task — body unchanged.

## Contracts

### Expects (preconditions — produced by Task 001)

- `lib/core/error/failures.dart` declares `@freezed sealed class Failure with _$Failure` (Task 001 dropped `abstract` because Dart 3 forbids `abstract sealed` — `sealed` is implicitly `abstract`; see spec.md AC-1 amendment).
- `lib/core/error/failures.dart` contains all six factory constructors `notFound`, `cache`, `permissionDenied`, `notificationSchedule`, `validation`, `unknown` redirecting to public class names `NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`.
- `lib/core/error/failures.freezed.dart` exists and is committed.
- `bugs/006-failure-hierarchy-incomplete.md` currently has `Status: Open` and an empty `Fixed:` field.

### Produces (postconditions)

- `docs/architecture.md` §Failure handling code snippet shows `@freezed sealed class Failure` with all six factory constructors (literal text present).
- `docs/architecture.md` paragraph below the code block names all six public redirect classes (`NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`) in a single sentence.
- `bugs/006-failure-hierarchy-incomplete.md` header contains the literal strings `**Status**: Closed` and `**Fixed**: 2026-05-17 (spec 017)`.

## Risk

| Aspect | Rating | Note |
|--------|--------|------|
| Stray doc edits drift into other sections | Low | Single localized code block + one appended sentence; `git diff` is the gate. |
| Bug status format drift from project convention | Low | Other closed-bug files (002, 003, 004, 005, 011) are reference exemplars. |
