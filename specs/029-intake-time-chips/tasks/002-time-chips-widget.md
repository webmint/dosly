# Task 002: Add the intake-time chips section to the modal

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: 001
**Blocks**: 003
**Review checkpoint**: Yes
**Context docs**: None

**Description**:
Add a presentation-only "Intake time" section to `AddMedicationModal`, mirroring the existing private-widget + local-state pattern used by `_MedicationFormPicker` / `_DoseField` / `_QuantityStepper` (same file). Introduce a `_TimeChips` private widget rendering one Material `InputChip` per selected `TimeOfDay` (clock avatar, 24-hour `HH:MM` label, `onPressed` → edit, `onDeleted` × → remove) followed by a dashed-outline `ActionChip` to add a new time. The parent `_AddMedicationModalState` owns a `List<TimeOfDay> _intakeTimes` and the add/edit/remove logic, keeping the list **sorted ascending** and **de-duplicated** (reject duplicates with a localized `SnackBar`). Times are forced to **24-hour** in both the picker dialog and the labels. This is **visual-only**: nothing is persisted, validated against domain rules, or read by Save (which stays a no-op).

**Change details**:
- In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:
  - Add a named constant `const _defaultPickerTime = TimeOfDay(hour: 8, minute: 0);` (no magic literal; matches the HTML seed `08:00`). Do **not** use `TimeOfDay.now()`.
  - Add a private `_TimeChips` `StatelessWidget` with dartdoc, taking: `List<TimeOfDay> times`, `void Function(int index) onEdit`, `void Function(int index) onRemove`, `VoidCallback onAdd`. It builds a `Wrap(spacing:, runSpacing:, children: [...])`:
    - For each time: an `InputChip` with `avatar: Icon(LucideIcons.clock, …)`, `label: Text(<24h HH:MM>)`, `onPressed: () => onEdit(i)`, `onDeleted: () => onRemove(i)`, `deleteIcon: Icon(LucideIcons.x, …)`, `deleteButtonTooltipMessage: context.l10n.medsAddTimeRemoveTooltip`. Take shape/colors from `Theme.of(context)`.
    - The trailing add chip: an `ActionChip` with `avatar: Icon(LucideIcons.plus, …)`, `label: Text(context.l10n.medsAddTimeAddChip)`, a `side: BorderSide(color: colorScheme.outline)` + transparent background to approximate the dashed `.t-chip.add` look, `onPressed: onAdd`.
  - In `_AddMedicationModalState`:
    - Add field `final List<TimeOfDay> _intakeTimes = [];`.
    - Add `String _formatTime(BuildContext context, TimeOfDay t)` → `MaterialLocalizations.of(context).formatTimeOfDay(t, alwaysUse24HourFormat: true)`.
    - Add `Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial)` that calls `showTimePicker(context: context, initialTime: initial, builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child ?? const SizedBox.shrink()))`.
    - Add `Future<void> _addTime()`: `final picked = await _pickTime(context, _defaultPickerTime); if (picked == null) return; if (!context.mounted) return;` then insert-or-reject (see dedupe/sort below).
    - Add `Future<void> _editTime(int index)`: pick with `initialTime: _intakeTimes[index]`; on `null` return; `if (!context.mounted) return;`; if the picked value equals the chip's own current value → silent no-op; else insert-or-reject excluding `index`.
    - Add `void _removeTime(int index)`: `setState(() => _intakeTimes.removeAt(index));`.
    - Add a private helper that, given a candidate `TimeOfDay` (and an optional index to exclude for edit), checks duplication by minutes-key (`t.hour * 60 + t.minute`); if duplicate → `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.medsAddTimeDuplicate)))` and return without mutating; otherwise `setState` to update/insert and re-sort `_intakeTimes` ascending by minutes-key.
  - In `build`, between the last conditional form-dependent block (the `_StockCard` `if`) and the `SizedBox(height: 16)` preceding the Save `FilledButton.icon`, insert:
    - `const SizedBox(height: 16)`,
    - a section title `Text(context.l10n.medsAddTimeTitle, style: …)` styled like other section labels,
    - `const SizedBox(height: 8)` (or matching spacing),
    - `_TimeChips(times: _intakeTimes, onEdit: _editTime, onRemove: _removeTime, onAdd: _addTime)`.
  - Confirm the exact `LucideIcons` names (`clock`, `x`, `plus`) compile via `dart analyze`; if a name is absent, substitute the verified equivalent and note it.
  - Do **not** change the Save button (stays `onPressed: () {}`), `dispose()` (no controllers added — `_intakeTimes` needs no disposal), or any domain/data file.

