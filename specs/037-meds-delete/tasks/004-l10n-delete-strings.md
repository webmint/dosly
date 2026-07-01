# Task 004: Add delete l10n strings (EN/DE/UK) + regenerate

**Agent**: mobile-engineer
**Status**: Complete
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`, `lib/l10n/app_localizations*.dart` (regenerated)
**Depends on**: None
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

**Description**:
Add all user-facing strings for the delete flow to all three locale ARB files (English, German, Ukrainian), namespaced `medsDelete*` to match the existing `medsAdd*`/`medsEdit*` scheme, then regenerate the localizations. `medsDeleteDialogBody` takes a `{name}` placeholder (the medication name). Missing any locale fails `flutter gen-l10n` with an untranslated-message error (MEMORY: keep all three in sync).

**Change details**:
- Add these keys (with `@`-metadata: description, and for the body a `placeholders` entry for `name` of type `String`) to `app_en.arb`, `app_de.arb`, `app_uk.arb`:
  - `medsDeleteButtonTooltip` — e.g. EN "Delete medication"
  - `medsDeleteDialogTitle` — e.g. EN "Delete medication?"
  - `medsDeleteDialogBody` — e.g. EN "Delete \"{name}\"? This can't be undone." (placeholder `name`)
  - `medsDeleteDialogConfirm` — e.g. EN "Delete"
  - `medsDeleteDialogCancel` — e.g. EN "Cancel"
  - `medsDeleteSuccess` — e.g. EN "Medication deleted"
  - `medsDeleteError` — e.g. EN "Couldn't delete medication. Please try again."
- Provide idiomatic DE and UK translations for each (follow the tone of existing `medsEdit*` entries).
- Regenerate: `flutter gen-l10n` (updates `app_localizations.dart`, `app_localizations_en/de/uk.dart`).

**Done when**:
- [x] All 7 keys exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb` with `@`-metadata; `medsDeleteDialogBody` declares a `name` placeholder.
- [x] `flutter gen-l10n` completes with no untranslated-message error.
- [x] Generated `AppLocalizations` exposes `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody(String name)`, `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError`.
- [x] `dart analyze` passes.

**Spec criteria addressed**: AC-13

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `app_en.arb`, `app_de.arb`, `app_uk.arb` (+7 keys each) + 4 regenerated `app_localizations*.dart`
**Contract**: Expects [2/2 verified] | Produces [2/2 verified] (7 keys ×3 locales; `medsDeleteDialogBody(String name)` generated as a method at `app_localizations.dart:521`)
**Code review**: Self-reviewed (mechanical translation/generated content; `flutter gen-l10n` clean, `dart analyze` clean, key sets synchronized across locales).
**Notes**: `medsDeleteDialogBody` `@`-metadata/placeholder declared only in `app_en.arb` (template-arb convention); DE/UK keep the `{name}` token. No separate reviewer agent for data-only l10n.

## Contracts

### Expects
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` exist and contain `medsEditTitle`/`medsEditSaveSuccess`.
- `l10n.yaml` / gen-l10n config drives generation into `lib/l10n/app_localizations*.dart`.

### Produces
- `app_en.arb` (and DE/UK) contain keys `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody`, `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError`.
- Generated `AppLocalizations` declares getters/methods `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody(`, `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError`.
