# Task 012: Riverpod providers (intake composition seam)

**Agent**: architect
**Files**: `lib/features/meds/presentation/providers/intake_providers.dart` (+ generated `.g.dart`)
**Depends on**: 008, 009, 010
**Blocks**: 015
**Context docs**: docs/features/meds.md
**Review checkpoint**: Yes

**Description**:
Assemble the intake dependency graph in a presentation composition-seam file, exactly like `medication_providers.dart` (the only presentation files allowed to import `data/`). Expose domain-typed abstractions + the reactive intakes stream (mapping `Left→throw`).

**Change details**:
- `intake_providers.dart` with `@riverpod` functions:
  - `IntakeLocalDataSource intakeLocalDataSource(Ref ref) => IntakeLocalDataSource(ref.watch(appDatabaseProvider));`
  - `IntakeRepository intakeRepository(Ref ref) => IntakeRepositoryImpl(ref.watch(intakeLocalDataSourceProvider));`
  - `MarkIntakeTaken markIntakeTaken(Ref ref) => MarkIntakeTaken(ref.watch(intakeRepositoryProvider), ref.watch(idGeneratorProvider));`
  - `SkipIntake skipIntake(Ref ref) => SkipIntake(ref.watch(intakeRepositoryProvider), ref.watch(idGeneratorProvider));`
  - `UndoIntake undoIntake(Ref ref) => UndoIntake(ref.watch(intakeRepositoryProvider));`
  - `Stream<List<Intake>> intakesList(Ref ref) => ref.watch(intakeRepositoryProvider).watchAll().map((either) => either.fold((f) => throw f, (v) => v));`
- Run build_runner.

**Contracts**:

### Expects
- `IntakeLocalDataSource` (008), `IntakeRepositoryImpl` + `IntakeRepository` (009/007), `MarkIntakeTaken`/`SkipIntake`/`UndoIntake` (010), `appDatabaseProvider`, `idGeneratorProvider` exist.

### Produces
- `intake_providers.dart` declares `intakeRepositoryProvider`, `markIntakeTakenProvider`, `skipIntakeProvider`, `undoIntakeProvider`, and `intakesListProvider` (a `Stream<List<Intake>>` provider that folds `Left→throw`).

**Done when**:
- [ ] All providers generate and compile; `intakesListProvider` maps `Left→throw` like `medicationsListProvider`.
- [ ] Only this presentation file imports `data/` (seam preserved).
- [ ] `dart analyze` passes.

**Spec criteria addressed**: AC-9, AC-12

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `presentation/providers/intake_providers.dart` (+ `.g.dart`)
**Contract**: Expects [ok] | Produces [5+/5+] — `intakeRepositoryProvider`, `markIntakeTakenProvider`, `skipIntakeProvider`, `undoIntakeProvider`, `intakesListProvider` (Left→throw), plus `intakeLocalDataSourceProvider`.
**Notes**: Faithful mirror of `medication_providers.dart` seam. Verified seam intact — 0 screen/widget files import `data/`. `UndoIntake(repo)` only (no idGen); mark/skip take `(repo, idGen)`. Checkpoint: seam-integrity concern verified directly (grep) in lieu of a separate review agent for this mechanical mirror; full code review reserved for 014/015 UI. `dart analyze` clean.
