# Task 001: Add splash/error/retry localization strings

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb` (+ regenerated `lib/l10n/app_localizations*.dart`)
**Depends on**: None
**Blocks**: 003
**Context docs**: None
**Review checkpoint**: No
**Status**: Complete

## Description

Add the three user-facing strings the bootstrap splash and prefs-failure error UI need, in all three supported locales (en, de, uk), then regenerate the gen_l10n output. This task is first because `flutter gen-l10n` is a natural rollback boundary — if any ARB is missing a key, codegen fails before any source consumer is touched (MEMORY L226). English ARB carries `@`-metadata description blocks (translator-facing, also copied into the generated dartdoc per MEMORY L206); de/uk are value-only, matching the existing file conventions.

## Change details

- In `lib/l10n/app_en.arb` (add after `errorScreenGoHome`, before the closing `}`):
  - `"splashLoading": "Loading…"` + `@splashLoading` description (e.g. "Label shown on the startup splash screen while app preferences are being loaded.")
  - `"prefsLoadErrorMessage": "We couldn't load your preferences."` + `@prefsLoadErrorMessage` description (e.g. "Message on the startup error screen shown when SharedPreferences hydration fails.")
  - `"prefsLoadRetry": "Retry"` + `@prefsLoadRetry` description (e.g. "Label for the button on the startup error screen that retries loading preferences.")
- In `lib/l10n/app_de.arb` (add after `errorScreenGoHome`, value-only):
  - `"splashLoading": "Wird geladen…"`
  - `"prefsLoadErrorMessage": "Ihre Einstellungen konnten nicht geladen werden."`
  - `"prefsLoadRetry": "Erneut versuchen"`
- In `lib/l10n/app_uk.arb` (add after `errorScreenGoHome`, value-only):
  - `"splashLoading": "Завантаження…"`
  - `"prefsLoadErrorMessage": "Не вдалося завантажити ваші налаштування."`
  - `"prefsLoadRetry": "Повторити"`
- Run `flutter gen-l10n` to regenerate `lib/l10n/app_localizations*.dart`.

## Contracts

### Expects
- `lib/l10n/app_en.arb` is a JSON object with `"@@locale": "en"` and already contains the key `errorScreenGoHome`.
- `lib/l10n/app_de.arb` and `lib/l10n/app_uk.arb` already contain the key `errorScreenGoHome`.
- gen_l10n is configured (`lib/l10n/app_localizations.dart` exists and declares `String get errorScreenGoHome`).

### Produces
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` each contain the keys `splashLoading`, `prefsLoadErrorMessage`, `prefsLoadRetry`.
- `lib/l10n/app_localizations.dart` declares `String get splashLoading`, `String get prefsLoadErrorMessage`, and `String get prefsLoadRetry`.

## Done when
- [x] All three keys exist in all three ARB files with the values above.
- [x] `app_en.arb` includes `@`-description blocks for the three new keys.
- [x] `flutter gen-l10n` completes; `app_localizations.dart` exposes the three getters.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-7

## Completion Notes
**Completed**: 2026-05-23
**Files changed**: lib/l10n/app_en.arb, app_de.arb, app_uk.arb, app_localizations.dart (+de/en/uk generated)
**Contract**: Expects [3/3 verified] | Produces [getters 3/3 verified, keys 3/3 in all locales]
**Notes**: Used U+2026 ellipsis in loading strings. Translations align with existing terminology (Einstellungen/налаштування). Code review done inline (pure additive l10n, matches feature-019 pattern) — APPROVE.
