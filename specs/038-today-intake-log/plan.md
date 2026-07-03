# Plan: Today Screen — Daily Intake Checklist

**Date**: 2026-07-01
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Fill the placeholder Today tab with a reactive, time-sorted checklist of today's due doses, derived by a pure schedule-expansion function that reuses the existing DST-safe course/cyclic-pause day math. Users mark each dose taken or skipped (persisted to a new `intakes` drift table via the project's first schema migration, 1→2) and undo within a 5-minute grace window. The implementation mirrors the meds vertical slice end-to-end: pure domain (entity + value objects + expansion + use cases), a data source/mapper/repo-impl, `@riverpod` composition, a pure view model, and a `ConsumerStatefulWidget` screen with a grace-refresh ticker.

## Technical Context

**Architecture**: Clean Architecture — new code spans `domain/` (pure), `data/`, `core/database/`, and `presentation/` of the `meds` feature, plus the `home` feature's screen.
**Error Handling**: `Either<Failure, T>` at repository/use-case boundaries; data source throws, repo catches → `Left(CacheFailure)`; the reactive stream provider maps `Left→throw` so Riverpod surfaces `AsyncValue.error`.
**State Management**: Riverpod (`@riverpod`), reactive drift streams; ephemeral UI (ticker) in the screen; `clock.now()` injected for all time math.

## Constitution Compliance

- **§2.1 layer boundaries** — domain files (`Intake`, `IntakeId`, `IntakeStatus`, `DueDose`, `expandDueDoses`, use cases, repo contract) import no Flutter/drift/uuid. Drift lives in `core/database` + the data layer. The presentation composition seam (`*_providers.dart`) is the only presentation file importing `data/`. **Compliant.**
- **§3.2 error handling** — every fallible op returns `Either<Failure, T>`; no empty catches. **Compliant.**
- **§4.2.1 / §6.5 schema safety** — add-only migration with bumped `schemaVersion` + `onUpgrade`; no existing column/enum altered; migration test proves v1 data survives. **Compliant.**
- **MEMORY: UTC storage + `Clock` injection** — timestamps stored UTC, displayed local; `clock.now()` everywhere. **Compliant.**
- **§3.4 testing / §"document new code"** — unit + widget tests per AC; dartdoc on new public APIs. **Compliant.**
- **§5.1/§5.2 domain contract** — implements the pre-authored `Intake`/`IntakeStatus`/state-machine subset (taken/skipped + undo); `pending`/`missed` derived, documented as a deliberate MVP interpretation. **Compliant (noted).**

## Implementation Approach

### Layer Map

