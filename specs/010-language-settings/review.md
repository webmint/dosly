# Review Report: 010-language-settings

**Date**: 2026-04-27
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 18 (10 source + 4 ARB + regen + 5 tests + 2 fake patches)

## Security Review

**Counts**: Critical: 0 | High: 0 | Medium: 0 | Info: 6
**Verdict**: PASS — no exploit risks, no security weaknesses, no defense-in-depth gaps.

### Findings (Info — hardening notes)

- **`lib/features/settings/presentation/providers/settings_provider.dart:54,73,92,110`** — Four `kDebugMode`-guarded `debugPrint` sites log `$failure` (`CacheFailure` wrapping a SharedPreferences `Exception.toString()`). Sanctioned per spec 009 precedent. Constitution §4.2.1 mandates routing through a typed logger in `core/logging/` once it exists; track as a follow-up across the codebase, not a feature-scoped fix.
- **`lib/features/settings/data/datasources/settings_local_data_source.dart:67-76`** — `getManualLanguage()` defends against tampered/malformed `SharedPreferences` strings via `firstWhere(orElse: () => AppLanguage.en)`. Defense-in-depth confirmed.
- **`lib/main.dart:12-17`** — `allowList` correctly enumerates only the four non-PHI UI flags (`themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`). Aligned with constitution §4.2.1 (SharedPreferences must not hold medication data).
- **ARB files** — only static strings, no `{placeholders}`, no user-input interpolation.
- **Type safety** — no `!` null-assertions, no `dynamic`, no unchecked `as` casts found across the changed files (grep confirmed empty).
- **`manualLanguage` persistence** — stored as a constrained IETF code (`en`/`de`/`uk`) derived from an enum, never from free user input. `Locale(manualLanguage.code)` constructs only from validated enum values.

## Performance Review

**Counts**: High: 0 | Medium: 0 | Low: 1 | Info: 6
**Verdict**: PASS — no measurable regressions; one Low-impact note for future scaling.

### Findings

- **[Low] `lib/features/settings/presentation/widgets/language_selector.dart:build` — `DropdownMenuItem` list rebuilds on every `LanguageSelector` rebuild.** The `for (final language in AppLanguage.values)` allocates 3 `DropdownMenuItem` instances per build. With 3 items the cost is negligible. Recommendation: acceptable as-is; if the language list grows beyond ~10 entries (matches the picker-screen migration threshold from MEMORY.md), convert to a `static final` constant list at that point.
- **[Info] `lib/main.dart:allowList`** — adding two keys to `SharedPreferencesWithCache.create(allowList:…)` is a no-op for startup latency. The allowList filters during the single disk read; going from 2 to 4 keys adds no measurable I/O.
- **[Info] `lib/app.dart:DoslyApp.build`** — the two `select` calls (`(s) => s.effectiveLocale` and `(s) => s.effectiveThemeMode`) are independent; flipping one does not rebuild via the other. Selectors correctly scoped.
- **[Info] `lib/features/settings/presentation/widgets/language_selector.dart:build`** — `Localizations.localeOf(context)` called twice per `build()`. The closure call inside `SwitchListTile.onChanged` only fires on user tap (not on render); the top-level call is O(1) `InheritedWidget` lookup. Not a hot path.
- **[Info] Locale change → full `MaterialApp` subtree rebuild** — Flutter's intended mechanism. User-driven, not a hot path. `appRouter` top-level constant survives rebuild (memory note Feature 002), nav stack preserved.
- **[Info] `SharedPreferencesWithCache`** — fully synchronous reads after init; no async I/O lurking.
- **[Info] Test pump weight** — minimal harnesses, synchronous fakes, no over-pumping in 53 net new tests.

## Test Assessment

**Verdict**: GAPS FOUND (6 minor gaps; none are AC-blocking)

### AC-to-test mapping

