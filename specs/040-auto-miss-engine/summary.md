## Feature Summary: 040 — Auto-Miss Engine for Intakes

### What was built
Doses you never acted on no longer linger as "pending" forever. When a dose's intake window closes (its scheduled time plus the configurable window, default 120 min), the app now automatically records it as **missed** and shows a distinct, locked "Missed" label on the Today screen. Reconciliation runs on app open and each time the Today screen loads. This is Spec B of the three-spec Today-redesign chain — it makes the `missed` state (reserved since the lazy-intake model in spec 038, consuming the intake-window setting from spec 039) finally real, faithful to the constitution §5.2 state machine (`pending → missed`, distinct from a deliberate `skipped`).

### Changes
- Task 001: Auto-miss derivation — pure `findAutoMissDoses` returns today's due doses that are past-window and have no stored intake (reuses `expandDueDoses`/`localCalendarDate`).
- Task 002: Data-source `insertMissedIntake` — an `INSERT OR IGNORE` write that can never overwrite an existing occurrence row.
- Task 003: `IntakeRepository.markMissed` — contract + impl over the never-clobber write; the 2 hand-written fakes updated.
- Task 004: `ReconcileMissedIntakes` use case — reads the window (settings), snapshots meds/intakes, derives, and writes `missed` rows; idempotent, never-clobber, fail-fast.
- Task 005: Real in-memory-DB test proving `markMissed` preserves an existing `taken`/`skipped` row.
- Task 006: Riverpod providers — the use-case provider plus a keepAlive on-open trigger that logs failures and never throws.
- Task 007: Real `IntakeStatus.missed` tile (display-only, error-toned "Missed"; en/de/uk) — replaced the `SizedBox.shrink` placeholder.
- Task 008: App-open trigger in `AppBootstrap` (fire-and-forget, non-blocking) + neutralized in the integration harness and bootstrap test.
- Task 009: Today-screen `initState` trigger — reconciles once per mount, no rebuild loop.

### Files changed
- `lib/features/meds/domain/` — 2 added (`missed_intake_reconciliation.dart`, `reconcile_missed_intakes.dart`), 2 modified (`intake_repository.dart`, `intake_status.dart` comments)
- `lib/features/meds/data/` — 2 modified (`intake_local_data_source.dart`, `intake_repository_impl.dart`)
- `lib/features/meds/presentation/` — 3 modified (`intake_providers.dart` +generated, `today_screen.dart`, `today_dose_tile.dart`)
- `lib/l10n/` — 3 ARB modified (+4 regenerated) — added `todayStatusMissed`
- `lib/app_bootstrap.dart` — 1 modified (on-open trigger)
- `test/` + `integration_test/support/` — 7 test/harness files (added derivation, use-case, repo-impl, bootstrap, tile tests; extended today-screen tests; harness neutralization)
- **No drift schema change** — `schemaVersion` stays 2 (`missed` already fit the `intakes` table).
- [Total: 41 files changed, ~3093 insertions, ~33 deletions — incl. specs/tasks/review docs]

### Key decisions
- Never-clobber = two layers: derivation excludes any occurrence that already has a row **and** the DB write is `INSERT OR IGNORE` — a `taken`/`skipped` dose can never be downgraded to `missed`.
- Reconcile reads snapshots via `watchAll().first` (not a new `getAll()`) — reuses the existing repo contract, avoiding the interface-fake blast radius (plan OQ-1; accepted a small, non-blocking perf cost).
- Intake window read inside the use case via the settings domain (`SettingsRepository`, default-on-error) — keeps both triggers settings-free and the Today screen clean.
- App-open trigger is a dedicated keepAlive provider (mirrors `devSeedProvider`) so it's independently overridable — the integration harness neutralizes it, avoiding the debug-seeder test-poisoning trap.
- Scope held to today-only, display-only missed tile, no OS background execution (all per the approved spec).

### Deviations from plan
- Task 009: the initial AC-12 widget test drove a real `ReconcileMissedIntakes` whose `watchAll().first` drift-stream reads never resolve under widget-test fake-async → it hung. Rewritten (self-repair) to the file's proven real-DB→drift-`.watch()`→UI pattern (a fake reconcile writes the missed row; the live stream flips the tile); leftover debug scaffolding removed.
- Task 007: the Ukrainian "missed" label initially collided with "skipped" (both "Пропущено"); corrected to "Прострочено" so the two §5.2-distinct states render distinctly.
- Post-`/review`: 6 test-coverage gaps (AC-5/9/10/11/12) closed with additive tests — notably a falsifiable AppBootstrap-trigger-fires assertion via `container.exists(...)`.

### Acceptance criteria
- [x] AC-1–4: pure derivation — past-window ∧ unmatched ∧ due-today; strict boundary; existing-row exclusion; pure/clock-free (DST-safe)
- [x] AC-5,6: one `missed` per occurrence (fresh id, `confirmedAt` null); idempotent
- [x] AC-7: never-clobber (derivation + DB insert-or-ignore, proven via real-DB read-back)
- [x] AC-8: `Either` / `Left(CacheFailure)` on storage error
- [x] AC-9: no schema change (`schemaVersion` == 2); `missed` round-trips (enum name, UTC)
- [x] AC-10: AppBootstrap fires fire-and-forget, non-blocking; a failure doesn't break startup
- [x] AC-11: Today triggers once per mount (no loop); no-meds writes nothing
- [x] AC-12: past-window pending → `missed` reactively on load; idle-open dose does not live-flip
- [x] AC-13,14: display-only error-toned "Missed" tile (exhaustive switch); `todayStatusMissed` en/de/uk
- [x] AC-15: fakes/harness/bootstrap neutralized; `dart analyze` clean; full suite 798/798; dartdoc on new APIs
