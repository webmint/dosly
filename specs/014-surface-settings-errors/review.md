# Review Report: 014-surface-settings-errors

**Date**: 2026-05-08
**Spec**: `specs/014-surface-settings-errors/spec.md`
**Changed files**: 14 (2 source, 2 test, 3 ARB, 4 regenerated, 3 docs/bug)

## Security Review

- **Critical**: 0 | **High**: 0 | **Medium**: 0 | **Info**: 4

**Verdict**: APPROVE

The fix resolves the §4.2 silent-error-swallow violation it set out to fix. Zero new constitution violations: zero new `!` sites (§3.1), zero logging calls (§4.2.1), all user-facing strings localized (§6). PHI surface is well-contained — the `Failure` is discarded at the listener via `(_)`, the SnackBar renders only a static localized key (`context.l10n.settingsPersistenceError`), and `failure.message` is never read by any code in `lib/` (verified by repo-wide grep).

### Findings

- **Info** — `docs/architecture.md:143`: The documented "Side-channel error-stream pattern" describes the mechanism well but does not include a security caveat against displaying `failure.message` directly in the SnackBar. Future contributors implementing the same pattern in another feature (e.g. medication save failure) could write `Text(failure.message)` and inadvertently surface PHI from a future `MedicationFailure(name: "...")`.
  **Recommendation**: Add a sentence such as "The `Failure` object stays in the side-channel for diagnostics only — UI surfaces MUST render a static localized string and MUST NOT pass `failure.message` to the rendered widget. `failure.message` may contain context that is acceptable in the data layer but not at the UI boundary (PHI, technical leakage, untranslated)."

- **Info** — `lib/features/settings/presentation/screens/settings_screen.dart:38–47`: The `_` parameter shape in `whenData((_) => ...)` discards the `Failure` payload — this is the right shape for guaranteeing no failure-derived data leaks into the SnackBar text.
  **Recommendation**: Optional inline comment noting the underscore is intentional, to make this contract explicit for future readers.

- **Info** — `lib/features/settings/presentation/providers/settings_provider.dart:130–132`: `settingsErrorsProvider` is non-`autoDispose`. Since `settingsProvider` is also non-`autoDispose` and the controller is closed via `ref.onDispose`, lifecycle is correct. Calling out for the audit trail.

- **Info** — i18n strings (en/de/uk): All three translations are user-friendly, generic, and contain no technical terms ("CacheFailure", "SharedPreferences", stack traces, etc.). No PHI, no error codes, no technical leakage at the UI boundary.

## Performance Review

- **High**: 0 | **Medium**: 0 | **Low**: 4 (notes/test hygiene)

**Verdict**: APPROVE

The `StreamController.broadcast()` ownership model is sound, lifecycle is handled cleanly via `ref.onDispose`, `ref.listen` does not introduce rebuild pressure (does not trigger rebuilds; `SettingsScreen.build` does no `ref.watch` of its own), and `AppSettings` state shape is unchanged. No frame-budget impact, startup delta within noise (~< 5 µs), APK size delta negligible (~150 B/locale ARB key).

### Findings

- **Low (note)** — `settings_provider.dart:131`: `settingsErrorsProvider` calls `ref.watch(settingsProvider.notifier)` to access the broadcast stream. Riverpod caches the notifier, so the stream object is allocated once. Sound as written.

- **Low (note)** — `settings_screen.dart:38`: `ref.listen` callback closure allocates on every `build` call. `SettingsScreen.build` is not a hot path (only runs on push/pop, no `ref.watch`). Closure allocation cost is negligible and structurally unavoidable without method extraction.

- **Low (note)** — `settings_screen.dart:64,79`: Existing `theme.textTheme.labelSmall?.copyWith(...)` allocates a fresh `TextStyle` on every `build`. Pre-existing pattern, not introduced by this feature; non-issue at current rebuild frequency.

- **Low (test hygiene)** — `settings_screen_test.dart:240`: `pump(Duration(milliseconds: 100))` is a magic number. Recommendation: replace with `pumpAndSettle()` for clarity and CI safety.
  **Recommendation**: `await tester.pumpAndSettle(); // mutator runs + SnackBar fully visible` — single-line edit, eliminates magic number and avoids the fragility flagged in QA Gap 4.

## Test Assessment

- **AC items with test coverage**: 14 of 16 (AC-9 / AC-10 partially covered; AC-14 is a build-gate not a test-gate)
- **Coverage verdict**: GAPS FOUND

### AC Coverage Table

