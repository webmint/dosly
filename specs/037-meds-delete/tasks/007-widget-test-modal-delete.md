# Task 007: Widget test — modal delete flow

**Agent**: qa-engineer
**Status**: Complete
**Files**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (modify)
**Depends on**: 005, 008
**Context docs**: None
**Review checkpoint**: No

**Description**:
Widget-test the delete affordance and flow in `AddMedicationModal`, reusing the existing `_harness(...)` + provider-override pattern (see the spec-032 "Save — wired behavior" group). Override `deleteMedicationProvider` with a fake/mock `DeleteMedication` (backed by a mock `MedicationRepository`) and pass `initial:` a fixture medication to enter edit mode.

**Change details**:
- In `test/features/meds/presentation/widgets/add_medication_modal_test.dart`, add a `group('AddMedicationModal delete (spec 037)')` covering:
  - **Affordance gating (AC-7)**: with `initial != null`, the trash `IconButton` (find by `medsDeleteButtonTooltip` tooltip) is present; with `initial == null` (add mode) it is absent.
  - **Confirm dialog (AC-8)**: tapping the trash icon shows an `AlertDialog` whose text contains the fixture medication's name.
  - **Cancel = no-op (AC-9)**: tapping Cancel dismisses the dialog, the modal remains, and `deleteMedicationProvider`'s use case is never called.
  - **Delete success (AC-10)**: tapping Delete invokes the delete use case once, the modal is popped, and a SnackBar with `medsDeleteSuccess` is shown.
  - **Delete failure (AC-11)**: when the overridden use case returns `Left(Failure)`, an error SnackBar (`medsDeleteError`) is shown and the modal stays open.
  - Use `find.byTooltip(...)` for the trash action (avoid `find.byIcon` ambiguity — MEMORY F035) and `await tester.pumpAndSettle()` after dialog open/close.

**Done when**:
- [x] Tests assert the trash affordance is present in edit mode and absent in add mode.
- [x] Tests assert the confirm dialog shows the medication name; Cancel does not call the use case; Delete calls it once, pops, and shows the success SnackBar.
- [x] A failure test asserts the error SnackBar shows and the modal stays open on `Left`.
- [x] Existing `AddMedicationModal` tests (specs 026–036) remain green.
- [x] `flutter test test/features/meds/presentation/widgets/add_medication_modal_test.dart` passes; `dart analyze` passes.

**Spec criteria addressed**: AC-7, AC-8, AC-9, AC-10, AC-11

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `add_medication_modal_test.dart` (+`group('AddMedicationModal delete (spec 037)')`, 6 tests; extended `_RecordingMedicationRepository` with `capturedDeleteId`/`deleteCallCount`/configurable `deleteResult`; +`DeleteMedication` import)
**Contract**: Expects [3/3 verified] | Produces [1/1 verified]
**Code review**: Self-reviewed (test-only; `find.byTooltip(deleteTooltip)` used exclusively — no `byIcon` for trash, per MEMORY F035; reuses spec-036 pop-assertion harness; 67/67 modal tests, full suite 583 green; analyze clean).
**Notes**: Added dep on Task 008 (its `delete` fake stubs are the base extended here). Success test asserts pop + `medsDeleteSuccess`; failure test asserts `medsDeleteError` + modal stays open.

## Contracts

### Expects
- `AddMedicationModal` renders an edit-only trash `IconButton` (tooltip `medsDeleteButtonTooltip`) and `_onDelete`/`_confirmDelete` behavior (Task 005).
- `deleteMedicationProvider` is overridable in a `ProviderScope` (Task 003).
- Existing `_harness(...)` builder and mock/fake patterns in this test file.

### Produces
- `add_medication_modal_test.dart` contains a `group('AddMedicationModal delete` covering affordance gating, confirm dialog, cancel no-op, success (pop + SnackBar), and failure (error SnackBar, stays open).
