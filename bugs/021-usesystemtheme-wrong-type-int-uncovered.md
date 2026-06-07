# Bug 021: bool settings keys' wrong-type AC-2 coverage tests only the String variant, not int

**Status**: Open
**Severity**: Warning (low — corroborative coverage only)
**Source**: fix (bug 019 — Phase 7 test assessment)
**Feature**: specs/022-settings-error-containment/spec.md
**AC**: AC-2
**Reported**: 2026-06-07
**Fixed**:

## Description

The AC-2 wrong-type group in `settings_repository_impl_test.dart` proves that the
three unguarded settings keys promote a wrong-type cached value to
`Left(UnknownFailure)`. The two **bool** keys (`useSystemTheme`,
`useSystemLanguage`) are each probed with a single wrong type — a `String`
(`'not-a-bool'`) — which makes `getBool()` raise a `TypeError`. There is no
complementary probe storing those keys as an `int`.

This is **corroborative coverage only**, not a real gap: the unguarded
`TypeError → load() outer catch → Left` path is already proven by the
String-stored case, so an `int`-stored variant would exercise the same code path
with a different input and merely add belt-and-suspenders. It is the symmetric
counterpart to bug 019, where `themeMode` ended up with two wrong-type probes
(legacy `int 1` and `double 2.5`) — the bool keys could likewise carry a second
wrong-type input to complete the matrix.

## File(s)

| File | Detail |
|------|--------|
| test/features/settings/data/repositories/settings_repository_impl_test.dart | AC-2 group: `useSystemTheme` / `useSystemLanguage` tested only as `String`-stored, not `int`-stored |

## Evidence

Noted by qa-engineer during bug 019 `/fix` test assessment:

> One precise gap exists that is adjacent but outside bug 019's scope: the
> `useSystemTheme` wrong-type path is covered only by the String-stored-as-bool
> case. A complementary test for `useSystemTheme` stored as an `int` ... would
> complete the wrong-type matrix for bool keys ... Low priority — the existing
> test already proves the unguarded TypeError→Left path; the int variant would be
> corroborative.

## Fix Notes

Optional: add one (or two) `test(...)` cases to the AC-2 group storing
`{'useSystemTheme': 1}` (and/or `{'useSystemLanguage': 1}`) and asserting
`load()` returns `Left` with `isA<UnknownFailure>()`, mirroring the existing
String-stored cases. Pure test addition, single file, no production change.
Lowest-priority of the feature-022 verify follow-ups — defer or skip unless
doing a settings test-coverage sweep.

## Related Issues

- bug 019 (the fix during whose test assessment this was surfaced)
- bug 018, bug 020 (same feature-022 `/verify` Warning-batch follow-ups)
- specs/022-settings-error-containment (the feature whose AC-2 this corroborates)
