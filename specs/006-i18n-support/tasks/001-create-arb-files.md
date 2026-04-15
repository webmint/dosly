# Task 001: Create ARB translation files

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`
**Depends on**: None
**Blocks**: 002
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Description

Create the three ARB (Application Resource Bundle) source files that hold all translatable strings for the four keys `settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`. English is the template + fallback and carries `@key` metadata describing each string's purpose; German and Ukrainian provide the values without metadata.

ARB files are pure JSON data and do not affect compilation until Task 002 wires them into the build (`generate: true` + `l10n.yaml`). This task is therefore isolated and reversible.

## Change details

- Create directory `lib/l10n/` (new — does not exist yet).
- Create `lib/l10n/app_en.arb`:
  - Top-level JSON object.
  - `"@@locale": "en"`.
  - Four keys with English values and per-key `@key` metadata blocks (each metadata block contains at minimum a `description` field — one sentence describing where the string appears).
  - Values:
    - `settingsTooltip`: `"Settings"` — `description`: "Tooltip for the Settings icon button in the HomeScreen AppBar."
    - `bottomNavToday`: `"Today"` — `description`: "Label for the Today destination in the home bottom navigation bar."
    - `bottomNavMeds`: `"Meds"` — `description`: "Label for the Meds destination in the home bottom navigation bar."
    - `bottomNavHistory`: `"History"` — `description`: "Label for the History destination in the home bottom navigation bar."
- Create `lib/l10n/app_de.arb`:
  - `"@@locale": "de"`.
  - Same four keys, German values, NO `@key` metadata blocks.
  - Values: `settingsTooltip: "Einstellungen"`, `bottomNavToday: "Heute"`, `bottomNavMeds: "Medikamente"`, `bottomNavHistory: "Verlauf"`.
- Create `lib/l10n/app_uk.arb`:
  - `"@@locale": "uk"`.
  - Same four keys, Ukrainian values, NO `@key` metadata blocks.
  - Values: `settingsTooltip: "Налаштування"`, `bottomNavToday: "Сьогодні"`, `bottomNavMeds: "Ліки"`, `bottomNavHistory: "Історія"`.
- JSON must be valid (double-quoted keys and values, no trailing commas, UTF-8 encoding — required for Cyrillic).

## Contracts

### Expects
- `lib/l10n/` directory does not exist yet (verified by reading project tree; spec confirms no prior i18n infrastructure).
- No ARB files currently exist in the repo.

### Produces
- `lib/l10n/app_en.arb` exists, is valid JSON, contains keys `settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory` and corresponding `@settingsTooltip`, `@bottomNavToday`, `@bottomNavMeds`, `@bottomNavHistory` metadata blocks with a `description` field each.
- `lib/l10n/app_de.arb` exists, is valid JSON, contains the same four keys with German values and `"@@locale": "de"`.
- `lib/l10n/app_uk.arb` exists, is valid JSON, contains the same four keys with Ukrainian values (UTF-8 Cyrillic) and `"@@locale": "uk"`.

## Done when

- [x] All three ARB files exist at `lib/l10n/`.
- [x] Each file is valid JSON (can be parsed — quick sanity check: `python3 -c "import json; json.load(open('lib/l10n/app_en.arb'))"` succeeds for each file).
- [x] Each file contains all four keys (`settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`).
- [x] `app_en.arb` contains `@`-prefixed metadata blocks for each of the four keys, each with a non-empty `description` field.
- [x] `app_de.arb` and `app_uk.arb` do NOT contain `@key` metadata blocks.
- [x] Ukrainian file contains the expected Cyrillic characters (no mojibake) — visually inspect `lib/l10n/app_uk.arb`.
- [x] `dart analyze` produces zero warnings or errors (ARB files are not analyzed by Dart, so this is verified incidentally — the analyzer should remain clean).

## Spec criteria addressed
AC-3

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: `lib/l10n/app_en.arb` (new), `lib/l10n/app_de.arb` (new), `lib/l10n/app_uk.arb` (new)
**Contract**: Expects 2/2 verified | Produces 3/3 verified
**Notes**: No deviations. Code review APPROVE with no Critical/Warning findings. `dart analyze` clean. UTF-8 Cyrillic renders correctly in `app_uk.arb` (no escape sequences or mojibake).
