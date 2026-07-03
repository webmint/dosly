## Feature Summary: 038 — Today Screen & Daily Intake Checklist

### What was built
The placeholder "Today" tab is now the app's daily driver: a reactive, time-sorted checklist of every dose due today, derived from each active medication's schedule. Users mark each dose **taken** or **skipped** and can **undo** within a 5-minute grace window. Marking persists to a new `intakes` table via the project's **first drift schema migration** (v1→v2). This adds the *intake* pillar of the product vision (medication → schedule → **intake** → adherence); adherence/History, reminders, and auto-miss remain future work.

### Changes
- **001** Capture v1 schema snapshot — dumped `drift_schemas/drift_schema_v1.json` (before the bump) to back the migration test.
- **002** Intake domain types — `Intake`, `IntakeStatus`, `IntakeId`, `kIntakeUndoGracePeriod` (pure Dart).
- **003** Schedule expansion — pure `expandDueDoses` + `DueDose` + shared `localCalendarDate`, reusing the DST-safe course/pause day-math.
- **004** `intakes` drift table — occurrence-unique `(medicationId, slotId, scheduledAt)`; `medicationId` FK cascade, `slotId` plain text.
- **005** Schema migration v1→v2 — register `Intakes`, `schemaVersion => 2`, add-only `onUpgrade`.
- **006** Migration tests — `SchemaVerifier`-style validation + v1-data-survival + fresh-install (proves no data loss).
- **007** `IntakeRepository` contract — reactive `watchAll` + mark/skip/undo, all `Either`.
- **008** Intake data source — reactive watch + idempotent upsert on the occurrence key + delete-by-id.
- **009** Intake mapper + repository impl — row⇆domain (UTC), errors → `Left(CacheFailure)`.
- **010** Use cases — `MarkIntakeTaken`, `SkipIntake`, `UndoIntake` (undo enforces the grace window).
- **011** Localization — 10 `today*` keys in en/de/uk (+ `@`-descriptions).
- **012** Riverpod composition seam — intake providers + `intakesListProvider` (Left→throw).
- **013** Today view model — pure `buildTodayView` matching doses↔intakes by local date + `undoable` derivation.
- **014** Today dose tile — form icon, 24h time, dose, take/skip/undo affordances (Undo gated on grace).
- **015** Today screen + routing — reactive `TodayScreen` (grace-refresh timer); routed as branch 0; `HomeScreen` retired.
- **016** Integration gate — full suite green + APK build + on-device add→Today→Take→Undo flow.
- **/fix** (post-verify) — closed 6 review warnings: +22 tests and a behavior-preserving `buildTodayView` perf refactor.

### Files changed
- `lib/features/meds/domain/` — ~10 files added (entities, value objects, repo contract, 3 use cases)
- `lib/features/meds/data/` — 3 files added (data source, mapper, repo impl)
- `lib/features/meds/presentation/` — 5 files added (providers, view model, screen, tile, empty state)
- `lib/core/database/` — `intakes_table.dart` added; `database.dart` migrated to schemaVersion 2 (+ generated)
- `lib/core/routing/app_router.dart` — branch 0 (`/`) → `TodayScreen`
- `lib/features/home/` — **deleted** (`HomeScreen` + its test; feature dir removed)
- `lib/l10n/` — 3 ARBs + regenerated `AppLocalizations`
- `test/` + `integration_test/` — 18 test files added/updated (incl. migration, expansion, view-model, data source/mapper, repo impl, use cases, tile, screen, cascade, DE/UK, and an on-device flow)
- `drift_schemas/` + `test/core/database/schema/` — v1 snapshot + generated migration-test helper
- `docs/` — 7 files reconciled (meds, home, medication-persistence, architecture, overview, settings, i18n)
- **Total: 87 files changed, +11,025 / −699** (incl. generated + docs + specs)

### Key decisions
- **Lazy intake model**: persist only `taken`/`skipped`; `pending` is the derived "no row" state, `missed` reserved. Keyed by the occurrence unique index; marking is an idempotent upsert.
- **First drift migration = add-only**: `onUpgrade` only `createTable(intakes)` (no ALTER/DROP) — lowest-risk shape for health data; proven with a v1-data-survival test.
- **Today view composed from two reactive streams** (medications + intakes) merged in a pure `buildTodayView`, rather than a bespoke cross-table join — reuses the meds stream and keeps the VM unit-testable.
- **`intakes.slotId` has no FK** (plain text) so slot reconciliation on edit never cascade-deletes intake history; `medicationId` FK cascades.
- **Grace refresh via a non-periodic one-shot `Timer`** (never `Timer.periodic`, which would hang `pumpAndSettle`).

### Deviations from plan
- **Task 014/015 — Today UI placement (constitution §2.1)**: the plan sited the Today screen in `features/home/` (editing `home_screen.dart`), but a layer-boundary code review flagged that a `home` widget importing `meds/presentation` (providers/view-model/widgets) violates §2.1. Resolved by building the entire Today UI in `features/meds/presentation/` and routing branch 0 to it via `core/routing` (the sanctioned composition root); `HomeScreen` was retired. Behavior unchanged; the retirement rippled into `app_router_test` (hermetic `_HomeStub`) and two boot tests (DB overrides).
- **Task 006 — migration test**: only a v1 snapshot was dumped, so `migrateAndValidate(db, 2)` (needs a captured v2 schema) was replaced with drift's `validateDatabaseSchema()` self-check + an explicit data-survival test — same guarantee.

### Acceptance criteria
- [x] AC-1: Continuous med due today; future start → none
- [x] AC-2: Non-cyclic course window (inclusive), completed/before-start → none
- [x] AC-3: Cyclic course due in active window, none on pause-gap
- [x] AC-4: Time-sorted; effective dose (slot override else default); DST-safe
- [x] AC-5: `intakes` table; schemaVersion 2; add-only `onUpgrade`; fresh install all 3 tables; FK pragma
- [x] AC-6: Idempotent mark by occurrence; UTC round-trip
- [x] AC-7: v1 data survives the upgrade
- [x] AC-8: Flat time-sorted checklist (icon/name/24h/dose)
- [x] AC-9: Take/skip reactive; survives rebuild
- [x] AC-10: Early marking; no overdue styling
- [x] AC-11: Empty / loading / error states
- [x] AC-12: Undo deletes the row → pending
- [x] AC-13: Undo gated on the 5-min grace window (boundary, disappears, no-op after)
- [x] AC-14: Strings in en/de/uk (+ `@`-descriptions); consumed via `context.l10n`
- [x] AC-15: `dart analyze` clean; pure domain; `Either` everywhere; dartdoc; green suite (681 tests)