**Done when**:
- [x] `_TimeChips` renders only the add chip when `_intakeTimes` is empty (no `InputChip`).
- [x] Tapping the add chip opens `showTimePicker`; confirming appends a chip showing 24-hour `HH:MM`; cancelling changes nothing.
- [x] Tapping a chip body opens `showTimePicker` with `initialTime` = that chip's time; confirming replaces it; the × removes the chip without opening the picker.
- [x] `_intakeTimes` is kept ascending; picking a duplicate leaves it unchanged and shows the `medsAddTimeDuplicate` SnackBar; editing a chip to its own value is a silent no-op.
- [x] No `!` null-assertion anywhere; `mounted` is checked after each awaited `showTimePicker` before any `context` use.
- [x] Save remains a no-op; no `domain/`/`data/` files touched; `_intakeTimes` is not persisted.
- [x] `dart analyze` passes (verification deferred the heavy `flutter build apk`; compilation confirmed via clean analyze + the full widget-test suite compiling/passing in task 003).

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-12, AC-13

## Completion Notes

**Completed**: 2026-06-14
**Files changed**: lib/features/meds/presentation/widgets/add_medication_modal.dart (only)
**Contract**: Expects [3/3 verified] | Produces [5/5 verified — `_TimeChips`, `_intakeTimes`, `showTimePicker`, `alwaysUse24HourFormat: true`, `InputChip`+`ActionChip`, `medsAddTimeTitle` in build]
**Notes**: Lucide names `clock`/`x`/`plus` all confirmed real in lucide_icons_flutter 3.1.12 (no substitution). Label formatting via `MaterialLocalizations.formatTimeOfDay(t, alwaysUse24HourFormat: true)` inside `_TimeChips`; picker forced 24h via a `MediaQuery` builder. Dedup by minutes-key excluding the edited index; ascending sort after add/edit; edit-to-own-value short-circuits before `_commitTime`. Code review APPROVE WITH WARNINGS (no Critical): applied W2 (`if (!mounted) return;` self-guard at top of `_commitTime`) and I3 (class docstring → iterations 3–4). W1 (stale test-file header naming only specs 011/026/027) deferred to task 003's test file. All 18 pre-existing modal tests still pass (AC-14). The "40 deletions" in the WIP diff were pure `dart format` whitespace reflow (0 non-blank lines removed).

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` declares getters `medsAddTimeTitle`, `medsAddTimeAddChip`, `medsAddTimeRemoveTooltip`, `medsAddTimeDuplicate` (from task 001).
- `add_medication_modal.dart` defines `_AddMedicationModalState` whose `build` returns a `Scaffold` containing a `FilledButton.icon` Save button with `onPressed: () {}`.
- `add_medication_modal.dart` imports `package:flutter/material.dart` and `package:lucide_icons_flutter/lucide_icons.dart`.

### Produces
- `add_medication_modal.dart` declares a class `_TimeChips`.
- `_AddMedicationModalState` declares the field `final List<TimeOfDay> _intakeTimes`.
- `add_medication_modal.dart` contains a `showTimePicker(` call and the literal `alwaysUse24HourFormat: true`.
- `add_medication_modal.dart` references `InputChip` and `ActionChip`.
- `_AddMedicationModalState.build` references `_TimeChips` and `context.l10n.medsAddTimeTitle`.
