# Task 005: Edit-modal trash affordance + confirm dialog + delete handler

**Agent**: mobile-engineer
**Status**: Complete
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: 003, 004
**Blocks**: 007
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
Wire the delete UI into `AddMedicationModal`. In **edit mode only** (`widget.initial != null`) render a trailing trash `IconButton` in the AppBar; tapping it opens a Material `AlertDialog` confirmation (`showDialog<bool>`); on confirm, invoke `deleteMedicationProvider`, and on success pop the modal and show a success SnackBar, on failure show an error SnackBar and stay open. This reuses the proven `_onSave` async-mutation idiom exactly — capture `ScaffoldMessenger`/`Navigator`/`l10n` before the `await`, guard `mounted`, and use an `_isDeleting` in-flight flag (mirrors `_isSaving`) to prevent double-invocation and satisfy `use_build_context_synchronously` (lints are errors here).

**Change details**:
- In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:
  - Add state field `bool _isDeleting = false;` near `_isSaving`.
  - In the `build` method's `AppBar`, add an `actions:` list rendered only when `widget.initial != null`: an `IconButton(icon: Icon(LucideIcons.trash2, color: Theme.of(context).colorScheme.error), tooltip: context.l10n.medsDeleteButtonTooltip, onPressed: (_isDeleting || _isSaving) ? null : _onDelete)`. In add mode render no delete action.
  - Add `Future<bool> _confirmDelete(Medication medication)` that returns `await showDialog<bool>(...) ?? false`, building a Material `AlertDialog` with `title: Text(l10n.medsDeleteDialogTitle)`, `content: Text(l10n.medsDeleteDialogBody(medication.name))`, and actions: a Cancel `TextButton` (`Navigator.pop(ctx, false)`) and a Delete `TextButton` (`Navigator.pop(ctx, true)`) whose label uses `TextButton.styleFrom(foregroundColor: colorScheme.error)`.
  - Add `Future<void> _onDelete()` mirroring `_onSave`: read `original = widget.initial`; if null return (defensive). Capture `l10n`, `messenger = ScaffoldMessenger.of(context)`, `navigator = Navigator.of(context)` before any await. `if (!await _confirmDelete(original)) return;` then `if (!mounted) return;` `setState(() => _isDeleting = true);` `final result = await ref.read(deleteMedicationProvider).call(original.id);` `if (!mounted) return;` `result.fold((_) { setState(() => _isDeleting = false); messenger.showSnackBar(SnackBar(content: Text(l10n.medsDeleteError))); }, (_) { messenger.showSnackBar(SnackBar(content: Text(l10n.medsDeleteSuccess))); navigator.pop(); });`
  - Keep dartdoc on the new methods; update the class/library docs to mention the edit-mode delete affordance.

**Done when**:
- [x] In edit mode the AppBar shows a trash `IconButton` (error-tinted) with the `medsDeleteButtonTooltip` tooltip; in add mode no delete action is present.
- [x] Tapping the trash icon shows a Material `AlertDialog` whose content includes the medication name; Cancel dismisses with no side effect, Delete proceeds.
- [x] On confirm, `ref.read(deleteMedicationProvider).call(original.id)` is invoked; `Right` → success SnackBar + modal pops; `Left` → error SnackBar + modal stays open.
- [x] `messenger`/`navigator`/`l10n` are captured before the `await`; `mounted` is checked after awaits; `_isDeleting` disables the action while in flight.
- [x] `dart analyze` passes with no `use_build_context_synchronously` warning.

**Spec criteria addressed**: AC-7, AC-8, AC-9, AC-10, AC-11, AC-12

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `add_medication_modal.dart` (+`_isDeleting`, `_confirmDelete`, `_onDelete`, edit-only AppBar `actions:` trash button; ~129 additive lines + 1-line repair)
**Contract**: Expects [4/4 verified] | Produces [4/4 verified]
**Code review**: APPROVE with warnings → warning addressed. Reviewer flagged an asymmetric in-flight guard (Save button only checked `_isSaving`, not `_isDeleting`) → a narrow race between concurrent save+delete on the same id. Fixed: Save guard now `(_isSaving || _isDeleting) ? null : _onSave` (line 1990), symmetric with the trash button (1810).
**Notes**: Purely additive; `_onSave`/form/initState untouched. Context captured before awaits (no `use_build_context_synchronously`). Full suite 568 tests green; modal tests 61/61. Delete uses `original.id` (no rebuilt aggregate).

## Contracts

### Expects
- `medication_providers.g.dart` defines `deleteMedicationProvider` (Task 003) and `DeleteMedication.call(MedicationId)` returns `Future<Either<Failure, void>>`.
- `AppLocalizations` exposes `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody(String name)`, `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError` (Task 004).
- `AddMedicationModal` has `final Medication? initial;`, an AppBar in `build`, a `_isSaving` flag, and an `_onSave` method that captures context before `await`.
- `Medication` exposes `.id` (`MedicationId`) and `.name` (`String`); `LucideIcons` is imported in this file.

### Produces
- `add_medication_modal.dart` declares `_onDelete(` and `_confirmDelete(` and a `bool _isDeleting` field.
- The AppBar `actions:` renders an `IconButton` with `LucideIcons.trash2` gated on `widget.initial != null`.
- `_onDelete` calls `ref.read(deleteMedicationProvider).call(` and `navigator.pop()` on the success branch.
- `_confirmDelete` calls `showDialog<bool>(` returning an `AlertDialog`.
