# Spec: Bug 006 — `Failure` hierarchy → @freezed sealed union

**Date**: 2026-05-17
**Status**: Complete
**Author**: Claude + Webmint
**Closes**: `bugs/006-failure-hierarchy-incomplete.md`
**Research**: `research/2026-05-17-bug-006-failure-hierarchy.md`
**Branch**: `spec/017-failure-freezed`

## 1. Overview

Re-author `lib/core/error/failures.dart` to match the constitution §3.2 prescription: a single `@freezed abstract sealed class Failure` union with **six** factory constructors (`notFound`, `cache`, `permissionDenied`, `notificationSchedule`, `validation`, `unknown`). This brings the codebase into compliance with §3.2 (mandated shape) and §3.1 ("All entities, DTOs, and state classes use `freezed` — never hand-roll `==`, `hashCode`, or `copyWith`"), and unblocks any future feature that needs a `ValidationFailure`, `PermissionDeniedFailure`, or typed `UnknownFailure` (e.g. AddMedication validation, notifications permissions, drift wrapping).

The change is intentionally non-behavioral: factory redirects preserve the public `CacheFailure` class name and its `final String message` field, so every existing construction site (`Left(CacheFailure(e.toString()))`), every consumption site (`result.fold(...)` in the notifier), every `isA<CacheFailure>()` test matcher, and every `const CacheFailure('mock failure')` literal continues to compile and pass.

## 2. Current State

**Constitution prescription (`constitution.md:171–181`)** — authoritative target shape:

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.notFound({String? id}) = NotFoundFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.permissionDenied(String permission) = PermissionDeniedFailure;
  const factory Failure.notificationSchedule(String reason) = NotificationScheduleFailure;
  const factory Failure.validation({required String field, required String message}) = ValidationFailure;
  const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;
}
```

> Note: bug 006's title ("missing 6 of 7 mandated variants") overcounts — the constitution code block specifies **6** variants. The spec follows the constitution.

**Actual file (`lib/core/error/failures.dart:1–26`)** — hand-rolled, 1 of 6 variants present:

```dart
library;

sealed class Failure {
  const Failure();
}

