# Research: Bug 006 — `Failure` hierarchy → @freezed sealed union

**Date**: 2026-05-17
**Spec**: `specs/017-failure-freezed/spec.md`
**Signals detected**: spec §8 Open Questions Q1 — verify freezed 3.x positional factory redirect preserves the `const CacheFailure('x')` call syntax, so that AC-8/9/10 (byte-identical production + test files) can hold.

## Questions Investigated

### Q1: Does `const factory Failure.cache(String message) = CacheFailure;` allow callers to construct `const CacheFailure('msg')` directly, or does it force `const Failure.cache('msg')`?

**Finding**: Standard Dart factory-redirect semantics + freezed 3.x behavior together guarantee both forms work.

- A Dart `factory A.bar(T x) = B;` redirect requires `B` to be a concrete class with a constructor matching the factory's parameter signature. Callers may construct `B(x)` or `A.bar(x)` — both are legal Dart and produce the same instance.
- Freezed generates the redirect target (`CacheFailure`, `NotFoundFailure`, …) as a **public** concrete class extending `Failure`, with a constructor signature matching the factory's parameter list and `const`-ness.
- The Context7 freezed docs (sourced from the official rrousselgit/freezed repo) show this canonical pattern: `const factory ApiResult.success(T data) = Success;` — `Success` is a real class usable for both construction and pattern matching (`Success(:final data) => ...`).

**Decision**: Use the constitution-§3.2 shape verbatim — all 6 factory constructors redirect to public class names. Pre-existing call sites that use `const CacheFailure('mock failure')` (4 production catches, 27 test references) keep compiling unchanged.

### Q2: Does freezed 3.x preserve `const` on the redirect target?

**Finding**: Yes — when the factory is declared `const factory Foo.bar(...) = Bar;`, freezed emits `Bar` with a `const` canonical constructor matching the parameter signature. This is required by Dart's redirect-rules (a const factory cannot redirect to a non-const constructor).

**Decision**: Declare all 6 factories `const` per constitution §3.2 verbatim. Existing `const CacheFailure('...')` literals in tests stay valid.

### Q3: Does the `isA<CacheFailure>()` matcher continue to work?

**Finding**: Yes. `CacheFailure` is a concrete subclass of `Failure`. `isA<CacheFailure>()` is a runtime-type matcher and matches any instance whose runtime type is the freezed-generated `CacheFailure` (the redirect target). Five existing matchers in `test/features/settings/presentation/providers/settings_provider_test.dart` are unaffected.

**Decision**: No test changes required for the 5 `isA<CacheFailure>()` matchers. AC-10 (test files byte-identical) holds.

### Q4: Freezed 3.x `abstract` keyword requirement — does it apply to sealed unions too?

**Finding**: Yes. MEMORY L163 records "freezed 3.x requires `abstract` keyword on classes using `with _$ClassName`" — the requirement is universal, not specific to single-constructor classes. The existing `AppSettings` in this codebase uses `@freezed abstract class AppSettings with _$AppSettings`; the same form applies to sealed unions: `@freezed abstract sealed class Failure with _$Failure`.

**Decision**: Declare the class `abstract sealed`. Codegen will succeed on first run; no second-pass fix needed.

### Q5: Can the `library;` declaration coexist with `part 'failures.freezed.dart';`?

**Finding**: Yes. The existing `app_settings.dart` does exactly this (line 12: `library;`, line 19: `part 'app_settings.freezed.dart';`). Dart 3 allows them to coexist; the `part` directive doesn't require an explicit library URI.

**Decision**: Keep `library;` at the top of the rewritten `failures.dart`.

## Alternatives Compared

### Sealed-union implementation strategy
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **A. `@freezed abstract sealed class` with 6 factory redirects to public class names** (constitution-§3.2 verbatim) | Matches constitution exactly. Non-breaking — preserves `CacheFailure(...)` constructor + `isA<CacheFailure>()` matchers. Compiler-enforced exhaustive switches available to future features. | One generated `*.freezed.dart` file (~committed). | **Chosen** |
| B. Hand-rolled `sealed class Failure` + 5 new plain Dart subclasses | No codegen. | Violates constitution §3.1 ("never hand-roll `==`/`hashCode`"). Hand-rolled equality breaks `expect(result, Left<Failure, void>(...))` equality checks unless every subclass implements `==`/`hashCode` by hand — error-prone. | Rejected |
| C. Switch redirect targets to private (`= _CacheFailure` etc.) and add typedefs | Hides freezed internals. | Diverges from constitution §3.2 (which names public classes). Forces all existing `const CacheFailure('...')` literals to migrate to `const Failure.cache('...')`. Breaks AC-10. | Rejected |

**Decision**: Option A — the constitution shape is non-negotiable and also happens to be the lowest-friction migration.

## References

- [Context7 — freezed docs](https://context7.com/rrousselgit/freezed/llms.txt) (queried 2026-05-17) — confirms `const factory X.variant(T x) = VariantClass;` pattern for sealed unions, public concrete subclass generation, exhaustive-switch support.
- `constitution.md:164–181` — §3.2 authoritative shape.
- `lib/features/settings/domain/entities/app_settings.dart:14–44` — existing `@freezed abstract class … with _$…` exemplar in this codebase.
- `.claude/memory/MEMORY.md:163` — freezed 3.x `abstract`-keyword requirement.
- `research/2026-05-17-bug-006-failure-hierarchy.md` — pre-spec feasibility report.
