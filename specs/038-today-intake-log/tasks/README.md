# Tasks: Today Screen — Daily Intake Checklist

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-07-01
**Total tasks**: 16
**Status**: ✅ ALL COMPLETE — `/verify` APPROVED (15/15 ACs PASS, 659 tests green, APK builds, security PASS). 6 non-blocking Warnings (test-coverage gaps + 1 perf) in `../verify.md`.

## Dependency Graph

```
001 (v1 snapshot) ───────────────┐
                                  ├──→ 005 (migrate v2) ──→ 006 (migration tests)
002 (domain types) ──→ 004 (table)┘            │
   │                                           ├──→ 008 (data source) ──┐
   ├──→ 007 (repo contract) ───────────────────┼─────────────────────── ┤
   ├──→ 010 (use cases) ───────────────────────┼───────────────┐        │
   │        ▲                                   │               │        │
   │        └── 007                             └── 009 (mapper+repo impl) ◄─ 002,005,007,008
   │
003 (expansion) ──→ 013 (view model) ◄── 002
                         │
009,010,008 ──→ 012 (providers) ──┐
011 (l10n) ──┐                    │
013 ─────────┼──→ 014 (dose tile) │
             │        │           │
             └────────┴──→ 015 (Today screen) ◄── 011,012,013,014 ──→ 016 (integration gate)
```

Independent roots (can start immediately, in parallel): **001**, **002**, **003**, **011**.

## Task Index

| # | Title | Agent | Depends on | Checkpoint | Status |
|---|-------|-------|-----------|:---:|--------|
| 001 | Capture v1 drift schema snapshot | architect | None | No | ✅ Complete |
| 002 | Define Intake domain types | architect | None | No | ✅ Complete |
| 003 | Schedule expansion (DueDose + expandDueDoses) | architect | None | No | ✅ Complete |
| 004 | Intakes drift table | architect | 002 | No | ✅ Complete |
| 005 | Migrate schema to v2 (register + onUpgrade) | architect | 001, 004 | **Yes** | ✅ Complete (review: approve w/ warnings) |
| 006 | Migration tests (SchemaVerifier + data survival) | qa-engineer | 005, 001 | **Yes** | ✅ Complete (3/3 pass, 611 suite green) |
| 007 | Intake repository contract | architect | 002 | No | ✅ Complete |
| 008 | Intake local data source | architect | 005 | No | ✅ Complete |
| 009 | Intake mapper + repository impl | architect | 002, 005, 007, 008 | No | ✅ Complete |
| 010 | Intake use cases (mark/skip/undo) | architect | 002, 007 | No | ✅ Complete |
| 011 | Today localization keys | mobile-engineer | None | No | ✅ Complete |
| 012 | Riverpod providers (composition seam) | architect | 008, 009, 010 | **Yes** | ✅ Complete (seam verified) |
| 013 | Today view model (buildTodayView) | architect | 002, 003 | No | ✅ Complete |
| 014 | Today dose tile widget | mobile-engineer | 011, 013 | **Yes** | ✅ Complete (relocated to meds/ per §2.1 review) |
| 015 | Today screen assembly + empty state | mobile-engineer | 011, 012, 013, 014 | **Yes** | ✅ Complete (screen in meds/, routed; review approved) |
| 016 | Integration gate — full test + build | qa-engineer | 015 | **Yes** | ✅ Complete (PASS: 659 tests, APK builds) |

## Additions to Spec

Discovered during planning (all internal decompositions of spec-listed areas, noted in plan.md):
- `lib/features/meds/domain/value_objects/local_calendar_date.dart` — shared DST-safe day helper (avoids a third private `_localDate` copy; existing copies left untouched per minimal-change).
- `lib/features/meds/domain/value_objects/intake_grace.dart` — the `kIntakeUndoGracePeriod` constant (spec listed a generic "grace constant" area).
- `today_empty_state.dart` / `today_dose_tile.dart` — widget split of the spec's "Today screen UI" area.
- `drift_schemas/` (v1 JSON snapshot) + `test/core/database/schema/` (generated `SchemaVerifier` helper) — tooling for the migration tests.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 005 | **High** | First-ever schema migration of the health-data system of record; add-only mitigates, but a mistake risks data. |
| 015 | Med-High | Integration convergence: two streams + view model + widgets + ticker + async-safe action wiring. |
| 006 | Medium | Migration verification + `drift_dev schema` tooling setup (first use). |
| 003 | Medium | DST / future-start / pause-gap day-math edge cases. |
| 012 | Medium | Composition-seam convergence; `Left→throw` stream wiring. |
| 009 | Low-Med | Mechanical glue, but 4-way convergence (contract + row + mapper + data source). |
| 001,002,004,007,008,010,011,013,014,016 | Low | Isolated types/pattern-following/verification. |

## Review Checkpoints

| Before proceeding past | Reason | What to verify |
|-------------|--------|----------------|
| 005 | High-risk | `schemaVersion==2`; `onUpgrade` is add-only (`createTable(intakes)` only); `onCreate`/FK pragma intact; no existing column altered. |
| 006 | High-risk verification (convergence 005+001) | SchemaVerifier v1→v2 passes; v1 medication+slot survive the upgrade; fresh install has `intakes`. |
| 012 | Convergence (008+009+010) | Composition seam only presentation file importing `data/`; `intakesListProvider` folds `Left→throw`. |
| 014 | Layer boundary (first UI) | Tile renders 24h time + status affordances; Undo gated on `undoable`; no overdue styling. |
| 015 | Convergence + integration | Reactive checklist + mark/skip/undo end-to-end; empty/loading/error; ticker disposed; settings nav intact. |
| 016 | Terminal gate | Whole suite green; debug build compiles; analyze clean. |

## Contract Chain Integrity

**No orphans, no unsatisfied Expects.** Verified:
- 001→006; 002→{004,007,009,010,013}; 003→013; 004→005; 005→{006,008,009}; 007→{009,010,012}; 008→{009,012}; 009→012; 010→012; 011→{014,015}; 012→015; 013→{014,015}; 014→015; 015→016.
- Terminal producers 006 and 016 map directly to acceptance criteria (AC-5/AC-7 and AC-15 respectively) rather than a downstream Expects — expected for verification tasks.

## Acceptance-Criteria Coverage

| AC | Tasks |
|----|-------|
| AC-1..4 (expansion) | 003 |
| AC-5 (migration/schema) | 004, 005, 006 |
| AC-6 (idempotent persist, UTC) | 004, 008, 009 |
| AC-7 (v1 data survives) | 001, 006 |
| AC-8 (checklist, sort) | 013, 014, 015 |
| AC-9 (mark reactive) | 010, 012, 015 |
| AC-10 (early mark, no overdue) | 013, 014, 015 |
| AC-11 (empty/loading/error) | 015 |
| AC-12 (undo → pending) | 010, 012, 013, 014, 015 |
| AC-13 (5-min grace lock) | 002, 010, 013, 014, 015 |
| AC-14 (i18n) | 011 |
| AC-15 (quality gates) | 016 (+ every task's analyze/test gate) |
