# Review Report: 039-intake-settings

**Date**: 2026-07-03
**Spec**: specs/039-intake-settings/spec.md
**Changed files**: 14 production source files (+ generated), 13 test files
**Status**: all 11 tasks Complete; full suite 756 green; project-wide `dart analyze` clean

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 7
- **Overall: PASS**

No exploitable security issues. Key confirmations:
- **Non-PHI storage is correct** — the 3 keys in `SharedPreferences` (`intakeWindowMinutes`, `gracePeriodMinutes`, `allowMarkAhead`) are pure behavior preferences; no medication names/dosages/schedules touch prefs (constitution-compliant; medication/intake data stays in drift).
- **Clamp-on-read is the real enforcement boundary** — tampered/out-of-range persisted ints are clamped by the `IntakeWindow`/`GracePeriod` factories (`settings_local_data_source.dart`), so a rooted-device prefs edit cannot inject an unbounded/negative value.
- **Graceful degradation** — a wrong-type persisted value throws in the unguarded getter → `load()`'s single catch → `Left(Failure.unknown)` → default `AppSettings()`. No crash, no info leak.
- **No sensitive logging** — no `print`/`debugPrint`/`developer.log`; failure surfaces a generic localized `settingsPersistenceError`, never the raw `Failure`/stacktrace.
- Inapplicable checklist items (network/TLS/auth/injection/deserialization/path-traversal/webview) — none exist in this feature. No new dependencies.

## Performance Review

- High: 0 | Medium: 0 | Low: 2 (informational, no action)

Performance is fine for a settings screen:
- **Narrow rebuilds** — `IntakeSettingsControls` uses 3 `ref.watch(...select(...))` reads; intake changes don't cascade to `MaterialApp`/`ThemeSelector`/`LanguageSelector` (verified against `lib/app.dart` and `settings_screen.dart`).
- **Sync hot path** — data-source getters are synchronous cache reads, run once in `SettingsNotifier.build()`, not per frame.
- **+3 prefs keys at startup** — same `allowList`, one `SharedPreferencesWithCache.create()`, negligible.
- Low-1: all 3 fields watched in one `build()` → whole `Column` rebuilds on any intake change (3 trivial leaf rows — splitting is not worth the indirection; leave as is).
- Low-2 (positive): VO value-equality + clamping factory means tapping past a bound produces an `==` object → `select` skips the rebuild. Intentional, correct.

## Test Assessment

- AC items with adequate coverage: **11 of 17 fully Covered**; 6 Partial/None (domain layer is exemplary; gaps are top-of-stack).
- **Verdict: GAPS FOUND** (test-coverage gaps only — no correctness bugs; all 756 tests pass)

### Coverage gaps (ranked)
1. **High — AC-13/AC-15 screen-integration hole**: `IntakeSettingsControls` is tested in isolation, but **no test verifies it is actually mounted inside `SettingsScreen`** (no "INTAKE" header assertion, no `find.byType(IntakeSettingsControls)`), and **none of the 3 new mutators' failure→SnackBar paths are exercised through the real `SettingsScreen` + `settingsErrorsProvider` wiring** — `settings_screen_test.dart`'s error-SnackBar group covers only the 4 pre-existing mutators. A code comment in `intake_settings_controls_test.dart` claims this SnackBar path "is wired (and covered) at the SettingsScreen level" — that claim is **not true** (a lying-comment red flag).
2. **Medium — AC-12/AC-14 `allowMarkAhead` one-directional**: only `false→true` is tested at both the notifier and widget layers. `true→false` is never exercised — a toggle-off bug would slip through.
3. **Medium — AC-16 non-English rendering untested**: de/uk Intake strings exist and pass `dart analyze`, but no widget test renders the Intake section under `Locale('de')`/`Locale('uk')` (Appearance/Language sections do). A malformed `{minutes}` placeholder in one locale would not be caught by a test.
4. **Low — AC-1/AC-4 placement/rigor**: AC-1 defaults are asserted only in the Riverpod-dependent `settings_provider_test.dart`, not in the dependency-free `app_settings_test.dart` (left untouched). AC-4 domain purity has no automated check (inspection only) — the spec text implies one should exist.
5. **Low — AC-5**: no direct `settingsPrefsKeys.containsAll([...])` assertion (correctness implied transitively).

### Per-AC status
Covered: AC-2, AC-3, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-17 (9 fully) + AC-12/AC-14 (covered except the noted toggle-off direction).
Partial: AC-1 (indirect), AC-13, AC-15, AC-16.
None (inspection-only): AC-4, AC-5.

### Recommended follow-ups (small — all in existing files with existing harnesses)
- Add a `SettingsScreen` test asserting the "INTAKE" header + `find.byType(IntakeSettingsControls)` after Language.
- Add `setIntakeWindow`/`setGracePeriod`/`setAllowMarkAhead` failure cases to `settings_screen_test.dart`'s error-SnackBar group (then fix/verify the misleading comment).
- Add `true→false` cases for `allowMarkAhead` at notifier + widget layers.
- Add a de/uk render check for the Intake section.

## Review Incident (must record)
During the test-assessment pass, the qa-engineer agent ran an **errant `rm -f` that deleted the untracked file `audits/2026-06-10-audit-2.md`** (outside its read-only scope). The file was never git-tracked → not recoverable via git; not in Trash. See the session hand-off for recovery avenues (IDE local history / Time Machine). A read-only review agent must never mutate the working tree — flagged for process hardening.
