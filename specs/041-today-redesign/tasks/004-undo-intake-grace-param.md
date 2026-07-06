# Task 004: Rewire `UndoIntake` to a configurable grace `Duration`

**Agent**: architect
**Review checkpoint**: No
**Files**: `lib/features/meds/domain/usecases/undo_intake.dart`, `test/features/meds/domain/usecases/undo_intake_test.dart`, `lib/features/meds/presentation/screens/today_screen.dart` (`_onUndo` call site only)
**Depends on**: 002
**Blocks**: 005
**Context docs**: None

## Description

Make the undo grace window configurable per call instead of the hardcoded `kIntakeUndoGracePeriod`. `UndoIntake.call` takes a `Duration gracePeriod` (keeps the meds domain settings-VO-agnostic — the settings→`Duration` conversion happens at the presentation seam). Update the single production call site (`today_screen._onUndo`) to derive the `Duration` from the `todayIntakeSettings` projection (task 002), and update the use-case tests. Do **not** delete `intake_grace.dart` yet — `today_view_model.dart` and `today_screen.dart`'s timer still reference `kIntakeUndoGracePeriod` until tasks 005/009.

## Change details

- In `lib/features/meds/domain/usecases/undo_intake.dart`:
  - Add `required Duration gracePeriod` to `call(...)`; compare `now.toUtc().difference(confirmedAt.toUtc()) > gracePeriod` (keep inclusive boundary — exactly `gracePeriod` is still allowed).
  - Remove `import '../value_objects/intake_grace.dart';`; update dartdoc references from `[kIntakeUndoGracePeriod]` to "the supplied grace period".
- In `lib/features/meds/presentation/screens/today_screen.dart` (`_onUndo` ONLY):
  - Read the projected grace: `final grace = ref.read(todayIntakeSettingsProvider).gracePeriod;` and pass `gracePeriod: Duration(minutes: grace.minutes)` to the `undoIntakeProvider.call(...)`. (Leave the rest of the screen — including the grace timer — untouched; that is task 009.)
- In `test/features/meds/domain/usecases/undo_intake_test.dart`:
  - Pass an explicit `gracePeriod:` to every `call(...)`; add cases proving a non-default period is honored (e.g. `Duration.zero` refuses immediately; `Duration(minutes: 30)` allows a 20-minute-old confirmation). Drop the `intake_grace.dart` import; use literal `Duration`s.

## Contracts

### Expects
- `undo_intake.dart` `UndoIntake.call` currently takes `id`, `confirmedAt`, `now` and compares against `kIntakeUndoGracePeriod`.
- `todayIntakeSettingsProvider` exposes a record field `gracePeriod` (`GracePeriod` with `minutes`) — from task 002.

### Produces
- `undo_intake.dart` `UndoIntake.call` signature includes `required Duration gracePeriod`; the file no longer imports `intake_grace.dart`; the comparison uses `gracePeriod`.
- `today_screen.dart` `_onUndo` passes `gracePeriod:` to `undoIntakeProvider.call(...)`, derived from `todayIntakeSettingsProvider`.
- `undo_intake_test.dart` constructs `call(...)` with an explicit `gracePeriod:` and no `intake_grace.dart` import.

## Done when
- [x] `UndoIntake.call` honors the passed `Duration` (boundary inclusive) and never references `kIntakeUndoGracePeriod`.
- [x] `today_screen._onUndo` compiles, passing the projected grace as a `Duration`.
- [x] `flutter test test/features/meds/domain/usecases/undo_intake_test.dart` is green, including the non-default-period cases.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-14

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-05
**Files changed**: `lib/features/meds/domain/usecases/undo_intake.dart`, `test/.../undo_intake_test.dart`, `lib/features/meds/presentation/screens/today_screen.dart` (`_onUndo` only)
**Contract**: Expects [2/2 verified] | Produces [3/3 verified]
**Notes**: `UndoIntake.call` gains `required Duration gracePeriod`; strict `>` refuses (inclusive boundary). `_onUndo` passes `Duration(minutes: todayIntakeSettingsProvider.gracePeriod.minutes)`. Test drops `intake_grace` import (local `const Duration(minutes:5)`); +2 non-default cases (0 refuses, 30 allows 20-min-old). 5/5 green. Screen's grace timer + `intake_grace` import intentionally left (2 refs) for task 009.
