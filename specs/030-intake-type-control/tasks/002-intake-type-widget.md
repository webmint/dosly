# Task 002: Build the intake-type section in the modal (+ promote `clock`)

**Agent**: mobile-engineer
**Review checkpoint**: Yes
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`, `pubspec.yaml`
**Depends on**: 001
**Blocks**: 003
**Context docs**: None

**Description**:
Add the "Intake type" section to `AddMedicationModal`: an inline `SegmentedButton<_IntakeType>` (Continuous / Course) placed **after** the `_TimeChips` section and **before** the Save button, plus a `_CourseCard` private widget revealed only when Course is selected (Duration, Pause, a `showDatePicker` start-date field, and a live-computed date-range info chip). Promote the already-transitive `clock` package to a direct dependency so the default start date is `clock.now()`. All state is local; Save stays a no-op; no `domain/`/`data/` code.

Mirror established in-file patterns: private widgets driven by parent state + callbacks; conditional `if (...) ...[ widget ]` spreads (spec 028); the `InputDecorator(isEmpty:false,…)` outlined frame (`_QuantityStepper`); the `_StockCard` titled-container shape; the `showTimePicker` await/`mounted`/`setState` idiom (→ `showDatePicker`); and the `SegmentedButton` usage in `lib/features/settings/presentation/widgets/theme_selector.dart` (including the `selection.isEmpty` guard before `.first`).

**Change details**:
- In `pubspec.yaml`:
  - Add `clock: ^1.1.1` under `dependencies` (promotes the existing transitive dep — pin to the version `flutter pub deps | grep clock` reports). Run `flutter pub get`.
- In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:
  - Add `import 'package:clock/clock.dart';`.
  - Add a private `enum _IntakeType { continuous, course }` (with `///` doc) near the top-of-library option types.
  - Add a `_CourseCard` private `StatelessWidget` (dartdoc'd, visual-only note) shaped like `_StockCard`: a titled `Container` (`surfaceContainerLow`, `outlineVariant` border, radius 16, padding 16) with:
    - header row: `Icon(LucideIcons.repeat, color: colorScheme.tertiary)` + `Text(l10n.medsAddCourseParamsTitle, titleSmall)`;
    - a `Row` of two numeric `TextField`s — Duration (`key: ValueKey('medsAddCourseDuration')`, `keyboardType: number`, `controller: durationController`, `labelText: medsAddCourseDurationLabel`, `onChanged: onDurationChanged`) and Pause (`key: ValueKey('medsAddCoursePause')`, `controller: pauseController`, `labelText: medsAddCoursePauseLabel`);
    - a tappable start-date field: `InputDecorator(isEmpty:false, decoration: InputDecoration(labelText: medsAddCourseStartLabel, suffixIcon: Icon(LucideIcons.calendarDays)))` wrapping `Text(MaterialLocalizations.of(context).formatMediumDate(startDate))`, wrapped in `InkWell(onTap: onPickStart)`, `key: ValueKey('medsAddCourseStartField')`;
    - an info chip: a tertiary-container rounded `Container` (`key: ValueKey('medsAddCourseInfoChip')`) with a leading `Icon(LucideIcons.info, color: onTertiaryContainer)` and the computed label `Text`.
  - The `_CourseCard` takes: `durationController`, `pauseController`, `startDate`, `onPickStart`, `onDurationChanged`, and a precomputed `infoLabel` string (compute in the parent so the widget stays presentation-pure).
  - In `_AddMedicationModalState`:
    - add fields: `_IntakeType _intakeType = _IntakeType.continuous;`, `final TextEditingController _durationController = TextEditingController(text: '7');`, `final TextEditingController _pauseController = TextEditingController(text: '0');`, `DateTime _startDate = DateUtils.dateOnly(clock.now());`.
    - in `dispose()`: add `_durationController.dispose();` and `_pauseController.dispose();`.
    - add `_pickStartDate()`: `final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(_startDate.year - 1), lastDate: DateTime(_startDate.year + 5)); if (picked == null) return; if (!mounted) return; setState(() => _startDate = DateUtils.dateOnly(picked));` (mirror `_addTime`'s guard ordering).
    - add `_courseInfoLabel(AppLocalizations l10n, MaterialLocalizations ml)`: parse `int.tryParse(_durationController.text.trim())`; if `n != null && n >= 1`, `end = _startDate.add(Duration(days: n - 1))` and return `l10n.medsAddCourseRangeLabel('${ml.formatMediumDate(_startDate)} — ${ml.formatMediumDate(end)}', n)`; else return `l10n.medsAddCourseStartOnly(ml.formatMediumDate(_startDate))`.
  - In `build`, after the `_TimeChips` block and before the Save `FilledButton.icon`, insert:
    - `SizedBox(height: 16)`, `Text(context.l10n.medsAddIntakeTypeTitle, style: titleSmall)`, `SizedBox(height: 8)`;
    - a full-width `SegmentedButton<_IntakeType>` (`key: ValueKey('medsAddIntakeTypeSegmented')`) with two `ButtonSegment`s (continuous → `medsAddIntakeTypeContinuous` + `LucideIcons.infinity`; course → `medsAddIntakeTypeCourse` + `LucideIcons.repeat`), `selected: <_IntakeType>{_intakeType}`, `onSelectionChanged: (sel){ if (sel.isEmpty) return; setState(() => _intakeType = sel.first); }`;
    - `if (_intakeType == _IntakeType.course) ...[ const SizedBox(height: 16), _CourseCard(... infoLabel: _courseInfoLabel(context.l10n, MaterialLocalizations.of(context)), onPickStart: _pickStartDate, onDurationChanged: (_) => setState((){}) ) ]`.
  - Update the library-level dartdoc header to mention iteration 5 (intake-type section), matching the existing iteration notes.

**Status**: Complete

**Done when**:
- [x] `pubspec.yaml` lists `clock` under `dependencies`; `flutter pub get` succeeds with no version downgrades.
- [x] The modal renders the intake-type section after the intake-time chips and before Save (AC-1); a `SegmentedButton` with exactly two segments (AC-2).
- [x] On open `_intakeType == _IntakeType.continuous` and no `_CourseCard` is built (AC-3); selecting Course builds it (AC-4); selecting Continuous removes it (AC-5). *(impl verified; behaviorally test-confirmed in Task 003)*
- [x] `_CourseCard` shows the header, Duration (default `7`), Pause (default `0`), start-date field, and info chip (AC-6); start date defaults to `DateUtils.dateOnly(clock.now())` (AC-7).
- [x] Info label computes the inclusive range + plural for valid duration, and falls back to `medsAddCourseStartOnly` for empty/invalid duration (AC-9, AC-10).
- [x] `_durationController` and `_pauseController` are disposed (AC-12); no hardcoded user-facing strings (AC-11); Save unchanged, no domain/data added (AC-13).
- [x] `dart analyze` passes clean on changed files; the app still builds/compiles.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11 (no hardcoded), AC-12, AC-13

## Contracts

### Expects
- Generated `AppLocalizations` exposes `medsAddIntakeTypeTitle`, `medsAddIntakeTypeContinuous`, `medsAddIntakeTypeCourse`, `medsAddCourseParamsTitle`, `medsAddCourseDurationLabel`, `medsAddCoursePauseLabel`, `medsAddCourseStartLabel`, `medsAddCourseRangeLabel(String, int)`, `medsAddCourseStartOnly(String)` (from Task 001).
- `pubspec.lock` already contains `clock` as a transitive dependency.
- `add_medication_modal.dart` contains the `_TimeChips` section and the Save `FilledButton.icon` (spec 029 baseline).
- `lib/features/settings/presentation/widgets/theme_selector.dart` contains a `SegmentedButton` example with a `selection.isEmpty` guard.

### Produces
- `pubspec.yaml` contains `clock:` under `dependencies`.
- `add_medication_modal.dart` contains `import 'package:clock/clock.dart';` and `enum _IntakeType { continuous, course }`.
- `add_medication_modal.dart` declares `class _CourseCard`.
- `_AddMedicationModalState` declares fields `_intakeType`, `_durationController`, `_pauseController`, `_startDate`, and method `_pickStartDate`.
- `dispose()` in `_AddMedicationModalState` calls `_durationController.dispose()` and `_pauseController.dispose()`.
- `build` contains `SegmentedButton<_IntakeType>` and a `ValueKey('medsAddCourseCard')`-or-equivalent path gated on `_IntakeType.course`; the segmented button carries `ValueKey('medsAddIntakeTypeSegmented')`.
- `_CourseCard` subtree carries `ValueKey('medsAddCourseDuration')`, `ValueKey('medsAddCoursePause')`, `ValueKey('medsAddCourseStartField')`, `ValueKey('medsAddCourseInfoChip')`.

## Completion Notes

**Completed**: 2026-06-15
**Files changed**: pubspec.yaml (+ pubspec.lock), lib/features/meds/presentation/widgets/add_medication_modal.dart
**Contract**: Expects [4/4 verified] | Produces [8/8 verified — clock direct dep, package:clock import, `enum _IntakeType`, `class _CourseCard`, state fields, dispose calls, `SegmentedButton<_IntakeType>` + gated `_CourseCard`, all 5 ValueKeys]
**Verification**: dart analyze clean; flutter test 313/313 pass (no regression); clock resolved to 1.1.2 (no downgrade).
**Code review**: APPROVE WITH WARNINGS (review checkpoint). No Critical. W1: pubspec hand-edited instead of `flutter pub add` (process only; resolved state correct — logged in MEMORY). W2: showDatePicker firstDate/lastDate derived from `_startDate` not `clock.now()` — spec-accepted, no assertion risk since initialDate is always within the window. Both non-blocking; left as-is per "minimal changes".
**Notes**: end = start + (n-1) days (inclusive). `_courseInfoLabel` pure (int.tryParse fallback). `_CourseCard` presentation-pure (receives precomputed infoLabel). enum is multi-line (dartdoc per value). Behavioral ACs (3/4/5/8) implemented; full behavior asserted by Task 003 tests.
