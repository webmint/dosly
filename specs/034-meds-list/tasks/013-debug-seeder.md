# Task 013: Debug seeder + bootstrap wiring

**Agent**: architect
**Files**: `lib/core/database/dev_seed.dart` (new), `lib/features/meds/presentation/providers/medication_providers.dart` (modify), `lib/app_bootstrap.dart` (modify)
**Depends on**: 003
**Blocks**: None
**Context docs**: `specs/034-meds-list/data-model.md` (seed set table)
**Review checkpoint**: Yes

**Description**:
Populate the database with representative variants for on-device testing — **debug builds only**, **only when the table is empty**, never destructive. Build the seed `Medication` entities (relative to `clock.now()`) and persist them via the real repository write path, so the reactive list picks them up automatically. Must not log medication names (PHI).

**Change details**:
- `dev_seed.dart`: `List<Medication> devSeedMedications(DateTime now)` returning the 12-variant set from `data-model.md` (stable `MedicationId('seed-...')` ids; dates relative to `now`; covers all 8 forms, continuous + non-cyclic + cyclic, with/without dose, with/without stock, a low-stock pack, a paused cyclic, and a completed course). Pure builder — no I/O, no logging.
- `medication_providers.dart`: add
  ```dart
  @Riverpod(keepAlive: true)
  Future<void> devSeed(Ref ref) async {
    if (!kDebugMode) return;
    final db = ref.watch(appDatabaseProvider);
    final existing = await db.select(db.medications).get();
    if (existing.isNotEmpty) return;
    final repo = ref.watch(medicationRepositoryProvider);
    for (final med in devSeedMedications(clock.now())) {
      await repo.add(med);
    }
  }
  ```
  (imports: `package:flutter/foundation.dart` for `kDebugMode`, `package:clock/clock.dart`, `appDatabaseProvider`, `dev_seed.dart`). Run build runner for the `.g.dart`.
- `app_bootstrap.dart`: in the `data:` branch (or via a `ref.read`), `if (kDebugMode) ref.read(devSeedProvider);` — fire-and-forget (do not block startup). Keep it side-effect-only, mirroring the existing `ref.read(loggerProvider)` pattern.

**Done when**:
- [x] `devSeedMedications(now)` returns the full variant set (all 8 forms; continuous/non-cyclic/cyclic; with/without dose & stock; low-stock; paused cyclic; completed course).
- [x] `devSeedProvider` no-ops in release (`!kDebugMode`) and when the table is non-empty; inserts only via `repo.add` (never deletes).
- [x] Bootstrap triggers the seeder once in debug without blocking startup; no `print`/PHI logging; `dart analyze` clean.

**Spec criteria addressed**: AC-16, AC-17, AC-18

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: dev_seed.dart (new, 12 meds), medication_providers.dart (+devSeed provider, +.g.dart), app_bootstrap.dart (fire-and-forget trigger)
**Contract**: Expects 3/3 verified | Produces 3/3 verified
**Notes**: 12 seed meds cover all 8 forms + continuous/non-cyclic/cyclic-active/cyclic-paused/completed + low-stock. Triple-guarded (kDebugMode + empty-table + insert-only); `Either` discarded via `.fold((_){},(_){})` (no startup crash on Left); no PHI logging; fire-and-forget bootstrap. **Code-reviewer (high-risk checkpoint): REQUEST CHANGES → 2 criticals fixed**: (1) `ref.watch`-after-`await` → `ref.read` (one-shot keepAlive); (2) B12 seed start −31d was mathematically ACTIVE (`31%30=1`), corrected to −25d (`25%30=25` → genuinely paused) so AC-17's cyclic-paused variant is real. Re-verified against the actual derivation. Full suite **481/481**; analyze clean.

## Contracts

### Expects
- Task 003 `Produces` indirectly via `repo.add` (existing) + `watchAll` (so seeded rows surface reactively).
- `medication_providers.dart` exposes `medicationRepositoryProvider`; `appDatabaseProvider` exposes `AppDatabase` with `medications` table.
- `MedicationId('...')` constructor + `Medication`/`MedicationType`/`Dosage`/`PackStock`/`Schedule`/`TimeSlot` constructors available.

### Produces
- `dev_seed.dart` exports `List<Medication> devSeedMedications(DateTime now)`.
- `medication_providers.dart` contains `@Riverpod(keepAlive: true) Future<void> devSeed(Ref ref)` guarded by `kDebugMode` + empty-table check.
- `app_bootstrap.dart` references `devSeedProvider` under a `kDebugMode` guard.
