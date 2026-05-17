# Task 004: Create `CycleThemeMode` use case (returns next-state record)

**Agent**: architect
**Files**:
- `lib/features/settings/domain/usecases/cycle_theme_mode.dart` (create)
- `test/features/settings/domain/usecases/cycle_theme_mode_test.dart` (create)

**Depends on**: None
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Description

Create `CycleThemeMode`, the use case behind the `theme_preview_screen.dart` cycle button (`system → light → dark → system`). Plan §"Key Design Decisions" refines the spec's `Future<Either<Failure, void>>` to a record-returning shape — the use case returns the post-cycle state in its `Right` so the notifier can apply `state.copyWith(...)` without re-deriving the cycle rule (which would re-introduce bug 011 in a new location).

### Branch logic

| Input `currentUseSystemTheme` | Input `currentManualMode` | Repo writes (in order) | `Right` value |
|---|---|---|---|
| `true` | (any) | `saveThemeMode(AppThemeMode.light)` then `saveUseSystemTheme(false)` | `(useSystemTheme: false, manualThemeMode: AppThemeMode.light)` |
| `false` | `AppThemeMode.light` | `saveThemeMode(AppThemeMode.dark)` | `(useSystemTheme: false, manualThemeMode: AppThemeMode.dark)` |
| `false` | `AppThemeMode.dark` | `saveUseSystemTheme(true)` | `(useSystemTheme: true, manualThemeMode: AppThemeMode.dark)` |

If any inner write returns `Left`, the use case returns that `Left` immediately and skips remaining writes. The returned `Right` always reflects what was actually persisted at the time of return — so when the second write fails after the first succeeded, the caller still gets `Left`, not a partial record.

### Test cases (4 total)

1. `'system on → cycles to light manual: writes manual=light then toggle=false, returns (false, light)'` — `verifyInOrder([saveThemeMode(light), saveUseSystemTheme(false)])`.
2. `'manual light → cycles to manual dark: writes manual=dark only, returns (false, dark)'` — `verifyNever(() => repo.saveUseSystemTheme(any()))`.
3. `'manual dark → cycles to system on: writes toggle=true only, returns (true, dark)'` — `verifyNever(() => repo.saveThemeMode(any()))`.
4. `'first write fails: returns Left, skips second write'` — when entering from `system on` and `saveThemeMode` returns `Left`, `verifyNever(() => repo.saveUseSystemTheme(any()))` and result is the Left.

## Change details

- In `lib/features/settings/domain/usecases/cycle_theme_mode.dart` (create):
  - Library dartdoc explaining the cycle, the return-type record (with the field names), and the 3-branch table from above.
  - `class CycleThemeMode { const CycleThemeMode(this._repo); final SettingsRepository _repo; ... }`.
  - Method: `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>> call({required bool currentUseSystemTheme, required AppThemeMode currentManualMode}) async { ... }`.
  - Implement the three branches with explicit `if/else if/else` in that order. Use `result.fold` or `isLeft()`+early-return for short-circuiting.

- In `test/features/settings/domain/usecases/cycle_theme_mode_test.dart` (create):
  - `MockSettingsRepository` from mocktail.
  - 4 tests as enumerated above. Each test asserts both the recorded write sequence (`verifyInOrder`/`verifyNever`) AND the returned `Right` record's two fields.

## Done when

- [x] `cycle_theme_mode.dart` exists with the `CycleThemeMode` class, `const` constructor, and `call({required bool currentUseSystemTheme, required AppThemeMode currentManualMode})` returning `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>`.
- [x] Three transition branches are present in the use case body and verified by tests.
- [x] Test file has 4 cases (3 transitions + 1 failure short-circuit), all passing.
- [x] No `package:flutter/*`, `package:flutter_riverpod/*`, or `package:drift/*` imports in either file.
- [x] `dart analyze lib/features/settings/domain/usecases/cycle_theme_mode.dart test/features/settings/domain/usecases/cycle_theme_mode_test.dart` exits 0.
- [x] `flutter test test/features/settings/domain/usecases/cycle_theme_mode_test.dart` passes.

## Spec criteria addressed

AC-1 (partial — 1 of 5), AC-2 (partial), AC-3 (partial), AC-7. Note: this task ships the spec-deviating return type (record, not `void`) — flagged in `/plan` Risk Assessment and `/breakdown` README "Additions to Spec".

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `lib/features/settings/domain/usecases/cycle_theme_mode.dart` (new)
- `test/features/settings/domain/usecases/cycle_theme_mode_test.dart` (new, 4 tests)

**Contract**: Expects 3/3 verified | Produces 3/3 verified

**Notes**:
- Code review verdict: APPROVE (1 Warning).
- The implementer added a private `_propagateLeft` helper that lifts `Left<Failure, void>` (from repo) into `Left<Failure, record>` (use case return type) — the helper's `Right` branch throws `StateError` because every caller guards via `isLeft()` first. Reviewer flagged the unreachable-throw style as a Warning; functionally clean. Future code (Task 005) should not replicate verbatim if a similar lift comes up — inline `result.fold(Left.new, ...)` is fine.
- `else` branch (manual-dark → system-on) preserves `currentManualMode` in the returned record — this is the load-bearing UX invariant ("when user later toggles system off, the manual override is still meaningful"). Reviewer ratified the comment at the assertion site documents the intent.
- 16/16 use-case tests green project-wide.

## Contracts

### Expects
- `SettingsRepository` exposes `saveThemeMode(AppThemeMode)` and `saveUseSystemTheme(bool)`.
- `AppThemeMode` enum has `light` and `dark` values.
- Dart records syntax is enabled (Dart 3+) — `pubspec.yaml` already requires `>=3.x`.

### Produces
- `lib/features/settings/domain/usecases/cycle_theme_mode.dart` exports `class CycleThemeMode` with `const CycleThemeMode(this._repo)` and `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>> call({required bool currentUseSystemTheme, required AppThemeMode currentManualMode})`.
- The use case writes through `SettingsRepository` exclusively — no notifier or other use case is referenced.
- The Right record's two fields exactly mirror what was just persisted; tests assert both.
