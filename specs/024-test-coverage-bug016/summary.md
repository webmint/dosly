## Feature Summary: 024 — Test-coverage hardening (Bug 016)

### What was built

Closed the still-real test-coverage gaps from Bug 016. Added three new test
files (data source, home-screen gear-tap navigation, locale resolver),
deduplicated the locale-fallback function across the test harnesses into the
existing production `resolveAppLocale`, documented one defensive guard in
`language_selector`, and updated the bug record. Net: +20 tests, no production
behavior change, full suite 261 green.

### Changes

- Task 001: Add `SettingsLocalDataSource` unit tests — 15 tests across all 6 public methods (theme, language, defaults, setter round-trips).
- Task 002: Add `HomeScreen` gear-tap navigation widget test — minimal 2-route `GoRouter`, taps the gear, asserts the real `SettingsScreen` mounts.
- Task 003: Add `resolveAppLocale` unit test — null / supported / unsupported / country-code cases, with a `de`-first list pinning the English-fallback regression guard.
- Task 004: Deduplicate `_resolveLocale` across 7 test harnesses — replaced 7 byte-equivalent private copies with the single production function.
- Task 005: Document the `language_selector` defensive guard + mark Bug 016 Fixed with per-sub-item dispositions (6 fixed by this spec, 2 already-closed, 2 moot).

### Files changed

- `test/` — 3 files added (datasource, home-screen, locale-resolver tests), 7 harness files modified (dedup)
- `lib/features/settings/presentation/widgets/` — 1 file modified (3-line comment on the existing guard)
- `bugs/016-test-coverage-gaps-consolidated.md` — Status → Fixed, Resolution section added
- `specs/024-test-coverage-bug016/` — spec, plan, 5 task files, review.md, summary.md, tasks/README.md
- `research/2026-05-27-bug-016-test-coverage.md` — pre-spec feasibility report
- `.claude/memory/MEMORY.md` — 3 lessons added (audit-bug re-verification, in-memory prefs type-mismatch quirk, honest test naming)

Total (specs + research + tests + lib + bugs + .claude): 25 files changed, +1185 / -138.

### Key decisions

- **Datasource test harness**: `InMemorySharedPreferencesAsync.withData(...)` + `SharedPreferencesWithCache.create` per the proven recipe (MEMORY L112), not legacy `setMockInitialValues`. Fresh prefs per test for isolation.
- **Home-nav test mounts the real `SettingsScreen`**: minimal 2-route `GoRouter` + `_FakeSettingsRepository` override on `settingsRepositoryProvider`. No OQ-1 route-observer fallback needed.
- **Guard documented, not removed**: kept `if (selected != null)` with a 3-line `//` comment; removing it would have required a `!` null-assertion (constitution Never #7 forbids).
- **Harness dedup is a single mechanical task**: 7 files in one task per the §3.4 "rename/replace across many files" exception, behavior-preserving substitution to the already-shipped `resolveAppLocale`.

### Deviations from plan

- Task 001: the literal legacy-`int` `catch (_)` branch in `getThemeMode()` is unreachable via `InMemorySharedPreferencesAsync` (the in-memory fake does not throw a `TypeError` on type-mismatched keys, unlike the real platform). Substituted an unrecognized string code (`'legacy'`) that drives the same `AppThemeMode.light` outcome through `fromCodeOrDefault.orElse`; the test name and an inline `//` comment disclaim catch-branch coverage. Recorded as a reusable quirk in MEMORY (External API Quirks).
- The bug originally claimed "4-way" duplication of `_resolveLocale`; verification during `/specify` showed the actual count is **7**. Spec and tasks scoped to the real number.

### Acceptance criteria

- [x] AC-1: `getThemeMode` valid / absent / unreachable-code-via-fallback paths tested
- [x] AC-2: `getManualLanguage` null / unknown / empty / valid paths tested
- [x] AC-3: `getUseSystem*` defaults + all 4 setter round-trips tested
- [x] AC-4: In-memory prefs harness, isolated, no sleeps / `DateTime.now()`
- [x] AC-5: Gear tap mounts the real `SettingsScreen`
- [x] AC-6: `resolveAppLocale` null / supported / unsupported asserted with `de`-first list
- [x] AC-7: Zero `_resolveLocale` declarations remain under `test/`; harnesses import the production function
- [x] AC-8: Guard kept + commented; no `!` introduced
- [x] AC-9: Bug 016 Status: Fixed; all 10 sub-items dispositioned
- [x] AC-10: `dart analyze` clean; `flutter test` 261 passed