| AC | Test(s) | Verdict |
|---|---|---|
| AC-1 (errors getter, broadcast, onDispose) | 6 error-stream tests in `settings_provider_test.dart` | COVERED |
| AC-2 (setThemeMode failure emits) | `'settingsErrorsProvider emits CacheFailure when setThemeMode fails'` | COVERED |
| AC-3 (other 3 mutators emit) | 3 dedicated tests, one per mutator | COVERED |
| AC-4 (Right does NOT emit) | `'does NOT emit on successful save'` | COVERED |
| AC-5 (state-not-updated preserved) | 4 pre-existing tests pass unmodified | COVERED |
| AC-6 (zero debugPrint/print/log) | `dart analyze` + grep | COVERED (static) |
| AC-7 (no deferral comments) | grep | COVERED (static) |
| AC-8 (ARB key in en/de/uk) | ARBs + generated Dart files verified | COVERED |
| AC-9 (SnackBar with localized text) | Widget test asserts English string only | PARTIALLY COVERED |
| AC-10 (floating + verbatim text) | Verbatim text tested; `behavior` property NOT asserted | PARTIALLY COVERED |
| AC-11 (ConsumerWidget; body unchanged) | Existing locale/header/AppBar tests pass unmodified | COVERED |
| AC-12 (`dart analyze` passes) | Confirmed clean | COVERED |
| AC-13 (`flutter test` passes) | 203/203 pass | COVERED |
| AC-14 (`flutter build apk --debug`) | Outside QA-engineer scope (build gate) | NOT VERIFIED in this phase (verified by `/execute-task` Task 003 integration gate) |
| AC-15 (bug 003 Closed) | File state confirmed | COVERED |
| AC-16 (settings.md updated) | File state confirmed | COVERED |

### Gap Findings

- **Gap 1 (Medium) — AC-9/AC-10**: SnackBar widget test only validates English locale. The de and uk ARB strings exist but no widget test asserts the SnackBar text under `Locale('de')` or `Locale('uk')`. This is a test-parity gap compared to existing locale-switching coverage for titles and section headers.
  **Recommendation**: Add 2 more widget tests in the new `'SettingsScreen error SnackBar'` group covering the German and Ukrainian variants (mirror the existing `'shows localized error SnackBar...'` test).

- **Gap 2 (Medium) — AC-10**: The source sets `behavior: SnackBarBehavior.floating` but no test asserts this property. A future refactor that drops `behavior:` would not be caught.
  **Recommendation**: Add a single-line assertion in the existing widget test: `expect(tester.widget<SnackBar>(find.byType(SnackBar)).behavior, SnackBarBehavior.floating);`.

- **Gap 3 (Low) — AC-3 widget integration**: All 4 mutator failure paths are covered at the unit-test (stream) level. At the widget level only `setUseSystemTheme` is exercised. The other 3 mutators trigger SnackBars only if the listener wiring is correct; that is proven indirectly for one path. Adding 3 more widget tests would strengthen regression protection.

- **Gap 4 (Low) — Test fragility**: `tap → pump() → pump(100ms)` works because `_FakeSettingsRepository.saveUseSystemTheme` has no internal `await`. If the fake ever gains a real `await`, the test would fail spuriously. Already flagged in Task 003 code review.
  **Recommendation**: Replace with `pumpAndSettle()` (also closes Performance "Low (test hygiene)" finding).

- **Gap 5 (Low) — Maintenance**: `_FakeSettingsRepository` is duplicated in `settings_provider_test.dart` and `settings_screen_test.dart`. Currently in sync, but any future change to `SettingsRepository` (e.g. a new `saveX` method) must be applied to both independently.
  **Recommendation**: Extract to a shared `test/features/settings/_fake_settings_repository.dart` file. Optional refactor, can be deferred.

## Aggregate Summary

- **Security**: APPROVE — zero blocking findings. 1 doc-hardening Info recommendation worth applying.
- **Performance**: APPROVE — zero perf-impact findings. 1 test-hygiene Low recommendation overlaps with QA Gap 4.
- **Test Coverage**: GAPS FOUND — 2 Medium gaps (locale parity for SnackBar, missing `SnackBarBehavior.floating` assertion). 3 Low gaps (mutator widget integration, pump fragility, fake duplication).

No findings block `/finalize`. The two Medium QA gaps are quick fixes (~10 lines of widget test code) and the user can choose to address pre-`/finalize` or defer.

The Info-level security recommendation (add a "do not pass `failure.message` to UI" caveat to `docs/architecture.md`) is a single-paragraph documentation hardening; small cost, high value for future feature reuse of the pattern.
