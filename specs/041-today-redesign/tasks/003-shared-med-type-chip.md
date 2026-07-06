# Task 003: Extract the shared `MedTypeChip` widget

**Agent**: mobile-engineer
**Review checkpoint**: No
**Files**: `lib/features/meds/presentation/widgets/med_type_chip.dart` (new), `lib/features/meds/presentation/widgets/medication_tile.dart`
**Depends on**: None
**Blocks**: 006
**Context docs**: None

## Description

Extract the continuous / "Day N/M" / paused type chip (currently `medication_tile.dart`'s `_TypeChip` + `_Pill`) into a reusable `MedTypeChip` widget so the Today dose tile can render the same chip without duplicating the color+label logic (constitution DRY; avoids divergence). Refactor `medication_tile.dart` to delegate to it. This is **behavior-preserving** for the meds list — its existing tests are the guard.

## Change details

- In `lib/features/meds/presentation/widgets/med_type_chip.dart` (new):
  - Export a `StatelessWidget` `MedTypeChip({required Medication medication, required CourseProgress? progress})`.
  - Render logic moved verbatim from `medication_tile._resolveTypeSpec` + `_Pill`:
    - `ContinuousType` → `medsListTypeContinuous`, `surfaceContainerHigh` / `onSurfaceVariant`.
    - `CourseType` + `progress.phase == activeWindow` → `medsListTypeCourseDay(currentDay, totalDays)`, `tertiaryContainer` / `onTertiaryContainer`.
    - `CourseType` + `progress.phase == paused` (or `progress == null`) → `medsListTypeCoursePaused` (neutral) / render nothing when `progress == null` (defensive `SizedBox.shrink`).
  - Include the stadium `_Pill` (radius 100, `labelSmall` w500) — move it here as the chip's private renderer (or make it a small public `MedPill` if `/plan` prefers; keep private).
  - dartdoc on `MedTypeChip`.
- In `lib/features/meds/presentation/widgets/medication_tile.dart`:
  - Replace `_TypeChip`'s body with `MedTypeChip(medication: item.medication, progress: item.progress)`. Keep `_StatusChip` (active/completed) local — it is meds-list-specific.
  - Remove the now-unused `_resolveTypeSpec`/`_ChipSpec`/`_Pill` if fully superseded; keep whatever `_StatusChip` still needs (it may keep its own `_Pill` or reuse the shared renderer — no behavior change).

## Contracts

### Expects
- `medication_tile.dart` renders a type chip via `_TypeChip`/`_resolveTypeSpec` using `CourseProgress` and keys `medsListTypeContinuous`, `medsListTypeCourseDay`, `medsListTypeCoursePaused`.
- `course_progress.dart` exports `CourseProgress` with `currentDay`, `totalDays`, `phase`; `course_phase.dart` exports `CoursePhase`.

### Produces
- `med_type_chip.dart` exports `MedTypeChip` taking named params `medication` (`Medication`) and `progress` (`CourseProgress?`).
- `medication_tile.dart` imports `med_type_chip.dart` and its type chip renders via `MedTypeChip`.

## Done when
- [x] `MedTypeChip` renders continuous/Day-N/M/paused identically to the previous `_TypeChip`.
- [x] `medication_tile.dart` delegates its type chip to `MedTypeChip`; no dead `_resolveTypeSpec`/`_ChipSpec` left behind.
- [x] Existing `test/features/meds/presentation/widgets/medication_tile_test.dart` passes unchanged.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-11, AC-13

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-05
**Files changed**: `lib/features/meds/presentation/widgets/med_type_chip.dart` (new), `medication_tile.dart` (refactor)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified — `MedTypeChip(medication, progress)` export; `medication_tile` renders via it]
**Notes**: Extracted verbatim continuous/activeWindow/paused/null-guard logic + `_Pill` into `MedTypeChip`. Removed `_TypeChip`/`_resolveTypeSpec`/`_ChipSpec` + 2 now-unused imports from `medication_tile.dart`; kept `_StatusChip` + its local `_Pill` (unchanged visuals). Guard `medication_tile_test.dart` 10/10 green unchanged. analyze clean.
