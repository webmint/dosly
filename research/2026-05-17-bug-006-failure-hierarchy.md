# Research: Bug 006 — `Failure` hierarchy incomplete & not freezed

**Date**: 2026-05-17
**Topic**: Re-author `lib/core/error/failures.dart` as the constitution-§3.2-prescribed `@freezed sealed class Failure` with the full variant set.
**Verdict**: **Feasible** — low-risk, scope is small and tooling is already wired up.

## Summary

The work is a near-mechanical migration: the codebase already declares `freezed: ^3.2.5`, `freezed_annotation: ^3.1.0`, and `build_runner: ^2.15.0`, and the analyzer is already configured to exclude `**/*.freezed.dart`. The actual surface that touches `CacheFailure` outside `failures.dart` is tightly bounded — one repository (4 catch sites), one notifier (5 `result.fold(...)` branches), one stream-side-channel, and three use-case tests. Migrating to the constitution shape (`@freezed abstract sealed class Failure` with the 6 prescribed factory constructors) is a single concentrated edit followed by codegen. The follow-on bug 010 (catching `Exception` only and leaking `e.toString()` into `CacheFailure`) is the natural place to also stop creating `CacheFailure` from raw `e.toString()` — research recommends pairing the two but lets `/specify` decide scope.

## Codebase Findings

### Existing Related Code

| Area | Files | Relevance |
|------|-------|-----------|
| Failure declaration | `lib/core/error/failures.dart:13–26` | The file to rewrite. Currently hand-rolled `sealed class Failure` + lone `CacheFailure`. |
| Constitution prescription | `constitution.md:164–181` | Authoritative shape: 6 factory constructors (`notFound`, `cache`, `permissionDenied`, `notificationSchedule`, `validation`, `unknown`). Bug title says "6 of 7" but the constitution code block specifies 6 — the title overcounts by one. |
| Construction sites | `lib/features/settings/data/repositories/settings_repository_impl.dart:35,45,56,67` | All 4 catches return `Left(CacheFailure(e.toString()))`. These call sites compile against the new factory `Failure.cache(...)` unchanged because the constitution preserves the `CacheFailure` name + single-String-message signature. |
| Consumption sites | `lib/features/settings/presentation/providers/settings_provider.dart:102,124,153,174,193` | All 5 use `result.fold(...)` and forward the `Failure` to a `StreamController<Failure>`. No pattern-matching on subtype today — they will keep compiling. |
| Stream surfacing | `lib/features/settings/presentation/providers/settings_provider.dart:73–87,214` + `settings_screen.dart:38` | The widget already treats `Failure` opaquely (per `docs/architecture.md:146`: "never forward `failure.message` to UI text"). New variants don't need UI translations yet. |
| Tests | `test/features/settings/domain/usecases/{set_theme_mode,set_use_system_theme,set_use_system_language,cycle_theme_mode}_test.dart` | Construct `CacheFailure('mock failure')` literals in `Left<Failure, void>(...)`. With freezed factories these become `Failure.cache('mock failure')` (or unchanged if the redirected name `CacheFailure` is preserved — freezed allows that). |
| Architecture docs | `docs/architecture.md:131–142` | Currently documents the hand-rolled shape. Will need a one-paragraph update. |

### Patterns Available
- Feature 012/Task 003 already proved freezed 3.x integration in this codebase — `MEMORY.md:163` records the gotcha: **`@freezed` 3.x requires the `abstract` keyword** (`@freezed abstract class Foo with _$Foo { ... }`). Same applies to a sealed union.
- The analyzer already excludes `**/*.freezed.dart` (Feature 012 Task 001 addendum brought the analyzer config into compliance).
- `dart run build_runner build --delete-conflicting-outputs` is the established codegen invocation.

### Gaps
- No call site currently exhaustively `switch`es on `Failure` subtype — so introducing 5 new variants is a non-breaking expansion of the union. (If `/specify` decides any consumer should pattern-match, that becomes an explicit AC.)
- Tests that build `CacheFailure('...')` literals must be migrated to the new constructor form (likely `Failure.cache('...')`). Trivial mechanical change.

## Constitution Constraints

| Rule | Impact on This Idea |
|------|---------------------|
| §3.2 (Error Handling) | Mandates exact shape — this work brings the codebase into compliance. |
| §3.1 ("All entities, DTOs, and state classes use `freezed`") | Mandates `@freezed`, not hand-rolled. |
| §3.1 (exhaustive switch over sealed types, no `default:`) | Adding variants is safe today (no exhaustive switches exist on `Failure`); becomes load-bearing for future features that do switch. |
| §2.1 (`domain/` allowed imports) | `freezed_annotation` is on the §2.1 allow-list — no layer-boundary issue. |
| §3.3 (naming) | Constitution example uses `CacheFailure`, `ValidationFailure`, etc. — keep the type aliases via `= NotFoundFailure` redirect syntax so external names stay stable. |
| Memory (Feature 012 / Task 003) | freezed 3.x needs `abstract` keyword on classes using `with _$ClassName`. |

