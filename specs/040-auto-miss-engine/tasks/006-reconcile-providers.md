# Task 006: Wire the reconcile providers

**Agent**: architect
**Review checkpoint**: No
**Files**: `lib/features/meds/presentation/providers/intake_providers.dart` (modify), `lib/features/meds/presentation/providers/intake_providers.g.dart` (regenerated)
**Depends on**: 004
**Blocks**: 007, 008
**Context docs**: None

## Description

Expose the use case and a one-shot startup trigger through the meds composition seam. Two providers: `reconcileMissedIntakesProvider` (wires the use case from its four dependencies) and `reconcileMissedOnOpenProvider` (a `@Riverpod(keepAlive: true)` future that runs the reconcile **once** per app run, folds the result, and logs — never throws — mirroring `devSeedProvider`). This is a DI-seam file, so it may import `data/` and, for this feature, the settings repository provider (a documented cross-feature DI import; screens/widgets stay settings-free).

## Change details

- In `lib/features/meds/presentation/providers/intake_providers.dart`:
  - Add imports for `../../domain/usecases/reconcile_missed_intakes.dart`, the `medicationRepositoryProvider` (from `medication_providers.dart`), and `settingsRepositoryProvider` (from `../../../settings/presentation/providers/settings_provider.dart`), plus `package:clock/clock.dart` and the logger provider.
  - `@riverpod ReconcileMissedIntakes reconcileMissedIntakes(Ref ref) => ReconcileMissedIntakes(ref.watch(medicationRepositoryProvider), ref.watch(intakeRepositoryProvider), ref.watch(settingsRepositoryProvider), ref.watch(idGeneratorProvider));`
  - `@Riverpod(keepAlive: true) Future<void> reconcileMissedOnOpen(Ref ref) async { final result = await ref.read(reconcileMissedIntakesProvider).call(now: clock.now()); result.fold((failure) => /* log via loggerProvider, no throw */, (_) {}); }` with dartdoc noting: keepAlive so it runs once per app run; fire-and-forget from `AppBootstrap`; self-logging; overridable in tests.
- Run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `intake_providers.g.dart`.

## Contracts

### Expects
- `ReconcileMissedIntakes` with constructor `(MedicationRepository, IntakeRepository, SettingsRepository, IdGenerator)` and `call({required DateTime now})` (Task 004).
- `medication_providers.dart` exposes `medicationRepositoryProvider`; `intake_providers.dart` already exposes `intakeRepositoryProvider` and reads `idGeneratorProvider`; `settings_provider.dart` exposes `settingsRepositoryProvider` (existing).

### Produces
- `intake_providers.dart` declares `reconcileMissedIntakes` (generating `reconcileMissedIntakesProvider`) returning `ReconcileMissedIntakes`.
- `intake_providers.dart` declares `reconcileMissedOnOpen` annotated `@Riverpod(keepAlive: true)` (generating `reconcileMissedOnOpenProvider`) returning `Future<void>` and folding the reconcile result without throwing.
- `intake_providers.g.dart` regenerated to include both providers.

## Done when
- [x] Both providers exist and compile; `reconcileMissedOnOpen` folds the `Either` and never rethrows a `Failure`.
- [x] `dart run build_runner build` regenerates `.g.dart` with both providers (committed).
- [x] `dart analyze` clean on changed files.

**Spec criteria addressed**: AC-10 (provider), AC-11 (provider)

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/features/meds/presentation/providers/intake_providers.dart`, `lib/features/meds/presentation/providers/intake_providers.g.dart` (regenerated)
**Contract**: Expects [confirmed] | Produces [3/3 verified]
**Notes**: `reconcileMissedIntakesProvider` (autoDispose) wires the use case in the correct constructor arg order (verified). `reconcileMissedOnOpenProvider` is `@Riverpod(keepAlive: true) Future<void>` — runs reconcile once with `clock.now()`, folds the Either, logs the Left via `loggerProvider.warning('...failed', failure)` (generic message, no PHI — Failures are redacted by the log sanitizer), Right is no-op → never throws (mirrors `devSeedProvider`). Function-form providers, so MEMORY-015 `name:` pitfall N/A. No other `.g.dart` regenerated. Project-wide analyze clean. Code review: APPROVE.