| Layer | What | Files (new unless noted) |
|-------|------|--------------------------|
| Domain — entities | `Intake`, `IntakeStatus` | `lib/features/meds/domain/entities/intake.dart` (+ `.freezed.dart`), `intake_status.dart` |
| Domain — value objects | `IntakeId`, `DueDose`, shared local-date helper | `domain/value_objects/intake_id.dart` (+`.freezed.dart`), `due_dose.dart`, `local_calendar_date.dart` |
| Domain — expansion | `expandDueDoses(meds, now)` | `domain/value_objects/due_dose.dart` (or `usecases/`); pure, reuses `CourseProgress`/`resolveMedicationActivity` |
| Domain — policy | `kIntakeUndoGracePeriod` | `domain/value_objects/intake_grace.dart` |
| Domain — repo contract | `IntakeRepository` (watchAll, markTaken, skip, undo) | `domain/repositories/intake_repository.dart` |
| Domain — use cases | `MarkIntakeTaken`, `SkipIntake`, `UndoIntake` | `domain/usecases/mark_intake_taken.dart`, `skip_intake.dart`, `undo_intake.dart` |
| Core — DB table | `Intakes` table + `IntakeRow` | `lib/core/database/tables/intakes_table.dart` |
| Core — DB schema | register table, `schemaVersion` 1→2, `onUpgrade` | `lib/core/database/database.dart` **(modify)** + regenerated `database.g.dart` |
| Data | data source (watch + upsert + delete), mapper, repo impl | `data/datasources/intake_local_data_source.dart`, `data/mappers/intake_mapper.dart`, `data/repositories/intake_repository_impl.dart` |
| Presentation — providers | intake DS/repo/use-case providers + reactive `intakesList` stream | `presentation/providers/intake_providers.dart` (new) |
| Presentation — view model | `buildTodayView(meds, intakes, now)` → `TodayView`/`TodayDose` | `presentation/view_models/today_view_model.dart` |
| Presentation — UI | Today screen body + dose row + empty state | `lib/features/home/presentation/screens/home_screen.dart` **(modify)**, `home/presentation/widgets/today_dose_tile.dart`, `today_empty_state.dart` |
| l10n | Today keys in 3 ARBs (+ regenerated) | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` **(modify)** |
| Tests | unit + widget + migration | `test/**` mirrors; `integration_test/` optional |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| First migration | Add-only `onUpgrade` `m.createTable(intakes)`, keep `onCreate: createAll` + FK `beforeOpen` | Can't touch existing tables; matches drift docs; lowest risk | `stepByStep`/FK-toggling (overkill for add-only) |
| Migration test | drift `SchemaVerifier` (dump v1 snapshot **first**) + a data-survival unit test | Validates real schema; precedent for a health-data app | Hand-written v1 DDL (brittle, duplicates schema) |
| Today composition | Two streams (`medicationsListProvider` + new `intakesListProvider`) merged in pure `buildTodayView` at the widget | Reuses meds stream; testable pure VM; mirrors `MedsScreen` | Single cross-table drift join (couples, duplicates grouping) |
| Occurrence key | UNIQUE `(medicationId, slotId, scheduledAt)`; upsert on target; VM matches by **local date** via `_localDate` | Idempotent; §5.1-aligned; avoids instant-equality trap | Composite string PK (`medId#slotId#date`) |
| `intakes.medicationId` | FK → `Medications`, `onDelete: cascade`; `slotId` plain text (no FK) | No orphans on med delete; slot reconciliation never wipes intake history | No-FK retain (orphans); slot FK cascade (loses history on edit) |
| Grace refresh | Screen `Timer.periodic (~30s)` rebuild + undo use case re-checks window with injected clock | Reactive streams don't tick; defense-in-depth; tests stay deterministic | Ticker stream provider (heavier); no refresh (affordance lingers) |
| Intakes query scope | `watchAll()` all intakes; VM filters to today's expanded doses | Trivial query; day-rollover "just works" on ticker rebuild; volume is small (personal app) | Date-scoped query (stale across midnight while open) — noted as future optimization |
| Grace enforcement | In `UndoIntake` use case (domain owns the rule); UI mirrors by gating the affordance | Business rule belongs in domain; UI is defense-in-depth | UI-only gate (rule leaks into presentation) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `domain/entities/intake.dart`, `intake_status.dart` | Create | freezed `Intake`; `IntakeStatus` enum (storage-by-name). |
| `domain/value_objects/intake_id.dart` | Create | typed id (mirror `MedicationId`). |
| `domain/value_objects/due_dose.dart` | Create | `DueDose` + `expandDueDoses(meds, now)` pure expansion. |
| `domain/value_objects/local_calendar_date.dart` | Create | shared `_localDate` idiom for the new expansion (existing dupes left untouched — minimal change). |
| `domain/value_objects/intake_grace.dart` | Create | `kIntakeUndoGracePeriod = 5 min`. |
| `domain/repositories/intake_repository.dart` | Create | contract: `watchAll()`, `markTaken`, `skip`, `undo` — all `Either`. |
| `domain/usecases/mark_intake_taken.dart`, `skip_intake.dart`, `undo_intake.dart` | Create | three single-purpose use cases (undo enforces grace). |
| `core/database/tables/intakes_table.dart` | Create | `Intakes` table + unique index + health-data contract docs. |
| `core/database/database.dart` | Modify | register `Intakes`; `schemaVersion => 2`; add `onUpgrade`. |
| `core/database/database.g.dart` | Modify (generated) | build_runner regen. |
| `data/datasources/intake_local_data_source.dart` | Create | `watchAllIntakes()`, upsert (conflict target), delete-by-key. |
| `data/mappers/intake_mapper.dart` | Create | `Intake` ⇆ `IntakeRow`/companion; UTC round-trip; `Value.absent` idiom. |
| `data/repositories/intake_repository_impl.dart` | Create | maps throws → `Left(CacheFailure)`; `Right` on success. |
| `presentation/providers/intake_providers.dart` | Create | DS/repo/use-case providers + `intakesList` stream (`Left→throw`). |
| `presentation/view_models/today_view_model.dart` | Create | pure `buildTodayView(meds, intakes, now)` → time-sorted `TodayDose`s + empty flag. |
| `features/home/presentation/screens/home_screen.dart` | Modify | → `ConsumerStatefulWidget`; localized "Today" title + date header; reactive body via `.when`; grace ticker; wire mark/skip/undo. |
| `features/home/presentation/widgets/today_dose_tile.dart`, `today_empty_state.dart` | Create | dose row (icon/name/time/dose + take/skip/undo affordances) and empty state. |
| `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Modify | Today title, date/chrome, taken/skip/undo, status labels, empty-state title+body. |
| `lib/l10n/app_localizations*.dart` | Modify (generated) | l10n regen. |
| `test/**` (+ optional `integration_test/`) | Create | expansion edges, VM status/grace, mapper UTC, migration (SchemaVerifier + data survival), widget mark/skip/undo/empty/lock. |

**Additions discovered during planning (not explicitly in the spec's Affected Areas):** `local_calendar_date.dart` (shared day-math helper to avoid a third copy of `_localDate`), `intake_grace.dart` (policy constant — the spec listed a "grace constant" area generically), and `today_empty_state.dart`/`today_dose_tile.dart` widget split. All are internal decompositions of spec-listed areas.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/meds.md` | Update | New "Today / intake logging" section: expansion rules, lazy-intake model, mark/skip/undo + grace, new `intakes` table. |
| `docs/features/home.md` | Update | Today tab is no longer a placeholder — describe the checklist. |
| `docs/architecture.md` | Update | Local-database section: note `schemaVersion=2`, the `intakes` table, and the first migration + `SchemaVerifier` test convention. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| First migration mishandled / v1 data loss | Low (add-only) | High | `createTable`-only `onUpgrade`; `SchemaVerifier` + data-survival test (AC-7); dump v1 snapshot before editing `database.dart`. |
| Off-by-one in "due today" (DST/future-start/pause-gap) | Medium | Medium | Reuse `CourseProgress.resolve` + `resolveMedicationActivity` + `_localDate`; clock-injected edge-case unit tests (AC-1..4). |
| Instant-equality mismatch when matching doses↔intakes | Medium | Medium | VM matches by local calendar date (`_localDate`), not raw instant; unique index keys the row. |
| Grace-window UI drift | Medium | Low | Ticker rebuild + injected-clock math + undo re-check (AC-13). |
| Upsert-on-non-PK-target misuse (duplicate rows) | Low | Medium | `insert(..., onConflict: DoUpdate(target: [medId, slotId, scheduledAt]))`; unique index as backstop; idempotency test (AC-6). |
| Scope creep (adherence/notifications/stock/missed) | Medium | Medium | Spec §6 Out of Scope is exhaustive; ACs bound to checklist + lazy log. |

## Dependencies

None new at runtime. Dev-time: drift's schema tooling (`dart run drift_dev schema dump …` / `… schema generate …`) for `SchemaVerifier` tests — part of the existing `drift_dev`/`build_runner` toolchain, no `pubspec.yaml` change expected (verify `drift_dev` is a dev_dependency during breakdown).

## Supporting Documents

- [Research](research.md) — migration idiom, composition, uniqueness, grace decisions
- [Data Model](data-model.md) — `Intake`/`IntakeStatus`/`IntakeId`/`DueDose`, `intakes` table, migration
- Contracts: N/A — no REST/GraphQL; fully local.
