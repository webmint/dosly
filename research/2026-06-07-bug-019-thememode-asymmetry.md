# Research: Bug 019 — `themeMode` wrong-type returns `Right(default)`, asymmetry untested

**Date**: 2026-06-07
**Topic**: `themeMode` wrong-type read returns `Right(default)`, not `Left` — asymmetry untested
**Verdict**: **Feasible — trivial single-file `/fix` (test-only)**

## Summary

Bug 019 is a **regression-documentation gap**, not a defect. Feature 022's AC-2 ("a wrong-type cached value never throws out of `load()`") is satisfied by all four settings keys, but they reach safety two different ways: three keys (`useSystemTheme`, `useSystemLanguage`, `manualLanguage`) have **unguarded** getters, so a wrong-type value throws a `TypeError` that `load()`'s outer catch promotes to `Left(UnknownFailure)`; `themeMode` is **internally guarded** in `getThemeMode()` and degrades to `Right(AppThemeMode.light)`. The AC-2 test group asserts `Left` for the three unguarded keys but never names `themeMode` as the deliberate exception. The behavior itself *is* exercised (the legacy-int test at line 149), so this is purely about making the asymmetry explicit and co-located so a future change to `getThemeMode()`'s guard can't silently flip the contract unnoticed. The fix is a single test addition, no production change.

## Codebase Findings

### Verification against current code

| Claim | Evidence at HEAD | Status |
|------|------------------|--------|
| `getThemeMode()` is internally guarded → `light` | `settings_local_data_source.dart:40-51` (own `try/catch` → `return AppThemeMode.light`) | Confirmed |
| Other three getters unguarded | `getUseSystemTheme`/`getUseSystemLanguage` → `getBool(...) ?? true` (l.61,70); `getManualLanguage` → `getString(...)` (l.76-82) — all throw on wrong type | Confirmed |
| `load()` outer catch → `Left(Failure.unknown)` | `settings_repository_impl.dart:22-35` | Confirmed |
| AC-2 group tests only the 3 unguarded keys → `Left` | test lines 333-378: `useSystemTheme`/`useSystemLanguage` as String, `manualLanguage` as int → `isLeft()` + `isA<UnknownFailure>()`. No `themeMode` case. | Confirmed (the gap) |
| `themeMode` wrong-type behavior already exercised | test line 149-159: `{'themeMode': 1}` → `Right`, `manualThemeMode == light` (passes; suite is 285/285 green) | Confirmed — behavior covered, just not *named* as the AC-2 exception |

### Patterns Available
- **Co-located contrast test**: add one `test(...)` inside the existing AC-2 group (lines 333-378) using the same `_buildRepository(initialData: {...})` + `getOrElse`/`fold` helpers already in the file.
- **Distinct wrong-type value to avoid duplicating line 149**: line 149 uses int `1`. A new AC-2-group test should use a *different* wrong type (e.g. `{'themeMode': <List or bool or double>}`) so it's clearly an independent assertion of "wrong type -> `Right(default)`", not a copy of the legacy-int test. (`getString` on any non-String cached value hits the same internal catch -> `light`.)
- **Existing dartdoc already documents the guard**: `getThemeMode()`'s dartdoc (lines 33-39) already states it "falls back to `AppThemeMode.light` when ... the stored value is of the wrong type." So the optional production comment the bug mentions is **largely redundant** — the contract is already documented in source; the missing piece is purely the *test* that names it.

### Gaps
- No test in (or adjacent to) the AC-2 group flags that `themeMode` is the one key that returns `Right(default)` rather than `Left` on wrong type. A reader scanning the group title "wrong-type cache values return Left (AC-2)" would wrongly infer all four keys behave that way.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §3.4 Testing — data layer coverage mandatory | The addition strengthens the data-layer regression suite; fully in-spirit. |
| §3.2 Error Handling | The guarded-vs-unguarded asymmetry is intentional graceful degradation for a cosmetic preference (theme); the bug explicitly scopes to **documenting** it, **not** changing it. No production behavior change. |
| §3.4 "honest test naming" (and MEMORY: name tests for what they actually exercise) | The new test must be named to make the asymmetry explicit (e.g. "...returns Right(light), NOT Left — themeMode is the guarded exception to AC-2"). |
| §6.1 Minimal changes | Single file, one test (+ optional 1-line comment). |

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low** | 1 test added to `settings_repository_impl_test.dart`; optional 1-line cross-ref comment on `getThemeMode()` (likely unnecessary — dartdoc already covers it). |
| New dependencies | **None** | Reuses existing `_buildRepository(initialData:)` harness. |
| Risk | **Very low** | Pure test addition; no production logic touched. Behavior already proven green by line 149, so the new assertion cannot fail if written correctly. |

## Recommendation

**Do not run `/specify`.** Like bug 018, this is a textbook test-only `/fix` — even lower-stakes (the behavior is already exercised; the fix adds explicit, co-located regression-naming). Worth doing to lock the asymmetry against future silent drift.

```
Next steps:
- To fix now:  /fix "Bug 019 — add a test in the AC-2 group of settings_repository_impl_test.dart asserting that a wrong-type themeMode cache value returns Right(manualThemeMode == AppThemeMode.light), explicitly named as the guarded exception to the AC-2 'wrong type -> Left' rule (contrast with the 3 unguarded keys). Use a wrong-type value distinct from the existing legacy-int(1) test to avoid duplication. No production change."
- To shelve: no action needed (Warning-low; behavior is already green, only the named contract is missing).
```

Two notes for the `/fix`: (1) place the test **inside** the existing `load() — wrong-type cache values return Left (AC-2)` group so the contrast is co-located; (2) skip the optional `getThemeMode()` comment unless you want belt-and-suspenders — the existing dartdoc already documents the wrong-type fallback.

## Related Issues

- bug 018 (same feature-022 `/verify` Warning batch — fixed 2026-06-07)
- bug 020 (settings screen save-error-path coverage gap — spun off during bug 018 `/fix`)
- specs/022-settings-error-containment (the feature whose AC-2 this documents)
