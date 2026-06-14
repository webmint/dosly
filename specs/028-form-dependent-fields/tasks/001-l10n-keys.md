# Task 001: Add the 14 form-field l10n keys

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb` (+ regenerated `lib/l10n/app_localizations*.dart`)
**Depends on**: None
**Blocks**: 002, 003
**Context docs**: `docs/features/i18n.md` (the 3-locale `flutter gen-l10n` pattern)
**Review checkpoint**: No

## Description

Add the **14** new localization keys for the form-dependent fields (8 labels/chrome + 6 unit abbreviations) to all three ARB files, then regenerate the bindings with `flutter gen-l10n`. This is a mechanical, additive extension of the established 3-locale pattern (same as spec 027's l10n task). Nothing consumes the keys yet, so the project stays green after this task. `@`-description metadata goes in `app_en.arb` only.

## Change details

In `lib/l10n/app_en.arb` — add the 14 keys with an `@`-description block for each (insert after the existing `medsAddForm*` keys, keeping JSON valid):

**Field labels & chrome (8):**
| key | EN value |
|---|---|
| `medsAddDoseLabel` | Dose |
| `medsAddDoseUnitLabel` | Unit |
| `medsAddQuantityLabel` | Quantity per intake |
| `medsAddStockTitle` | Pack stock |
| `medsAddStockNote` | For capsules, tablets and similar forms. Decreases automatically after each intake. |
| `medsAddStockRemainingLabel` | Remaining |
| `medsAddStockTotalLabel` | Total in pack |
| `medsAddStockWarnLabel` | Warn when remaining reaches |

**Unit abbreviations (6):**
| key | EN value |
|---|---|
| `medsAddUnitMl` | ml |
| `medsAddUnitMg` | mg |
| `medsAddUnitUnits` | units |
| `medsAddUnitDrops` | drops |
| `medsAddUnitTablet` | tab |
| `medsAddUnitCapsule` | cap |

In `lib/l10n/app_de.arb` — add the same 14 keys (values only, no `@` blocks):
`medsAddDoseLabel`=Dosis · `medsAddDoseUnitLabel`=Einheit · `medsAddQuantityLabel`=Menge pro Einnahme · `medsAddStockTitle`=Packungsbestand · `medsAddStockNote`=Für Kapseln, Tabletten und ähnliche Formen. Verringert sich automatisch nach jeder Einnahme. · `medsAddStockRemainingLabel`=Verbleibend · `medsAddStockTotalLabel`=Gesamt in Packung · `medsAddStockWarnLabel`=Warnen, wenn Restbestand erreicht · `medsAddUnitMl`=ml · `medsAddUnitMg`=mg · `medsAddUnitUnits`=IE · `medsAddUnitDrops`=Tropfen · `medsAddUnitTablet`=Tabl. · `medsAddUnitCapsule`=Kaps.

In `lib/l10n/app_uk.arb` — add the same 14 keys (values only, no `@` blocks):
`medsAddDoseLabel`=Доза · `medsAddDoseUnitLabel`=Одиниця · `medsAddQuantityLabel`=Кількість на прийом · `medsAddStockTitle`=Залишок у пачці · `medsAddStockNote`=Для капсул, таблеток та подібних форм. Автоматично зменшується після кожного прийому. · `medsAddStockRemainingLabel`=Залишок · `medsAddStockTotalLabel`=Всього в пачці · `medsAddStockWarnLabel`=Попередити коли лишиться · `medsAddUnitMl`=мл · `medsAddUnitMg`=мг · `medsAddUnitUnits`=од · `medsAddUnitDrops`=краплі · `medsAddUnitTablet`=табл · `medsAddUnitCapsule`=капс

Then run `flutter gen-l10n` to regenerate `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart`. **Do not hand-edit** the generated files.

## Contracts

### Expects
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` exist and already contain the spec-027 `medsAddForm*` keys.
- `l10n.yaml` declares `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-class: AppLocalizations`.

### Produces
- `app_en.arb` contains all 14 keys (`medsAddDoseLabel`, `medsAddDoseUnitLabel`, `medsAddQuantityLabel`, `medsAddStockTitle`, `medsAddStockNote`, `medsAddStockRemainingLabel`, `medsAddStockTotalLabel`, `medsAddStockWarnLabel`, `medsAddUnitMl`, `medsAddUnitMg`, `medsAddUnitUnits`, `medsAddUnitDrops`, `medsAddUnitTablet`, `medsAddUnitCapsule`), each with a matching `@`-description block.
- `app_de.arb` and `app_uk.arb` each contain all 14 keys with the DE/UK values above and **no** `@` blocks.
- `lib/l10n/app_localizations.dart` declares getters for all 14 keys (e.g. `String get medsAddQuantityLabel;`, `String get medsAddUnitTablet;`).

## Done when
- [x] All 14 keys exist in all three ARB files with the values above.
- [x] `app_en.arb` has an `@`-description for each of the 14 keys; `app_de.arb`/`app_uk.arb` have values only.
- [x] `flutter gen-l10n` runs cleanly with no untranslated-message warnings (all 14 present in all 3 locales).
- [x] `lib/l10n/app_localizations.dart` exposes the 14 getters.
- [x] `dart analyze` passes on the ARB-adjacent generated files (zero issues).
- [x] `flutter test` still passes (no consumer yet — project stays green).

## Spec criteria addressed
AC-9, AC-10, AC-11 (l10n correctness)

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-14
**Files changed**: lib/l10n/app_en.arb, app_de.arb, app_uk.arb (+ regenerated app_localizations.dart, _en, _de, _uk)
**Contract**: Expects [2/2 verified] | Produces [3/3 verified] — 14 keys in all 3 ARBs, `@`-meta EN-only (14 EN / 0 DE / 0 UK), 14 getters in app_localizations.dart
**Verification**: dart analyze "No issues found!"; flutter gen-l10n clean (no untranslated-message warnings); flutter test 299 pass
**Code review**: APPROVE WITH WARNINGS — W1: `medsAddUnitUnits` EN value "units" vs `@`-description "international units" vs DE "IE" was internally inconsistent (developer-facing). **RESOLVED 2026-06-14** (user chose International Units): EN "IU", DE "IE", UK "од"→"МО", `@`-desc → "Dose unit: international units (IU) — e.g. insulin, vitamins". Regenerated bindings; analyze clean; 305 tests pass. Info: UK `medsAddStockWarnLabel` could use a comma ("Попередити, коли лишиться"); `medsAddDoseLabel` description says "(liquid forms)" — accurate (solid forms use `medsAddQuantityLabel`).
