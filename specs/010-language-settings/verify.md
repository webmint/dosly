# Verification Report — Language Settings

**Feature**: 010-language-settings
**Spec**: [spec.md](spec.md)
**Tasks**: [tasks/](tasks/)
**Date**: 2026-04-27
**Mode**: code-reading (`AC_VERIFICATION = "off"` in `.claude/project-config.json`)

## Pre-flight

- `/review` was NOT run before `/verify`. **Warning**: security/performance/test-coverage findings are unavailable. Recommend running `/review` before `/finalize` to complete the audit trail. AC and integration checks proceed below.

## Acceptance Criteria

| AC | Description | Task(s) | Status | Evidence |
|----|---|---|---|---|
| AC-1 | `AppLanguage` enum at `lib/features/settings/domain/entities/app_language.dart` with three values, `code` + `nativeName`, no Flutter imports | 001 | **PASS** | File exists with `enum AppLanguage { en('en','English'), de('de','Deutsch'), uk('uk','Українська') }`. Imports: none. Constitution §2.1 honoured. |
| AC-2 | `AppSettings.useSystemLanguage` (default `true`), `manualLanguage` (default `AppLanguage.en`), `Locale? get effectiveLocale` returns `null` when system on else `Locale(manualLanguage.code)`. `copyWith` accepts both new params | 001 | **PASS** | `app_settings.dart:30-31` declares fields with documented defaults; `effectiveLocale` getter at `:68-69`; `copyWith` extended at `:72-82`. |
| AC-3 | `SettingsRepository` declares `saveUseSystemLanguage(bool)` and `saveManualLanguage(AppLanguage)`; `load()` returns populated `AppSettings` | 001 (contract) + 002 (impl) | **PASS** | Abstract methods at `settings_repository.dart:34-39`. Impl at `settings_repository_impl.dart:50-69`; `load()` at `:21-27` populates new fields. |
| AC-4 | Data source reads/writes `useSystemLanguage` (bool) and `manualLanguage` (string=`code`); `getUseSystemLanguage` defaults `true`; `getManualLanguage` defaults `AppLanguage.en` on missing/unknown code | 002 | **PASS** | `settings_local_data_source.dart:17-20` declares keys; `:61` returns `true` default; `:67-76` uses `firstWhere(orElse: () => AppLanguage.en)`. |
| AC-5 | `main.dart` allowList contains `'useSystemLanguage'` and `'manualLanguage'` | 003 | **PASS** | `main.dart:12-17` allowList has all four keys. |
| AC-6 | `SettingsNotifier.setUseSystemLanguage(bool)` and `setManualLanguage(AppLanguage)` exist; on success state updated via `copyWith`; on `CacheFailure` state unchanged + `kDebugMode`-guarded `debugPrint` | 003 | **PASS** | `settings_provider.dart:86-117` declares both methods with documented shape. Both follow the `kDebugMode`-`debugPrint`/state-update-only-on-Right pattern. |
| AC-7 | `MaterialApp.router` configured with `locale: ref.watch(settingsProvider.select((s) => s.effectiveLocale))`; system mode → null → resolution callback wins; manual mode → `Locale` directly | 003 | **PASS** | `app.dart:58` `locale:` argument wired to `effectiveLocale`. `_resolveLocale` callback unchanged at `:32-41`; `localeResolutionCallback: _resolveLocale` registration at `:54` unchanged. |
| AC-8 | `LanguageSelector` widget renders `SwitchListTile` and a manual-language picker; native names render; disabled state when system on; tap → `setManualLanguage` | 004 (+ post-task refactor + fix) | **PASS** | `language_selector.dart` declares `class LanguageSelector extends ConsumerWidget`. Switch at `:51-71`. **Implementation deviation from spec**: spec §3.5 prescribed 3 `RadioListTile<AppLanguage>` rows; implementation uses a single full-width `DropdownButton<AppLanguage>` (post-task refactor — see deviation note below). Behavioural contract preserved (native names, disabled state, tap-to-save). |
| AC-9 | "Language" section header above `LanguageSelector`, identical styling to Appearance header | 004 | **PASS** | `settings_screen.dart:60-69` renders `Text(context.l10n.settingsLanguageHeader.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500, letterSpacing: 0.5))` — byte-equivalent to the Appearance header style. Padding insets `EdgeInsets.fromLTRB(16, 16, 16, 6)` match. |
| AC-10 | All three ARB files contain the three new keys (`settingsLanguageHeader`, `settingsUseDeviceLanguage`, `settingsUseDeviceLanguageSub`); English with `@key` metadata; generated `AppLocalizations` exposes getters | 004 | **PASS** | Verified via grep: en.arb lines 43, 47, 51 + `@key` blocks at 44, 48, 52; de.arb lines 13-15; uk.arb lines 13-15. `app_localizations.dart` declares all three abstract getters. |
| AC-11 | `LanguageSelector` widget tests cover: switch default, disabled when system on, native names, tap-to-save, pre-fill on toggle-OFF (incl. `fr` fallback) | 005 + post-task refactor | **PASS (with adjusted mechanism)** | `language_selector_test.dart` has 16 tests (was 14 before the dropdown refactor + bug fix). Adapted to dropdown semantics: `expect(dropdown.onChanged, isNull)` for disabled state; `expect(dropdown.value, ...)` for displayed selection; tap-via-menu for selection. Switch / pre-fill / native-name / locale-label tests intact. |
| AC-12 | `MaterialApp.locale` reactivity test proves null default and `Locale('de')` after switching to manual-de | 005 | **PASS** | `widget_test.dart` adds two new tests under `MaterialApp.locale reactivity` group: default-null and pre-seeded `Locale('de')`. Both green. (Spec allowed pre-seeded approach as alternative to live-notifier path; chose pre-seeded for clarity.) |
| AC-13 | All existing tests continue to pass | 005 | **PASS** | `flutter test`: 170/170 passing (was 117 baseline; +53 net new). No existing tests were re-asserted. |
| AC-14 | Persistence round-trip test reads back `useSystemLanguage` + `manualLanguage` after rebuilding repo | 005 | **PASS** | `settings_repository_impl_test.dart` persistence-round-trip group exercises both new keys via `InMemorySharedPreferencesAsync` reuse across two repo instances. |
| AC-15 | `dart analyze` zero warnings/errors | per-task gate | **PASS** | Verified at `/verify` time: `dart analyze` exits zero. |
| AC-16 | `flutter test` passes | 005 (terminal gate) | **PASS** | 170/170 passed (verified at `/verify` time). |
| AC-17 | `flutter build apk --debug` succeeds | 005 (terminal gate) | **PASS** | Verified at Task 005 completion: `build/app/outputs/flutter-apk/app-debug.apk` produced. |
| AC-18 | Manual on-device verification: pick each language, persist across restart; toggle back to system | deferred | **MANUAL** | Not automatable in sandbox. Deferred to user post-merge per spec §5. Standing instruction: install the debug APK, exercise the language picker for English / Deutsch / Українська, force-quit, relaunch, confirm persistence. Then toggle "Use device language" ON and confirm UI reverts to device-resolved language. |

