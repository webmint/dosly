# Research: Medication Entity — Shape & Local Storage

**Date**: 2026-06-16
**Topic**: Define the core `Medication` entity produced by the add-medication form; decide how/where it is stored. Constraints: best Flutter practices; MVP stores data on-device.
**Verdict**: **Feasible** — the storage mechanism is *already decided* (drift, per constitution). The real open work is **reconciling the entity shape with what the form now actually collects**, which has outgrown the constitution's §5.1 model.

## Summary

The constitution already mandates the answer to "where": **drift** (typed SQLite) is the system of record for all medication/schedule/intake data, and SharedPreferences is forbidden for it (§4.2.1). External research confirms drift is the correct 2026 best-practice choice. So this isn't really an open question — but **drift isn't in `pubspec.yaml` yet** (only `shared_preferences`, `fpdart`, `freezed`, `riverpod` are). The genuinely open decision is the **entity shape**: the add-medication modal collects pack-stock, quantity-per-intake, and *cyclic* courses (duration + **pause** + start) that the constitution's §5.1 `Medication` does not model. The recommendation is a **freezed `Medication` aggregate (domain) ↔ a small normalized drift schema (`Medications` + `TimeSlots`, `Intakes` later)** following the exact Clean-Architecture pattern the `settings` feature already uses — plus a small §5.1 constitution amendment to absorb stock + cyclic courses.

## Codebase Findings

### What the form actually produces today (the entity's real fields)
From `lib/features/meds/presentation/widgets/add_medication_modal.dart` (all currently visual-only local state, Save is a no-op):

| Group | Field | Type collected | In constitution §5.1? |
|---|---|---|---|
| A | `name` | `String` | ✅ |
| A | `form` | enum: tablet, capsule, syrup, drops, injection, inhaler, cream, sachet | ✅ `MedicationForm` |
| A | dose amount + unit (syrup/drops/injection) | `double` + {ml, mg, drops, units} | ✅ `Dosage` |
| A | quantity-per-intake + unit (tablet/capsule) | `double` (step .5/1) + {tab, cap} | ⚠️ overlaps `Dosage` |
| A | pack stock (tablet/capsule) | `remaining`, `total`, `warnAt` (int) | ❌ **not modeled** |
| B | intake times | `List<TimeOfDay>` (sorted, deduped) | ✅ `Schedule.TimeSlot` |
| C | intake type | continuous \| course | ✅ `MedicationType` (Permanent\|Course) |
| C | course params | `durationDays`, **`pauseDays`**, `startDate` | ⚠️ §5.1 `Course` only has `{startDate, endDate}` — no pause/cycling |

Three real divergences: **(1)** pack-stock isn't in the domain model at all; **(2)** "dose" (liquids) and "quantity-per-intake" (pills) are two UIs for the *same* concept (amount-per-intake) and should unify into one `Dosage`; **(3)** the form models *cyclic* courses (on/off via `pauseDays`) — richer than §5.1's plain start/end. The form does **not** yet collect a weekday/every-N-days frequency, so `Schedule.frequency` is implicitly **daily** for MVP.

### Pattern already in the repo to copy (`settings` feature)
`features/settings/` is a complete, idiomatic Clean-Architecture vertical slice to mirror:
- **Domain**: `app_settings.dart` — `@freezed abstract class` entity, pure Dart, no Flutter imports (documents the "domain stays Flutter-free; map at the presentation seam" rule).
- **Repository contract** returns `Either<Failure, T>`; **impl** (`settings_repository_impl.dart`) catches every datasource exception → `Left(Failure.unknown(e, st))`. Exceptions never escape `data/`.
- **Data source** (`settings_local_data_source.dart`) is the only thing that touches the storage SDK.
- Wired with `@riverpod` codegen providers via the sanctioned composition seam.

The `meds` feature currently has **only presentation** — no `domain/` or `data/`. This research defines that missing stack.

