# Spec: Medication Persistence (drift)

**Date**: 2026-06-16
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Turn the add-medication modal's Save button from a no-op into real persistence. This spec introduces the app's core entity — `Medication` — as a freezed domain aggregate, a versioned local **drift** (SQLite) database (`Medications` + `TimeSlots` tables), an `Either`-returning `MedicationRepository` + `AddMedication` use case, and wires the modal's Save through a Riverpod provider. It is the first feature to give the `meds` module a `domain/` and `data/` layer; it mirrors the Clean-Architecture vertical slice already used by `features/settings/`. Storage choice (drift) and entity shape are pre-decided in `constitution.md` §1/§5.1 (amended 2026-06-16) and `research/2026-06-16-medication-entity-storage.md`.

## 2. Current State

**`meds` feature has presentation only — no `domain/` or `data/`.**

- `lib/features/meds/presentation/widgets/add_medication_modal.dart` — a `StatefulWidget` (`AddMedicationModal`) that collects all of: medication name (`_nameController`), form (`_selectedForm`, one of 8 keyed `_MedFormOption`s whose `key` strings already match the planned domain enum names), per-form dose/quantity/stock, intake times (`_intakeTimes: List<TimeOfDay>`, sorted + deduped), and intake type (`_IntakeType.continuous|course` with `_durationController`/`_pauseController`/`_startDate`). **All of this is local `State` only.** The Save button is `FilledButton.icon(onPressed: () {}, …)` — an intentional documented no-op (`add_medication_modal.dart:1447`).
- `lib/features/meds/presentation/screens/meds_screen.dart` — placeholder; `body: const SizedBox.shrink()`, a FAB opens the modal via `Navigator.push(MaterialPageRoute(fullscreenDialog: true, …))` on the root navigator. **No medication list is rendered.**
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart` — contains spec-026 assertions that **Save is a no-op** (must be updated by this spec; see MEMORY 2026-06-12 notes on those tests over-claiming).

**Reference pattern — `features/settings/` (mirror this):**
- Domain: `domain/entities/app_settings.dart` — `@freezed abstract class`, pure Dart, documents "domain stays Flutter-free; map at the presentation seam."
- `domain/repositories/settings_repository.dart` (abstract) + `data/repositories/settings_repository_impl.dart` — every datasource exception caught → `Left(Failure.unknown(e, st))`; exceptions never escape `data/`.
- `data/datasources/settings_local_data_source.dart` — the only class touching the storage SDK.
- `presentation/providers/settings_provider.dart` — `@riverpod` codegen; the provider file imports `data/` to wire the repo (sanctioned composition seam, constitution §2.1 amendment 2026-06-09).

**Core available:**
- `lib/core/error/failures.dart` — sealed `Failure`: `notFound`, `cache(String)`, `permissionDenied`, `notificationSchedule`, `validation({field, message})`, `unknown(error, stack)`.
- `lib/core/clock/` — injectable `Clock` (constitution §4.1.1; the modal already uses `clock.now()`).
- Localization: `lib/l10n/` ARB-generated `AppLocalizations` for `en`, `de`, `uk` (constitution: no hardcoded UI strings).

**Dependencies present:** `flutter_riverpod`, `riverpod_annotation`, `fpdart`, `freezed_annotation`, `clock`; dev: `freezed`, `build_runner`, `riverpod_generator`, `mocktail`. **Absent (this spec adds):** `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `drift_dev`, `uuid`. No `lib/core/database/` exists yet (constitution §7.1 items 4–5).

## 3. Desired Behavior

When the user fills the add-medication form and taps **Save**:

