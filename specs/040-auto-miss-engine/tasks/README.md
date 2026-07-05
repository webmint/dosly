# Tasks: Auto-Miss Engine for Intakes

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-07-04
**Total tasks**: 9
**Status**: ✅ Complete — all 9 tasks done; `/verify` APPROVED (2026-07-05). 15/15 ACs PASS; `dart analyze` clean; full suite 798/798; `/review` PASS/PASS/ADEQUATE (2 security Info + 3 perf Medium tracked as non-blocking follow-ups).

## Dependency Graph

```
001 (derivation) ─────────────────────────┐
                                           ▼
002 (data source) ──→ 003 (repo markMissed) ──→ 004 (use case) ──→ 006 (providers) ──┬─→ 008 (app-open trigger)
                                        └──────→ 005 (impl test)                       └─→ 009 (today-load trigger)
                                                                                            ▲
007 (missed tile + l10n) ───────────────────────────────────────────────────────────────┘
```

- Foundation, parallelizable: **001** (derivation), **002** (data source), **007** (missed tile) have no dependencies.
- **004** is the convergence point (derivation + repo write); **009** converges the providers + the missed tile.

## Task Index

| # | Title | Agent | Depends on | Checkpoint | Status |
|---|-------|-------|-----------|-----------|--------|
| 001 | Add the pure `findAutoMissDoses` derivation | architect | None | No | Complete |
| 002 | Add `insertMissedIntake` (insert-or-ignore) to the data source | architect | None | No | Complete |
| 003 | Add `markMissed` to `IntakeRepository` (contract + impl + fakes) | architect | 002 | No | Complete |
| 004 | Add the `ReconcileMissedIntakes` use case | architect | 001, 003 | **Yes** | Complete |
| 005 | Test `markMissed` at the repository-impl / DB level | qa-engineer | 003 | No | Complete |
| 006 | Wire the reconcile providers | architect | 004 | No | Complete |
| 007 | Render a real `IntakeStatus.missed` tile + `todayStatusMissed` l10n | mobile-engineer | None | No | Complete |
| 008 | Fire reconcile on app open + neutralize in tests/harness | mobile-engineer | 006 | **Yes** | Complete |
| 009 | Fire reconcile on Today-screen load | mobile-engineer | 006, 007 | **Yes** | Complete |

## Additions to Spec

Discovered during planning (already reflected in `plan.md`):
- **`lib/features/meds/data/datasources/intake_local_data_source.dart`** gains `insertMissedIntake` (Task 002). The spec left the persist mechanism to `/plan`; the plan chose a dedicated **insert-or-ignore** write (never overwrites an existing occurrence row) instead of reusing `upsertIntake`, hardening the #1 clobber risk.
- **`ReconcileMissedIntakes` injects `MedicationRepository` + `SettingsRepository`** (Task 004); this pulls `medicationRepositoryProvider` + `settingsRepositoryProvider` into `intake_providers.dart` as DI-seam imports (Task 006). The spec left the snapshot source (OQ-1) and window source (OQ-3) open.
- **`reconcileMissedOnOpenProvider`** (keepAlive) is added specifically so the `AppBootstrap` trigger is independently overridable in the integration harness (Task 006/008) — the MEMORY 035 mitigation.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Pure function; DST/boundary edges covered by clock-injected tests. |
| 002 | Low | One-method data-source addition; no schema change. |
| 003 | Med | Interface change — breaks the 2 hand-written `implements IntakeRepository` fakes; requires **project-wide** analyze (not just changed-file). |
| 004 | **High** | Orchestration + the never-clobber / idempotency guarantee (spec's #1 High risk); convergence of 001 + 003. |
| 005 | Low | Test-only; but the airtight DB-level never-clobber proof. |
| 006 | Low | DI wiring; cross-feature settings import at the seam (documented). |
| 007 | Low | Display-only tile + 3 ARB keys; independent of the engine. |
| 008 | **High** | New `AppBootstrap` side-effect — the devSeed poisoning failure mode (MEMORY 035); must be neutralized in harness + bootstrap test. |
| 009 | Med | Screen trigger must fire once per mount with no reconcile↔rebuild loop (AC-11). |

## Review Checkpoints

| Before proceeding past | Reason | What to Review |
|-------------------------|--------|----------------|
| 004 | Convergence (001 + 003) + High risk | The use case never passes an already-recorded occurrence to `markMissed` (idempotency + never-clobber); resilient window read; `Either` on every path; no `DateTime.now()`. |
| 008 | High risk (app-level side-effect) | Startup trigger is fire-and-forget and non-blocking; the harness **and** bootstrap test neutralize it (no real reconcile in golden flows); startup never errors on a reconcile failure. |
| 009 | Convergence (006 + 007) + loop risk | `initState` fires exactly once per mount; a rebuild/stream re-emission does NOT re-fire (no busy-loop); past-window pending → `missed` reactively; no live flip while idle. |

## Contract Chain Integrity

No orphans, no unsatisfied expectations:
- **001** `findAutoMissDoses` → consumed by **004**.
- **002** `insertMissedIntake` → consumed by **003**.
- **003** `markMissed` → consumed by **004**, **005**, and the test fakes in **008**/**009**.
- **004** `ReconcileMissedIntakes` → consumed by **006**.
- **006** `reconcileMissedIntakesProvider` / `reconcileMissedOnOpenProvider` → consumed by **008**, **009**.
- **005 / 007 / 008 / 009** produce terminal outputs that map directly to acceptance criteria (AC-7/8/9, AC-13/14, AC-10/15, AC-11/12).
- All `Expects` not produced upstream are satisfied by existing codebase state: `expandDueDoses`, `localCalendarDate`, `IntakeWindow`, `MedicationRepository.watchAll`, `IntakeRepository.watchAll`, `SettingsRepository.load`, `IdGenerator`, `intakeToCompanion`, the `Intakes` drift table + `IntakesCompanion`, and the `devSeedProvider` override pattern.

## Acceptance-Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1, AC-2, AC-3, AC-4 | 001 |
| AC-5, AC-6 | 004 |
| AC-7 | 002 (DB), 003 (impl), 004 (use-case guard), 005 (proof) |
| AC-8 | 003, 004, 005 |
| AC-9 | 002, 003, 005 |
| AC-10 | 006, 008 |
| AC-11 | 006, 009 |
| AC-12 | 009 |
| AC-13, AC-14 | 007 |
| AC-15 | 003 (fakes), 008 (harness/bootstrap), + every task's analyze gate |
