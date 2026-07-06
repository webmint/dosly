# Tasks: Today Screen Redesign — Hourly Groups, Countdown, Checkbox Model

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-07-05
**Total tasks**: 10

## Dependency Graph

```
001 (l10n) ───────────────────────────┐
                                       ├─→ 006 (tile) ─┐
003 (MedTypeChip) ─────────────────────┘               ├─→ 008 (group) ─┐
                                                        │                │
002 (settings projection) ─┬─→ 004 (undo grace) ─→ 005 (view model) ────┼─→ 007 (countdown) ─┤
                           │                             │               │                    │
                           └─────────────────────────────┴───────────────┴────────────────────┴─→ 009 (screen) ─→ 010 (regression)
```

Simplified chain: **002 → 004 → 005** is the core spine (settings seam → grace rewire → view-model contracts). **001** and **003** feed the widgets. **005 + 006 + 007 + 008 + 002** converge at **009** (screen), then **010** closes the blast radius.

## Task Index

| # | Title | Agent | Depends on | Review | Status |
|---|-------|-------|-----------|--------|--------|
| 001 | Add Today-redesign l10n keys (en/de/uk) | mobile-engineer | None | No | Complete |
| 002 | Add `todayIntakeSettings` projection provider | architect | None | No | Complete |
| 003 | Extract shared `MedTypeChip` widget | mobile-engineer | None | No | Complete |
| 004 | Rewire `UndoIntake` to a `Duration` grace | architect | 002 | No | Complete |
| 005 | Rewrite `today_view_model` (groups/window/countdown) | architect | 002, 004 | **Yes** | Complete |
| 006 | Restyle `today_dose_tile` (checkbox/skip/chips/stock) | mobile-engineer | 005, 003, 001 | **Yes** | Complete |
| 007 | Create `TodayCountdownCard` | mobile-engineer | 005, 001 | No | Complete |
| 008 | Create `TodayGroupSection` (collapsible group) | mobile-engineer | 005, 006, 001 | No | Complete |
| 009 | Redesign `today_screen` (countdown+groups+timer) | mobile-engineer | 005, 006, 007, 008, 002 | **Yes** | Complete |
| 010 | Integration & regression sweep | qa-engineer | 009 | **Yes** | Complete |

## Additions to Spec

- **`lib/features/meds/presentation/widgets/med_type_chip.dart`** (new) + **`medication_tile.dart`** refactor (task 003) — the spec flagged a "shared status chip (maybe)" in §4 and OQ-4; resolved here as an extraction so the Today tile and meds-list tile share one non-trivial chip implementation. The meds-list change is behavior-preserving (its existing tests guard it).
- **Widget name `TodayGroupSection`** (task 008) rather than `TodayHourGroup` (plan's tentative name) to avoid colliding with the view-model class `TodayHourGroup`.
- **`today_screen.dart` is touched by three tasks** (004 `_onUndo` call site, 005 `buildTodayView` call site, 009 full redesign). Each edit is minimal and strictly ordered; this keeps every intermediate state compiling (`dart analyze` green) despite the two signature changes.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 005 | High | Contract-defining view-model rewrite + `buildTodayView` signature change (blast radius: screen + VM test). Everything downstream depends on `TodayHourGroup`/`TodayGroupState`/`DoseWindowState`/`nextIntake`. |
| 009 | High | Convergence of 5 tasks; the one-shot boundary `Timer` must never regress to `Timer.periodic` / a reschedule loop (breaks `pumpAndSettle`); deletes `intake_grace.dart`. |
| 006 | Med | First task in the new interaction model; drops `todayTake`/`todaySkip`-button keys → `today_screen_test.dart` shows transient failures until task 009 rewrites it (see note below). |
| 004 | Med | `UndoIntake` signature change with a cross-task call-site update; grace boundary must stay inclusive. |
| 003 | Med | Refactors the shipped `medication_tile`; guarded by existing meds-list tests (must pass unchanged). |
| 010 | Med | Blast-radius closure — may surface app/router/bootstrap tests that pump the Today screen. |
| 001, 002, 007, 008 | Low | Additive keys/providers/widgets with their own tests. |

## Review Checkpoints

| Before/At Task | Reason | What to review |
|----------------|--------|----------------|
| 005 | High risk + contract-defining | `TodayHourGroup`/`TodayGroupState`/`DoseWindowState`/`nextIntake` shapes match `data-model.md`; window boundary inclusive and consistent with spec 040; VM stays pure; screen still compiles. |
| 006 | Layer boundary (first new-interaction widget) | Checkbox/skip/undo enable matrix; exhaustive `IntakeStatus` switch; low-stock only when low; no `surfaceVariant`. |
| 009 | Convergence (5 deps) + high risk | One-shot boundary timer (no `Timer.periodic`, no reconcile loop, cancels correctly); Mark-all filters to actionable pending; `intake_grace.dart` deleted with zero refs; screen test `pumpAndSettle`-safe. |
| 010 | Final regression gate | Project-wide analyze + full suite green; ARB parity; audit greps empty. |

> **Transient-test note (tasks 006 → 009)**: task 006 changes the dose tile's interaction keys, so `today_screen_test.dart` (rewritten in task 009) is expected to fail if run in between. Per-task verification is scoped to each task's own changed-file tests; the full-suite green gate is task 010. If the harness runs the full suite per task, run task 009 immediately after 006.

## Contract Chain Integrity

- **No orphaned Produces**: every task's Produces is consumed by a downstream Expects (001→006/007/008/009; 002→004/005/009; 003→006; 004→005; 005→006/007/008/009; 006→008/009; 007→009; 008→009; 009→010) or maps directly to an AC.
- **No unsatisfied Expects**: every Expects traces to existing codebase state (specs 032/038/039/040) or an upstream Produces.
- **AC coverage**: AC-1 (005), AC-2 (005/008), AC-3 (008/009), AC-4 (005/007), AC-5 (009), AC-6 (006/009), AC-7 (006/009), AC-8 (002/005/009), AC-9 (005), AC-10 (008/009), AC-11 (003/006), AC-12 (006), AC-13 (006/007/008/009/010), AC-14 (004/005/009), AC-15 (009), AC-16 (010). All 16 covered.

## Completion Summary

**All 10 tasks Complete.** `/verify` verdict: **APPROVED** (2026-07-06). 16/16 ACs PASS (code-reading mode — `AC_VERIFICATION: off`). Full `flutter test` **836/836**; `dart analyze` clean; no scope creep; no leftover artifacts; cross-task consistency PASS.
- `/review`: Security **PASS** (0 Critical/High/Medium, 8 Info). Performance **no blockers** (0 High/Med, 3 Low). Test **GAPS FOUND** (9/16 solid; gaps are screen-level integration assertions over behavior already verified at the VM/use-case/widget layer — non-blocking Warnings).
- Deferred (non-blocking, tracked for `/finalize` or follow-up): §3.5 cleanup of the production-unused `TodayView.doses` getter; screen-level tests for AC-5 (live countdown), AC-8/AC-14 (settings-reactive enablement/undo), AC-10 (mixed-group mark-all + failure SnackBar); run `integration_test/` on a device.
- Next: `/summarize` → `/finalize`.
