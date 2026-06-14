# Task 001: Add the 19 medication-form l10n keys

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb` (+ regenerated `lib/l10n/app_localizations*.dart`)
**Depends on**: None
**Blocks**: 002, 003
**Context docs**: None
**Review checkpoint**: No

## Description

Add the 19 new localization keys the form picker needs (3 chrome + 8 form names + 8 form sub-descriptions) to all three ARB files, then regenerate the bindings with `flutter gen-l10n`. Follows the established 3-locale pattern (MEMORY F006): keys in all three ARBs, `@`-description metadata **only** in `app_en.arb`. Nothing consumes these keys yet, so the project stays green after this task.

## Change details

- In `lib/l10n/app_en.arb` (after the existing `medsAddSaveButton` / `@medsAddSaveButton` entries; add a comma after the current last top-level entry as needed to keep valid JSON):
  - Add each key with its EN value **and** an `@`-description block:
    - `medsAddFormLabel` = `"Medication form"` — floating label on the form-picker display row.
    - `medsAddFormPlaceholder` = `"Choose a form"` — display-row text before a form is selected.
    - `medsAddFormGridTitle` = `"Common forms"` — title above the form grid.
    - `medsAddFormTablet` = `"Tablet"`, `medsAddFormTabletSub` = `"Compressed form"`
    - `medsAddFormCapsule` = `"Capsule"`, `medsAddFormCapsuleSub` = `"Hard gelatin shell"`
    - `medsAddFormSyrup` = `"Syrup"`, `medsAddFormSyrupSub` = `"Liquid dosage form"`
    - `medsAddFormDrops` = `"Drops"`, `medsAddFormDropsSub` = `"Liquid drop form"`
    - `medsAddFormInjection` = `"Injection"`, `medsAddFormInjectionSub` = `"Intramuscular / IV"`
    - `medsAddFormInhaler` = `"Inhaler"`, `medsAddFormInhalerSub` = `"Aerosol form"`
    - `medsAddFormCream` = `"Cream / Ointment"`, `medsAddFormCreamSub` = `"Topical form"`
    - `medsAddFormSachet` = `"Sachet"`, `medsAddFormSachetSub` = `"Soluble powder"`
  - Each `@`-block: `{ "description": "<concise description of where the string is used>" }`. The name/sub descriptions should note the form and that it is a medication-form option in the Add-medication picker.
- In `lib/l10n/app_de.arb` (values only, **no** `@` blocks):
  - `medsAddFormLabel` = `"Medikamentenform"`, `medsAddFormPlaceholder` = `"Form wählen"`, `medsAddFormGridTitle` = `"Typische Formen"`
  - tablet `"Tablette"` / `"Gepresste Form"`; capsule `"Kapsel"` / `"Harte Gelatinehülle"`; syrup `"Sirup"` / `"Flüssige Darreichungsform"`; drops `"Tropfen"` / `"Flüssige Tropfenform"`; injection `"Injektion"` / `"Intramuskulär / i.v."`; inhaler `"Inhalator"` / `"Aerosolform"`; cream `"Creme / Salbe"` / `"Äußerliche Form"`; sachet `"Sachet"` / `"Lösliches Pulver"`
- In `lib/l10n/app_uk.arb` (values only, **no** `@` blocks):
  - `medsAddFormLabel` = `"Форма препарату"`, `medsAddFormPlaceholder` = `"Оберіть форму"`, `medsAddFormGridTitle` = `"Типові форми"`
  - tablet `"Таблетка"` / `"Пресована форма"`; capsule `"Капсули"` / `"Тверда желатинова оболонка"`; syrup `"Сироп"` / `"Рідка лікарська форма"`; drops `"Краплі"` / `"Рідка крапельна форма"`; injection `"Ін'єкція"` / `"Внутрішньом'язова/в/в"`; inhaler `"Інгалятор"` / `"Аерозольна форма"`; cream `"Крем / Мазь"` / `"Зовнішня форма"`; sachet `"Саше"` / `"Розчинний порошок"`
- Run `flutter gen-l10n` to regenerate `app_localizations.dart` + the three per-locale files. Do **not** hand-edit the generated files.

## Contracts

### Expects
- `lib/l10n/app_en.arb` is valid JSON and contains the key `medsAddSaveButton` (the last existing meds key).
- `lib/l10n/app_de.arb` and `lib/l10n/app_uk.arb` contain `medsAddSaveButton` and follow the values-only (no `@`) convention.
- `flutter gen-l10n` is the configured binding generator (an `l10n.yaml` / `gen-l10n` setup already produces `lib/l10n/app_localizations*.dart`).

### Produces
- `app_en.arb`, `app_de.arb`, and `app_uk.arb` each contain all 19 keys: `medsAddFormLabel`, `medsAddFormPlaceholder`, `medsAddFormGridTitle`, `medsAddFormTablet`, `medsAddFormCapsule`, `medsAddFormSyrup`, `medsAddFormDrops`, `medsAddFormInjection`, `medsAddFormInhaler`, `medsAddFormCream`, `medsAddFormSachet`, and the 8 `*Sub` variants.
- `app_en.arb` contains an `@`-description block for each of the 19 keys; `app_de.arb` and `app_uk.arb` contain none of those `@`-blocks.
- `lib/l10n/app_localizations.dart` declares an abstract getter for each of the 19 keys (e.g. `String get medsAddFormLabel;` … `String get medsAddFormSachetSub;`).

## Done when
- [x] All 19 keys present in all three ARB files with the values above.
- [x] `app_en.arb` has `@`-metadata for all 19 keys; DE/UK have none.
- [x] `flutter gen-l10n` regenerated `app_localizations*.dart` with the 19 getters (no untranslated-message warnings for these keys).
- [x] `dart analyze` passes on changed files (zero issues).
- [x] `flutter test` still passes (additive, nothing consumes the keys yet).

## Spec criteria addressed
AC-9, AC-10 (and enables AC-5/AC-11 string consumption in Task 002).

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-13
**Files changed**: lib/l10n/app_en.arb, app_de.arb, app_uk.arb (+ regenerated app_localizations.dart, app_localizations_en.dart, app_localizations_de.dart, app_localizations_uk.dart)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified] — 19 keys in each ARB; 19 @-blocks in en / 0 in de+uk; 19 getters in app_localizations.dart
**Verification**: dart analyze clean; flutter test 295 pass; gen-l10n no warnings
**Code review**: APPROVE WITH WARNINGS
**Notes**: One review warning — UK `medsAddFormCapsule` = "Капсули" (plural) vs singular for other forms. This is the VERBATIM design value (`dosly_m3_template.html:2035` `data-name="Капсули"`) per spec §3.6, and spec §8 defers wording to the user (translator). Left as-is; user may adjust. EN-locale tests (Task 003) are unaffected.