| AC | Coverage |
|----|----------|
| AC-1 (AppLanguage enum) | Covered |
| AC-2 (AppSettings + effectiveLocale) | Partially — `copyWith` not unit-tested in isolation |
| AC-3 (Repository contract + impl) | Covered |
| AC-4 (Data source defaults) | Partially — empty-string fallback path missing |
| AC-5 (allowList) | Covered indirectly via integration |
| AC-6 (Notifier methods + failure path) | Covered |
| AC-7 (MaterialApp.locale wiring) | Covered |
| AC-8 / AC-11 (LanguageSelector behaviour) | Mostly — `de` device-locale branches untested |
| AC-9 (Section header) | Covered |
| AC-10 (Localization keys) | Covered via screen + selector tests |
| AC-12 (MaterialApp.locale reactivity) | Partially — toggle-back-to-system case missing |
| AC-13 / AC-16 (regression / `flutter test`) | Covered (170/170 passing) |
| AC-14 (Persistence round-trip) | Covered |
| AC-15 / AC-17 (analyze / build) | Out of test scope |

### Coverage gaps

1. **[AC-4] `getManualLanguage()` with empty string (`''`) is untested.** Two null-branch paths exist: `code == null` (key absent) and the `orElse` (recognised-but-unmatched). `''` hits the `orElse` branch, not the `null` branch. The `'xx'` test exercises `orElse`; missing-key test exercises `null`. The empty-string edge case is unverified.
   _Suggested test_: add a `settings_repository_impl_test.dart` case with `initialData: {'manualLanguage': ''}` and assert `manualLanguage == AppLanguage.en`.

2. **[AC-2] No isolated `copyWith` unit tests for the two new fields.** Tests drive `copyWith` only via the notifier. No test asserts `AppSettings().copyWith(useSystemLanguage: false).useSystemLanguage == false` with all other fields retaining defaults, or that omitting a new field leaves it unchanged.
   _Suggested test_: 4 pure-Dart unit tests (each new field both set and omitted in `copyWith`).

3. **[AC-11] `displayedLanguage` with `useSystemLanguage=true, manualLanguage=en, device=de` not directly tested.** The existing "device locale differs from stored" case uses `(uk stored, de device)`. The mirror case `(en stored, de device)` is not exercised, leaving the device-locale branch's `de` lookup untested in this configuration.
   _Suggested test_: add an `initial: AppSettings(useSystemLanguage: true, manualLanguage: AppLanguage.en)` + `Locale('de')` + `expect(dropdown.value, AppLanguage.de)` case.

4. **[AC-8] Toggle-OFF pre-fill with `de` device locale untested.** Pre-fill is tested for `uk` (saves `AppLanguage.uk`) and `fr` fallback (saves `AppLanguage.en`). The `de` branch of `AppLanguage.values.firstWhere(...)` is unexercised.
   _Suggested test_: mirror the existing `uk` test with locale `de` → `repo.savedManualLanguage == AppLanguage.de`.

5. **[AC-12] `setUseSystemLanguage(true)` reverts `MaterialApp.locale` to `null` not tested.** The reactivity group has default-null and pre-seeded-de. The third sub-criterion (manual → system → null) is unverified.
   _Suggested test_: pump with `useSystemLanguage: false, manualLanguage: de`, verify `locale == Locale('de')`, then call `setUseSystemLanguage(true)` via `ProviderScope.containerOf(...)`, pump, assert `MaterialApp.locale == null`.

6. **[untested code] No test verifies the exact string values of the four `_k*Key` constants.** A rename of `_kManualLanguageKey` from `'manualLanguage'` to anything else would silently break persistence — only an integration test against the literal string would catch it. Round-trip tests exercise read/write through the data source but not the key-name contract.
   _Suggested test_: store a value directly via `SharedPreferencesAsync` using the literal `'manualLanguage'` key and read it back through `SettingsLocalDataSource.getManualLanguage()`, confirming the constant matches the on-disk format.

### Severity

All gaps are **Low/Info severity**:
- Gaps 1, 3, 4, 6 are edge-case completeness — code paths are correct; just under-asserted.
- Gap 2 is style — `copyWith` is exercised via the notifier path, just not in isolation.
- Gap 5 is the most semantically meaningful gap — proves the round-trip toggle behaviour.

None are AC-blocking. The 17/17 automated ACs in `verify.md` remain PASS. These gaps should be addressed in a follow-up test-hardening pass (or as part of `/finalize` cleanup), not blocking merge.
