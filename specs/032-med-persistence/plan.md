# Plan: Medication Persistence (drift)

**Date**: 2026-06-16
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Build the `meds` feature's first `domain/` + `data/` layers and the app's first local database. A versioned **drift** schema (`Medications` + `TimeSlots`) is created under `lib/core/database/`; a pure-Dart `freezed` `Medication` aggregate, an `Either`-returning `MedicationRepository`, and an `AddMedication` use case are added under `lib/features/meds/`; the add-medication modal becomes a `ConsumerStatefulWidget` whose Save button maps form state to the use case via a Riverpod provider. The vertical slice mirrors `features/settings/`.

## Technical Context

**Architecture**: Clean Architecture — all three `meds` layers + a new `core/database/` and `core/id/`. Composition wired with `@riverpod` codegen (the provider file is the only place `presentation` touches `data`, per the §2.1 seam amendment).
**Error Handling**: `Either<Failure, T>` (fpdart) at the repository and use-case boundaries; `data/` catches every drift exception → `Left(Failure.cache/unknown)`.
**State Management**: Riverpod 3 codegen. `appDatabase`/`idGenerator` are `@Riverpod(keepAlive: true)` singletons; repo/datasource/use-case are plain `@riverpod` functions. Save is a one-shot imperative call from the modal (`ref.read`) with a local in-flight flag — no notifier (KISS; there is no shared observed state).
**Time / IDs**: ambient `clock.now().toUtc()`; an injected `IdGenerator` (uuid-backed, in `core/`) supplies all IDs so `domain/` stays import-pure and tests get deterministic IDs.

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 domain purity (no `flutter`/`drift`/`uuid` imports in `domain/`) | **Compliant via design** — `package:uuid` used only in `core/id/`; IDs injected as `IdGenerator`. This refines spec AC-7/AC-9 (drop `MedicationId.generate()`). See [research.md](research.md). |
| §2.1 composition seam (provider file may import `data/`) | Compliant — `medication_providers.dart` wires datasource+repo, mirroring `settings_provider.dart`. |
| §3.1 type safety (freezed, typed IDs, no `!`/`dynamic`/unchecked `as`, exhaustive switch) | Compliant — freezed entities + IDs; exhaustive `switch` on `MedicationForm`/`MedicationType` in the mapper. |
| §3.2 `Either<Failure,T>` both branches | Compliant — repo + use case return `Either`; modal `.fold`s. |
| §4.1.1 UTC + inject `Clock` | Compliant — `createdAt = clock.now().toUtc()`; `startDate` stored as UTC calendar date. |
| §4.2.1 drift is the system of record (never SharedPreferences) | Compliant — meds data goes to drift; settings prefs untouched. |
| §4.2.1 / §6.6 bump `schemaVersion` + migration on schema change | Compliant — fresh `schemaVersion = 1`, `MigrationStrategy.onCreate = createAll`. |
| §6.6 codegen committed; `build_runner` after freezed/riverpod/drift | Compliant — run `build_runner build --delete-conflicting-outputs`; commit `*.g.dart`/`*.freezed.dart`. |
| §2.3 `flutter pub add`; new-package justification | Compliant — drift stack pre-blessed (§1/§7.3); `uuid` justified in [research.md](research.md). |
| §3.4 testing (domain + data mandatory) | Compliant — use-case unit tests + in-memory drift data tests + updated widget tests. |

No NON-NEGOTIABLE rule is violated. The only deviation from an *illustrative* constitution snippet is dropping §7.2's `MedicationId.generate()` (greenfield-only example) in favour of `IdGenerator` — the binding §2.1 import rule wins.

## Implementation Approach

### Layer Map

