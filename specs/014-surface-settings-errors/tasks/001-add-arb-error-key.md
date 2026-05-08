# Task 001: Add `settingsPersistenceError` ARB key in en/de/uk

**Agent**: mobile-engineer
**Status**: Complete
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb` (+ regenerated `lib/l10n/app_localizations*.dart` × 4)
**Depends on**: None
**Blocks**: 003
**Context docs**: `docs/i18n.md`
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-05-07
**Files changed**: lib/l10n/app_en.arb, app_de.arb, app_uk.arb (manual); app_localizations.dart, app_localizations_en.dart, app_localizations_de.dart, app_localizations_uk.dart (regenerated)
**Contract**: Expects 3/3 verified | Produces 5/5 verified
**Code review**: APPROVE (zero findings)
**Notes**: Translations validated as idiomatic in both German and Ukrainian by code-reviewer. Dartdoc on the abstract `app_localizations.dart` getter carries the description as expected (Feature 011 pitfall satisfied).

## Description

Add a single new localized string key, `settingsPersistenceError`, that the
SnackBar in Task 003 will display when a Settings preference fails to persist.
Mechanical i18n change following the established ARB pattern. Run
`flutter gen-l10n` to regenerate the localization classes — do not hand-edit
`lib/l10n/app_localizations*.dart`.

## Change details

- In `lib/l10n/app_en.arb`:
  - Add a new key/value pair `"settingsPersistenceError": "Couldn't save your preference. Please try again."` after the last existing settings-related key.
  - Add the matching `@settingsPersistenceError` description block:
    ```
    "@settingsPersistenceError": {
      "description": "SnackBar message shown on the Settings screen when a preference change fails to persist (e.g. SharedPreferences write error)."
    }
    ```
  - Maintain alphabetical or logical ordering with sibling settings keys; group near other `settingsX` keys.
- In `lib/l10n/app_de.arb`:
  - Add `"settingsPersistenceError": "Einstellung konnte nicht gespeichert werden. Bitte erneut versuchen."`
  - No `@`-description block (German file follows the existing convention of value-only entries — only `app_en.arb` carries `@key.description` blocks).
- In `lib/l10n/app_uk.arb`:
  - Add `"settingsPersistenceError": "Не вдалося зберегти налаштування. Спробуйте ще раз."`
- Run `flutter gen-l10n` to regenerate `app_localizations.dart`,
  `app_localizations_en.dart`, `app_localizations_de.dart`, and
  `app_localizations_uk.dart`. The regenerated abstract `String get
  settingsPersistenceError;` (in `app_localizations.dart`) must include the
  English description as dartdoc per Feature 011 lesson — verify by grep.

## Done when

- [x] `app_en.arb` contains `settingsPersistenceError` + matching `@settingsPersistenceError` block (`grep -F 'settingsPersistenceError' lib/l10n/app_en.arb` shows ≥ 2 matches).
- [x] `app_de.arb` contains `settingsPersistenceError` (`grep -F 'settingsPersistenceError' lib/l10n/app_de.arb` shows 1 match).
- [x] `app_uk.arb` contains `settingsPersistenceError` (`grep -F 'settingsPersistenceError' lib/l10n/app_uk.arb` shows 1 match).
- [x] `flutter gen-l10n` runs cleanly (exit 0, no warnings).
- [x] Regenerated `lib/l10n/app_localizations.dart` declares `String get settingsPersistenceError;`.
- [x] Regenerated `lib/l10n/app_localizations_en.dart`, `_de.dart`, `_uk.dart` each override the getter with their respective string.
- [x] `dart analyze` passes on `lib/l10n/` with zero issues.

## Spec criteria addressed

AC-8.

## Contracts

### Expects
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` exist and contain valid ARB JSON (already true).
- `l10n.yaml` is configured with `template-arb-file: app_en.arb` and `output-class: AppLocalizations` (already true).
- `lib/l10n/l10n_extensions.dart` exposes the `context.l10n` getter routing to `AppLocalizations.of(context)!` (already true — used widely).

### Produces
- `lib/l10n/app_en.arb` contains the literal key string `"settingsPersistenceError"` paired with the English value.
- `lib/l10n/app_de.arb` contains the literal key string `"settingsPersistenceError"` paired with the German value.
- `lib/l10n/app_uk.arb` contains the literal key string `"settingsPersistenceError"` paired with the Ukrainian value.
- Regenerated `lib/l10n/app_localizations.dart` declares the abstract getter `String get settingsPersistenceError;`.
- The expression `context.l10n.settingsPersistenceError` resolves to a `String` and compiles cleanly anywhere `l10n_extensions.dart` is imported.
