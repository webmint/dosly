# Plan: Auto-Miss Engine for Intakes

**Date**: 2026-07-04
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Add a pure `findAutoMissDoses` derivation and a `ReconcileMissedIntakes` use case that scan today's due doses, select those past their intake window (`now > scheduledAt + intakeWindow.minutes`) with **no stored intake row**, and persist each as a `missed` `Intake`. The use case reads `intakeWindow` via the settings domain (`SettingsRepository.load()`), takes point-in-time meds/intake snapshots from the existing repositories' `watchAll().first`, and writes through a new `IntakeRepository.markMissed` backed by an **insert-or-ignore** data-source path (so a `taken`/`skipped` row can never be clobbered). It is triggered fire-and-forget on app open (a keepAlive `reconcileMissedOnOpenProvider`, mirroring `devSeedProvider`) and once per Today-screen mount (`initState`). `IntakeStatus.missed` gains a display-only, error-toned "Missed" tile. No drift schema change; `schemaVersion` stays 2.

## Technical Context

**Architecture**: Clean Architecture across all three meds layers + one app-level trigger site; reads the settings feature's domain interface.
**Error Handling**: `Either<Failure, T>` (fpdart) at every repository/use-case boundary; triggers are fire-and-forget and fold failures to a log (never crash startup).
**State Management**: Riverpod codegen (`@riverpod` / `@Riverpod(keepAlive: true)`); the reactive `intakesListProvider` propagates newly written `missed` rows to the UI with no manual refresh.

## Constitution Compliance