## Approaches

### Option A: Direct migration to the constitution-prescribed `@freezed` shape (recommended)
- **Description**: Rewrite `lib/core/error/failures.dart` as `@freezed abstract sealed class Failure with _$Failure` with the 6 factory constructors verbatim from constitution §3.2. Run codegen. Update the 4 test files (`CacheFailure('x')` → `Failure.cache('x')` or keep `CacheFailure` via the freezed redirect). Update `docs/architecture.md` paragraph.
- **Pros**:
  - Smallest blast radius — no behavior changes at any call site.
  - Brings constitution + code into alignment in one step.
  - Unblocks any future feature needing `Failure.validation(...)`, `Failure.permissionDenied(...)`, etc.
  - Type aliases via factory redirects (`= NotFoundFailure;`) keep the external class names the constitution's §3.3 naming rule prescribes.
- **Cons**:
  - Requires running build_runner once; one new `failures.freezed.dart` enters the tree (committed per §2.2).
  - The 4 settings tests construct `CacheFailure('mock failure')`; under freezed 3.x positional factory redirects, these literals stay valid — but if codegen names a `_$CacheFailureImpl`, the public constructor is now `Failure.cache(...)`. Net: trivial test churn either way (≤ 8 lines).
- **Complexity**: Low.

### Option B: Plain-Dart sealed hierarchy with all 6 subclasses (interim, no codegen)
- **Description**: Keep the hand-rolled `sealed class Failure` and add the 5 missing subclasses as plain Dart classes with hand-rolled `==`/`hashCode`.
- **Pros**: No codegen; no new generated file.
- **Cons**:
  - Violates constitution §3.1 ("All entities, DTOs, and state classes use `freezed` — never hand-roll `==`, `hashCode`, or `copyWith`").
  - Tests comparing `Left<Failure, void>(CacheFailure('boom'))` rely on value equality; would have to be hand-written per subclass.
  - Bug 006's fix notes explicitly call this "acceptable as an interim" but inferior — codebase already has freezed wired up, so the interim has no payoff.
- **Complexity**: Low, but with hand-rolled equality, error-prone.

**Recommended approach**: **Option A.** Tooling is already wired; constitution mandates freezed; payoff (unblocking future variants + compliance) is real and the cost is one codegen run plus ≤ 15 lines of test churn.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | One core file rewrite + 4 test files (literal swaps) + 1 doc paragraph. The 4 catch sites and 5 fold sites compile unchanged if `Failure.cache(...)` is preserved as the constitution prescribes. |
| New dependencies | None | `freezed` / `freezed_annotation` / `build_runner` are already in `pubspec.yaml`. |
| Risk | Low | Non-breaking union expansion; no exhaustive `switch` on `Failure` exists today. Main risk = forgetting the `abstract` keyword (documented in MEMORY). |

## Pairing question for /specify

Bug 010 (repository catches only `Exception`) and bug 006's Fix Notes both target the same 4 catch sites. Bug 006 alone leaves `Left(CacheFailure(e.toString()))` shape unchanged; pairing with bug 010 would replace 3-of-4 of those with `Left(Failure.unknown(e, st))`. Two reasonable scopes for `/specify` to clarify:
- **Narrow**: bug 006 only — rewrite `failures.dart`, fix tests, update docs. Bug 010 stays open.
- **Wide**: bug 006 + bug 010 in one spec — also broaden the catches and stop funneling `e.toString()` into `CacheFailure`.

## Recommendation

**Proceed** — narrow scope by default; widen only if the user wants to bundle bug 010.

- Suggested next command (narrow): `/specify "Bug 006: Migrate lib/core/error/failures.dart to constitution §3.2 — @freezed abstract sealed class Failure with the 6 prescribed factory constructors (notFound, cache, permissionDenied, notificationSchedule, validation, unknown). Run build_runner. Preserve the public CacheFailure name via factory redirect so the 4 repository catch sites, 5 notifier fold branches, and 4 use-case tests keep compiling. Update docs/architecture.md §Failure handling. Out of scope: bug 010 (broaden catches from Exception to all throwables) — explicitly deferred."`
- Suggested next command (wide): `/specify "Bug 006 + bug 010: Migrate lib/core/error/failures.dart to constitution §3.2 freezed sealed union with all 6 variants, AND broaden settings_repository_impl.dart catches from on Exception to catch (e, st) returning Left(Failure.unknown(e, st)) for non-cache exceptions. Keep cache-keyed catches returning Failure.cache(...). Add a _FailingDataSource test double for non-Exception throws (audit F8)."`
