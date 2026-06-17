# Task 009: Presentation providers (composition seam)

**Agent**: architect
**Files**: `lib/features/meds/presentation/providers/medication_providers.dart`
**Depends on**: 005, 006, 007, 008
**Blocks**: 011
**Context docs**: `lib/features/settings/presentation/providers/settings_provider.dart` (seam pattern), `.claude/memory/MEMORY.md` (§2.1 composition-seam exception)
**Review checkpoint**: Yes — convergence point; full DI graph wired (the one place presentation imports `data/`)

**Description**:
Wire the dependency graph as `@riverpod` codegen functions, exposing a `domain`-typed `AddMedication` provider the modal consumes. This is the sanctioned composition seam: this provider file may import `data/` (constitution §2.1 amendment, MEMORY 2026-06-09); screens/widgets must not.

**Change details**:
- `medication_providers.dart` with `part 'medication_providers.g.dart'`:
  - `@riverpod MedicationLocalDataSource medicationLocalDataSource(Ref ref) => MedicationLocalDataSource(ref.watch(appDatabaseProvider));`
  - `@riverpod MedicationRepository medicationRepository(Ref ref) => MedicationRepositoryImpl(ref.watch(medicationLocalDataSourceProvider));`
  - `@riverpod AddMedication addMedication(Ref ref) => AddMedication(ref.watch(medicationRepositoryProvider), ref.watch(idGeneratorProvider));`
- Imports: `data/datasources/...`, `data/repositories/...`, `domain/repositories/...`, `domain/usecases/...`, `core/database/database_provider.dart`, `core/id/id_generator_provider.dart`.
- Run `build_runner` (riverpod codegen).

**Done when**:
- [ ] `addMedicationProvider`, `medicationRepositoryProvider`, `medicationLocalDataSourceProvider` exist and compile
- [ ] `addMedicationProvider` resolves to a `domain`-typed `AddMedication` wired with the repo + `idGenerator`
- [ ] only this provider file (not screens/widgets) imports `meds/data/`
- [ ] generated file committed; `dart analyze` passes

## Contracts
### Expects
- `appDatabaseProvider` (task 005), `idGeneratorProvider` (task 006), `AddMedication` (task 007), `MedicationLocalDataSource` + `MedicationRepositoryImpl` (task 008)
### Produces
- `medication_providers.dart` exports `addMedicationProvider`, `medicationRepositoryProvider`, `medicationLocalDataSourceProvider`

**Spec criteria addressed**: AC-17

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: presentation/providers/medication_providers.dart (+ .g.dart)
**Contract**: Expects 4/4 | Produces 3/3 (medicationLocalDataSourceProvider, medicationRepositoryProvider, addMedicationProvider)
**Review**: Verified (not separately agent-reviewed) — mechanical mirror of the already-reviewed settings_provider.dart composition seam. Seam invariant confirmed: no meds screen/widget imports data/. analyze clean.
**Notes**: Providers expose domain-typed MedicationRepository/AddMedication; plain `Ref` param (generator 4.x idiom).
