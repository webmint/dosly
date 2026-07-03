# Research: Today Screen — Daily Intake Checklist

**Date**: 2026-07-01
**Signals detected**:
- **Greenfield pattern** — the project's **first drift schema migration** (`onUpgrade`, schemaVersion 1→2). No `onUpgrade` exists today.
- **Architectural decision (multiple valid approaches)** — how to compose the reactive Today view from two sources (medications + intakes).
- **Architectural decision** — the `intakes` table shape and how a dose "occurrence" is uniquely keyed for idempotent mark/undo.
- **Architectural decision** — how the 5-minute grace window refreshes in a reactive UI.

All underlying tech (`drift`, `riverpod`, `freezed`, `fpdart`, `clock`, `uuid`) is already in the stack — no new dependencies. `flutter_local_notifications`/`timezone`/`permission_handler` are explicitly out of scope (spec §6).

## Questions Investigated

1. **What is the current drift migration idiom (health-data safe)?** → Confirmed against live drift docs (`drift.simonbinder.eu/migrations`): bump `schemaVersion`, add `onUpgrade: (Migrator m, from, to) async { if (from < 2) await m.createTable(intakes); }`, keep `onCreate: (m) => m.createAll()` for fresh installs, keep the `beforeOpen` FK pragma. Because this migration only **adds a table** (never alters `medications`/`time_slots`), no FK-toggling dance is needed; the referenced `medications` table already exists. **Decision**: add-only `createTable` migration.

2. **How to test the first migration rigorously?** → drift ships `SchemaVerifier` (`package:drift_dev/api/migrations_native.dart`) driven by dumped schema snapshots: `verifier.startAt(1)` boots a v1 DB, `verifier.migrateAndValidate(db, 2)` runs the upgrade and validates the resulting schema. Requires dumping the **v1** snapshot **before** editing `database.dart`. **Decision**: adopt `SchemaVerifier` (precedent-setting for a health-data app), plus a plain unit test that inserts a v1 medication row and asserts it survives the upgrade (AC-7) and that a fresh `onCreate` yields all three tables (AC-5).

3. **Compose the Today view from meds + intakes — one joined query, or two streams merged in the presentation layer?** → The meds slice already exposes a reactive `medicationsListProvider` and computes its view model **in the widget** (`buildMedsListView(now: clock.now())`). **Decision**: mirror that — add a separate reactive intakes stream provider and combine meds + intakes in a **pure `buildTodayView(meds, intakes, now)`** called from the screen. Keeps the existing meds stream untouched and the view model unit-testable; avoids a bespoke cross-table join.

4. **How is a dose occurrence uniquely identified for idempotent mark/undo?** → A dose is `(medicationId, slotId, scheduled calendar date)`. **Decision**: store `scheduledAt` (UTC instant of the local scheduled time), enforce a **UNIQUE index on `(medicationId, slotId, scheduledAt)`**, and upsert on that target (update `status` + `confirmedAt`); undo deletes by the same key. The view model matches expanded doses to stored intakes by **local calendar date** (via the `_localDate` idiom), never by raw instant equality (the codebase's documented instant-equality trap).

5. **How does the 5-minute grace window expire in a reactive UI?** → The stream providers only re-emit on data change, not on clock ticks. **Decision**: the Today screen (a `ConsumerStatefulWidget`, like `MedsScreen`) runs a `Timer.periodic` (~30 s) that rebuilds, so `buildTodayView` re-evaluates grace against `clock.now()`; the undo use case **also** re-checks the window at call time and no-ops if expired (defense in depth). Grace math uses the injected `clock`, so tests stay deterministic; the ticker need not fire in tests.

## Alternatives Compared

### First drift migration
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Add-only `onUpgrade` with `m.createTable(intakes)` | Minimal; can't touch existing tables; matches drift docs | none material | **Chosen** |
| `stepByStep` / `runMigrationSteps` with FK toggling | Robust for column alterations | Overkill for an add-only table; extra ceremony | Rejected |

### Migration testing
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| drift `SchemaVerifier` + dumped v1 snapshot | Validates real schema; no hand-written DDL; sets precedent | Adds a `drift_dev schema dump/generate` dev step + generated helper; must dump v1 first | **Chosen** |
| Hand-written v1 DDL in an in-memory test | No tooling | Brittle; duplicates schema; must set `user_version` manually | Rejected |

### Today view composition
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Two streams (`medicationsListProvider` + new intakes stream) merged in pure `buildTodayView` | Reuses existing meds stream; testable pure VM; mirrors meds pattern | Two subscriptions | **Chosen** |
| Single cross-table drift query (meds ⨝ slots ⨝ today's intakes) | One stream | Couples meds+intakes; duplicates join/grouping; harder to test | Rejected |

### Occurrence uniqueness
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| UNIQUE `(medicationId, slotId, scheduledAt)` + upsert on target | Idempotent; one row per occurrence; §5.1-aligned (`scheduledAt`) | Needs conflict-target upsert (not PK upsert) | **Chosen** |
| Deterministic composite PK string (`medId#slotId#date`) | Simple upsert on PK | Diverges from typed `IntakeId`/§5.1; encodes keys in a string | Rejected |

### `intakes.medicationId` on delete
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| FK → `Medications` `onDelete: cascade` | No orphan rows; consistent with `time_slots` | Loses would-be adherence history on hard delete | **Chosen** (deleted meds aren't in Today; adherence-retention revisited when History/soft-archive land) |
| No FK / retain on delete | Preserves history | Orphan intakes referencing a gone med; no integrity | Rejected for this slice |

## References
- drift migrations — https://drift.simonbinder.eu/migrations (MigrationStrategy, `onUpgrade`, `Migrator.createTable`)
- drift migration testing — https://drift.simonbinder.eu/migrations/tests (`SchemaVerifier`, `startAt`, `migrateAndValidate`)
- Existing patterns: `lib/core/database/database.dart` (schemaVersion/migration), `lib/features/meds/data/datasources/medication_local_data_source.dart` (watched query + upsert), `lib/features/meds/data/mappers/medication_mapper.dart` (row⇆domain, `Value.absent`), `lib/features/meds/presentation/providers/medication_providers.dart` (composition seam, `Left→throw` stream), `lib/features/meds/presentation/view_models/meds_list_view_model.dart` (pure clock-injected VM), `lib/features/meds/domain/value_objects/course_progress.dart` + `medication_activity.dart` (DST-safe `_localDate` day math).
