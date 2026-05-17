# Task 001: Add `AppLanguage.fromLanguageCodeOrDefault` + adopt in data source

**Agent**: architect
**Files**:
- `lib/features/settings/domain/entities/app_language.dart` (modify)
- `lib/features/settings/data/datasources/settings_local_data_source.dart` (modify)
- `test/features/settings/domain/entities/app_language_test.dart` (create)

**Depends on**: None
**Blocks**: 005, 006
**Context docs**: None
**Review checkpoint**: No

## Description

Add a `static AppLanguage fromLanguageCodeOrDefault(String code)` factory to the existing `AppLanguage` enum that mirrors the existing `AppThemeMode.fromCodeOrDefault` shape: it scans `AppLanguage.values` for a matching `code` field and returns `AppLanguage.en` for any unmatched input (including unknown codes and the empty string).

Migrate the single existing `firstWhere(orElse: en)` literal in the data layer (`settings_local_data_source.dart::getManualLanguage`) to the new helper. The two presentation-layer migrations (in `language_selector.dart`) are deferred to Task 006 — separating presentation from domain/data keeps this task pure-Dart and lets the helper land standalone.

Create `test/features/settings/domain/entities/app_language_test.dart` (the file does not exist yet) with cases covering the three known codes (`'en'`, `'de'`, `'uk'`), at least one unknown code (`'xx'`), and the empty string — all unknown inputs must resolve to `AppLanguage.en`.

## Change details

- In `lib/features/settings/domain/entities/app_language.dart`:
  - Add a `static AppLanguage fromLanguageCodeOrDefault(String code)` factory inside the existing `AppLanguage` enum, after the existing `nativeName` field declaration.
  - Add a dartdoc comment on the factory explaining the fallback semantics and noting it mirrors `AppThemeMode.fromCodeOrDefault`.
  - The body should be `AppLanguage.values.firstWhere((lang) => lang.code == code, orElse: () => AppLanguage.en)`.

- In `lib/features/settings/data/datasources/settings_local_data_source.dart`:
  - In `getManualLanguage()` (~line 76), replace the explicit `AppLanguage.values.firstWhere((AppLanguage lang) => lang.code == code, orElse: () => AppLanguage.en)` block with `AppLanguage.fromLanguageCodeOrDefault(code)`.
  - The early `if (code == null) return AppLanguage.en;` guard stays — `fromLanguageCodeOrDefault` takes a non-null `String`.

- In `test/features/settings/domain/entities/app_language_test.dart` (create):
  - Use `package:flutter_test/flutter_test.dart` and `package:dosly/features/settings/domain/entities/app_language.dart`.
  - One `group('fromLanguageCodeOrDefault', () { ... })` with five tests:
    - `"resolves 'en' to AppLanguage.en"`, `"resolves 'de' to AppLanguage.de"`, `"resolves 'uk' to AppLanguage.uk"`
    - `"falls back to AppLanguage.en for unknown code 'xx'"`
    - `"falls back to AppLanguage.en for empty string"`

## Done when

- [x] `AppLanguage.fromLanguageCodeOrDefault(String)` exists, is `static`, and returns `AppLanguage`.
- [x] `settings_local_data_source.dart::getManualLanguage` uses the helper — `grep -n "AppLanguage.values.firstWhere" lib/features/settings/data/datasources/settings_local_data_source.dart` returns zero matches.
- [x] `test/features/settings/domain/entities/app_language_test.dart` exists with five passing test cases.
- [x] `dart analyze lib/features/settings/domain/entities/app_language.dart lib/features/settings/data/datasources/settings_local_data_source.dart test/features/settings/domain/entities/app_language_test.dart` exits 0.
- [x] `flutter test test/features/settings/domain/entities/app_language_test.dart test/features/settings/data/repositories/settings_repository_impl_test.dart` passes.

## Spec criteria addressed

AC-12, AC-13 (partial — data layer site only; widget sites land in Task 006).

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `lib/features/settings/domain/entities/app_language.dart` (+13 lines: dartdoc + static factory)
- `lib/features/settings/data/datasources/settings_local_data_source.dart` (-3, +1 lines: helper delegation)
- `test/features/settings/domain/entities/app_language_test.dart` (new, 5 tests)

**Contract**: Expects 2/2 verified | Produces 3/3 verified

**Notes**:
- Code review verdict: APPROVE with warnings.
- Warning (deferred): `fromLanguageCodeOrDefault(String code)` signature is asymmetric with `AppThemeMode.fromCodeOrDefault(String? code)`. Task file prescribed the non-nullable shape and the implementer followed it; the data-layer null guard stays. Task 006's planned call sites use `Localizations.localeOf(context).languageCode` (already non-nullable), so the asymmetry doesn't introduce a new null risk. If the asymmetry bothers a future reader, mirroring the `String?` shape is a one-line change.
- The implementer chose plain backtick (`` ` ``) for the dartdoc cross-reference to `AppThemeMode.fromCodeOrDefault` rather than a bracket-link, to avoid importing `AppThemeMode` solely for a doc hyperlink. Mirrors the inverse precedent in `app_theme_mode.dart:39`. Reviewer ratified.

## Contracts

### Expects
- `AppLanguage` enum exists in `lib/features/settings/domain/entities/app_language.dart` with three values `en`, `de`, `uk`, each carrying a `code: String` field.
- `settings_local_data_source.dart::getManualLanguage()` exists and returns `AppLanguage`.

### Produces
- `lib/features/settings/domain/entities/app_language.dart` exports `AppLanguage` with a public static method named `fromLanguageCodeOrDefault` taking a single `String` parameter and returning `AppLanguage`.
- `lib/features/settings/data/datasources/settings_local_data_source.dart` contains the literal `AppLanguage.fromLanguageCodeOrDefault(code)` inside `getManualLanguage` and does NOT contain the literal `AppLanguage.values.firstWhere`.
- `test/features/settings/domain/entities/app_language_test.dart` exists, uses `flutter_test`, and tests `fromLanguageCodeOrDefault` for `'en'`, `'de'`, `'uk'`, `'xx'`, and `''`.