| Layer | What | Files (all new unless noted) |
|-------|------|------------------------------|
| Core | drift `AppDatabase` (optional-executor ctor, `schemaVersion=1`, `MigrationStrategy` w/ `foreign_keys` pragma) + tables | `lib/core/database/database.dart`, `tables/medications_table.dart`, `tables/time_slots_table.dart` |
| Core | `appDatabase` singleton provider (`@Riverpod(keepAlive:true)`, `ref.onDispose(close)`) | `lib/core/database/database_provider.dart` |
| Core | `IdGenerator` interface + `UuidIdGenerator` impl + provider | `lib/core/id/id_generator.dart`, `uuid_id_generator.dart`, `id_generator_provider.dart` |
| Domain | entities/enums/value objects (pure Dart) | `meds/domain/entities/{medication,medication_form,dosage,pack_stock,medication_type,schedule,time_slot}.dart`, `meds/domain/value_objects/{medication_id,time_slot_id}.dart` |
| Domain | repo contract: `Future<Either<Failure,Medication>> add(Medication)` | `meds/domain/repositories/medication_repository.dart` |
| Domain | `AddMedication(this._repo, this._idGenerator)` — validate → assemble (`MedicationId`/`TimeSlotId` via generator, `createdAt` via clock) → `add` | `meds/domain/usecases/add_medication.dart` |
| Data | mapper (domain ↔ companions/rows; exhaustive switches) | `meds/data/mappers/medication_mapper.dart` |
| Data | local data source — `transaction()` inserting medication row + slot rows | `meds/data/datasources/medication_local_data_source.dart` |
| Data | repo impl — try/catch → `Left(Failure)` | `meds/data/repositories/medication_repository_impl.dart` |
| Presentation | `@riverpod` wiring: `medicationLocalDataSource` ← `appDatabase`; `medicationRepository` ← datasource; `addMedication` ← repo + `idGenerator` | `meds/presentation/providers/medication_providers.dart` |
| Presentation | modal → `ConsumerStatefulWidget`; build typed inputs; Save→use case; SnackBars; in-flight disable | `meds/presentation/widgets/add_medication_modal.dart` (**modify**) |
| l10n | success + validation/error strings | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (**modify**) + regen |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| UUID vs domain purity | Injected `IdGenerator` (uuid in `core/`) | Keeps `domain/` import-pure (§2.1); deterministic test IDs; symmetric with `Clock` | uuid in domain (violates §2.1); amend §2.1 (weakens boundary) |
| Drift row-class collision | `@DataClassName('MedicationRow'/'TimeSlotRow')` | Avoids clash with domain `Medication` | `@UseRowClass` (more wiring) |
| Save state mgmt | Imperative `ref.read(addMedication)` + local `_isSaving` | One-shot action, no shared/observed state (KISS) | `AsyncNotifier` controller (overkill; settings notifier holds *persistent* state — Save does not) |
| Atomic write | single `transaction()` (med row + `batch.insertAll` slots) | All-or-nothing aggregate persist | per-row inserts (non-atomic) |
| Stock/dose nullability | nullable columns, 1:1 flattened onto `Medications` | KISS — no over-normalised 1:1 child tables | separate `Stocks`/`Doses` tables |
| `startDate` storage | `DateTime.utc(y,m,d)` (calendar date) | A start *date* must not day-shift across tz/DST | `toUtc()` of local midnight (shifts the day) |
| `frequency` column now | persist, always `daily` | Forward-compat with the future scheduling spec; cheap | defer column (migration churn later) — OQ-3 |
| Typed dose units in form | add a `DoseUnit` value to each `_MedFormOption` unit entry | Save needs typed units, not just label closures | parse the localized label back to an enum (fragile) |

**Open questions resolved here**: OQ-1 → PackStock only when remaining+total parse (warnAt defaults 0), else null. OQ-2 → `add` keeps `Either<Failure, Medication>` (echo; used by tests + future list). OQ-3 → persist `frequency` now.

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | Modify | `flutter pub add drift drift_flutter sqlite3_flutter_libs uuid` + `--dev drift_dev` |
| `lib/core/database/database.dart` + `tables/*.dart` | Create | `AppDatabase`, 2 tables |
| `lib/core/database/database_provider.dart` | Create | kept-alive `appDatabase` provider |
| `lib/core/id/{id_generator,uuid_id_generator,id_generator_provider}.dart` | Create | ID abstraction + uuid impl + provider |
| `meds/domain/**` (7 entities + 2 value objects + repo + use case) | Create | pure-Dart domain layer |
| `meds/data/**` (mapper, datasource, repo impl) | Create | drift-backed data layer |
| `meds/presentation/providers/medication_providers.dart` | Create | composition seam |
| `meds/presentation/widgets/add_medication_modal.dart` | Modify | Consumer + Save wiring + typed units |
| `lib/l10n/app_{en,de,uk}.arb` | Modify | new strings |
| `test/features/meds/**` | Create/Modify | use-case + data tests (new); modal tests (rewrite no-op-Save) |
| `*.g.dart` / `*.freezed.dart` (drift+freezed+riverpod) | Create | committed codegen |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| docs/ | None | `docs/` is empty (never onboarded); `/finalize` tech-writer will create initial docs when invoked. No existing docs to update. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `textEnum` value rename later breaks stored rows | Med | Med | Freeze enum value names; reorder/rename only with a migration (note in code) |
| Combined drift+freezed+riverpod codegen conflicts | Med | Low | `build_runner build --delete-conflicting-outputs` (AC-25) |
| Modal mapping needs typed units added to `_MedFormOption` (currently label closures) | Med | Med | Add a `DoseUnit` field per unit entry; hot **restart** after editing the top-level list (MEMORY 2026-06-14) |
| Dropdown-driven widget tests for dose-unit are flaky with `find.text` | Med | Low | Use the off-stage `DropdownMenuItem` idiom (MEMORY 2026-06-08) |
| `pragma foreign_keys` omitted → cascade silently off | Med | Low | Set in `beforeOpen` (AC-2) |
| `IdGenerator` indirection misread as over-engineering | Low | Low | Documented as the §2.1-compliant, Clock-symmetric choice (research.md) |
| Existing no-op-Save modal tests break | High | Low | In scope — AC-24 rewrites them |

## Dependencies

- **Add** (`flutter pub add`): `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `uuid` (runtime); `drift_dev` (dev). No `path`/`path_provider` needed — `drift_flutter` manages the file path; tests use `NativeDatabase.memory()`.
- No services, env vars, or platform config (local-only, no new permissions).

## Supporting Documents
- [Research](research.md) — drift API decisions + the IdGenerator/uuid resolution
- [Data Model](data-model.md) — entities, drift tables, mapping, validation
- (No contracts.md — no REST/GraphQL surface; the repository interface is in the Layer Map.)
