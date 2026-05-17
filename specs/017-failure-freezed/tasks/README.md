# Tasks: Bug 006 — `Failure` hierarchy → @freezed sealed union

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Research**: [../research.md](../research.md)
**Generated**: 2026-05-17
**Total tasks**: 2
**Completion**: 2/2 Complete — feature VERIFIED 2026-05-17 (`verify.md`, 14/14 ACs PASS, APPROVED)

## Dependency Graph

```
001 (rewrite + codegen + verify byte-identical) ──→ 002 (docs + close bug)
```

Linear chain. Task 002 cannot start until 001 has produced both `failures.dart` (in the new shape) and `failures.freezed.dart` (generated), and the byte-identical compatibility checks pass.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Rewrite `Failure` as `@freezed` sealed union + run codegen | architect | None | Complete |
| 002 | Update architecture docs + close bug 006 | tech-writer | 001 | Complete |

## Additions to Spec

None. Plan's File Impact (4 files: `failures.dart`, `failures.freezed.dart`, `docs/architecture.md`, `bugs/006-...md`) is a strict subset of spec §4 Affected Areas. No files surfaced during breakdown that weren't already in scope.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Medium | Carries the spec's load-bearing claim — that factory redirects keep all consumer files (5 production sites, 27 test references) byte-identical. Verification via `git diff` is exhaustive but a Q1-fail at codegen time forces an AC-10 amendment (fallback documented in plan.md). |
| 002 | Low | Mechanical doc edit (one code block + one appended sentence) + a status-header flip. Reference exemplars exist for both. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 002 | High-risk upstream (T1 carries the byte-identical claim); transition from code-layer work to doc/bug-status work | Verify `git diff main -- lib/features/settings/` and `git diff main -- test/features/settings/` are both empty; verify `failures.freezed.dart` is committed; verify `dart analyze` is clean and `flutter test` matches the pre-spec baseline pass count. If any of these fail, do not proceed to Task 002 — escalate per plan.md Risk Assessment. |

## Contract Chain Integrity

Verified: every "Produces" item from Task 001 is consumed by Task 002's "Expects" or maps to a spec acceptance criterion.

| Task 001 Produces | Consumed by |
|-------------------|-------------|
| `@freezed abstract sealed class Failure with _$Failure` declaration | T002 Expects (used in doc snippet) |
| 6 `const factory Failure.x` constructors | T002 Expects (named in doc paragraph) |
| 6 public redirect class names | T002 Expects (named in doc paragraph) |
| `part 'failures.freezed.dart';` directive | AC-3 |
| Single-import constraint | AC-4 |
| `failures.freezed.dart` exists and is staged | T002 Expects + AC-3 |
| `git diff main -- lib/features/settings/` empty | AC-8, AC-9 |
| `git diff main -- test/features/settings/` empty | AC-10 |
| `const CacheFailure('x')` still valid | AC-7, AC-10 |

| Task 002 Produces | Consumed by |
|-------------------|-------------|
| `docs/architecture.md` §Failure handling updated | AC-11 |
| `bugs/006-...md` header `Status: Closed` + `Fixed: 2026-05-17 (spec 017)` | AC-12 |

No orphaned "Produces". No unsatisfied "Expects".

## AC ↔ Task Coverage

| AC | Addressed by |
|----|--------------|
| AC-1 (`@freezed abstract sealed class Failure`) | 001 |
| AC-2 (6 factories verbatim, in order) | 001 |
| AC-3 (`part` directive + generated file) | 001 |
| AC-4 (single import) | 001 |
| AC-5 (`library;` preserved) | 001 |
| AC-6 (`dart analyze` clean) | 001 |
| AC-7 (`flutter test` baseline pass count) | 001 |
| AC-8 (`settings_repository_impl.dart` byte-identical) | 001 |
| AC-9 (`settings_provider.dart` byte-identical) | 001 |
| AC-10 (test files byte-identical) | 001 |
| AC-11 (`docs/architecture.md` §Failure handling) | 002 |
| AC-12 (`bugs/006-...md` closed) | 002 |
| AC-13 (`flutter build apk --debug`) | 001 |
| AC-14 (no new lint warnings) | 001 |

All 14 ACs covered.