### Gaps
- `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `drift_dev` are **not in `pubspec.yaml`** (constitution §7.3 lists them; never added).
- No `lib/core/database/` exists yet (constitution §7.1 items 4–5).
- Domain cannot use `TimeOfDay` (it's `package:flutter`) → intake times must be stored as a Flutter-free `minuteOfDay` int (or a `LocalTime` value object), mapped to `TimeOfDay` at the presentation seam.

## Constitution Constraints

| Rule | Impact |
|---|---|
| §4.2.1 — **never** SharedPreferences for med/schedule/intake data; it goes in **drift** | Storage choice is fixed = drift. |
| §2.1 — domain is pure Dart; no `package:flutter/*` or `package:drift/*` | Entity uses value objects, not `TimeOfDay`; drift tables/DTOs live in `data/`, mapped via `mappers/`. |
| §3.1 — typed value-object IDs; no `dynamic`/`!`; freezed for entities | `MedicationId`, `Dosage`, etc. as value objects; `@freezed` everywhere. |
| §3.2 — `Either<Failure, T>` at every repo/use-case boundary | `AddMedication` use case returns `Future<Either<Failure, Medication>>`. |
| §4.1.1 — timestamps in **UTC**; inject `Clock` | `startDate`/`createdAt` stored UTC; `MedicationId.generate()` + `createdAt` use `clock.now()`. |
| §6.6 / §4.2.1 — bump `schemaVersion` + write a migration for any schema change | First schema = v1; design tables to evolve (frequency, intakes) without destructive changes. |
| §5.1 currently lacks stock + cyclic courses | **Needs a small amendment** before `/specify` so spec and constitution agree. |

## Approaches

The storage *engine* is settled (drift). The real choice is the **persistence layout** for the aggregate.

### Option A — Single table + serialized children (document-style)
- **Description**: One `Medications` row; schedule times + stock packed into JSON/text columns.
- **Pros**: Fewest tables; trivial to write.
- **Cons**: Fights SQLite's strengths; cannot relationally query intake records for adherence (the very next feature); JSON columns lose type safety and migration tooling. Anti-pattern for drift.
- **Complexity**: Low now, High later.

### Option B — Normalized relational schema *(recommended)*
- **Description**: `Medications` aggregate root (stock + type flattened as nullable columns, 1:1) + `TimeSlots` child table (1:many) + `Intakes` table later for adherence. Domain exposes one `Medication` aggregate assembled by a mapper.
- **Pros**: Plays to drift/SQLite; relational queries for adherence; type-safe migrations; matches §5.1's entity vocabulary; KISS (don't over-normalize 1:1 stock into its own table).
- **Cons**: 2 tables + mappers up front.
- **Complexity**: Medium.

**Recommended: Option B** — the only layout that supports the adherence/intake features already specified in §5.2 without a later rewrite.

### Proposed entity (domain, pure Dart + freezed)
```dart
enum MedicationForm { tablet, capsule, syrup, drops, injection, inhaler, cream, sachet }
enum DoseUnit { tablet, capsule, ml, mg, drops, units, puff, application, sachet }

@freezed
sealed class Dosage with _$Dosage {                 // unifies "dose" + "quantity-per-intake"
  const factory Dosage({required double amount, required DoseUnit unit}) = _Dosage;
}

@freezed
sealed class PackStock with _$PackStock {            // NEW vs §5.1
  const factory PackStock({required int remaining, required int total, required int warnAt}) = _PackStock;
}

@freezed
sealed class MedicationType with _$MedicationType {
  const factory MedicationType.continuous({required DateTime startDate}) = ContinuousType;
  const factory MedicationType.course({              // pauseDays = cyclic on/off (0 = single bounded course)
    required DateTime startDate,
    required int durationDays,
    required int pauseDays,
  }) = CourseType;
}

@freezed
sealed class TimeSlot with _$TimeSlot {
  const factory TimeSlot({
    required TimeSlotId id,
    required int minuteOfDay,                        // 0..1439 local — no Flutter TimeOfDay in domain
    Dosage? doseOverride,
  }) = _TimeSlot;
}

@freezed
sealed class Medication with _$Medication {
  const factory Medication({
    required MedicationId id,
    required String name,
    required MedicationForm form,
    required MedicationType type,
    required List<TimeSlot> slots,                   // Schedule.frequency defaults to daily for MVP
    Dosage? dosePerIntake,                           // null for forms that track neither (inhaler/cream/sachet)
    PackStock? stock,                                // null unless the form tracks pack stock
    String? notes,
    required DateTime createdAt,                     // UTC, via clock.now()
  }) = _Medication;
}
```

### Proposed drift schema (data layer)
```dart
class Medications extends Table {
  TextColumn get id => text()();                     // MedicationId (uuid v4)
  TextColumn get name => text()();
  TextColumn get form => textEnum<MedicationForm>()();
  RealColumn get doseAmount => real().nullable()();  // dosePerIntake
  TextColumn get doseUnit => textEnum<DoseUnit>().nullable()();
  TextColumn get typeKind => textEnum<MedicationTypeKind>()();   // continuous | course
  DateTimeColumn get startDate => dateTime()();      // UTC
  IntColumn get durationDays => integer().nullable()();
  IntColumn get pauseDays => integer().nullable()();
  IntColumn get stockRemaining => integer().nullable()();
  IntColumn get stockTotal => integer().nullable()();
  IntColumn get stockWarnAt => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();      // UTC
  @override Set<Column> get primaryKey => {id};
}

class TimeSlots extends Table {
  TextColumn get id => text()();
  TextColumn get medicationId => text().references(Medications, #id, onDelete: KeyAction.cascade)();
  IntColumn get minuteOfDay => integer()();          // 0..1439 local
  RealColumn get doseAmount => real().nullable()();
  TextColumn get doseUnit => textEnum<DoseUnit>().nullable()();
  @override Set<Column> get primaryKey => {id};
}
// Intakes table (status/scheduledAt/confirmedAt) — same data model, but OUT OF SCOPE for the add form.
```
Modern setup uses `drift_flutter`'s `driftDatabase(name: ...)` helper in `lib/core/database/database.dart` with `schemaVersion = 1` and a `MigrationStrategy` (Context7 confirms this is the current recommended pattern).

## External Research

| Library | Status | Fit | Notes |
|---|---|---|---|
| **drift** | Active, High reputation | ✅ Recommended | 2026 default for offline-first relational Flutter; type-safe SQL, reactive streams, first-class migrations. Already the constitution's choice. |
| Isar | **Abandoned** (author left; Rust core) | ❌ | Matches MEMORY note; no web support. |
| sqflite | Active | ❌ for this app | Untyped raw SQL; hand-roll what drift generates. |
| Hive / SharedPreferences | Active | ❌ for PHI | Key-value only; constitution forbids for med data; no relational queries for adherence. |

Consensus: drift is "the default choice and the right one for most projects" when you need structured, related, queryable offline data — exactly this app.

### References
- Flutter Local Databases in Depth (drift, Isar, SQLite) — https://medium.com/@alaxhenry0121/flutter-local-databases-in-depth-drift-isar-sqlite-migrations-relationships-reactive-90165af86b85
- Flutter databases overview (Greenrobot, 2025) — https://greenrobot.org/database/flutter-databases-overview/
- Best Local Database for Flutter Apps (Dinko Marinac) — https://dinkomarinac.dev/best-local-database-for-flutter-apps-a-complete-guide
- Drift setup docs — https://drift.simonbinder.eu/setup

## Complexity Assessment

| Dimension | Rating | Notes |
|---|---|---|
| Codebase changes | Medium | New `lib/core/database/` + full `meds` domain/data stack + wire Save. Mirrors existing `settings` slice. |
| New dependencies | Low | `flutter pub add drift drift_flutter sqlite3_flutter_libs path path_provider` + `--dev drift_dev`; all pre-blessed in §7.3. |
| Risk | Low–Medium | Main risk is locking the schema/entity shape before stock + cyclic-course semantics are agreed. Do the §5.1 amendment first. |

## Recommendation

**Proceed — amend the constitution first.**

1. **Amend constitution §5.1/§5.2** to: (a) unify dose/quantity into one `Dosage`; (b) add `PackStock`; (c) change `MedicationType.Course` to `{startDate, durationDays, pauseDays}` (derive `endDate`) and rename `Permanent` → `Continuous` to match the shipped UI. *(Applied 2026-06-16.)*
2. Then run **`/specify`** for the persistence feature.

Suggested next command:
```
/specify "Persist the Medication entity from the add-medication form to a local drift database. Add drift + drift_flutter, create lib/core/database with a versioned schema (Medications + TimeSlots tables), a meds domain layer (freezed Medication aggregate with MedicationForm, Dosage, PackStock, MedicationType continuous|course{durationDays,pauseDays}, TimeSlot), an Either-returning MedicationRepository + AddMedication use case, and wire the modal's Save button through a @riverpod provider. Mirror the settings feature's Clean-Architecture pattern."
```
