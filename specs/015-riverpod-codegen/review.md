# Review Report: 015-riverpod-codegen

**Date**: 2026-05-09
**Spec**: `specs/015-riverpod-codegen/spec.md`
**Plan**: `specs/015-riverpod-codegen/plan.md`
**Changed files**: 17 (5 markdown + 8 production source/generated + 1 test + 2 pubspec + 1 dartdoc-only domain edit)

## Security Review

- Critical: **0** | High: **0** | Medium: **0** | Info: **4**
- Overall: **PASS**

Pure compile-time refactor with no new attack surface. The new dependencies (`riverpod_annotation` / `riverpod_generator`) come from the verified `remi.rousselet` publisher, are MIT-licensed, declare no telemetry, and require no INTERNET permission. Constitution §1, §2.1, §2.3, §4.2, §4.2.1 all satisfied.

### Findings (Info-level only)

- **Info** — `pubspec.lock:540-543`: `riverpod_analyzer_utils 1.0.0-dev.9` is a pre-release, pulled transitively by `riverpod_generator 4.0.3`. Dev/build-time only — never runs in the shipped APK. Track for upgrade to a stable line when published; build-stability concern, not security.
  Recommendation: monitor for stable release; no action now.

- **Info** — `lib/core/providers/shared_preferences_provider.dart:25-29`: throwing-placeholder error message `'sharedPreferencesProvider must be overridden in main()'` is implementation-detail leakage. Harmless because it can only fire on developer mis-wiring of `ProviderScope`; never user-visible in a release build.
  Recommendation: none.

- **Info** — Generated `.g.dart` files contain SHA-1 hash strings (`r'096a40d2...'`, `r'7ae3e50f...'`) used by Riverpod for dev-time provider-identity validation. Confirmed not credentials or session tokens.
  Recommendation: none.

- **Info** — Codegen pipeline introduces no new permission requirements, network access, or platform-channel surface. The migration is a pure compile-time transformation that preserves the runtime semantics of the four migrated providers.
  Recommendation: none.

### Verifications passed

- New direct dep `riverpod_annotation 4.0.2`: verified publisher, MIT, no telemetry, no INTERNET. ✓
- New dev dep `riverpod_generator 4.0.3`: dev-only, no runtime payload. ✓
- All `.g.dart` files use `part of` only — no extra imports introduced. ✓
- `lib/main.dart:23` `sharedPreferencesProvider.overrideWithValue(prefs)` semantically identical post-migration; `prefs` instance not exposed globally. ✓
- Domain purity: `lib/features/settings/domain/entities/app_settings.dart` has only `freezed_annotation`, `app_language.dart`, `app_theme_mode.dart` imports. The two `package:flutter` mentions are inside dartdoc, not actual imports. Constitution §2.1 upheld. ✓
- PHI/log exposure: zero `print`/`debugPrint`/`debugger` calls in any changed source file. No medication/dosage/intake data flows through these files. ✓
- `_FakeSettingsRepository` (test) `implements SettingsRepository` (abstract domain contract). No broader leak. ✓
- `lib/main.dart:13-17` SharedPreferences allowlist: exactly `themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`. No medication keys leaked. Constitution §4.2.1 upheld. ✓

## Performance Review

- High: **0** | Medium: **0** | Low: **0** | Info: **1**
- Overall: **No regressions; no concerns**

| Metric | Value | Status |
|--------|-------|--------|
| Test suite (203 tests) | 4s wall, 6.2s CPU | No regression |
| Generated `.g.dart` volume | 288 lines / 9,128 bytes across 2 files | Minimal |
| Net new runtime packages | 1 (`riverpod_annotation`) — const annotations, tree-shaken | Negligible binary impact |
| Release APK | 52.9 MB | No regression |
| Analysis warnings | 0 | Clean |

### Findings (Info-level only)

- **Info** — `lib/features/settings/presentation/providers/settings_provider.dart:38`: `_errors` is declared `late final StreamController<Failure>`. With the current `keepAlive: true` + no `ref.invalidateSelf()` contract, this is fine — `build()` runs exactly once. **Future-proofing note**: if a future task adds `ref.invalidateSelf()` to the notifier, the second `build()` call would throw `LateInitializationError` on re-assignment. Not a current bug; only flagged for future awareness.
  Recommendation: if `ref.invalidateSelf()` is ever added, drop `final` from the declaration and explicitly close the previous controller before reassigning.

### Lifetime decisions verified sound

- `settingsRepositoryProvider` (autoDispose) is transitively kept alive by the `keepAlive` notifier's `ref.watch`. No startup-window issue (notifier is first accessed during `DoslyApp.build()`, well after `ProviderScope` override injection).
- `settingsErrorsProvider` (autoDispose) re-subscribes to the same broadcast stream on the kept-alive notifier when `SettingsScreen` remounts. Subscription is O(1); broadcast streams handle late subscribers correctly. No data accumulator semantics lost — by design.
- `settingsNotifierProvider` (`keepAlive: true`) preserves the original implicit `NotifierProvider<>` lifetime, ensuring the `_errors` `StreamController` initialized in `build()` lives for the app's lifetime (closed at process exit via `ref.onDispose`).
- `sharedPreferencesProvider` (`keepAlive: true`) matches its override-only contract.

