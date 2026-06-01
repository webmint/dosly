# Task 003: Add resolveAppLocale unit test

**Agent**: qa-engineer
**Status**: Complete
**Files**: `test/core/l10n/locale_resolver_test.dart`
**Depends on**: None
**Blocks**: 004, 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-05-27
**Files changed**: test/core/l10n/locale_resolver_test.dart (new, 4 tests)
**Contract**: Expects [1/1 verified] | Produces [2/2 verified]
**Notes**: Pure-Dart unit test; `de`-first supported list makes the English-pin
regression guard explicit (unsupported `fr` → `en`, not `de`). Country-code test
confirms languageCode-only matching. Code review APPROVE-with-warnings; the sole
warning (`package:flutter/widgets.dart` vs `dart:ui show Locale`) accepted as-is
— matches the production `locale_resolver.dart` import style (§3.5 consistency).

**Description**:
Add the missing direct unit test for `resolveAppLocale`
(`lib/core/l10n/locale_resolver.dart`), Bug 016 sub-item 9 — already filed as
a known coverage Warning by spec 021's `/verify` (MEMORY L110). The function
pins the English fallback regardless of `supportedLocales` ordering (which
gen_l10n emits alphabetically as `de`, `en`, `uk` — see MEMORY L89). This test
is the contract that lets Task 004 safely point all harnesses at the function.

**Change details**:
- Create `test/core/l10n/locale_resolver_test.dart`:
  - `resolveAppLocale(null, supported)` → `const Locale('en')`.
  - `resolveAppLocale(const Locale('uk'), supported)` → the matching supported `Locale('uk')`.
  - `resolveAppLocale(const Locale('fr'), supported)` (unsupported) → `const Locale('en')` — assert this holds even when `supported` starts with `de` (e.g. pass `[Locale('de'), Locale('en'), Locale('uk')]`) to prove ordering-independence.
  - Optionally assert matching by `languageCode` ignores country (`Locale('en', 'US')` → `Locale('en')`).
  - Pure Dart test — no widgets, no pump.

**Done when**:
- [ ] All three core branches (null / supported / unsupported) are asserted, with the unsupported case using a `de`-first list to prove the English pin.
- [ ] The test is pure (no `WidgetTester`, no prefs, no sleeps) and isolated.
- [ ] `flutter test test/core/l10n/locale_resolver_test.dart` passes.
- [ ] `dart analyze` passes on the changed file.

**Spec criteria addressed**: AC-6

## Contracts

### Expects
- `lib/core/l10n/locale_resolver.dart` exports a top-level function `resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales)` returning `Locale`, with English fallback for null/unmatched input.

### Produces
- `test/core/l10n/locale_resolver_test.dart` exists and imports `package:dosly/core/l10n/locale_resolver.dart`.
- The file calls `resolveAppLocale` with `null`, a supported, and an unsupported device locale and asserts the English-pin behavior against a `de`-first supported list.