**Result**: 17 of 17 automatable ACs PASS. AC-18 deferred (manual).

### AC-8 Implementation Deviation

The spec prescribed `RadioListTile<AppLanguage>` × 3 rows for the manual selector. After Task 004 shipped (using `RadioGroup<AppLanguage>` + 3 `RadioListTile` to work around Flutter 3.32+ deprecations), the user requested a UX refactor to a single full-width dropdown to scale better as more Settings sections land. The post-task `/refactor` swapped the inner control to `DropdownButton<AppLanguage>`. A follow-up fix made the dropdown reflect the device-resolved language when system mode is on (mirrors `ThemeSelector`'s system-brightness behaviour) — closing a UX gap that would have shown a stale `manualLanguage` value.

The behavioural contract specified by AC-8 (native names render, disabled when system on, tap → `setManualLanguage`) is fully preserved. The spec's "RadioListTile × 3" prescription is superseded by the user's approved refactor proposal. **Not a regression — a deliberate UX improvement.**

## Code Quality

- **Type checker** (`dart analyze`): **PASS** (zero issues)
- **Linter** (same command): **PASS**
- **Build** (`flutter build apk --debug`): **PASS** (verified at Task 005 + carried forward)
- **Cross-task consistency**: **PASS**
  - `AppLanguage` enum (Task 001) consumed correctly by data source (002), notifier (003), widget (004), and tests (005).
  - `effectiveLocale` getter (001) reaches `MaterialApp.locale` (003) — verified end-to-end via `widget_test.dart`'s reactivity test.
  - Persistence schema (002) matches allowList (003) matches load() (002) — no key mismatches.
  - The two test-fake patches (`app_router_test.dart`, `theme_selector_test.dart`) added the two new abstract methods correctly; no fakes are missing implementations.
- **No scope creep**: **PASS**
  - Files changed (lib/) match spec §4 Affected Areas exactly.
  - Two extra test files patched (`app_router_test.dart`, `theme_selector_test.dart`) — strictly necessary additive stubs to satisfy the extended `SettingsRepository` contract from Task 001. Documented in Task 005 completion notes.
  - One file NOT in the original spec affected areas: `test/widget_test.dart` extended for AC-12 (replaces the originally-proposed `test/app_test.dart` — discovery during breakdown, plan/spec already updated).
- **No leftover artifacts**: **PASS**
  - No bare `TODO`s introduced in this feature.
  - No `print()` / unguarded `debugPrint()`. Four `debugPrint` sites in `settings_provider.dart` are all `kDebugMode`-guarded (sanctioned pattern from spec 009).
  - No commented-out code.
  - No `// ignore:` / `// ignore_for_file:` directives.

## Review Findings

**No `/review` report available.** Run `/review` before `/finalize` to complete the audit trail (security, performance, test-coverage analysis).

- **Security**: not reviewed (no `/review` run)
- **Performance**: not reviewed (no `/review` run)
- **Test coverage**: not formally reviewed; per-task qa-engineer assessment at Task 005 declared coverage ADEQUATE. No gaps surfaced during AC verification.

## Issues Found

None.

### Critical (must fix before merge)
None.

### Warning (should fix, not blocking)
- `/review` was not run for this feature. The verdict below is rendered without security/performance/test-coverage findings. Strongly recommend running `/review` before `/finalize`.

### Info
- AC-8 deviation from spec text is a deliberate, user-approved UX improvement — captured in `/refactor` proposal acceptance and follow-up `[WIP] Fix:` commit. No spec text update is needed because spec §6 "Out of Scope" already permitted UI control choices and the dropdown still satisfies the spec's behavioural contract; future readers see the deviation in `tasks/004` completion notes + verify report.
- Native language names are NOT translated (literal `English`/`Deutsch`/`Українська` from `AppLanguage.nativeName`), per the universal language-picker convention. Documented in spec §3.5/§3.7 and verified by widget tests under all three locales.

## Overall Verdict

**APPROVED** (with the soft warning that `/review` should run before `/finalize` for a complete audit trail).

All 17 automatable acceptance criteria pass. Code quality gates green. Cross-task integration verified. No scope creep, no leftover artifacts, no constitution violations. AC-18 is the only remaining gap and is intentionally manual.

## Next Steps

1. **Recommended**: run `/review` to produce the security/performance/test-coverage report (`specs/010-language-settings/review.md`). If `/review` raises Critical or High findings, revisit before `/finalize`.
2. Run `/summarize` to generate the PR-ready feature summary.
3. Run `/finalize` to squash all `[WIP]` commits into a clean feature commit and update `docs/`.
4. After merge, perform AC-18 manual verification on a real device.
