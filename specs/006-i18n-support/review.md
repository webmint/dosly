# Review Report: 006-i18n-support

**Date**: 2026-04-15
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 15

## Security Review

- Critical: 0 | High: 0 | Medium: 2 | Info: 6

### Findings

- **Medium** — `pubspec.yaml:42` [CWE-1357 / CWE-1104]: `intl: any` is fully unpinned. Medical-data (PHI) context warrants tighter supply-chain discipline even for transitive-tracking packages. `pubspec.lock` is committed with sha256, providing integrity IF CI uses `flutter pub get` (not `upgrade`); any future `flutter pub upgrade` or fresh CI resolve could silently pull a yanked/compromised/breaking version.
  **Recommendation**: Tighten to `intl: ^0.20.2` (or `>=0.20.0 <0.21.0`). Flutter's own docs moved away from `any`; `flutter_localizations` already exports its required range, so pinning loses nothing. Confirm CI flow uses `flutter pub get` with committed lockfile.

- **Medium** — `lib/features/home/presentation/screens/home_screen.dart:45` & `lib/features/home/presentation/widgets/home_bottom_nav.dart:42` [CWE-476]: Two `!` null-assertions on `AppLocalizations.of(context)`, not one. Spec §7 claims "single sanctioned `!` site" but both files have one each (each file has exactly one, total two across the feature). Low runtime risk — delegates are registered at app root, so `of(context)` cannot return null inside the Material subtree — but the discrepancy with the documented contract is a constitution §4.2.1 bookkeeping gap.
  **Recommendation**: Either (a) update spec §7 wording to acknowledge both call sites are sanctioned, or (b) introduce a `context.l10n` extension helper centralizing the `!` to exactly one site. Option (b) also localizes blast radius if the resolver is ever reconfigured. Not blocking — defer to the Settings feature or a micro-refactor.

### Info (hardening notes)
- `_resolveLocale` correctly handles `null` device locale + unsupported locales; matches by `languageCode` only (right for this 3-locale set, no script-code exposure).
- ARB files contain only user-visible labels — no keys, tokens, URLs, credentials, or ICU placeholders that could enable format-string confusion.
- Four generated `app_localizations*.dart` files match Flutter's gen_l10n template exactly (no tampering, no injected imports).
- PHI regression risk: NONE. No medication names/dosages/schedules pass through i18n; spec §6 exclusion honored.
- No `print` / `debugPrint` introduced (grep clean).
- Locale sourced from OS device settings — no attacker-controlled vector.
- Attack surface unchanged: no new network, no `dart:io` HTTP, no secure-storage churn.

**Security verdict**: PASS — no Critical or High findings.

## Performance Review

- High: 0 | Medium: 0 | Low: 1 (maintainability)

### Findings

- **Low (maintainability, not perf)** — `lib/app.dart:30` and `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart:13`: `_resolveLocale` is duplicated (identical) between production and the test harness. Not a performance issue, but a divergence risk — if production logic evolves (e.g., country-code matching), tests silently stop exercising the real policy.
  **Recommendation**: Extract the production `_resolveLocale` to a package-visible helper that tests can import. Defer to a follow-up — safe to ship as-is because the two copies are identical today.

### Confirmed non-issues
- **`NavigationDestination` const loss**: structurally unavoidable (runtime labels). `NavigationBar` has no `const` constructor anyway, so no parent-level optimization was lost. `Icon` leaves correctly retain `const`. Trade-off is correct.
- **ARB loading**: fully synchronous via `SynchronousFuture` — no first-frame delay. `shouldReload => false` is the correct and optimal setting for static string tables.
- **`localeResolutionCallback`**: O(n=3) loop, fires rarely (locale changes); categorically negligible.
- **`flutter_localizations` + `intl` bundle size**: ~1–2 KB Dart source (generated), tree-shakes to effectively zero incremental AOT binary impact beyond what `flutter_localizations` already contributes.
- **`AppLocalizations.of(context)` call sites**: each widget calls it once per build (O(1) `InheritedWidget` lookup) then binds to local `l`; no redundant lookups.

**Performance verdict**: CLEAN — no high- or medium-impact concerns. One low-impact maintainability note.

## Test Assessment