- **§2.1 domain purity** — `findAutoMissDoses` and `ReconcileMissedIntakes` are pure Dart (no Flutter/drift/data imports). ✓
- **§2.1 cross-feature dependency** — the use case depends on the settings **public domain API** (`SettingsRepository`, an abstract interface) to read `intakeWindow`; §2.1 explicitly permits "via the public domain API of B", and spec 039 OQ-1 blessed meds↔settings domain coupling. The meds→settings direction has no cycle. **Requires attention (documented, compliant)**: `intake_providers.dart` imports `settingsRepositoryProvider` at the DI seam — a cross-feature *provider* import confined to the composition root; screens/widgets never import settings. ✓
- **§3.1 exhaustive switch** — the tile's `IntakeStatus` switch stays exhaustive, no `default:`; the `missed` arm becomes a real widget. ✓
- **§3.2 Either everywhere** — new repo method + use case return `Either<Failure, T>`; both fold-paths handled. ✓
- **§4.2.1 non-blocking startup** — the app-open trigger is fire-and-forget, never awaited on the path to `runApp`. ✓
- **§4.2.1 / §6.5 schema** — no column/table/enum change; `missed` already fits the `intakes` table + `IntakeStatus` `textEnum`. `schemaVersion` stays 2. ✓
- **Clock injection** — `now` flows in as `clock.now()` at the trigger sites; derivation/use case never call `DateTime.now()`. ✓
- **§5.2 state machine** — auto-transition target is `missed` (never `skipped`); missed tile is locked (Manual-Correction is out of scope). ✓
- **UTC storage / local display** — `DueDose.scheduledAt` is already UTC; `missed` rows store UTC via the existing mapper. ✓

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain — value object | Pure `findAutoMissDoses({meds, intakes, window, now}) → List<DueDose>` (past-window ∧ no-row subset of `expandDueDoses`) | **New** `lib/features/meds/domain/value_objects/missed_intake_reconciliation.dart` |
| Domain — use case | `ReconcileMissedIntakes` — read window (settings) + meds/intake snapshots, derive, mint `IntakeId`, `markMissed` each; `Either<Failure, int>` | **New** `lib/features/meds/domain/usecases/reconcile_missed_intakes.dart` |
| Domain — repo contract | Add `Future<Either<Failure, Intake>> markMissed(Intake)` | **Modify** `lib/features/meds/domain/repositories/intake_repository.dart` |
| Data — data source | `insertMissedIntake(companion)` via `InsertMode.insertOrIgnore` (never overwrites an existing occurrence row) | **Modify** `lib/features/meds/data/datasources/intake_local_data_source.dart` |
| Data — repo impl | Implement `markMissed` → `insertMissedIntake(intakeToCompanion(...))`, exceptions → `Left(CacheFailure)` | **Modify** `lib/features/meds/data/repositories/intake_repository_impl.dart` |
| Presentation — providers | `reconcileMissedIntakesProvider` (use case wiring) + `reconcileMissedOnOpenProvider` (`@Riverpod(keepAlive: true)`, fire-and-forget, self-logging) | **Modify** `lib/features/meds/presentation/providers/intake_providers.dart` (+ regen `.g.dart`) |
| Presentation — startup trigger | Read `reconcileMissedOnOpenProvider` on the `data:` branch (fire-and-forget, non-blocking) | **Modify** `lib/app_bootstrap.dart` |
| Presentation — Today trigger | `initState` fire-and-forget `ref.read(reconcileMissedIntakesProvider).call(now: clock.now())` (once per mount) | **Modify** `lib/features/meds/presentation/screens/today_screen.dart` |
| Presentation — missed tile | Replace `IntakeStatus.missed => SizedBox.shrink()` with a display-only error-toned "Missed" label | **Modify** `lib/features/meds/presentation/widgets/today_dose_tile.dart` |
| Localization | Add `todayStatusMissed` (+`@`-description) | **Modify** `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (regen `AppLocalizations`) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| **Snapshot source** (OQ-1) | `MedicationRepository.watchAll().first` + `IntakeRepository.watchAll().first` inside the use case | Zero new read methods → avoids the large `MedicationRepository` fake blast radius (MEMORY 037/039); drift `.watch()` emits current state immediately, so `.first` is a clean snapshot | Adding `getAll()` to both repos (big fake blast radius); passing lists in (AppBootstrap has none loaded) |
| **Where `intakeWindow` is read** (OQ-3) | Inject `SettingsRepository` into the use case; read `load().fold(default, s => s.intakeWindow)` | Keeps cross-feature coupling in the **domain** as an abstraction (§2.1-sanctioned public domain API); both triggers stay settings-free (`call(now:)`); unit-testable with a mock returning a fixed window; resilient (falls back to `IntakeWindow.defaultValue` on a Left) | Screen/AppBootstrap reading `settingsNotifierProvider` and passing `window` (Today screen → cross-feature *widget* import, violates §2.1); an app-root orchestration provider (inverts feature→app dependency) |
| **Never-clobber write** (OQ-2) | New `markMissed` → data source `insertMissedIntake` using `InsertMode.insertOrIgnore` (ignores on the `{medicationId, slotId, scheduledAt}` unique conflict) | Health-data safety in depth: even if a `taken`/`skipped` row appears between snapshot and write (race), the DB ignores rather than overwrites. Primary guard remains eligibility (derivation excludes existing rows) | Reusing `upsertIntake` (`DoUpdate`) — would clobber under the snapshot→write race; the spec's #1 High risk |
| **App-open trigger** | `@Riverpod(keepAlive: true) Future<void> reconcileMissedOnOpen` read fire-and-forget from `AppBootstrap` | Mirrors `devSeedProvider` exactly: runs once per app run, non-blocking, self-logging, and **independently overridable** by the integration harness (MEMORY 035) | Inlining `.call()` in `build()` (fires on every data-branch rebuild; not overridable as one seam) |
| **Today trigger** (OQ-4) | Fire-and-forget in `_TodayScreenState.initState` | `initState` runs exactly once per mount → "once per Today load, not per rebuild" for free; write→stream re-emit→`build()` cannot re-enter `initState`, so no reconcile loop (AC-11) | A future provider (autoDispose caches across mounts → wouldn't re-run on re-open; keepAlive → wouldn't re-run either) |
| **Derivation return type** (OQ-6) | Return the eligible `List<DueDose>` (a subset of `expandDueDoses`) | Reuses the existing `DueDose` (medication/slot/scheduledAt already present); no new type; the use case maps each to a `missed` `Intake` | A bespoke `MissedOccurrence` record (redundant with `DueDose`) |
| **Use-case return** (OQ-5) | `Either<Failure, int>` (count of rows written) | Useful for logging/tests; folds cleanly | `Either<Failure, Unit>` (loses observability) |
| **Multi-write error policy** | Fail-fast: first `markMissed` `Left` short-circuits to `Left` | Simplest Either-idiomatic path; partial writes already done are fine (idempotent — next trigger continues) | Best-effort accumulate (more code for negligible benefit) |
| **Missed tile** | Display-only error-toned `Text(l10n.todayStatusMissed)` in the `missed` switch arm; no actions | Matches §5.2 (post-window correction = separate Manual-Correction flow, out of scope); consistent with `_ConfirmedActions` label treatment | Missed tile with Take/Skip (diverges from §5.2; blurs missed→taken) |

### Data flow (use case)

```
ReconcileMissedIntakes.call({now}):
  window   = settingsRepo.load().fold((_) => IntakeWindow.defaultValue, (s) => s.intakeWindow)
  meds     = await medRepo.watchAll().first     → fold Left⇒return Left, Right⇒list
  intakes  = await intakeRepo.watchAll().first  → fold Left⇒return Left, Right⇒list
  eligible = findAutoMissDoses(meds:, intakes:, window:, now:)          // pure
  for d in eligible:
     intake = Intake(id: IntakeId(idGen.newId()), medicationId: d.medication.id,
                     slotId: d.slot.id, scheduledAt: d.scheduledAt, // already UTC
                     confirmedAt: null, status: IntakeStatus.missed, notes: null)
     res = await intakeRepo.markMissed(intake)  → if Left, return Left   // fail-fast
  return Right(count)
