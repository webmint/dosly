# Bug 019: `themeMode` wrong-type read returns `Right(default)`, not `Left` — asymmetry untested

**Status**: Open
**Severity**: Warning (low)
**Source**: verify (feature 022)
**Feature**: specs/022-settings-error-containment/spec.md
**AC**: AC-2
**Reported**: 2026-05-25
**Fixed**:

## Description

Feature 022's AC-2 requires that a wrong-type cached value for any settings key
never throws out of `load()`. The behavior differs between keys, and the
difference is correct but undocumented by any test:

- `useSystemTheme`, `useSystemLanguage`, `manualLanguage` — their data-source
  getters are **unguarded**, so a wrong-type cached value raises a `TypeError`
  that `load()`'s outer `try/catch` converts to `Left(Failure.unknown)`. Three
  tests cover this (assert `isLeft()` + `isA<UnknownFailure>()`).
- `themeMode` — its getter `getThemeMode()` is **internally guarded** (its own
  `try/catch` falls back to `AppThemeMode.light`). So a wrong-type `themeMode`
  produces `Right(default)`, NOT `Left`. The existing legacy-int test
  (`returns manualThemeMode=light when legacy int themeMode (1) is stored`)
  covers the guarded-fallback path, but no test explicitly names that
  `themeMode` is the one key that does NOT propagate to a `Left` on wrong type.

The asymmetry is intentional and works. The gap is documentation/regression
coverage: nothing makes the "themeMode is guarded differently" contract explicit,
so a future change to `getThemeMode()`'s guard could silently alter behavior.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/data/datasources/settings_local_data_source.dart | `getThemeMode()` internal `try/catch` (guarded); the other three getters unguarded |
| test/features/settings/data/repositories/settings_repository_impl_test.dart | AC-2 group tests the 3 unguarded keys → `Left`; legacy-int themeMode test covers the guarded fallback but doesn't name the asymmetry |

## Evidence

Reported by qa-engineer during feature 022 `/review`:

> **AC-2 — `themeMode` wrong-type key not tested.** The three AC-2 tests cover
> `useSystemTheme`, `useSystemLanguage`, and `manualLanguage`. The `themeMode`
> key is intentionally guarded inside the data source ... it produces
> `Right(default)`. No test currently documents or asserts this difference in
> behaviour. Priority: low (the protection exists and works; it just lacks a
> test that names it).

## Fix Notes

Add a single test asserting that a wrong-type `themeMode` (e.g. legacy int, or a
non-matching string) makes `load()` return `Right` with
`manualThemeMode == AppThemeMode.light` — explicitly labeling it as the guarded
exception to the AC-2 "wrong type → Left" rule. Pure test addition, single file,
no production change. Optionally add a one-line comment on `getThemeMode()`
cross-referencing this guaranteed-fallback contract.

## Related Issues

- bug 018 (same feature-022 `/verify` Warning batch)
