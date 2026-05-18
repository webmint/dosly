# Plan: Bug 006 — `Failure` hierarchy → @freezed sealed union

**Date**: 2026-05-17
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Rewrite `lib/core/error/failures.dart` as the constitution-§3.2-prescribed `@freezed abstract sealed class Failure` union with all six factory constructors and public-class redirect targets. Run `build_runner` to emit `failures.freezed.dart`. Update one paragraph in `docs/architecture.md` and close `bugs/006`. The strategy's load-bearing claim — that factory redirects keep every existing call site compiling — is verified at the gate by the existing test suite passing unchanged.

## Technical Context

**Architecture**: Single-file edit in `lib/core/error/` (the `core/` layer). No new layers, no new features, no new modules.
**Error Handling**: This spec **defines** the error-handling shape used everywhere else; it does not consume it. `Either<Failure, T>` continues to be the pattern at repository boundaries and use-case returns (constitution §3.2).
**State Management**: Untouched. The `SettingsNotifier`'s `StreamController<Failure>` side-channel (Feature 014 pattern) is type-compatible with the new union.

## Constitution Compliance

| Rule | Compliant? | Note |
|------|-----------|------|
| §2.1 (`domain/` / `core/` import allow-list) | ✅ | `freezed_annotation` is on the allow-list. No Flutter / `dart:io` / `dart:ui` / `package:fpdart` / `package:drift` / feature imports. |
| §2.2 (generated files committed) | ✅ | `failures.freezed.dart` will be committed alongside `failures.dart`. |
| §3.1 (freezed for entities/DTOs/sealed unions; no hand-rolled `==`/`hashCode`/`copyWith`) | ✅ | The whole point of this spec. |
| §3.1 (freezed 3.x `abstract` keyword) | ✅ | Declared `abstract sealed`. MEMORY L163 already documents this gotcha. |
| §3.2 (`Failure` shape) | ✅ | All 6 factories verbatim, in the prescribed order. |
| §3.3 (naming: `XFailure` suffix) | ✅ | All 6 redirect target class names end in `Failure`. |
| §2.2 + §3.2 — generated file linted under strict mode | ✅ | Analyzer already excludes `**/*.freezed.dart` (Feature 012 / Task 001 addendum). |
| §3.4 (testing) | ✅ | Existing tests stay valid; no new domain code to test (the union is a pure data shape; freezed-generated equality covers what would need testing). |
| §6 (commit hygiene — `Co-Authored-By: Claude` trailer) | ✅ | Applies at `/finalize`. |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Core (data-shape) | Rewrite the sealed `Failure` union and run codegen. | `lib/core/error/failures.dart` (modify) + `lib/core/error/failures.freezed.dart` (new, generated) |
| Docs | Update `docs/architecture.md` §Failure handling to reflect the 6-variant freezed shape. | `docs/architecture.md` (modify) |
| Bugs | Close bug 006. | `bugs/006-failure-hierarchy-incomplete.md` (modify — status only) |
| Domain (verify) | No edits. `lib/features/settings/domain/repositories/settings_repository.dart` references `Failure` opaquely. | (unchanged) |
| Data (verify) | No edits. `settings_repository_impl.dart` constructs `CacheFailure(e.toString())` — preserved by factory redirect. | (unchanged) |
| Presentation (verify) | No edits. `settings_provider.dart` carries `Failure` through a `StreamController<Failure>`. `settings_screen.dart` reads via `AsyncValue<Failure>`. | (unchanged) |
| Tests (verify) | No edits expected. 7 test files reference `CacheFailure` literally or as a type. | (unchanged) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Sealed-union form | `@freezed abstract sealed class Failure with _$Failure` + 6 `const factory Failure.x(...) = XFailure;` redirects to **public** class names | Constitution §3.2 prescribes this exact shape. Public redirect targets are non-breaking — existing `const CacheFailure('msg')` literals + `isA<CacheFailure>()` matchers keep working (research.md Q1/Q2/Q3). | Hand-rolled (violates §3.1); private redirect targets (violates §3.2 + breaks AC-10). |
| Where to invoke codegen | `dart run build_runner build --delete-conflicting-outputs` from project root | Project's documented invocation (`docs/architecture.md:152`, MEMORY L163). | One-off `build` without `--delete-conflicting-outputs` risks stale-output collisions; `watch` mode is for dev loops, not single-shot codegen. |
| File preamble | Keep `library;` at top, add `part 'failures.freezed.dart';` after imports | Matches `app_settings.dart` precedent (research.md Q5). | Removing `library;` is unnecessary — Dart 3 allows it with `part`. |
| Dartdoc on the new union | One paragraph above the class explaining the role of `Failure`; one short comment line above each factory constructor naming its trigger | Constitution §6 ("document new code") — every public factory gets a one-line dartdoc; per-variant comments are short (`/// Resource not found.` etc.). | Hand-write `/// {@template ...}` snippets — overkill for a 6-line code block. |
| Bug-006 closure stamp | Edit `bugs/006-failure-hierarchy-incomplete.md` to set `Status: Closed` and `Fixed: 2026-05-17 (spec 017)` | Project convention for bug closure (see closed bugs 002, 003, 004, 005, 011 patterns under their spec PRs). | Delete the file (loses traceability); leave it open (violates bug-tracking discipline). |
| Where to update docs | `docs/architecture.md` §Failure handling only — the code snippet (lines ~135–142) | Spec §4 limits doc scope to one paragraph. The side-channel-pattern paragraph at line 146 stays unchanged (still accurate). | Touch `docs/features/...` — none of those describe `Failure` directly. |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/core/error/failures.dart` | Modify (rewrite) | Replace lines 9–26 (hand-rolled `sealed class Failure` + `CacheFailure`) with `@freezed abstract sealed class Failure with _$Failure { ... }` containing 6 `const factory` constructors verbatim from constitution §3.2. Add `import 'package:freezed_annotation/freezed_annotation.dart';` and `part 'failures.freezed.dart';`. Keep `library;` preamble. |
| `lib/core/error/failures.freezed.dart` | Create (generated) | Produced by `build_runner`. Contains generated mixin `_$Failure` and 6 concrete subclasses (`NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`) each with const constructors, `==`/`hashCode`/`toString`, and `copyWith` where applicable. Committed to git per §2.2. |
| `docs/architecture.md` | Modify | Replace the §Failure handling code snippet (lines ~135–142) with the new 6-variant freezed shape. Leave surrounding prose untouched — the side-channel-pattern paragraph (line 146) and the "never forward `failure.message`" guidance remain accurate. |
| `bugs/006-failure-hierarchy-incomplete.md` | Modify (close) | Set `Status: Closed`. Set `Fixed: 2026-05-17 (spec 017)`. |

**Files in spec's Affected Areas that this plan does NOT modify** (verified, not touched):
- `lib/features/settings/data/repositories/settings_repository_impl.dart` — AC-8 byte-identical
- `lib/features/settings/presentation/providers/settings_provider.dart` — AC-9 byte-identical
- All `test/features/settings/**/*_test.dart` (7 files) — AC-10 byte-identical
- `lib/features/settings/domain/repositories/settings_repository.dart` — type-references `Failure` only, unchanged
- `lib/features/settings/domain/usecases/*.dart` (5 use cases) — type-references `Failure`/`Either<Failure, …>` only, unchanged
- `lib/features/settings/presentation/screens/settings_screen.dart` — type-references `AsyncValue<Failure>` only, unchanged

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/architecture.md` (§Failure handling, ~lines 131–142) | Update | Replace the code snippet to show `@freezed abstract sealed class Failure` with all 6 factory constructors. Add one sentence noting that generated subclasses (`NotFoundFailure`, `CacheFailure`, …) are public and usable directly for pattern matching + `isA<>()` assertions. Preserve the rest of the section unchanged. |

No other docs change. `docs/features/*` doesn't reference `Failure`; `docs/api/*` doesn't exist (local-only app, no APIs).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Codegen emits an unexpected error (e.g. unsupported parameter shape on a factory) | Low | Medium | Spec §3.2 factories use only well-trodden freezed forms — positional `String`, named-optional `{String? id}`, named-required `{required String field, required String message}`, two-positional `(Object error, StackTrace stack)`. All have working precedents in freezed docs. If codegen fails, the error surfaces immediately and the diff stays in `failures.dart` only — no other file is touched yet. |
| `isA<CacheFailure>()` matcher in `settings_provider_test.dart` (5 occurrences) silently matches against a different generated runtime type than expected | Very low | Medium | Freezed factory redirect generates exactly the named subclass (research.md Q3). If this misbehaves, the 5 tests fail at the existing `flutter test` gate (AC-7) — caught before commit. |
| `const CacheFailure('mock failure')` literal stops compiling (Q1 fail mode) | Very low | High (forces AC-10 amendment) | Verified by Context7 docs + Dart factory-redirect semantics in research.md. If it does fail, fallback: mass-rewrite test literals to `const Failure.cache('mock failure')` (still `const`, still equality-correct) — costs ~25 line edits across 7 files and reduces AC-10's strength to "literal-call-site-preserving edits only". Plan still ships. |
| `failures.freezed.dart` gets linted under strict mode and fails `dart analyze` | Very low | Low | Analyzer already excludes `**/*.freezed.dart` (Feature 012 / Task 001 addendum, also verified by reading `analysis_options.yaml`). |
| `library;` + `part` directive collision | Very low | Low | Verified by existing `app_settings.dart` precedent (research.md Q5). |
| Stale `*.freezed.dart` from a prior session | Very low | Low | Always invoke build_runner with `--delete-conflicting-outputs`. |

## Dependencies

**External packages**: none to install. `freezed: ^3.2.5`, `freezed_annotation: ^3.1.0`, `build_runner: ^2.15.0` are already in `pubspec.yaml`.

**Tooling**: requires `dart` + `flutter` on `PATH` (already established by prior specs).

**Environment**: none.

## AC ↔ Plan Cross-Reference (Phase 2.5)

| Spec AC | Plan element addressing it |
|---------|---------------------------|
| AC-1 (file declares `@freezed abstract sealed class Failure`) | File Impact row 1; Key Design Decisions row 1 (sealed-union form). |
| AC-2 (6 factories verbatim, in order) | File Impact row 1; Key Design Decisions row 1. |
| AC-3 (`part` directive + `failures.freezed.dart` exists) | File Impact rows 1 & 2; Key Design Decisions row 2 (codegen invocation). |
| AC-4 (`failures.dart` imports only `freezed_annotation`) | Constitution Compliance §2.1; File Impact row 1. |
| AC-5 (`library;` preserved or dartdoc rewritten) | Key Design Decisions row 3 (file preamble); Q5 in research.md. |
| AC-6 (`dart analyze` clean) | Constitution Compliance row "generated file linted under strict mode"; Risk row "freezed.dart linted under strict mode". |
| AC-7 (`flutter test` baseline pass count) | Risk rows "isA matcher" and "const literal" both backstop AC-7; the test pass is the verification mechanism. |
| AC-8 (`settings_repository_impl.dart` byte-identical) | File Impact bottom list (NOT modified); load-bearing claim of the spec defended by research.md Q1/Q2. |
| AC-9 (`settings_provider.dart` byte-identical) | Same as AC-8. |
| AC-10 (test files byte-identical) | Same as AC-8/9; risk-mitigated fallback in Risk Assessment if Q1 fails at codegen time. |
| AC-11 (`docs/architecture.md` §Failure handling updated) | Documentation Impact table; Key Design Decisions row 6. |
| AC-12 (`bugs/006-...md` closed) | File Impact row 4; Key Design Decisions row 5. |
| AC-13 (`flutter build apk --debug` succeeds) | Risk row "codegen emits unexpected error" backstops; debug build is run at the gate. |
| AC-14 (no new lint warnings) | Constitution Compliance §2.2 / §3.1; Risk row "freezed.dart linted" backstops. |

Every AC has an implementation path. No AC requires clarification during breakdown.

## Reverse check — files in plan but not in spec's Affected Areas

None. Plan's File Impact (4 rows) ⊆ Spec §4 Affected Areas. The plan's "files NOT modified" list mirrors Spec §4's "verify only" rows.

## Supporting Documents

- [research.md](research.md) — freezed 3.x factory-redirect semantics verification (5 questions, 3 alternatives compared, Context7-sourced).
- No `data-model.md` — the union itself is the data shape and is fully captured in spec §2 + constitution §3.2.
- No `contracts.md` — local-only app, no API.
