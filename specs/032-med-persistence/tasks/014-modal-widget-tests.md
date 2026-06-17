# Task 014: Rewrite modal widget tests for real Save

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 011
**Context docs**: `.claude/memory/MEMORY.md` (no-op-Save test gaps 2026-06-12; off-stage Dropdown idiom; pop needs a route below)
**Review checkpoint**: No

**Description**:
Replace the obsolete spec-026 "Save is a no-op" assertions with tests of the wired behavior: valid input persists and pops; invalid input shows the localized error SnackBar and stays open. Use a `ProviderScope` with `addMedicationProvider` overridden so the widget test does not touch a real DB.

**Change details**:
- Remove/rewrite the no-op-Save test(s); update the file header comment so it no longer claims Save is a no-op (avoid a "lying comment" — MEMORY 2026-06-12).
- Pump the modal inside a `ProviderScope(overrides: [addMedicationProvider.overrideWith((ref) => _FakeAddMedication(...))])` and a `MaterialApp` with `AppLocalizations` delegates, **with a route below the modal** so `Navigator.pop` is observable (MEMORY 2026-06-12).
- Tests:
  - fill name + add one time + (default continuous) → tap Save → fake use case returns `Right` → assert the success SnackBar shows and the modal route is popped.
  - tap Save with an empty name (use case returns `Left(ValidationFailure(field:'name'))`, or drive real validation) → assert the `medsAddSaveErrorName` SnackBar shows and the modal is NOT popped.
  - assert the Save button is disabled (`onPressed == null`) while the in-flight future is unresolved (optional but recommended).
- For any `DropdownButton`/`DropdownButtonFormField` interaction, use the off-stage `DropdownMenuItem` idiom (MEMORY 2026-06-08), not `find.text` + `pumpAndSettle`.

**Done when**:
- [ ] no test asserts Save is a no-op; the file header reflects the wired behavior
- [ ] valid-input test asserts success SnackBar + route popped; invalid-input test asserts error SnackBar + not popped
- [ ] `flutter test test/features/meds/presentation/widgets/add_medication_modal_test.dart` is green; `dart analyze` passes

## Contracts
### Expects
- modal calls `addMedicationProvider` and pops on `Right` (task 011); `medsAdd*` error/success strings (task 010)
### Produces
- `add_medication_modal_test.dart` asserts wired Save behavior (success→pop, validation→error SnackBar, no-op assertions removed)

**Spec criteria addressed**: AC-18, AC-19, AC-24

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: test/features/meds/presentation/widgets/add_medication_modal_test.dart
**Contract**: Produces 1/1
**Notes**: Removed the spec-026 no-op-Save test + its lying comment; added group "Save — wired behavior (spec 032)" with 3 tests: (1) valid→success SnackBar + route popped, (2) empty name→`medsAddSaveErrorName` SnackBar + stays open, (3) Save disabled (onPressed==null) while in flight (Completer-backed fake). Pop made observable via a base-route harness (push the modal over a base Scaffold), per MEMORY 2026-06-12. Override: `addMedicationProvider.overrideWith((_) => AddMedication(_FakeMedicationRepository(), _FakeIdGenerator()))` — real use-case validation runs, repo faked (no drift). Modal-file tests 48/48; full suite **384/384**; analyze clean.
