# Task 002: Add name field + no-op Save button to AddMedicationModal (+ update test)

**Agent**: mobile-engineer
**Review checkpoint**: Yes
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 001
**Blocks**: None
**Context docs**: None

> **Why a review checkpoint**: This is the substantive visual change and the user cares about HTML-design fidelity (spec 011 was reworked because it "looked absolutely different from HTML"). Verify the field + Save button visually match `dosly_m3_template.html` Screen 3 before marking done.

## Description

Replace the empty body of `AddMedicationModal` with the two controls from the design's "Screen 3 — Add / Edit Medication": an outlined medication-name `TextField` and a full-width `FilledButton.icon` Save button. The Save button is a **documented no-op** this iteration — it does not read, validate, persist, navigate, pop, or show feedback. To own a `TextEditingController` the widget must become a `StatefulWidget` (it is currently `StatelessWidget`). Update the widget's existing test in the same task: the current `body is empty (SizedBox.shrink)` assertions break the moment the field/button are added, so they are replaced; the locale-switching, back-arrow-leading, and title-typography tests must remain and keep passing.

## Change details

- In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:
  - Convert `AddMedicationModal` from `StatelessWidget` to `StatefulWidget` with a `State<AddMedicationModal>`.
  - In the `State`, declare `final TextEditingController _nameController = TextEditingController();` and override `dispose()` to call `_nameController.dispose()` (call `super.dispose()` last).
  - Keep the `AppBar` exactly as-is (back-arrow `IconButton` leading with `LucideIcons.arrowLeft` → `Navigator.pop`, `backButtonTooltip`, `title: Text(context.l10n.medsAddTitle)`).
  - Replace `body: const SizedBox.shrink()` with a `SingleChildScrollView` → `Padding(EdgeInsets.all(16))` → `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` containing, in order:
    1. `TextField(controller: _nameController, decoration: InputDecoration(labelText: context.l10n.medsAddNameLabel, border: const OutlineInputBorder()))` — no explicit colors/fill/text style.
    2. spacing (e.g. `SizedBox(height: 16)`).
    3. `FilledButton.icon(onPressed: () { /* no-op */ }, icon: const Icon(LucideIcons.save), label: Text(context.l10n.medsAddSaveButton))` — non-null `onPressed` so the button renders enabled; an inline comment must state the no-op is intentional for iteration 1 and reference spec 026 (the data-save iteration will replace it). No bare `TODO`.
  - Update the library-level and class-level dartdoc to describe the new body (name field + Save button) and that Save is an intentional iteration-1 no-op.
- In `test/features/meds/presentation/widgets/add_medication_modal_test.dart`:
  - Remove the `body is empty (SizedBox.shrink)` test (and its `findsNothing` assertions for `TextField`/`Form`/buttons + the `scaffold.body` `SizedBox` assertion).
  - Add a test: the modal renders a `TextField` whose `InputDecoration.labelText` equals the localized `medsAddNameLabel` ("Medication name" under `Locale('en')`).
  - Add a test: the modal renders a `FilledButton` whose visible label text equals the localized `medsAddSaveButton` ("Save"), and whose icon resolves to `LucideIcons.save`.
  - Add a test: tapping the Save button (`tester.tap` + `pump`) completes without throwing and does NOT pop the modal (the `AddMedicationModal` is still present after the tap).
  - Keep the existing en/de/uk title tests, the back-arrow-leading test, and the title-typography test unchanged and passing.

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` declares `String get medsAddNameLabel;` and `String get medsAddSaveButton;` (from Task 001).
- `lib/features/meds/presentation/widgets/add_medication_modal.dart` exports `class AddMedicationModal` and imports `context.l10n` via `../../../../l10n/l10n_extensions.dart`.
- `lucide_icons_flutter` exposes `LucideIcons.save` (verified: `lucide_icons.dart` declares `static const IconData save`).

### Produces
- `add_medication_modal.dart` declares `class AddMedicationModal extends StatefulWidget` and a corresponding `State` class.
- The `State` declares a `TextEditingController` field and its `dispose()` calls `.dispose()` on that controller.
- `add_medication_modal.dart` contains a `TextField` whose decoration uses `context.l10n.medsAddNameLabel` and an `OutlineInputBorder`, and a `FilledButton.icon` using `LucideIcons.save` and `context.l10n.medsAddSaveButton`.
- `add_medication_modal.dart` body is a `SingleChildScrollView` and no longer uses `SizedBox.shrink` as the Scaffold body.
- `add_medication_modal_test.dart` no longer asserts `scaffold.body` is a `SizedBox`; it asserts the localized name label and Save-button label/icon are present.

## Done when

- [x] `AddMedicationModal` is a `StatefulWidget`; its `State` disposes the `TextEditingController` in `dispose()`.
- [x] Body is a `SingleChildScrollView` with a padded `Column` containing the name `TextField` (label `medsAddNameLabel`, `OutlineInputBorder`) and a full-width `FilledButton.icon` (`LucideIcons.save` + `medsAddSaveButton`).
- [x] Save button `onPressed` is a non-null no-op, documented inline with a reference to spec 026 (no bare TODO).
- [x] All visible strings use `context.l10n`; no `AppLocalizations.of(context)!` and no `!` at the call site.
- [x] AppBar, back-arrow leading, title, and push mechanics are unchanged.
- [x] Test file updated: empty-body assertions removed; field-label, Save-button-label/icon, and no-op-tap-harmless assertions added; locale/back-arrow/typography tests still pass.
- [x] `dart analyze` passes on changed files with zero issues (controller-disposal lint satisfied; no lint-suppression).
- [x] `flutter test` passes for the full project.
- [x] `flutter build apk --debug` succeeds.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-8, AC-9, AC-10, AC-11, AC-12 (AC-13 = manual, verified by /verify)

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-12
**Files changed**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Contract**: Expects 3/3 verified | Produces 5/5 verified (StatefulWidget + `_AddMedicationModalState` with disposed `_nameController`; `TextField`→`medsAddNameLabel`+`OutlineInputBorder`; `FilledButton.icon`→`LucideIcons.save`+`medsAddSaveButton`; body is `SingleChildScrollView`, no `SizedBox.shrink`; test no longer asserts `SizedBox` body)
**Verification**: `dart analyze` → No issues; `flutter test` → 294 passed; `flutter build apk --debug` → built. Code review: APPROVE WITH WARNINGS → both warnings fixed (stale spec-011 header rewritten to name both specs; unguarded `as Icon` cast guarded with `isA<Icon>()`).
**Notes**: First `TextField` / first controller-owning `StatefulWidget` in the project — `add_medication_modal.dart` is the template for future form-field iterations. Reviewer Info (deferred to data-save iteration): the explicit `border: const OutlineInputBorder()` overrides the global filled+rounded `inputDecorationTheme` (`app_theme.dart`); later iterations should reconcile the design's outlined look with the global input theme. Save `onPressed: () {}` is an intentional documented no-op.
