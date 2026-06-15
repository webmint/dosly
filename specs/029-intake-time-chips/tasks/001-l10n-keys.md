# Task 001: Add the intake-time l10n keys

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb`, `lib/l10n/app_de.arb` (+ regenerated `lib/l10n/app_localizations*.dart`)
**Depends on**: None
**Blocks**: 002, 003
**Review checkpoint**: No
**Context docs**: None

**Description**:
Add the four user-visible strings the intake-time section needs to all three localization files, then regenerate the `AppLocalizations` delegates. This must land first so the widget in task 002 compiles against the new `context.l10n.medsAddTime*` getters. Follow the existing `medsAdd*` key + `@`-metadata convention already in the arb files (e.g. `medsAddSaveButton`). No ICU placeholders (the project's arb files use none).

**Change details**:
- In `lib/l10n/app_en.arb` — add four keys (each with a `@`-description block), grouped with the other `medsAdd*` keys:
  - `medsAddTimeTitle`: `"Intake time"` — section title.
  - `medsAddTimeAddChip`: `"Time"` — label of the dashed "+ time" add chip.
  - `medsAddTimeRemoveTooltip`: `"Remove time"` — tooltip/semantics label for the chip's × delete affordance.
  - `medsAddTimeDuplicate`: `"This time is already added"` — SnackBar message when a duplicate time is picked.
- In `lib/l10n/app_uk.arb` — same four keys, Ukrainian values: `"Час прийому"`, `"Час"`, `"Видалити час"`, `"Цей час уже додано"`.
- In `lib/l10n/app_de.arb` — same four keys, German values (e.g. `"Einnahmezeit"`, `"Zeit"`, `"Zeit entfernen"`, `"Diese Zeit ist bereits hinzugefügt"`).
- Run `flutter gen-l10n` (or `flutter pub get` which triggers it) so `lib/l10n/app_localizations.dart` and the per-locale files gain the four getters. Commit the regenerated files.

**Done when**:
- [x] All three arb files contain `medsAddTimeTitle`, `medsAddTimeAddChip`, `medsAddTimeRemoveTooltip`, `medsAddTimeDuplicate` with localized values + `@`-metadata in the template (`app_en.arb`).
- [x] `flutter gen-l10n` succeeds with no untranslated-message warnings for the new keys.
- [x] `lib/l10n/app_localizations.dart` declares getters `medsAddTimeTitle`, `medsAddTimeAddChip`, `medsAddTimeRemoveTooltip`, `medsAddTimeDuplicate`.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-11 (partial: AC-1, AC-7, AC-9 string sources)

## Completion Notes

**Completed**: 2026-06-14
**Files changed**: lib/l10n/app_en.arb, app_uk.arb, app_de.arb (+ regenerated app_localizations.dart, app_localizations_en/uk/de.dart)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified — 4 keys in each arb, 4 getters in app_localizations.dart]
**Notes**: Keys inserted after `medsAddUnitCapsule` to keep the `medsAdd*` group contiguous. EN carries `@`-description blocks; uk/de plain (matches file style). `dart analyze lib/l10n/` clean. Code review: APPROVE.

## Contracts

### Expects
- `lib/l10n/app_en.arb` exists and contains the key `medsAddSaveButton` (confirms the arb file + the `medsAdd*` naming/metadata pattern to copy).
- `lib/l10n/app_uk.arb` and `lib/l10n/app_de.arb` exist with a key set matching `app_en.arb`.
- `l10n.yaml` sets `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-class: AppLocalizations`.

### Produces
- `lib/l10n/app_en.arb` contains `medsAddTimeTitle`, `medsAddTimeAddChip`, `medsAddTimeRemoveTooltip`, `medsAddTimeDuplicate`.
- `lib/l10n/app_uk.arb` and `lib/l10n/app_de.arb` each contain the same four keys with localized (non-English) values.
- `lib/l10n/app_localizations.dart` declares `String get medsAddTimeTitle`, `String get medsAddTimeAddChip`, `String get medsAddTimeRemoveTooltip`, `String get medsAddTimeDuplicate`.
