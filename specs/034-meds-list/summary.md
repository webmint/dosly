## Feature Summary: 034 — Medications List Screen

### What was built
A live medications list: the Meds tab now reads every saved medication from the local database and shows them grouped into **Continuous** and **Course** sections, each as a tile with its form icon, name, a `dose · times · stock` line (low stock highlighted in red), and status/type chips (Active/Completed, "continuous"/"Day X/Y"/"Paused"). The list updates instantly when a medication is added, with **All/Active** filter chips and an app-bar name search. A debug-only seeder pre-fills 12 representative medications so the screen can be exercised on-device without manual data entry.

### Changes
- Task 001: Domain derivation — pure, time-injected `Active`/`Completed` status + course cycle-day (`Day X/Y`/Paused) computation.
- Task 002: Derivation unit tests — fixed-clock boundary coverage (caught + fixed a DST off-by-one in the day count).
- Task 003: Reactive read — watched drift join (`medications ⨝ time_slots`) exposed as `Stream<Either<Failure, List<Medication>>>`.
- Task 004: Reactive read data tests — in-memory drift; re-emission on insert/slot-change/delete; reactive-add (AC-19).
- Task 005: `medicationsListProvider` — folds the stream into `AsyncValue<List<Medication>>`.
- Task 006: l10n — 25 list-screen keys across en/de/uk (uk matches the design wording).
- Task 007: Shared `MedicationForm → IconData` map — extracted from the add modal for reuse (DRY).
- Task 008: Display formatters — dose/times/stock + localized unit abbreviations (+26 tests).
- Task 009: View-model — pure filter/search/group/sort shaping (+12 tests).
- Task 010: Tile + section widgets — the `#s-meds` design, theme-driven, non-interactive.
- Task 011: Rebuilt `MedsScreen` — search app-bar, filter chips, sections, loading/error/empty states; FAB preserved.
- Task 012: Screen widget tests — 33 tests across the behavioral ACs incl. reactive add.
- Task 013: Debug seeder — `kDebugMode`-only, empty-table-guarded, insert-only; 12 variants covering all forms + course states.

### Files changed
- `lib/features/meds/` (domain / data / presentation) — 6 added, 5 modified (derivation, reactive read, view-model, tiles, screen, providers)
- `lib/core/database/` + `lib/app_bootstrap.dart` — `dev_seed.dart` added, bootstrap wiring
- `lib/l10n/` — 3 ARB files updated (+ regenerated localizations)
- `test/features/meds/` + `test/core/routing/` — 8 added/updated test files (~147 feature tests)
- `specs/034-meds-list/` — spec, plan, research, data-model, 13 task files, review
- Total: **57 files changed, +6427 / −133** (2 generated)

### Key decisions
- Reactive read via a single watched left-outer join + in-Dart grouping — re-emits on either table, **no new dependency** (rxdart rejected).
- `Stream<Either<Failure,T>>` repo method folded to `AsyncValue` in the provider — the read-side analog of the existing `Future<Either>` write contract (§3.2).
- `Active`/`Completed` and the day-counter are **derived at read time** (Clock-injected, UTC-anchored for DST safety) — **no schema change**; Archive deferred to a follow-up.
- Debug seeder runs only in `kDebugMode`, only when the table is empty, insert-only via the real repository path — non-destructive and release-inert.

### Deviations from plan
- Task 001/002: a DST off-by-one in calendar-day counting (`localMidnight.difference().inDays`) was found by the tests and fixed by anchoring dates to `DateTime.utc`.
- Task 007/012: Task 003's new `watchAll()` interface method broke hand-written test doubles, and the rebuilt screen broke the router test (real DB open) — both cross-cutting regressions caught by the full suite and repaired (stub override / in-memory DB override).
- Task 013: code review caught a `ref.watch`-after-`await` and a seed entry that was mathematically *active* despite being labeled paused — both fixed (`ref.read`; start date −25d).

### Acceptance criteria
- [x] AC-1 reactive `Stream<Either>` read, re-emits on table changes, errors → Left
- [x] AC-2 `medicationsListProvider` exposes `AsyncValue<List<Medication>>`
- [x] AC-3 emissions reconstructed via `medicationFromRows` (slots/dose/stock/type)
- [x] AC-4 activity status (continuous/cyclic active; non-cyclic completed past end)
- [x] AC-5 course cycle-day counter (currentDay/totalDays, activeWindow/paused)
- [x] AC-6 derivation unit-tested with fixed Clock incl. boundaries (+ DST guard)
- [x] AC-7 Continuous/Course sections, name-sorted, localized headers
- [x] AC-8 tile: form icon, name, `dose · times · stock`, low-stock in error color
- [x] AC-9 status chip (Active/Completed) + type chip (continuous/Day X/Y/Paused)
- [x] AC-10 All/Active filter chips; Active hides Completed; reactive
- [x] AC-11 name search across both sections; clear restores
- [x] AC-12 empty states (top-level zero-meds; per-section placeholder)
- [x] AC-13 chevron rendered, tile not tappable
- [x] AC-14 loading + error views (all three AsyncValue branches)
- [x] AC-15 en/de/uk strings, parameterized keys, uk matches design
- [x] AC-16 seeder kDebugMode-only, empty-guarded, idempotent, release no-op
- [x] AC-17 seed covers all 8 forms + continuous/cyclic/completed + low-stock
- [x] AC-18 seeder logs no PHI; `dart analyze` clean
- [x] AC-19 add via modal → appears with no manual refresh

_Verified APPROVED (2026-06-18): 481/481 tests, debug APK builds, `dart analyze` clean. Non-blocking follow-ups in `review.md` (localize error string; seeder + Paused-chip test coverage)._
