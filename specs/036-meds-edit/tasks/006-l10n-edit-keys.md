# Task 006: Add edit-mode localization keys

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`
**Depends on**: None
**Blocks**: 007
**Context docs**: None
**Review checkpoint**: No

**Description**:
Add the two edit-mode strings the modal needs — an app-bar title and a save-success message — to all three locales, then regenerate the localizations. The Save button label is intentionally NOT added (edit mode reuses the existing `medsAddSaveButton` = "Save").

**Change details**:
- In `lib/l10n/app_en.arb`: add `medsEditTitle` = "Edit medication" and `medsEditSaveSuccess` = "Medication updated", each with an `@medsEditTitle` / `@medsEditSaveSuccess` description block (e.g. "App-bar title shown when editing an existing medication." / "SnackBar shown after an existing medication is successfully updated."). Place them near the existing `medsAddTitle` / `medsAddSaveSuccess` keys for diff locality.
- In `lib/l10n/app_de.arb`: add `medsEditTitle` = "Medikament bearbeiten" and `medsEditSaveSuccess` = "Medikament aktualisiert" (no `@`-description blocks — only the template ARB carries them).
- In `lib/l10n/app_uk.arb`: add `medsEditTitle` = "Редагувати ліки" and `medsEditSaveSuccess` = "Ліки оновлено".
- Run `flutter gen-l10n` so `AppLocalizations` gains `String get medsEditTitle` and `String get medsEditSaveSuccess`.

**Status**: Complete

**Done when**:
- [x] `medsEditTitle` and `medsEditSaveSuccess` exist in all three ARB files with matching placeholders (none here) and identical key sets across locales.
- [x] `app_en.arb` carries an `@`-description for each new key.
- [x] `flutter gen-l10n` runs cleanly and the generated `AppLocalizations` exposes `medsEditTitle` and `medsEditSaveSuccess` getters.
- [x] `dart analyze` passes.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `app_localizations*.dart`)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: en "Edit medication"/"Medication updated"; de "Medikament bearbeiten"/"Medikament aktualisiert"; uk "Редагувати ліки"/"Ліки оновлено". Placed next to the `medsAdd*` keys; en carries `@`-descriptions, de/uk do not (project convention). Code review = APPROVE (translations verified idiomatic, key-set parity confirmed). Save-button label intentionally reuses `medsAddSaveButton`.

## Contracts

### Expects
- `app_en.arb`, `app_de.arb`, `app_uk.arb` exist and contain `medsAddTitle` / `medsAddSaveSuccess`.
- The project uses `flutter gen-l10n` to generate `AppLocalizations`.

### Produces
- All three ARB files contain `medsEditTitle` and `medsEditSaveSuccess`.
- The generated `AppLocalizations` declares `String get medsEditTitle` and `String get medsEditSaveSuccess`.

**Spec criteria addressed**: AC-15
