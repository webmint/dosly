# Bug 018: `settings_screen_test.dart` fake injects `CacheFailure`, which production no longer emits

**Status**: Open
**Severity**: Warning
**Source**: verify (feature 022)
**Feature**: specs/022-settings-error-containment/spec.md
**AC**: N/A (test-fidelity issue, not an AC failure)
**Reported**: 2026-05-25
**Fixed**:

## Description

Feature 022 changed `SettingsRepositoryImpl`'s four `save*` methods to return
`Left(Failure.unknown(e, st))` on failure (previously `Left(CacheFailure(...))`).
The notifier test (`settings_provider_test.dart`) was realigned during Task 2 to
inject and assert `UnknownFailure`. The **screen** test was out of that task's
scope and still fabricates `CacheFailure('mock failure')` from its hand-written
`_FakeSettingsRepository` save methods.

The test still passes because `settings_screen.dart` discards the `Failure`
payload (`next.whenData((_) { ... static localized string ... })`) and never
inspects the type. But the fake now diverges from real production behavior: no
production code path emits `CacheFailure` for a settings save anymore. The test
documents a contract the system no longer honors, weakening its regression value.

## File(s)

| File | Detail |
|------|--------|
| test/features/settings/presentation/screens/settings_screen_test.dart | `_FakeSettingsRepository` save methods (~lines 32–62) return `Left(CacheFailure('mock failure'))` |

## Evidence

Reported by security-reviewer (Info note) and code-reviewer during feature 022
`/review`:

> `settings_screen_test.dart:32-62` still injects `CacheFailure('mock failure')`
> from its fake while production no longer emits `CacheFailure` for save
> failures — the screen ignores the payload so the test still passes, but the
> fake diverges from production behavior.

## Fix Notes

Mirror the Task 2 realignment already applied to `settings_provider_test.dart`:
change the screen test's `_FakeSettingsRepository` save methods to return
`Left(Failure.unknown(Exception('mock failure'), StackTrace.empty))`. Update any
doc comments / test names that reference `CacheFailure`. Since the screen ignores
the payload, no assertion change is required — this is purely fake-to-production
fidelity. Trivial, single-file `/fix`.

## Related Issues

- bug 019 (same feature-022 `/verify` Warning batch)
- Production change that caused the divergence: feature 022 Task 2 (closes bug 010)