class CacheFailure extends Failure {
  const CacheFailure(this.message);
  final String message;
}
```

**Construction surface (data layer)** — `lib/features/settings/data/repositories/settings_repository_impl.dart`:
- `:35` — `Left(CacheFailure(e.toString()))` in `saveThemeMode`
- `:45` — same in `saveUseSystemTheme`
- `:56` — same in `saveUseSystemLanguage`
- `:67` — same in `saveManualLanguage`

All 4 catches use `on Exception catch (e)` and funnel `e.toString()` into `CacheFailure.message`. Bug 010 (broaden to all throwables, switch to typed `Failure.unknown(e, st)`) targets this same surface but is **explicitly deferred** by this spec.

**Consumption surface (presentation layer)** — `lib/features/settings/presentation/providers/settings_provider.dart`:
- `:73–87` — `late final StreamController<Failure> _errors`, initialized in `build()` (Feature 014 pattern)
- `:102, :124, :153, :174, :193` — 5 `result.fold((f) => _errors.add(f), ...)` branches
- `:214` — `settingsErrorsProvider = StreamProvider<Failure>((ref) => ref.watch(settingsProvider.notifier).errors)`

No pattern-match on subtype anywhere — the notifier treats `Failure` opaquely.

**Widget surface** — `lib/features/settings/presentation/screens/settings_screen.dart:38`:
- `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, ...)` — uses static localized strings per `docs/architecture.md:146` ("never forward `failure.message` to UI text").

**Test surface** — 7 files reference `CacheFailure` (≈ 27 occurrences total):
| File | `CacheFailure` literals / matchers |
|------|------------------------------------|
| `test/features/settings/domain/usecases/set_theme_mode_test.dart` | 2 |
| `test/features/settings/domain/usecases/set_use_system_theme_test.dart` | 4 |
| `test/features/settings/domain/usecases/set_use_system_language_test.dart` | 4 |
| `test/features/settings/domain/usecases/set_manual_language_test.dart` | 2 |
| `test/features/settings/domain/usecases/cycle_theme_mode_test.dart` | 2 |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | 4 `const Left(CacheFailure(...))` + 5 `isA<CacheFailure>()` + 4 dartdoc references |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | 4 |

All uses fall into 3 categories: `const Left<Failure, void>(CacheFailure('...'))` constructors, `isA<CacheFailure>()` matchers, and dartdoc comments. Freezed factory redirects (`= CacheFailure`) generate a concrete `class CacheFailure extends Failure` subtype that preserves both the `const` constructor and the type for `isA<>()` — so all 27 uses should continue compiling unchanged.

**Tooling state — already in place** (no `pubspec.yaml` edits required):
- `freezed: ^3.2.5` (dev) — already in `pubspec.yaml:62`
- `freezed_annotation: ^3.1.0` (runtime) — already in `pubspec.yaml:47`
- `build_runner: ^2.15.0` (dev) — already in `pubspec.yaml:63`
- Analyzer excludes `**/*.freezed.dart` (Feature 012/Task 001 addendum)

**Docs state** — `docs/architecture.md:131–142` currently documents the hand-rolled shape; the §Failure handling paragraph needs a one-paragraph rewrite.

**Memory hits** (`/.claude/memory/MEMORY.md`):
- L12 — Greenfield bootstrap step explicitly names this as the first scaffolding (now corrective).
- L42 — freezed chosen for entities/DTOs/sealed unions during `/constitute`.
- L163 — **`@freezed` 3.x requires `abstract` keyword** when using `with _$ClassName`. Applies here.
- L127 — settings notifier's `StreamController<Failure>` side-channel is the canonical surface for forwarding failures; no UI-side variant translation needed in this spec.
- L146 — `docs/architecture.md` instructs "never forward `failure.message` to UI text"; this spec preserves that property (variants carry typed fields, but the widget still uses static localized strings).

## 3. Desired Behavior

After this spec lands:

1. `lib/core/error/failures.dart` declares exactly the constitution §3.2 union — `@freezed abstract sealed class Failure with _$Failure` with the **6** factory constructors verbatim, plus a `part 'failures.freezed.dart';` directive.
2. `lib/core/error/failures.freezed.dart` is generated by `dart run build_runner build --delete-conflicting-outputs` and committed (per constitution §2.2 — generated files committed alongside their source).
3. The file remains pure-Dart (no Flutter imports) — only `package:freezed_annotation/freezed_annotation.dart`, allowed by §2.1.
4. All 6 redirect target names — `NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure` — are exported by the same file (freezed emits them as top-level classes via redirect syntax).
5. Existing production code compiles **unchanged** (zero edits to `settings_repository_impl.dart`, `settings_provider.dart`, `settings_screen.dart`, or any other `lib/` file).
6. Existing tests compile and pass **unchanged** — `const CacheFailure('mock failure')` literals and `isA<CacheFailure>()` matchers stay valid under the redirect.
7. `docs/architecture.md` §Failure handling is updated to the new shape (6 variants, freezed-generated), preserving the existing guidance about never forwarding `failure.message` to UI text.
8. `dart analyze` is clean and `flutter test` passes with no new failures.
9. No other bugs from `bugs/` are addressed by this spec (see §6 Out of Scope).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Core Failure union | `lib/core/error/failures.dart` | Rewrite — replace hand-rolled sealed class + lone `CacheFailure` with `@freezed abstract sealed class Failure` + 6 factory constructors per constitution §3.2. Add `part 'failures.freezed.dart';` directive. |
| Generated freezed file | `lib/core/error/failures.freezed.dart` | Create new — produced by `dart run build_runner build --delete-conflicting-outputs`. Committed per §2.2. |
| Architecture docs | `docs/architecture.md` (§Failure handling, lines ~131–142) | Rewrite the code-snippet paragraph to the new 6-variant freezed shape; preserve the side-channel-pattern paragraph and the "never forward failure.message to UI" guidance. |
| Bug closure | `bugs/006-failure-hierarchy-incomplete.md` | Set `Status: Closed` and fill `Fixed: 2026-MM-DD (spec 017)`. |
| Repository (verify only) | `lib/features/settings/data/repositories/settings_repository_impl.dart` | No code edits. Verified by `dart analyze` + `flutter test` that the 4 `Left(CacheFailure(e.toString()))` sites compile unchanged. |
| Notifier (verify only) | `lib/features/settings/presentation/providers/settings_provider.dart` | No code edits. Verified that 5 `result.fold` branches and the `StreamController<Failure>` compile unchanged. |
| Use-case tests (verify only) | `test/features/settings/domain/usecases/*_test.dart` (5 files) | No code edits expected. Verified that all `const Left<Failure, void>(CacheFailure('...'))` literals compile + pass. |
| Provider test (verify only) | `test/features/settings/presentation/providers/settings_provider_test.dart` | No code edits expected. Verified that 4 `const Left(CacheFailure(...))` returns and 5 `isA<CacheFailure>()` matchers compile + pass. |
| Screen test (verify only) | `test/features/settings/presentation/screens/settings_screen_test.dart` | No code edits expected. Verified that 4 `const Left(CacheFailure(...))` literals compile + pass. |

**Net write-surface**: 2 source files (1 rewrite + 1 new generated), 1 doc file (§-level edit), 1 bug-status closure. Zero edits to any other `lib/` or `test/` file.

## 5. Acceptance Criteria

Each criterion must be testable and unambiguous.

### Core file shape

- [x] **AC-1**: `lib/core/error/failures.dart` contains exactly one top-level union declaration of the form `@freezed sealed class Failure with _$Failure { ... }`. (**Amended 2026-05-17**: original wording specified `@freezed abstract sealed class Failure` per MEMORY L163, but Dart 3 rejects `abstract sealed` — `sealed` implies `abstract`. The constitution §3.2 example itself omits `abstract`. MEMORY L163's `abstract` requirement applies only to non-sealed `@freezed` classes like `AppSettings`; sealed unions must NOT use `abstract`.) Verified by reading the file.

- [x] **AC-2**: The union declares exactly six factory constructors, in this order, with these signatures **verbatim** from constitution §3.2:
  1. `const factory Failure.notFound({String? id}) = NotFoundFailure;`
  2. `const factory Failure.cache(String message) = CacheFailure;`
  3. `const factory Failure.permissionDenied(String permission) = PermissionDeniedFailure;`
  4. `const factory Failure.notificationSchedule(String reason) = NotificationScheduleFailure;`
  5. `const factory Failure.validation({required String field, required String message}) = ValidationFailure;`
  6. `const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;`

  Verified by `grep -c "const factory Failure\." lib/core/error/failures.dart` returning `6` AND by direct text comparison against constitution §3.2.

- [x] **AC-3**: The file contains a `part 'failures.freezed.dart';` directive AND `lib/core/error/failures.freezed.dart` exists on disk after running `dart run build_runner build --delete-conflicting-outputs`. Both files are tracked by git and present in the final commit.

- [x] **AC-4**: `lib/core/error/failures.dart` imports **only** `package:freezed_annotation/freezed_annotation.dart` (and no other package). Verified by grep — no `package:flutter/`, `dart:io`, `dart:ui`, `package:fpdart/`, `package:drift/`, or any `data/` / `presentation/` imports. (Constitution §2.1 allow-list.)

- [x] **AC-5**: The `library;` declaration is preserved at the top of `failures.dart` (or replaced by the dartdoc preamble + `part` directive — whichever freezed 3.x convention requires). Public dartdoc on `Failure` is preserved or rewritten to describe the new union.

### Non-breaking compatibility

- [x] **AC-6**: After the rewrite, `dart analyze` reports zero errors and zero warnings across `lib/` and `test/`. (Codegen-generated `failures.freezed.dart` is covered by the existing `**/*.freezed.dart` analyzer exclude.)

- [x] **AC-7**: `flutter test` passes with the same number of passing tests as before this spec (no new failures, no skipped tests added). Baseline must be captured by running `flutter test` once on the pre-spec tip of `spec/017-failure-freezed` (or on `main`) and comparing pass counts.

- [x] **AC-8**: `lib/features/settings/data/repositories/settings_repository_impl.dart` is **byte-identical** to its pre-spec content. Verified by `git diff main -- lib/features/settings/data/repositories/settings_repository_impl.dart` producing zero output at finalize time.

- [x] **AC-9**: `lib/features/settings/presentation/providers/settings_provider.dart` is **byte-identical** to its pre-spec content. Verified the same way as AC-8.

- [x] **AC-10**: Every test file in `test/features/settings/` is **byte-identical** to its pre-spec content. Verified by `git diff main -- test/features/settings/ | wc -l` returning `0` at finalize time.

  Rationale for AC-8/9/10: the spec's load-bearing claim is "factory redirects make this non-breaking". The byte-identical assertion is the strongest possible test of that claim. If any of these files needs editing, the redirect strategy has failed and the spec must be amended before merge.

### Documentation + bug closure

- [x] **AC-11**: `docs/architecture.md` §Failure handling section is updated. The code snippet matches the new shape (6 factories, `@freezed abstract sealed class Failure`). The paragraph immediately following ("Sealed classes let callers pattern-match exhaustively...") and the "Side-channel error-stream pattern" paragraph remain present and unchanged in meaning. Verified by reading the file.

- [x] **AC-12**: `bugs/006-failure-hierarchy-incomplete.md` has `Status: Closed` and `Fixed: 2026-MM-DD (spec 017)` filled in. Verified by reading the file.

### Build hygiene

- [x] **AC-13**: `flutter build apk --debug` succeeds (debug Android build is the project's smoke-test build per `CLAUDE.md`). Verified by exit code 0.

- [x] **AC-14**: No new lint warnings introduced. Verified by comparing `dart analyze 2>&1 | wc -l` output before and after the spec (delta = 0).

## 6. Out of Scope

This spec is intentionally narrow. The following are **NOT** part of this spec and remain open bugs to be addressed by future specs:

- **NOT included — bug 010**: `lib/features/settings/data/repositories/settings_repository_impl.dart` continues to use `on Exception catch (e)` and continues to wrap with `CacheFailure(e.toString())`. Broadening to `catch (e, st)` and switching non-cache exceptions to `Failure.unknown(e, st)` is deferred. (`bugs/010-repository-catches-only-exception.md`)

- **NOT included — bug 014**: The `load()` method on `SettingsRepository` continues to return a non-`Either` `AppSettings` (audit F-load-never-fails). Re-typing it to `Either<Failure, AppSettings>` is deferred. (`bugs/014-load-never-fails-doc-lie.md`)

- **NOT included — bug 017**: A typed logger is not introduced by this spec. (`bugs/017-typed-logger-missing.md`)

- **NOT included — using the new variants**: This spec adds the variants but does **not** introduce any new call site that uses `Failure.notFound`, `Failure.permissionDenied`, `Failure.notificationSchedule`, `Failure.validation`, or `Failure.unknown`. Those will arrive with the features that need them (e.g. AddMedication for validation, notifications feature for permissionDenied + notificationSchedule).

- **NOT included — exhaustive `switch` migration**: No consumer is rewritten to pattern-match on the union. Today's `result.fold((f) => ..., (r) => ...)` calls stay untouched. Switch-based handling can arrive feature-by-feature.

- **NOT included — UI translation of new variants**: `docs/architecture.md:146`'s guidance "never forward `failure.message` to UI text" is preserved. No new localized strings are added for `validation.message` or any other variant's field — those are added by the feature that uses them.

- **NOT included — `pubspec.yaml` edits**: `freezed`, `freezed_annotation`, `build_runner` are already present at the required versions. No dependency changes.

## 7. Technical Constraints

- **Must follow constitution §3.2** — exact factory-constructor names, parameter shapes, redirect class names. No deviation.
- **Must follow constitution §3.1** — `freezed`, not hand-rolled equality; `abstract` keyword required by freezed 3.x (MEMORY L163).
- **Must follow constitution §2.1** — `lib/core/error/failures.dart` lives in `core/`, must remain feature-agnostic and Flutter-free; allowed imports limited to the §2.1 list.
- **Must follow constitution §2.2** — `lib/core/error/failures.freezed.dart` is committed alongside its source (project policy is to commit generated files).
- **Must use freezed 3.x conventions** — `@freezed abstract class` with `with _$ClassName`, factory redirects, `part` directive. (MEMORY L163.)
- **Must not break Feature 014's side-channel pattern** — `StreamController<Failure>`, `Stream<Failure>` getter, and `StreamProvider<Failure>` in `settings_provider.dart` rely on `Failure` being a single type that accepts all variants. The freezed sealed union preserves this.
- **Must preserve `const` for the cache factory** — existing `const CacheFailure('mock failure')` literals in tests rely on it. Freezed 3.x `const factory ... = CacheFailure;` generates a const constructor on the redirect target; verify after codegen.
- **Codegen invocation**: `dart run build_runner build --delete-conflicting-outputs` (the established invocation per Feature 012/Task 003 and `docs/architecture.md:152`).

## 8. Open Questions

These are minor uncertainties to resolve during `/plan` or `/execute-task`:

- **Q1**: Freezed 3.x with a positional factory parameter and a redirect to a public subclass — does `const factory Failure.cache(String message) = CacheFailure;` produce a `CacheFailure` class whose canonical constructor accepts `const CacheFailure('msg')` syntax (positional), as opposed to forcing callers to `const Failure.cache('msg')`? AC-10 (test files byte-identical) is the regression test for this. If it fails, the spec needs amendment — likely a small one-line shim or accepting test edits (would degrade AC-10 to "literal-pattern-preserving edits only"). Best resolved at `/plan` by reading current freezed 3.x docs (Context7) or a 30-second prototype.

- **Q2**: Does `library;` need to be removed from `failures.dart` when introducing `part 'failures.freezed.dart';`? Dart 3 allows `library;` and `part` to coexist; this should be a no-op concern but worth verifying at execute-time.

- **Q3**: Does the existing dartdoc on the hand-rolled `Failure` / `CacheFailure` need preservation? The new union should carry top-level dartdoc explaining the variants; the per-variant comments are short and can be added inline above each `const factory ...` line. Style decision deferred to `/execute-task` — pick the form that reads best.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Factory redirect doesn't preserve the positional `CacheFailure('x')` constructor signature → all `const CacheFailure('mock failure')` literals break → AC-10 fails | Low | Medium | At `/plan`, run a 30-second prototype on a scratch file or consult freezed 3.x docs via Context7. If redirects don't preserve the form, fall back to mass-rewriting tests to `Failure.cache('mock failure')` and downgrade AC-10 to "literal-call-site edits only". |
| Generated `failures.freezed.dart` triggers a strict-mode analyzer warning despite the `**/*.freezed.dart` exclude | Low | Low | The exclude was verified in Feature 012/Task 001. If it slips here, fix the analyzer config in the same commit. |
| Freezed 3.x emits getters like `failure.message` only on the union (not the redirect class) → `final CacheFailure cf = ...; cf.message` stops working | Low | Medium | Freezed factory redirects generate the field on the concrete subclass; this is the published behavior. Verify in `/plan` prototype. If broken, the consumer-side pattern `(failure as CacheFailure).message` would break — but no such pattern exists in this codebase (audit-confirmed; the notifier and screen treat `Failure` opaquely). |
| Codegen fails silently and an old `failures.freezed.dart` from a prior session lingers | Low | Medium | Always invoke with `--delete-conflicting-outputs` (per docs/architecture.md:152). Re-run analyzer after codegen. |
| Bug 006 title says "6 of 7" — could imply a 7th variant intended elsewhere | Very low | Low | Constitution §3.2 is authoritative and lists 6. The title is an overcount documented at `research/2026-05-17-bug-006-failure-hierarchy.md`. Implement exactly the 6. |
| Future feature accidentally adds a 7th variant without updating exhaustive switches | Low | Medium | Out of scope for this spec — constitution §3.1's "exhaustive switch over sealed types" + freezed-generated exhaustive matchers will surface the need at compile time. |
