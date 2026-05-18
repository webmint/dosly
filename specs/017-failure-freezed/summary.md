## Feature Summary: 017 — `Failure` hierarchy → @freezed sealed union (bug 006 fix)

### What was built

Closes bug 006 by re-authoring `lib/core/error/failures.dart` from a hand-rolled `sealed class Failure` + lone `CacheFailure` into the constitution-§3.2-prescribed `@freezed sealed class Failure` union with six factory constructors (`notFound`, `cache`, `permissionDenied`, `notificationSchedule`, `validation`, `unknown`). The migration is intentionally non-behavioral: factory redirects to public subclass names keep every existing call site and test reference compiling byte-identically, while unblocking future features that need typed validation, permission, notification-schedule, or unknown-error failures.

### Changes

- **Task 001** — Rewrite `Failure` as `@freezed` sealed union + run codegen (architect): replaced `failures.dart` with the constitution-§3.2 shape, ran `build_runner` to emit `failures.freezed.dart`, verified via three byte-identical `git diff` checks that no consumer file needed editing.
- **Task 002** — Update architecture docs + close bug 006 (tech-writer): updated `docs/architecture.md` §Failure handling code snippet + appended one sentence naming the 6 public redirect classes; stamped `bugs/006-failure-hierarchy-incomplete.md` as Closed.

### Files changed

- `lib/core/error/` — 1 modified (`failures.dart`), 1 added (`failures.freezed.dart`, generated)
- `lib/features/settings/.../settings_provider.g.dart` — regenerated as deterministic build_runner side-effect (source `.dart` byte-identical)
- `docs/architecture.md` — 1 paragraph in §Failure handling (code block + 1 sentence)
- `bugs/006-failure-hierarchy-incomplete.md` — header status flipped to Closed
- `bugs/017-typed-logger-missing.md` — added "Additional Finding: Failure-aware sanitizer" scope from `/review`
- `specs/017-failure-freezed/` — spec, plan, research, review, verify, summary, 2 task files + index
- `research/2026-05-17-bug-006-failure-hierarchy.md` — pre-spec feasibility report
- `.claude/memory/MEMORY.md` — L163 clarified (sealed vs non-sealed `abstract` rule) + 3 new pitfall entries

**Totals**: 17 files changed, 1,767 insertions, 39 deletions.

### Key decisions

- **Public-class redirect targets** (`= CacheFailure`, not `= _CacheFailure`): constitution §3.2 mandates this; happens to make the migration non-breaking because pre-existing `const CacheFailure('msg')` literals and `isA<CacheFailure>()` matchers keep working unchanged.
- **`@freezed sealed class Failure` (no `abstract` keyword)**: Dart 3 forbids `abstract sealed` — `sealed` is implicitly abstract. MEMORY L163's `abstract`-keyword rule was rewritten to distinguish sealed unions (no `abstract`) from non-sealed `@freezed` classes (`abstract` required).
- **Byte-identical-claim ACs (AC-8/9/10)**: encoded the "non-breaking migration" claim as `git diff main -- <path>` must produce zero output for `settings_repository_impl.dart`, `settings_provider.dart`, and `test/features/settings/`. Strongest possible regression test of the claim; caught zero regressions because the implementation was correct.
- **Forward-looking PII guidance, not constraint**: a 4-line dartdoc on `Failure.unknown.error: Object` warns callers against passing PII; the real defense (a `Failure`-aware sanitizer) was forwarded to `bugs/017` rather than expanding spec 017's scope.

### Deviations from plan

- **Task 001**: AC-1 was amended from "`@freezed abstract sealed class Failure`" to "`@freezed sealed class Failure`" mid-execution. Root cause: Dart 3 rejects the `abstract sealed` combination; the original wording inherited an over-broad reading of MEMORY L163. The constitution §3.2 example itself uses the non-`abstract` form. Spec, task file, and MEMORY were corrected.
- **Task 001**: `lib/features/settings/presentation/providers/settings_provider.g.dart` regenerated as a build_runner side-effect (8 lines of inline-comment propagation). The source `settings_provider.dart` is byte-identical, so AC-9 (which scopes to the source) held. Code-reviewer assessed as a deterministic generator side-effect, not scope creep.
- **`/review` follow-up**: security review's Medium finding (`UnknownFailure.toString()` PII leak path; CWE-209/CWE-532) was forwarded to `bugs/017-typed-logger-missing.md` as a per-variant redact/allowlist disposition table — extending that bug's `/specify` scope rather than expanding spec 017.

### Acceptance criteria

- [x] AC-1: `lib/core/error/failures.dart` declares `@freezed sealed class Failure with _$Failure` (amended; no `abstract` in Dart 3).
- [x] AC-2: Six factory constructors verbatim from constitution §3.2, in order.
- [x] AC-3: `part 'failures.freezed.dart';` directive + generated file present and tracked.
- [x] AC-4: Only `package:freezed_annotation/freezed_annotation.dart` imported.
- [x] AC-5: `library;` preserved; dartdoc on `Failure` present.
- [x] AC-6: `dart analyze` clean (`No issues found!`).
- [x] AC-7: `flutter test` matches baseline (227/227 pass).
- [x] AC-8: `settings_repository_impl.dart` byte-identical to pre-spec.
- [x] AC-9: `settings_provider.dart` (source) byte-identical to pre-spec.
- [x] AC-10: `test/features/settings/` byte-identical to pre-spec.
- [x] AC-11: `docs/architecture.md` §Failure handling code block + 1 sentence updated; surrounding prose preserved.
- [x] AC-12: `bugs/006-failure-hierarchy-incomplete.md` Status=Closed + Fixed=2026-05-17 (spec 017).
- [x] AC-13: `flutter build apk --debug` succeeds.
- [x] AC-14: No new lint warnings.

**Verdict (from `/verify`)**: APPROVED — 14 of 14 ACs PASS.
