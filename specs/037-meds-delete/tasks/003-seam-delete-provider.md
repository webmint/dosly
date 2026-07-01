# Task 003: Add `deleteMedicationProvider` to the composition seam

**Agent**: architect
**Status**: Complete
**Files**: `lib/features/meds/presentation/providers/medication_providers.dart`, `lib/features/meds/presentation/providers/medication_providers.g.dart` (regenerated)
**Depends on**: 001
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

**Description**:
Expose the `DeleteMedication` use case through the meds composition seam, wired to the existing `medicationRepositoryProvider`. This mirrors the existing `addMedicationProvider` / `editMedicationProvider` exactly (both `@riverpod` functions returning a domain-typed use case). Regenerate the `.g.dart` with build_runner. The seam stays the only presentation file importing `data/`; consumers receive the domain-typed `DeleteMedication` only.

**Change details**:
- In `lib/features/meds/presentation/providers/medication_providers.dart`:
  - Add `import '../../domain/usecases/delete_medication.dart';`.
  - Add, next to `editMedication`:
    ```dart
    /// Provides the [DeleteMedication] use case wired to the medication repository.
    ///
    /// The domain operation the edit-medication modal consumes to delete a
    /// medication; depends only on domain abstractions.
    @riverpod
    DeleteMedication deleteMedication(Ref ref) =>
        DeleteMedication(ref.watch(medicationRepositoryProvider));
    ```
- Regenerate: `dart run build_runner build --delete-conflicting-outputs` (updates `medication_providers.g.dart` with `deleteMedicationProvider`).

**Done when**:
- [x] `medication_providers.dart` defines an `@riverpod DeleteMedication deleteMedication(Ref ref)` wired to `ref.watch(medicationRepositoryProvider)`.
- [x] `medication_providers.g.dart` contains a generated `deleteMedicationProvider`.
- [x] No screen/widget imports `data/` (only this seam does).
- [x] `dart analyze` passes on the two changed files (no undefined symbols).

**Spec criteria addressed**: AC-6

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `medication_providers.dart` (+`deleteMedication` provider + import), `medication_providers.g.dart` (build_runner regen — `deleteMedicationProvider`)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Code review**: APPROVE (no issues)
**Notes**: Mirrors `editMedication` exactly. Agent surfaced a discovered build break — Task 001's interface change left 5 test fakes without a `delete` impl (whole-project analyze fails). Added remediation Task 008 (qa-engineer) to stub them; sequenced next.

## Contracts

### Expects
- `lib/features/meds/domain/usecases/delete_medication.dart` exports `class DeleteMedication` with `const DeleteMedication(MedicationRepository)` (from Task 001).
- `medication_providers.dart` defines `@riverpod MedicationRepository medicationRepository(Ref ref)` and `@riverpod EditMedication editMedication(Ref ref)`.

### Produces
- `medication_providers.dart` declares `DeleteMedication deleteMedication(Ref ref) =>` `DeleteMedication(ref.watch(medicationRepositoryProvider))`.
- `medication_providers.g.dart` defines `deleteMedicationProvider`.