### Codegen runtime overhead negligible

- 4 thin provider classes each adding ~40-80 bytes of machine code post-tree-shake → < 1 KB total against 52.9 MB APK.
- `riverpod_annotation` library is 233 lines of `const` annotation classes; Dart compiler does not retain annotation metadata in release builds (no dart:mirrors). Net runtime footprint effectively zero.

### Selector pattern preserved

- `lib/app.dart:66-77`: 4 `ref.watch(settingsNotifierProvider.select(...))` calls — codegen does not change `.select()` semantics. Each selector still drives an independent subscription firing only when its specific field changes. Optimal pattern unchanged from pre-migration.

## Test Assessment

- AC items behavior-relevant: 4 of 14 (AC-5, AC-6, AC-9, AC-11) — **all covered** by existing tests
- AC items infra-level: 10 of 14 — **appropriately gated** by build pipeline / inspection (correct by design — unit tests for these would test toolchain plumbing, not application behavior)
- Coverage gaps: **3 low-priority items, all pre-existing or by design**
- Verdict: **ADEQUATE**

### Gaps (all Low priority)

- **AC-9 lifecycle gap (Low)** — No explicit test verifies that `ref.onDispose(_errors.close)` prevents a "bad state: stream has been closed" error after `container.dispose()`. Tearing down via `container.dispose()` in `tearDown` provides an implicit canary across all 30+ tests; no failure has been observed. Acceptable structural-behavior gap; testing it directly would be testing Riverpod internals.

- **`settingsErrorsProvider` autoDispose lifecycle (Low)** — No tests cover subscribe-after-remount or confirm missed emissions (while unmounted) are not buffered. The "data loss when unmounted" behavior is intentional design (event-driven errors, not state to retain). Test would exercise Riverpod internals — out of scope.

- **`Future<void>.delayed(Duration.zero)` in `settings_provider_test.dart` (Low)** — 7 occurrences (lines 271, 290, 309, 328, 353, 369, 375). Pre-existing from feature 014, unchanged by this refactor. Constitution §3.4 discourages sleep in tests, but this pattern is a microtask flush, not a real-time wait — reliable for broadcast streams. Reasonable test-quality follow-up: migrate to `fake_async` + `FakeAsync.flushMicrotasks()`. Not a correctness problem; tests pass reliably across 203 runs.

### Coverage strengths

- **`keepAlive: true` canary robust**: The "errors stream supports multiple sequential emissions" test at `settings_provider_test.dart:360` calls `setThemeMode` twice sequentially on the same container and expects two emissions. This test would fail if `keepAlive` were removed and the notifier were disposed between calls (closing `_errors` mid-flight). Solid regression guard for the lifetime decision.
- **Symbol rename verified end-to-end**: Widget tests pump real screens that internally read `settingsNotifierProvider`. Stale references would surface as compile errors at pump time; all widget tests pass.
- **All four `setX` mutators**: Each has both success-path (state updated) and failure-path (stream emits, state preserved) coverage in `settings_provider_test.dart`.

## Cross-cutting observations

1. **Two pattern insights captured in MEMORY.md**:
   - `riverpod_generator 4.x` strips `Notifier` suffix from class names; `name:` annotation parameter is load-bearing for canonical class-form naming.
   - `@riverpod` defaults to autoDispose; manual `NotifierProvider<>` defaulted to keepAlive — semantic flips on migration.

2. **Constitution drift acknowledged but out of scope**:
   - §1 says "Riverpod 2.x" — actual is `flutter_riverpod ^3.3.1` (3.x major).
   - §7.2 example uses 2.x `XxxRef` typedef pattern (3.x uses `Ref` directly).
   - Both flagged as known follow-ups in spec §6 "Out of Scope".

3. **Doc-vs-code drift caught and fixed**: Code review caught a "Non-`autoDispose`" dartdoc lie at `settings_provider.dart:127` that contradicted the actual `@riverpod` (autoDispose) annotation. Fixed in repair pass before completion. Same pattern memorialized in MEMORY entries 012, 014, and now reinforced by 015.

## Summary verdict

| Dimension | Verdict |
|-----------|---------|
| Security | PASS (0 Critical / 0 High / 0 Medium / 4 Info) |
| Performance | PASS (no regressions; 1 future-proofing note) |
| Test coverage | ADEQUATE (3 low-priority pre-existing gaps) |

Feature 015 is ready for `/verify`. No findings rise to a level that should block the verdict; all Info/Low items are documented for future awareness or are explicitly out-of-scope follow-ups already tracked in spec §6.
