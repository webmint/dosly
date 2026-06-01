# Task 004: Deduplicate _resolveLocale across 7 test harnesses

**Agent**: qa-engineer
**Files**:
- `test/core/routing/app_bottom_nav_l10n_test.dart`
- `test/features/settings/presentation/screens/settings_screen_test.dart`
- `test/features/settings/presentation/widgets/theme_selector_test.dart`
- `test/features/settings/presentation/widgets/language_selector_test.dart`
- `test/features/history/presentation/screens/history_screen_test.dart`
- `test/features/meds/presentation/screens/meds_screen_test.dart`
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart`

**Status**: Complete
**Depends on**: 003
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-05-27
**Files changed**: all 7 listed harness files
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: Mechanical delete-local-fn + import-production-fn substitution across
7 files; `grep -rn "_resolveLocale" test/` now empty. Also updated one stale
inline comment in `language_selector_test.dart:170` that named the old function.
No imports orphaned. Full suite `flutter test` = 261 passed; `dart analyze`
clean. Code review APPROVE (no blocking issues). Reviewer noted a pre-existing
`fpdart` import-ordering slip in 3 files — NOT introduced here and
`directives_ordering` is OFF (MEMORY L95); deferred to the lint-hardening pass.

**Description**:
Bug 016 sub-item 9 (DRY half). Seven test harnesses each define a private
top-level `_resolveLocale` that is byte-equivalent to the production
`resolveAppLocale` in `lib/core/l10n/locale_resolver.dart` — a DRY violation
(1 production + 7 copies) by constitution §3.6. Replace every copy with a call
to the production function. This is a mechanical find-and-replace across files
(the §3.4 1-3 file limit's rename/replace exception). Behavior must stay
identical. Depends on Task 003 so the production function's behavior is proven
before the harnesses rely on it.

**Change details**:
- In each of the 7 files:
  - Delete the local `Locale _resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) { ... }` definition and its preceding doc comment.
  - Add `import 'package:dosly/core/l10n/locale_resolver.dart';` (sorted with existing imports).
  - Change `localeResolutionCallback: _resolveLocale` → `localeResolutionCallback: resolveAppLocale`.
  - After deletion, remove any now-unused imports (e.g. a `package:flutter/widgets.dart` import that only the deleted function needed). `dart analyze` does NOT flag unused private members but DOES flag unused imports — still grep each file to confirm no orphaned helper remains (MEMORY L103).

**Done when**:
- [ ] No occurrence of `_resolveLocale` remains in any `test/` file (`grep -rn "_resolveLocale" test/` returns nothing).
- [ ] Each of the 7 files imports `resolveAppLocale` and passes it to `localeResolutionCallback`.
- [ ] No unused imports introduced; no orphaned helpers left behind.
- [ ] `flutter test` passes (full suite — these harnesses back many tests).
- [ ] `dart analyze` passes with no new issues.

**Spec criteria addressed**: AC-7

## Contracts

### Expects
- `resolveAppLocale` is exported from `lib/core/l10n/locale_resolver.dart` and proven by `test/core/l10n/locale_resolver_test.dart` (Task 003).
- Each of the 7 listed files currently defines a private `_resolveLocale` and wires it to `localeResolutionCallback`.

### Produces
- Each of the 7 listed files imports `package:dosly/core/l10n/locale_resolver.dart` and references `resolveAppLocale` in its `localeResolutionCallback`.
- No `_resolveLocale` declaration exists anywhere under `test/`.
