# Task 003: Widget tests for the form picker

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 002
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

## Description

Add widget tests for the form picker behavior (AC-13 a–d), and confirm every existing spec-026 / locale / AppBar / typography test still passes unchanged. The picker uses `InputDecorator` + `InkWell` (not `TextField`/`FilledButton`), so the existing structure assertions remain valid and must not be edited to accommodate the picker.

**MEMORY (Bug 020) — off-stage finders**: the grid is conditionally built only when open, so before expanding, its title/options are absent from the tree (`findsNothing` is clean). After tapping the display row, `pump()` (the expand may animate via `AnimatedSize`; `pumpAndSettle()` is fine here since there is no infinite animation) and then locate the options. Make each assertion self-validating (assert the localized strings actually appear/disappear) so a no-op tap can't pass silently.

## Change details

In `test/features/meds/presentation/widgets/add_medication_modal_test.dart`, add a new group (e.g. `group('AddMedicationModal form picker', ...)`) using the existing `_harness(locale: Locale('en'))` helper:

- **(a) Collapsed initial state**: pump the modal; assert `find.text('Medication form')` (the display-row label) `findsOneWidget`, `find.text('Choose a form')` (placeholder) `findsOneWidget`, and that the grid is collapsed — `find.text('Common forms')` `findsNothing` and the option names (e.g. `find.text('Tablet')`, `find.text('Syrup')`) `findsNothing`.
- **(b) Expand reveals title + 8 options**: tap the display row (locate it via the label text / its `InkWell` / the `medsAddFormLabel` `InputDecorator`), `pumpAndSettle()`; assert `find.text('Common forms')` `findsOneWidget` and that all 8 localized option names are present (`Tablet`, `Capsule`, `Syrup`, `Drops`, `Injection`, `Inhaler`, `Cream / Ointment`, `Sachet`) — `findsOneWidget` each (or assert a representative subset plus a count of option chips).
- **(c) Select updates display row + collapses**: with the grid open, tap a specific option (e.g. `Syrup`), `pumpAndSettle()`; assert the display row now shows `Syrup` and its sub `Liquid dosage form`, and the grid collapsed again (`find.text('Common forms')` `findsNothing`, the placeholder `Choose a form` no longer shown). Distinguish the display-row `Syrup` from the grid copy by asserting after collapse (grid gone → only the display-row instance remains).
- **(d) Single selection**: after selecting one option, re-open and select a different option; assert the display row reflects the latest selection only (no two selections persist). _(If selected-state styling is asserted, verify exactly one option chip carries the selected decoration; otherwise (c)'s "display row reflects latest" covers single-selection observably.)_
- **Preserve**: do not modify or delete the existing groups — `AddMedicationModal locale switching`, `AddMedicationModal structure` (incl. the TextField/FilledButton/Save-no-op tests), and `AddMedicationModal typography`. They must remain and pass.
- Update the top-of-file comment to note the new tests enforce spec 027 (in addition to the existing 026/011 references) — avoid a "lying comment" that names only the old specs (MEMORY).

## Contracts

### Expects
- `add_medication_modal.dart` mounts `_MedicationFormPicker` in the modal body; before selection the display row shows the `medsAddFormPlaceholder` text and the grid (title + 8 options) is absent until the row is tapped (Task 002 Produces).
- `app_localizations.dart` provides the 19 `medsAddForm*` getters with the EN values from Task 001 (`Medication form`, `Choose a form`, `Common forms`, `Tablet`/`Compressed form`, …).

### Produces
- `add_medication_modal_test.dart` contains a `form picker` test group asserting: placeholder + label before selection; grid title + 8 option names after expanding; selecting `Syrup` updates the display row to `Syrup` / `Liquid dosage form` and collapses the grid; single-selection behavior.
- The file still contains the `AddMedicationModal locale switching`, `AddMedicationModal structure`, and `AddMedicationModal typography` groups (unmodified assertions).

## Done when
- [x] New `form picker` test group covers AC-13 (a) collapsed+placeholder, (b) expand→title+8 options, (c) select→display update+collapse, (d) single selection.
- [x] All pre-existing tests (locale switching, structure incl. TextField/Save no-op, typography) remain and pass unchanged.
- [x] Assertions are self-validating (localized strings appear/disappear; no silent no-op tap).
- [x] `dart analyze` passes on the test file (zero issues).
- [x] `flutter test` passes for the full project.

## Spec criteria addressed
AC-13, AC-14 (and regression-guards AC-3, AC-4, AC-6)

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-13
**Files changed**: test/features/meds/presentation/widgets/add_medication_modal_test.dart
**Contract**: Expects [2/2 verified] | Produces [2/2 verified] — `form picker` group with 4 tests (AC-13 a–d); locale/structure/typography groups preserved
**Verification**: dart analyze clean; flutter test 299 pass (295 + 4 new); header updated to name specs 011/026/027
**Code review**: APPROVE WITH WARNINGS (non-blocking, not actioned): W1 add a defensive comment in test (d) noting "Syrup" appears in both display row + chip when re-opened (current code taps "Injection", unambiguous — no bug); W2 tests open only via chevron tap (full-row InkWell path untested); W3 test (a) could also assert `find.byIcon(LucideIcons.chevronDown)` present (AC-13a chevron). All minor test-polish; tests are correct and comprehensive for AC-13. Candidates for a future test-hardening pass.
