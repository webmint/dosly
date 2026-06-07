# Research: Bug 018 — Stale `CacheFailure` in `settings_screen_test.dart` fake

**Date**: 2026-06-07
**Topic**: `settings_screen_test.dart` fake injects `CacheFailure`, which production no longer emits
**Verdict**: **Feasible — but this is a trivial `/fix`, not a `/specify` candidate**

## Summary

Bug 018 is a **test-fidelity defect**, not a feature. Feature 022 (Task 2, closing bug 010) changed all four `SettingsRepositoryImpl.save*` methods to return `Left(Failure.unknown(e, st))` and realigned the **notifier** test (`settings_provider_test.dart`) accordingly. The **screen** test was out of that task's scope and still fabricates `const Left(CacheFailure('mock failure'))` from its hand-written `_FakeSettingsRepository`. The test passes only because `settings_screen.dart` discards the `Failure` payload (`next.whenData((_) { … static localized string … })`) and never inspects the type. The fix is mechanical: mirror the realignment already proven in the notifier test, in one file. Every claim in the bug file reproduces against HEAD.

## Codebase Findings

### Verification against current code (all bug claims confirmed)

| Claim | Evidence at HEAD | Status |
|------|------------------|--------|
| Production save methods emit `UnknownFailure`, not `CacheFailure` | `settings_repository_impl.dart:43,53,64,75` → `return Left(Failure.unknown(e, st))` | ✅ Confirmed |
| No production path emits `CacheFailure` for a settings save | `grep CacheFailure lib/` → only the `failures.dart` definition, generated `*.freezed.dart`, and the `log_sanitizer.dart` sealed-switch case. **Zero emitters.** | ✅ Confirmed |
| Fake still injects `CacheFailure` | `settings_screen_test.dart:33,42,51,60` → `return const Left(CacheFailure('mock failure'))` | ✅ Confirmed (4 sites) |
| Screen ignores the payload | `settings_screen.dart:38-43` → `ref.listen(...)`, `next.whenData((_) {…})` shows a static localized string | ✅ Confirmed |
| Notifier test already realigned | `settings_provider_test.dart:63,72,81,90` inject `Failure.unknown(Exception('mock failure'), StackTrace.empty)`; assert `isA<UnknownFailure>()` | ✅ Confirmed (the template to mirror) |

### Patterns Available
- **Exact precedent to copy**: `settings_provider_test.dart` lines 63/72/81/90 are the proven realignment — same fake-method shape, same payload `Failure.unknown(Exception('mock failure'), StackTrace.empty)`.
- **Const subtlety**: `const Left(CacheFailure('…'))` is `const`; `Exception('…')` has no const constructor, so the replacement must **drop the `const` keyword** (the notifier test does exactly this). This is the only non-find-replace nuance.

### Gaps / Scope boundary
- **Fix is exactly one file, exactly four lines.** The other three `CacheFailure` test references are **not** stale and must be left alone:
  - `settings_repository_impl_test.dart` asserts `isNot(isA<CacheFailure>())` — a regression guard that *depends* on the name existing.
  - `set_theme_mode_test.dart` / `cycle_theme_mode_test.dart` use `CacheFailure` as a type-agnostic pass-through sentinel through a mocktail mock (testing that the use case forwards any `Left` unchanged). Optional cleanup, explicitly **out of bug 018's scope**.
  - `logger_test.dart` logs a `CacheFailure(secretPath)` to verify sanitizer redaction — a direct test of that variant.
- No doc-comment or test-name changes needed: the fake's class doc says only "simulate persistence failures," and no test name mentions `CacheFailure` (grep-confirmed). Fix notes' "update any doc/test names" clause has nothing to act on.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §3 — every fallible op returns `Either<Failure, T>` | Unchanged; both old and new returns are `Left<Failure, void>`. Purely swaps the variant. |
| Strict lint (`strict-casts`, no `dynamic`) | `Left(Failure.unknown(Exception(...), StackTrace.empty))` is fully typed; PostToolUse `dart analyze` hook will confirm green. |
| "Tests are contracts" (CLAUDE.md Always #5) | This is the whole point: the fake currently encodes a contract production no longer honors. Fix restores fidelity. |
| Minimal-change / no-scope-creep (Always #3, Never #5) | Hard boundary: touch only the 4 save methods in the one screen test; leave the other 3 legitimate `CacheFailure` refs untouched. |

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low** | 1 file, 4 lines (`const Left(CacheFailure('mock failure'))` → `Left(Failure.unknown(Exception('mock failure'), StackTrace.empty))`). |
| New dependencies | **None** | — |
| Risk | **Low** | Screen ignores the payload, so behavior and all assertions are unchanged; the existing error-SnackBar test (`failOnSaveUseSystemTheme`) still passes verbatim. Self-evidently behavior-preserving. |

## Recommendation

**Do not run `/specify`.** This is a textbook localized single-file test fix — the bug file itself says "Trivial, single-file `/fix`," and verification confirms it.

```
Next steps:
- To fix now:  /fix "Bug 018 — realign settings_screen_test.dart _FakeSettingsRepository save methods to return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty)) instead of the stale const Left(CacheFailure('mock failure')); drop const; one file, 4 lines; no assertion changes since the screen discards the payload"
- Related: bug 019 (same feature-022 /verify Warning batch) — consider batching both in one cleanup session.
- To shelve: no action needed (test is green; this is fidelity debt, not a live failure).
```

One judgment call worth flagging during `/fix`: whether to also realign the two **use-case** tests (`set_theme_mode_test.dart`, `cycle_theme_mode_test.dart`) that use `CacheFailure` as a generic sentinel. They're arguably fine as-is (they test type-agnostic pass-through), so leave them unless you want uniform `UnknownFailure` sentinels across the settings suite — but that's scope beyond bug 018.