- AC items with direct test coverage: 5 of 13 (AC-7, AC-8, AC-9 direct; AC-10/11/12 via automated guards; AC-1/2/3/4 via codegen + compilation; AC-5/6 gap; AC-13 manual/deferred)
- Verdict: **ADEQUATE**

### Coverage Map

| AC | Coverage Status |
|---|---|
| AC-1 (pubspec deps) | Validated by `flutter pub get` / build. Non-issue. |
| AC-2 (l10n.yaml exists) | Validated by codegen running. Non-issue. |
| AC-3 (3 ARB files with 4 keys + `@key` metadata) | Indirect via `dart analyze` on generated code. Direct ARB parse tests would be overkill. |
| AC-4 (AppLocalizations class with 4 getters) | Implicit — test files import all four getters; missing ones would be compile errors. |
| AC-5 (MaterialApp.router wired with delegates + `localeResolutionCallback`) | Indirect — `DoslyApp` smoke test in `widget_test.dart` renders bottom nav via AppLocalizations, confirming delegates registered. No explicit assertion. |
| AC-6 (HomeScreen `settingsTooltip` replaced) | **GAP** — no test asserts `'Settings' / 'Einstellungen' / 'Налаштування'` on HomeScreen across locales. Covered only by AC-13 manual verification. |
| AC-7 (HomeBottomNav labels replaced, outer `const` preserved) | **COVERED** — all three labels asserted in English (home_bottom_nav_test.dart); `const HomeBottomNav()` at harness call site confirms outer const. |
| AC-8 (pre-existing tests still pass) | **COVERED** — 88/88 pass; English-text assertions unchanged. |
| AC-9 (de / uk / fr-fallback widget tests) | **COVERED** — home_bottom_nav_l10n_test.dart: 3 cases, each asserting all three labels. |
| AC-10 (`dart analyze` clean) | Automated. |
| AC-11 (`flutter test` clean) | Automated (88/88). |
| AC-12 (`flutter build apk --debug`) | Automated. |
| AC-13 (manual on-device) | Deferred to user per spec. |

### Gaps

- **Gap 1 (nice-to-have)**: HomeScreen `settingsTooltip` has no locale-aware widget test. The existing `widget_test.dart` renders `DoslyApp` (which includes `HomeScreen`) but never calls `find.byTooltip('Settings')`, let alone a locale-switched variant. Risk is low because `HomeScreen` uses the same `AppLocalizations.of(context)!.settingsTooltip` pattern already validated for `HomeBottomNav` and draws from the same ARB files. AC-13 manual verification will catch any regression. Defer to when Settings feature lands.

- **Gap 2 (nice-to-have)**: Production `_resolveLocale` in `lib/app.dart` has no direct unit test. The l10n test file declares a local copy. If production logic changes, tests silently stay behind. A 3-line unit test (`expect(_resolveLocale(const Locale('fr'), supportedLocales), const Locale('en'))`) would close the gap. Defer — tied to the shared-helper recommendation from performance review.

- **Gap 3 (non-issue)**: Regional variants (`en-GB`, `de-AT`) and script codes (`zh-Hans`) not tested. `_resolveLocale` matches on `languageCode` only, so these would correctly resolve; feature ships exactly three locales with no script-code entries.

## Summary

| Category | Outcome |
|----------|---------|
| Security | PASS — 0 Critical, 0 High, 2 Medium, 6 Info |
| Performance | CLEAN — 1 Low maintainability note only |
| Test Coverage | ADEQUATE — 2 nice-to-have gaps, both deferrable |

**Constitution rule violations**: None that meet the "Critical" bar. The §4.2.1 `!` bookkeeping issue (2 sites vs spec's claimed 1) is documentation drift, not a runtime defect.

**Recommended pre-finalize fixes** (all optional):
1. Tighten `intl: any` → `intl: ^0.20.2` in `pubspec.yaml`.
2. Update spec §7 to acknowledge both `!` sanctioned sites (or introduce `context.l10n` extension).
3. Extract `_resolveLocale` to a shared location so test and production stay aligned.

**Recommended follow-up** (post-merge, non-blocking):
1. Widget test for HomeScreen `settingsTooltip` across locales (can bundle with Settings feature work).
2. Direct unit test for `_resolveLocale` (3 lines, pairs with #3 above).