```

`findAutoMissDoses` (pure): `expandDueDoses(meds, now)`, drop any dose whose occurrence key `(medId, slotId, localCalendarDate(scheduledAt))` is in the stored-intakes set, keep only those where `now.toUtc().isAfter(scheduledAt.toUtc() + Duration(minutes: window.minutes))` (strict — boundary not yet missed).

### New interface contract (internal)

`IntakeRepository.markMissed(Intake) → Future<Either<Failure, Intake>>` — persists an auto-generated `missed` occurrence via an insert-or-ignore write (an existing occurrence row is never overwritten). Returns `Right(intake)` on success (including the ignore case), `Left(CacheFailure)` when the data source throws.

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/domain/value_objects/missed_intake_reconciliation.dart` | Create | Pure `findAutoMissDoses` derivation |
| `lib/features/meds/domain/usecases/reconcile_missed_intakes.dart` | Create | `ReconcileMissedIntakes` use case |
| `lib/features/meds/domain/repositories/intake_repository.dart` | Modify | Add `markMissed` |
| `lib/features/meds/data/datasources/intake_local_data_source.dart` | Modify | Add `insertMissedIntake` (`InsertMode.insertOrIgnore`) |
| `lib/features/meds/data/repositories/intake_repository_impl.dart` | Modify | Implement `markMissed` |
| `lib/features/meds/presentation/providers/intake_providers.dart` (+`.g.dart`) | Modify | `reconcileMissedIntakesProvider` + `reconcileMissedOnOpenProvider`; imports `settingsRepositoryProvider` + `medicationRepositoryProvider` at the DI seam |
| `lib/app_bootstrap.dart` | Modify | Fire `reconcileMissedOnOpenProvider` on the `data:` branch |
| `lib/features/meds/presentation/screens/today_screen.dart` | Modify | `initState` fire-and-forget reconcile |
| `lib/features/meds/presentation/widgets/today_dose_tile.dart` | Modify | Real `missed` tile (display-only) |
| `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Modify | `todayStatusMissed` (en with `@`-desc) |
| `test/features/meds/presentation/screens/today_screen_test.dart` | Modify | Add `markMissed` no-op to the 2 hand-written `implements IntakeRepository` fakes; override `reconcileMissedIntakesProvider` with a no-op fake so `initState` doesn't error |
| `integration_test/support/app_harness.dart` | Modify | Add `reconcileMissedIntakesProvider.overrideWith(_NoOpReconcile)` (neutralizes both triggers, mirroring the `devSeedProvider` no-op) |
| `test/app_bootstrap_test.dart` | Modify | Neutralize the new startup side-effect (override the reconcile use-case provider) so existing assertions hold |
| `test/features/meds/domain/value_objects/missed_intake_reconciliation_test.dart` | Create | Derivation edge cases (window boundary, existing-row exclusion, future dose, no meds, DST) |
| `test/features/meds/domain/usecases/reconcile_missed_intakes_test.dart` | Create | Idempotency, never-clobber, snapshot-read Left, write Left, count, default-window fallback |
| `test/features/meds/data/repositories/intake_repository_impl_test.dart` | Modify | `markMissed` happy path + insert-or-ignore (existing row preserved) + error → `Left(CacheFailure)` |
| `test/features/meds/presentation/widgets/today_dose_tile_test.dart` | Modify | `missed` renders the "Missed" label, no Take/Skip/Undo (+ de/uk render) |

> **Additions discovered during planning** (not explicitly in the spec's Affected Areas): `lib/features/meds/data/datasources/intake_local_data_source.dart` gains `insertMissedIntake` (the spec left the persist mechanism to `/plan` and leaned on reusing `upsertIntake`; the plan chose a dedicated insert-or-ignore write for never-clobber safety). The use case injects `MedicationRepository` and `SettingsRepository` (the spec left the snapshot/window source open); this pulls `medicationRepositoryProvider` + `settingsRepositoryProvider` into `intake_providers.dart` as DI-seam imports.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/meds.md` | Update | New "Auto-miss engine" subsection under Today: `findAutoMissDoses`, `ReconcileMissedIntakes`, the two triggers, the real `missed` tile; update the "Deferred / out of scope" note (auto-miss now shipped; OS background + Manual-Correction + multi-day backfill still deferred) |
| `docs/features/settings.md` | Update | Note `intakeWindow` now has its first consumer (the auto-miss engine) |
| `docs/architecture.md` | Update (minor) | Note the meds→settings domain dependency (public domain API) and the two reconcile trigger points |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Reconcile clobbers a `taken`/`skipped` row with `missed` | Low | High | Two layers: derivation excludes any occurrence with a row (AC-3/7); `markMissed` write is insert-or-ignore, so the DB never overwrites even under a snapshot→write race. Test never-clobber by reading the row back unchanged. |
| Today `initState` trigger creates a reconcile↔rebuild loop | Low | Medium | `initState` runs once per mount; `build()`/stream re-emission can't re-enter it; already-missed occurrences are ineligible so even a re-fire converges (AC-11). Assert single fire in a widget test. |
| New `AppBootstrap` side-effect poisons integration/startup tests (repeat of devSeed) | Med | Medium | Dedicated overridable `reconcileMissedOnOpenProvider`; harness overrides `reconcileMissedIntakesProvider` with a no-op (neutralizes both triggers); `app_bootstrap_test.dart` does the same (AC-15). |
| Adding `markMissed` breaks the 2 hand-written `implements IntakeRepository` fakes; slips past changed-file analyze | High | Low | Enumerated (`today_screen_test.dart` `_LoadingIntakeRepository`/`_ErrorIntakeRepository`); add no-op overrides; run **project-wide** `dart analyze` + full suite. |
| Cross-feature settings coupling debated in review | Med | Low | Confined to domain interface (use case) + DI seam (provider); documented against §2.1 "public domain API of B" + spec 039 OQ-1. Screens/widgets stay settings-free. |
| `watchAll().first` never emits / hangs | Low | Medium | drift `.watch()` emits current state on listen; snapshots resolve promptly. Fire-and-forget triggers mean even a stall can't block startup. |
| Off-by-one/DST at the window-close boundary | Low | Medium | Reuse `localCalendarDate`/`expandDueDoses`; strict `isAfter` boundary; clock-injected unit tests at and past the edge (AC-2). |

## Dependencies

None. No new packages, services, env vars, or drift migration. Reuses `drift`, `flutter_riverpod`/`riverpod_annotation`, `fpdart`, `clock`, and the existing `IntakeWindow` VO, `IdGenerator`, and repository/provider seams. Run `dart run build_runner build --delete-conflicting-outputs` after the `@riverpod` provider additions.

## Supporting Documents

- No `research.md` — no external signals (all tech is in-stack; the open decisions are internal architecture, resolved above).
- No `data-model.md` — no new/changed entity; `Intake`/`IntakeStatus.missed` and the `intakes` table already exist; no schema change.
- No `contracts.md` — dosly is local-only; the one internal contract change (`IntakeRepository.markMissed`) is captured in "New interface contract" above.
