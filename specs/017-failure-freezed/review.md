# Review Report: 017-failure-freezed

**Date**: 2026-05-17
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 5 (`lib/core/error/failures.dart`, `lib/core/error/failures.freezed.dart` [NEW], `lib/features/settings/presentation/providers/settings_provider.g.dart` [regenerated side-effect], `docs/architecture.md`, `bugs/006-failure-hierarchy-incomplete.md`)
**Pre-spec checkpoint**: `b21380b9`
**Post-completion HEAD**: `0e821ba`

---

## Security Review

- Critical: 0 | High: 0 | Medium: 1 | Info: 4
- **Agent verdict**: APPROVE
- **Constitution compliance**: PASS (§3.1, §3.2, §2.1, §4.2.1 all satisfied — implementation matches §3.2 verbatim; §4.2.1 PII concerns are forward-looking).

### Medium

- **`lib/core/error/failures.dart:43–48`** — `Failure.unknown(Object error, StackTrace stack)` accepts unconstrained `Object`. Generated `toString()` (`failures.freezed.dart:558–560`) emits `error.toString()` verbatim. **[CWE-209: Generation of Error Message Containing Sensitive Information] / [CWE-532: Insertion of Sensitive Information into Log File]** — becomes exploitable only when a logger consumes `Failure.unknown` payloads.
  Why Medium not High: no production call site exists today; no logger exists today (bug 017 deferred). The 4-line dartdoc warning added in this spec is the appropriate developer-guidance intervention for the empty-variant phase.
  Recommendation: track via bugs 010 + 017. When bug 017 (typed logger) lands, ship a `Failure`-aware sanitizer that allowlists field-by-field (e.g. `PermissionDeniedFailure.permission` is safe; `UnknownFailure.error.toString()` is redact-by-default). When bug 010 (broaden catches) lands, change `on Exception catch (e)` → `catch (e, st)` to capture the stack and route uncategorized errors via `Failure.unknown(e, st)`.

### Info

- **CWE-209 deferral (bug 010) is acceptable for this spec**. Pre-existing `Left(CacheFailure(e.toString()))` at 4 sites in `settings_repository_impl.dart` is unchanged. Path leakage was present pre-spec; deferral is documented and traceable.
- **Forward-looking pitfalls for `Failure.validation({field, message})`**. Recommend the first consuming feature treats `field` as a closed enum-like string (`'name'`, `'dosage'`, …) and routes `message` through the bug-017 sanitizer's redact-by-default path.
- **`Failure.notFound({String? id})` + PHI**. A bare `MedicationId.value` is not PHI in isolation but is a correlation vector if logs include surrounding context. Bug 017's sanitizer should redact-by-default unless allowlisted.
- **`failures.freezed.dart` generated code is benign**. `DeepCollectionEquality` on `UnknownFailure.error` is the standard freezed shape for `Object` fields; no side effects beyond expected freezed semantics.

### Deferred bug chain (traceable)

- `bugs/010-repository-catches-only-exception.md` — broaden catches, route to `Failure.unknown(e, st)`
- `bugs/014-load-never-fails-doc-lie.md` — out of scope
- `bugs/017-typed-logger-missing.md` — typed logger + `Failure`-aware sanitize layer

---

## Performance Review

- High: 0 | Medium: 0 | Low: 3 | Notes: 5
- **Agent verdict**: APPROVE
- **Performance budgets**: none defined in constitution §5 (no startup/frame/memory/app-size constraints exist for this project).

### Low

- **L-1: `copyWith` getter allocates `_$XxxFailureCopyWithImpl` on every access**. Standard freezed pattern. No call site uses `.copyWith` on any `Failure` variant today. Forward-looking note: future authors should avoid `failure.copyWith(...)` on hot render paths.
- **L-2: `UnknownFailure.==` and `.hashCode` use `DeepCollectionEquality` on `Object error`**. Standard freezed behavior for an `Object` field. Cheap on non-collection error types; expensive only if `error` is itself a deeply nested collection AND `UnknownFailure` is used in `Set<Failure>` / `Map<Failure, ...>`. Not consumed in production today.
- **L-3: ~18 KB of generated source**. Static repo + parse-time cost. Post-AOT-tree-shake binary impact estimated `< 1 KB` (5 unused variants + their `copyWith` impls eliminated; `FailurePatterns` extension and `_$identity` similarly dead-code-eliminated). Not measured (`flutter build --release --analyze-size` requires signing setup, out of scope for personal-use app).

### Notes