1. The current form state is mapped to typed domain inputs and the `AddMedication` use case is invoked through a Riverpod provider.
2. **Validation** (in the use case, returning `Left(ValidationFailure)`): name must be non-empty (trimmed); at least one intake time must exist; when intake type is **Course**, `durationDays` must be ≥ 1. Stock fields are optional.
3. On **success**: the medication + its time slots are written to the local drift database in a single transaction, the modal pops, and a localized success SnackBar is shown.
4. On **failure** (validation or persistence): the modal stays open and shows a localized error SnackBar (a field-specific message for validation, a generic "couldn't save" message otherwise).
5. While the save is in flight the Save button is disabled to prevent double-submit; it re-enables on failure.

Field → entity mapping at Save:
- name → trimmed `String`; form key → `MedicationForm` enum.
- **tablet/capsule**: `dosePerIntake = Dosage(amount: quantity, unit: tablet|capsule)`; `stock = PackStock(remaining, total, warnAt)` when stock fields are provided, else `null`.
- **syrup/drops/injection**: `dosePerIntake = Dosage(amount: parsed dose, unit: selected DoseUnit)`; `stock = null`.
- **inhaler/cream/sachet**: `dosePerIntake = null`; `stock = null`.
- intake times → `List<TimeSlot>` with `minuteOfDay = hour*60 + minute`.
- **continuous** → `MedicationType.continuous(startDate)` (startDate = today's calendar date, UTC); **course** → `MedicationType.course(startDate, durationDays, pauseDays)` (startDate = picked date as UTC calendar date).
- `createdAt = clock.now().toUtc()`; `id = MedicationId.generate()`.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Dependencies | `pubspec.yaml` (via `flutter pub add`) | Add `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `uuid` (runtime); `drift_dev` (dev) |
| Core DB | `lib/core/database/database.dart` | Create new — `AppDatabase` (`@DriftDatabase`), `schemaVersion=1`, `MigrationStrategy` |
| Core DB | `lib/core/database/tables/medications_table.dart`, `time_slots_table.dart` | Create new — drift table definitions |
| Core DB | `lib/core/database/database_provider.dart` | Create new — `@Riverpod(keepAlive: true)` `AppDatabase` singleton + `ref.onDispose(close)` |
| Domain entities | `lib/features/meds/domain/entities/medication.dart`, `medication_form.dart`, `dosage.dart`, `pack_stock.dart`, `medication_type.dart`, `schedule.dart`, `time_slot.dart` | Create new — freezed entities + enums (pure Dart) |
| Domain VOs | `lib/features/meds/domain/value_objects/medication_id.dart`, `time_slot_id.dart` | Create new — typed IDs; `MedicationId.generate()` (uuid v4) |
| Domain repo | `lib/features/meds/domain/repositories/medication_repository.dart` | Create new — abstract; `add(Medication)` |
| Domain usecase | `lib/features/meds/domain/usecases/add_medication.dart` | Create new — validation + build + delegate; returns `Either<Failure, Medication>` |
| Data | `lib/features/meds/data/datasources/medication_local_data_source.dart` | Create new — transactional insert of medication + slots |
| Data | `lib/features/meds/data/mappers/medication_mapper.dart` | Create new — domain ↔ drift companions/rows |
| Data | `lib/features/meds/data/repositories/medication_repository_impl.dart` | Create new — implements contract; catches → `Left(Failure)` |
| Presentation | `lib/features/meds/presentation/providers/medication_providers.dart` | Create new — `@riverpod` data source / repo / use case wiring |
| Presentation | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify — `ConsumerStatefulWidget`; wire Save → use case; SnackBars; in-flight disable; typed unit values |
| l10n | `lib/l10n/app_*.arb` (+ regenerated `AppLocalizations`) | Add success + validation/error strings in `en`/`de`/`uk` |
| Tests | `test/features/meds/domain/usecases/add_medication_test.dart` | Create new — happy path + validation + repo-failure |
| Tests | `test/features/meds/data/.../medication_repository_impl_test.dart`, `medication_mapper_test.dart` | Create new — in-memory drift round-trip + failure path |
| Tests | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify — replace no-op-Save assertions with real save/validation behavior |
| Generated | `*.g.dart`, `*.freezed.dart` (drift/freezed/riverpod) | Create/commit — `build_runner` output |

## 5. Acceptance Criteria

**Dependencies & database scaffolding**
- [x] **AC-1**: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `uuid` are runtime deps and `drift_dev` is a dev dep, all added via `flutter pub add` (constraints match resolved versions); `flutter pub get` succeeds.
- [x] **AC-2**: `AppDatabase` in `lib/core/database/database.dart` is annotated `@DriftDatabase(tables: [Medications, TimeSlots])`, exposes `schemaVersion == 1`, is opened via `drift_flutter`'s `driftDatabase(name: …)`, and defines a `MigrationStrategy` that `createAll` on create and runs `pragma foreign_keys = ON` in `beforeOpen`.
- [x] **AC-3**: A `@Riverpod(keepAlive: true)` provider exposes the singleton `AppDatabase` and registers `ref.onDispose(db.close)`.

**Schema**
- [x] **AC-4**: `Medications` table (`@DataClassName('MedicationRow')`) has columns: `id` text PK; `name` text; `form` `textEnum<MedicationForm>`; `doseAmount` real nullable; `doseUnit` `textEnum<DoseUnit>` nullable; `typeKind` `textEnum` (continuous|course); `frequency` `textEnum<ScheduleFrequency>` (default `daily`); `startDate` dateTime; `durationDays` int nullable; `pauseDays` int nullable; `stockRemaining`/`stockTotal`/`stockWarnAt` int nullable; `notes` text nullable; `createdAt` dateTime.
- [x] **AC-5**: `TimeSlots` table (`@DataClassName('TimeSlotRow')`) has columns: `id` text PK; `medicationId` text referencing `Medications.id` with `onDelete: KeyAction.cascade`; `minuteOfDay` int; `doseAmount` real nullable; `doseUnit` `textEnum<DoseUnit>` nullable.

**Domain**
- [x] **AC-6**: `domain/entities/` defines freezed `Medication`, enum `MedicationForm` (tablet, capsule, syrup, drops, injection, inhaler, cream, sachet), `Dosage` + enum `DoseUnit` (tablet, capsule, ml, mg, drops, units, puff, application, sachet), `PackStock`, sealed `MedicationType` (`continuous({startDate})` | `course({startDate, durationDays, pauseDays})`), `Schedule` (frequency default `daily` + `List<TimeSlot> slots`) + enum `ScheduleFrequency` (`daily`), and `TimeSlot` (`id`, `minuteOfDay`, optional `doseOverride`). No file under `domain/` imports `package:flutter/*`, `package:drift/*`, or any `data/`/`presentation/` path.
- [x] **AC-7**: `value_objects/medication_id.dart` defines `MedicationId` (wraps a `String`, value equality, `MedicationId.generate()` → v4 UUID) and `time_slot_id.dart` defines `TimeSlotId`.
- [x] **AC-8**: `MedicationRepository` (abstract interface, `domain/repositories/`) declares `Future<Either<Failure, Medication>> add(Medication medication)`.
- [x] **AC-9**: `AddMedication` use case returns `Future<Either<Failure, Medication>>`, builds the `Medication` with `MedicationId.generate()` and `createdAt = clock.now().toUtc()`, and delegates to `MedicationRepository.add`.

**Validation (use case)**
- [x] **AC-10**: empty/whitespace name → `Left(ValidationFailure(field: 'name'))`; repository not called.
- [x] **AC-11**: zero intake times → `Left(ValidationFailure(field: 'times'))`; repository not called.
- [x] **AC-12**: Course type with `durationDays < 1` → `Left(ValidationFailure(field: 'durationDays'))`; repository not called.
- [x] **AC-13**: valid input → `repository.add` called exactly once; its `Right`/`Left` returned unchanged.

**Data layer**
- [x] **AC-14**: `MedicationRepositoryImpl` delegates to `MedicationLocalDataSource`, which inserts the medication row and all time-slot rows in **one drift transaction**; every data-source exception is caught and returned as `Left(Failure.cache(...))` or `Left(Failure.unknown(e, st))` — no exception escapes `data/`.
- [x] **AC-15**: the mapper round-trips every field (domain → companions → insert → read → domain): null `Dosage` ↔ both dose columns null; null `PackStock` ↔ all three stock columns null; `MedicationType` ↔ (`typeKind`,`startDate`,`durationDays`,`pauseDays`); each `TimeSlot.minuteOfDay` preserved. Verified against an in-memory drift database.
- [x] **AC-16**: `startDate` is persisted as a UTC calendar date (`DateTime.utc(y, m, d)`, no day-shift) and `createdAt` as `clock.now().toUtc()`.

**Presentation / wiring**
- [x] **AC-17**: `AddMedicationModal` is a `ConsumerStatefulWidget`; Save maps form state to typed inputs (form key→`MedicationForm`, dose/quantity→`Dosage`, dose-unit selection→`DoseUnit`, times→`minuteOfDay`, continuous/course→`MedicationType`) and invokes `AddMedication` via a provider (`ref.read` in the callback).
- [x] **AC-18**: on `Right` the modal pops and shows a localized success SnackBar; on `Left` it stays open and shows a localized error SnackBar (validation → field-specific message; otherwise → generic message).
- [x] **AC-19**: the Save button is disabled while the save is in flight (no double-submit) and re-enabled on failure; `mounted` is checked after every `await` before using `BuildContext` (`use_build_context_synchronously` stays satisfied).
- [x] **AC-20**: persisted dose/stock match the form: tablet/capsule → `Dosage(unit: tablet|capsule)` + optional `PackStock` (null when stock fields blank); syrup/drops/injection → `Dosage` with selected unit, `stock` null; inhaler/cream/sachet → `dosePerIntake` and `stock` both null.

**l10n, tests, build**
- [x] **AC-21**: all new user-facing strings (success + validation/error messages) exist in `en`, `de`, `uk` ARBs and are read via `AppLocalizations`; no hardcoded UI strings.
- [x] **AC-22**: unit tests cover `AddMedication` — happy path, AC-10/11/12 validations, and repository-failure passthrough — using a `mocktail` repository mock and a fixed `Clock`.
- [x] **AC-23**: data-layer tests cover `MedicationRepositoryImpl` + mapper with an in-memory drift database (full round-trip + a failure path).
- [x] **AC-24**: the modal widget tests no longer assert "Save is a no-op"; instead they assert that valid input invokes the use case (provider overridden) and pops, and that invalid input shows the error SnackBar and does not pop.
- [x] **AC-25**: `dart run build_runner build --delete-conflicting-outputs` produces all generated files (committed); `dart analyze` is clean under strict mode; `flutter test` passes.

## 6. Out of Scope

- NOT included: rendering / listing saved medications on the Meds screen (the body stays a placeholder; a separate spec adds the reactive list, empty state, and `getAll`/`watch` queries).
- NOT included: editing, deleting, or querying medications beyond `add` (no `getById`/`getAll`/`update`/`delete` in this spec).
- NOT included: `Intake` records, the intake state machine, adherence calculation, and the `Intakes` table (downstream — same data model, future spec).
- NOT included: notifications / reminder scheduling, exact-alarm permissions, boot re-arming.
- NOT included: schedule frequencies other than `daily` (`everyNDays`, `specificWeekdays` are modeled in the constitution but not built here; no UI exists).
- NOT included: pack-stock decrement on intake, low-stock warnings/notifications.
- NOT included: the `Settings` domain entity (gracePeriod/intakeWindow/etc.) — the existing SharedPreferences settings stack is untouched.
- NOT included: schema migrations beyond v1 (fresh database), data export, cloud sync.
- NOT included: a live/reactive "Save disabled until the form is valid" affordance — the button only disables during an in-flight save.

## 7. Technical Constraints

- **Clean Architecture (constitution §2.1)**: `domain/` is pure Dart (no `flutter`/`drift` imports); `presentation/` depends only on `domain/`, except the `@riverpod` provider file may import `data/` to wire the repository (sanctioned composition seam, MEMORY 2026-06-09). Mirror the `settings` slice.
- **Error handling (§3.2)**: `Either<Failure, T>` at the repository and use-case boundaries; `data/` catches every exception → `Left`; `.fold` handles both branches.
- **Drift row/domain name collision**: drift would otherwise generate a row class named `Medication`, colliding with the domain entity — use `@DataClassName('MedicationRow')` / `@DataClassName('TimeSlotRow')`.
- **Time (§4.1.1)**: store UTC, inject `Clock` (no `DateTime.now()`); `startDate` stored as a UTC calendar date to avoid DST/tz day-shift.
- **Type safety (§3.1)**: freezed entities; typed value-object IDs; no `!`, no `dynamic`, no unchecked `as`; exhaustive `switch` over `MedicationForm`/`MedicationType` (no `default:`).
- **Dependencies (§2.3)**: add via `flutter pub add`. `drift`/`drift_flutter`/`sqlite3_flutter_libs`/`drift_dev` are pre-blessed (constitution §1/§5.3/§7.3). `uuid` is new — justified as a DB-agnostic, collision-free source for typed string IDs (keeps drift autoincrement ints out of the domain).
- **Codegen (§6.6)**: run `build_runner` after any freezed/riverpod/drift change; generated files are committed. Beware: a class-form `@riverpod` notifier strips the `Notifier` suffix and defaults to autoDispose — if a notifier is introduced, pin its symbol with `name:` and use `@Riverpod(keepAlive: true)` where a resource is owned (MEMORY F015/T003, F015/T003 lifetime note; `late` not `late final` for build()-created controllers).
- **l10n**: new strings added to all three ARBs; `flutter gen-l10n` runs as part of the build.

## 8. Open Questions

- **OQ-1**: `PackStock` partial input — when only some of remaining/total/warn are filled. Proposed rule: persist `PackStock` only when `remaining` and `total` both parse to non-negative ints; `warnAt` defaults to `0` when blank; otherwise `stock = null`. Confirm during `/plan`.
- **OQ-2**: `MedicationRepository.add` returns the saved `Medication` (echo) though the modal discards it. Kept for testability and the future list feature; confirm the signature stays `Either<Failure, Medication>` rather than `Either<Failure, Unit>`.
- **OQ-3**: persisting the `frequency` column now (always `daily`) vs deferring it — included for forward-compatibility with the future scheduling spec; flag if it should be dropped until then.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Drift row class name collides with domain `Medication` | High | Med | `@DataClassName('MedicationRow')`/`TimeSlotRow` (AC-4/5); caught at codegen |
| Existing modal tests assert Save is a no-op → break | High | Low | AC-24 updates them; expected and in-scope |
| Modal stores presentation-only values (label-builder closures, string keys) — mapping to typed enums needs typed values added | Med | Med | Form `key`s already match enum names; add a typed `DoseUnit` to `_MedFormOption` (dropdown off-stage test idiom per MEMORY 2026-06-08) |
| `pragma foreign_keys = ON` omitted → cascade delete silently disabled | Med | Med | Enforce in `beforeOpen` (AC-2); not yet exercised but correct from v1 |
| Combined drift + freezed + riverpod codegen conflicts | Med | Low | `build_runner build --delete-conflicting-outputs` (AC-25) |
| Hot-reload stale state after adding fields to top-level/`_MedFormOption` instances | Med | Low | Hot **restart** after field/initializer changes (MEMORY 2026-06-14) |
| New `uuid` dependency rejected by package policy | Low | Low | Justified in §7; alternative is a hand-rolled v4 generator if disallowed |
