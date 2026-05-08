# Task 004: Update settings doc, architecture doc, and close bug 003

**Agent**: tech-writer
**Status**: Complete
**Files**: `bugs/003-silent-error-swallowing-fold.md`, `docs/features/settings.md`, `docs/architecture.md`
**Depends on**: 001, 002, 003
**Blocks**: None
**Context docs**: `specs/014-surface-settings-errors/spec.md`, `specs/014-surface-settings-errors/plan.md`
**Review checkpoint**: Yes — convergence point (depends on 001, 002, 003). Before starting, verify that the source-edit tasks shipped clean (`flutter test` passes, the SnackBar appears on persistence failure in the widget test).

## Completion Notes

**Completed**: 2026-05-07
**Files changed**: bugs/003-silent-error-swallowing-fold.md, docs/features/settings.md, docs/architecture.md
**Contract**: Expects 4/4 verified | Produces 3/3 verified
**Code review**: APPROVE (zero critical/warning findings; 2 minor info notes: arrow-vs-block listener syntax in illustrative snippet — accepted as shorthand)
**Notes**: Scope clean — only 3 markdown files modified. All deferral/empty-closure prose removed from settings.md. Architecture pattern paragraph placed in existing `### Failure handling` subsection (not a new section). dart analyze still passes cleanly.

## Description

Pure bookkeeping task. Source code is already final and tested by the
end of Task 003. This task records the closure of bug 003 in its front
matter and updates the two doc files affected: the settings feature doc
(describes the new error stream + SnackBar contract) and the architecture
doc (one-paragraph note documenting the side-channel error-stream pattern
for future feature reuse).

No source code, no test code, no ARB changes — this task touches only
markdown.

## Change details

- In `bugs/003-silent-error-swallowing-fold.md`:
  - Change the front matter:
    - `**Status**: Open` → `**Status**: Closed`
    - `**Fixed**:` → `**Fixed**: 2026-05-07 (spec 014)`
  - Do not modify the description, evidence, or fix-notes sections — they
    remain as the historical record of the bug.

- In `docs/features/settings.md`:
  - Locate the section that currently describes the four mutators' Left
    branch (likely titled "Error handling", "Persistence failures", or
    similar — the spec-013 update added language about the empty-closure
    deferral).
  - Replace the prose describing "deferred to bug 003" / "empty closure"
    with a concise description of the new behavior:
    1. Each of the four `setX` mutators forwards `Left(Failure)` to a
       broadcast `StreamController<Failure>` owned by `SettingsNotifier`.
    2. The stream is exposed via the top-level `settingsErrorsProvider`
       (a `StreamProvider<Failure>`).
    3. `SettingsScreen` is a `ConsumerWidget` that listens to the provider
       via `ref.listen` and shows a localized M3 floating SnackBar (text
       from `context.l10n.settingsPersistenceError`) on each emission.
    4. The new ARB key `settingsPersistenceError` lives in `app_en.arb`,
       `app_de.arb`, and `app_uk.arb` (English / German / Ukrainian).
    5. The state-update contract is preserved: the in-memory state is
       NOT updated on persistence failure (the Right-only
       `state = state.copyWith(...)` shape).
  - Remove any references to the spec-013 deferral comments — they no
    longer exist in source.
  - Cross-reference: add a one-line note that bug 003 was closed by spec
    014.

- In `docs/architecture.md`:
  - Locate the error-handling section (search for "Either", "fpdart",
    "Failure", or "error handling").
  - Add a one-paragraph subsection (or extend an existing paragraph) titled
    something like "Surfacing mutator failures to the UI" / "Side-channel
    error streams":
    > For mutators that return `Either<Failure, T>` and need to surface
    > failures to the UI without changing state shape or the mutator's
    > `Future<void>` return type, use a side-channel
    > `StreamProvider<Failure>` pattern. The notifier owns a broadcast
    > `StreamController<Failure>` initialized in `build()` and cleaned up
    > via `ref.onDispose`. Each Left fold-branch calls `controller.add`.
    > A top-level `StreamProvider<Failure>` exposes the stream. Consumers
    > use `ref.listen<AsyncValue<Failure>>(...)` with `whenData` to
    > trigger side-effects (e.g. SnackBar). First established by
    > `settingsErrorsProvider` in spec 014 — see
    > `lib/features/settings/presentation/providers/settings_provider.dart`
    > for the canonical example.
  - Keep the addition to a single paragraph. This is a pattern-pointer,
    not a tutorial.

## Done when

- [x] `bugs/003-silent-error-swallowing-fold.md` front matter contains the literal `**Status**: Closed`.
- [x] `bugs/003-silent-error-swallowing-fold.md` front matter contains the literal `**Fixed**: 2026-05-07 (spec 014)`.
- [x] `docs/features/settings.md` contains references to `settingsErrorsProvider`, `settingsPersistenceError`, and `SnackBar` (verify with `grep`).
- [x] `docs/features/settings.md` no longer contains "deferred to bug 003" or "empty closure" prose (verify with `grep -F 'deferred to bug 003' docs/features/settings.md` returning no matches).
- [x] `docs/architecture.md` contains a paragraph mentioning `settingsErrorsProvider` as the canonical example of the side-channel error-stream pattern.
- [x] No source code, ARB, or test files touched in this task (`git diff --name-only HEAD` should show only `bugs/003-...`, `docs/features/settings.md`, `docs/architecture.md`).
- [x] `dart analyze` still passes (sanity — docs shouldn't affect it, but verify nothing was accidentally edited).

## Spec criteria addressed

AC-15, AC-16.

## Contracts

### Expects
- (from Task 003) Source implementation is complete: `settingsErrorsProvider` exists, `SettingsScreen` is a `ConsumerWidget` with `ref.listen`, SnackBar shows localized text from `settingsPersistenceError`.
- (from Task 002) `settings_provider.dart` no longer contains the string `"deferred to bug 003"`.
- `bugs/003-silent-error-swallowing-fold.md` exists with `**Status**: Open` and an empty `**Fixed**:` field (already true at task start).
- `docs/features/settings.md` and `docs/architecture.md` exist (already true).

### Produces
- `bugs/003-silent-error-swallowing-fold.md` contains the literal strings `**Status**: Closed` and `**Fixed**: 2026-05-07 (spec 014)`.
- `docs/features/settings.md` contains the substrings `settingsErrorsProvider`, `settingsPersistenceError`, and `SnackBar`.
- `docs/architecture.md` contains a paragraph that mentions `settingsErrorsProvider` and describes the side-channel error-stream pattern for mutator failures.