- **N-1: `CacheFailure.==` is strictly no slower than the pre-spec hand-rolled version**. Adds `identical()` short-circuit + `runtimeType` check + fast-path `identical(other.message, message) || other.message == message`. `const` instances (most test literals) hit the `identical` path immediately.
- **N-2: `settings_provider.g.dart` delta is behaviorally inert**. 8 lines of inline-comment propagation; no method bodies / provider wiring / state logic changed.
- **N-3: `toString()` format changed for `CacheFailure`**. Old: default `Instance of 'CacheFailure'`; new: `Failure.cache(message: $message)`. Strictly more useful for debugging. Affects log lines only — and no logger exists yet.
- **N-4: Constitution §5 defines business rules, not performance budgets**. Assessment used project-neutral Dart/Flutter AOT reasoning.
- **N-5: `@pragma('vm:prefer-inline')` on all generated `copyWith` getters**. Standard freezed output; allows AOT escape analysis to eliminate wrapper allocations at locally-used call sites.

---

## Test Assessment

- AC coverage: 13 of 14 ACs PASS by test or inspection; AC-13 (debug APK build) deferred to CI.
- **Agent verdict**: ADEQUATE
- Suite size: 227 tests pre-spec → 227 tests post-spec (AC-7 met).
- Test files modified: 0 (AC-10 met — `git diff b21380b9 -- test/features/settings/` empty).

### AC coverage matrix

| AC | Description | Coverage source | Status |
|----|-------------|-----------------|--------|
| AC-1 | `@freezed sealed class Failure with _$Failure` (no `abstract`) | Read of `failures.dart:21–22` | PASS |
| AC-2 | 6 factory constructors verbatim from constitution §3.2 | `grep -c` returns 6; full signature comparison | PASS |
| AC-3 | `part 'failures.freezed.dart';` present + file exists + tracked | `grep` + `ls` + `git ls-files` | PASS |
| AC-4 | Only `package:freezed_annotation` imported | `grep "^import "` returns 1 | PASS |
| AC-5 | `library;` preserved; dartdoc on `Failure` present | Read of `failures.dart:1–22` | PASS |
| AC-6 | `dart analyze` clean | `dart analyze` → No issues found! | PASS |
| AC-7 | `flutter test` matches baseline (227) | 227/227 pre + post | PASS |
| AC-8 | `settings_repository_impl.dart` byte-identical | `git diff b21380b9 -- ...` empty | PASS |
| AC-9 | `settings_provider.dart` byte-identical | Same — empty | PASS |
| AC-10 | All `test/features/settings/` files byte-identical | Same — empty | PASS |
| AC-11 | `docs/architecture.md` §Failure handling updated | Read of `architecture.md:131–149` | PASS |
| AC-12 | `bugs/006-...md` Status=Closed + Fixed=2026-05-17 (spec 017) | Read of file header | PASS |
| AC-13 | `flutter build apk --debug` succeeds | Reported green by architect agent during Task 001; not re-verified by qa agent | NOT VERIFIED (defer to CI) — strong surrogate via AC-6 + AC-7 |
| AC-14 | No new lint warnings | `dart analyze` → No issues found! | PASS |

### Coverage gaps

None blocking. The five new variants (`NotFoundFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`) have no dedicated tests. Constitution §3.4 mandates tests for use cases, not for unused data shapes. The first consuming feature should naturally exercise its variant; pre-emptive tests would be YAGNI without a production trigger to keep them honest.

### Forward-looking edge cases (not blocking — surface when each variant lands a consumer)

- `Failure.validation`: empty `field`, empty `message`, whitespace-only strings — relevant when AddMedication validation ships.
- `Failure.unknown`: passing unusual `Object` types (`TypeError`, `FlutterError`) — confirm generated `toString()` doesn't blow up and that callers don't leak PII via `error.toString()`.
- `Failure.notFound`: `null` vs `''` vs valid id for the optional `id` field — relevant when the first repository that can return `NotFoundFailure` ships.

---

## Summary

| Dimension | Verdict | Critical/High | Action |
|-----------|---------|---------------|--------|
| Security | APPROVE | 0 / 0 | Track 1 Medium via bug 017 sanitizer scope |
| Performance | APPROVE | 0 / 0 | None — defer measurement to a future spec if budgets emerge |
| Tests | ADEQUATE | — | Verify AC-13 in CI on PR |

Overall posture: **clean, non-behavioral migration**. The deferred bug chain (010 → 017) is documented and traceable. No production consumer of the new variants exists yet, so all variant-specific concerns are forward-looking. The `/verify` step can render verdict confidently based on this report.
