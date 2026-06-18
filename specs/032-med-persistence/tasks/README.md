# Tasks: Medication Persistence (drift)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-17
**Total tasks**: 14

## Dependency Graph

```
Infra/Types ──────────────► Core ───────────► Domain logic ──► Data ──► Wiring ──► UI ──► Tests
001 deps ─┬───────────────► 005 drift db ─┬──────────────────► 008 data ─┬─► 009 providers ─► 011 modal ─► 014 modal tests
          └─► 006 idgen ──┐               │                              │
002 enums/ids ─┬─► 003 VOs ─► 004 aggregate ─► 007 repo+usecase ─────────┘
               └────────────► 005 (textEnum)
007 ─► 012 usecase tests
005 + 008 ─► 013 data tests
010 l10n ──────────────────────────────────────────────────────► 011 modal
002 (DoseUnit) ────────────────────────────────────────────────► 011 modal
```

Execution waves (respecting deps): **[001, 002, 010]** → **[003, 006]** → **[004]** → **[005, 007]** → **[008, 012]** → **[009, 013]** → **[011]** → **[014]**.

## Task Index

| # | Title | Agent | Depends on | Checkpoint | Status |
|---|-------|-------|-----------|-----------|--------|
| 001 | Add drift + uuid dependencies | architect | None | No | Complete |
| 002 | Domain enums + ID value objects | architect | None | No | Complete |
| 003 | Domain value objects (Dosage, PackStock, TimeSlot) | architect | 002 | No | Complete |
| 004 | Domain aggregate (MedicationType, Schedule, Medication) | architect | 002, 003 | No | Complete |
| 005 | drift database (tables, AppDatabase, provider) | architect | 001, 002 | **Yes** | Complete |
| 006 | IdGenerator (interface + uuid impl + provider) | architect | 001 | No | Complete |
| 007 | MedicationRepository contract + AddMedication use case | architect | 004, 006 | No | Complete |
| 008 | Data layer (mapper, data source, repo impl) | architect | 005, 007 | **Yes** | Complete |
| 009 | Presentation providers (composition seam) | architect | 005, 006, 007, 008 | **Yes** | Complete |
| 010 | Localized Save strings (en/de/uk) | mobile-engineer | None | No | Complete |
| 011 | Wire the modal Save button | mobile-engineer | 002, 009, 010 | **Yes** | Complete |
| 012 | Unit tests for AddMedication | qa-engineer | 007 | No | Complete |
| 013 | Data-layer tests (in-memory drift) | qa-engineer | 005, 008 | No | Complete |
| 014 | Rewrite modal widget tests | qa-engineer | 011 | No | Complete |

## Additions to Spec

Discovered during `/plan` and `/breakdown` (not in the spec's original Affected Areas):

- **`lib/core/id/` — `IdGenerator` + `UuidIdGenerator` + provider (tasks 006).** Replaces the spec's assumed `MedicationId.generate()`: `package:uuid` cannot be imported under `domain/` (constitution §2.1), so IDs are injected instead. **Refines AC-7/AC-9** (the IDs are plain value objects with no `generate()`; the use case takes an injected `IdGenerator`). Approved in `plan.md` / `research.md`.
- **`dose_unit.dart` and `schedule_frequency.dart`** split into their own files (one public enum per file), and **`MedicationTypeKind`** storage-discriminator enum defined in `medications_table.dart` (data layer). Structural detail within the spec's listed domain/data areas.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Standard `flutter pub add`; deps pre-blessed |
| 002 | Low | Trivial enums/freezed; first meds domain files |
| 003 | Low | Freezed value objects, no logic |
| 004 | Low | Freezed aggregate, no logic |
| 005 | **High** | First DB in the codebase; drift codegen; `@DataClassName` collision; `textEnum` values become a stored contract; `foreign_keys` pragma |
| 006 | Low | Small abstraction + provider |
| 007 | Med | Validation logic + exhaustive sealed switch; downstream contract |
| 008 | **High** | Mapper fidelity (null dose/stock, sealed type) + transactional insert — the persistence correctness core |
| 009 | Med | Convergence of the full DI graph; codegen |
| 010 | Low | ARB string additions |
| 011 | **High** | First UI↔domain integration; typed-unit refactor of `_MedFormOption`; async/`mounted`/SnackBar/pop |
| 012 | Low | Pure unit tests with mocks |
| 013 | Med | In-memory drift round-trip fidelity |
| 014 | Med | Widget-test pop/SnackBar harness (route-below + provider override pitfalls) |

## Review Checkpoints

| Before/After Task | Reason | What to Review |
|-------------------|--------|----------------|
| 005 | High risk (first DB, codegen) | Schema columns vs data-model.md; `@DataClassName` applied; `schemaVersion=1`; `foreign_keys` pragma in `beforeOpen`; enum value names frozen |
| 008 | Convergence + high risk | Mapper round-trip rules (null dose/stock, sealed `MedicationType` switch); single `transaction`; no exception escapes `data/` |
| 009 | Convergence (full DI graph) | Only this file imports `data/`; providers resolve to domain types; codegen committed |
| 011 | Layer crossing + high risk | `ConsumerStatefulWidget`; per-form dose/stock mapping (§3); `mounted` after await; button disabled in-flight; localized SnackBars |

(Convergence tasks 004 and 007 are not checkpointed by default — add them during approval if desired.)

## Contract Consistency Check

**Result: no orphans, no unsatisfied expectations.**
- Every `Produces` is consumed by a downstream `Expects` (001→005/006; 002→003/004/005/011; 003→004; 004→007/008; 005→008/009/013; 006→007/009; 007→008/009/012; 008→009/013; 009→011; 010→011/014; 011→014) or maps to a terminal AC (012/013/014 are test tasks).
- Every `Expects` traces to an upstream `Produces` or existing codebase state (`core/error/failures.dart`, `package:clock`, existing `l10n` ARBs, `settings` provider pattern).

## Coverage Check (all spec ACs addressed)

AC-1→T001 · AC-2/3/4/5→T005 · AC-6→T002/003/004 · AC-7→T002/006 · AC-8/9→T007 · AC-10/11/12/13→T007/012 · AC-14/15/16→T008/013 · AC-17→T009/011 · AC-18/19→T011/014 · AC-20→T008/011/013 · AC-21→T010 · AC-22→T012 · AC-23→T013 · AC-24→T014 · AC-25→all (build_runner + analyze + test gates in every task's Done-when).

## Completion Summary (/verify 2026-06-17)
- **Verdict: APPROVED.** All 14 tasks Complete; spec → Complete.
- **AC**: 25/25 PASS (code-reading mode — AC verification off for this project).
- **Quality gates**: `dart analyze` clean · `flutter test` **384/384** · `flutter build apk --debug` ✓ (native drift deps link) · no leftover artifacts · no scope creep · cross-task DI graph consistent.
- **Review (non-blocking)**: Security 1 Medium (unencrypted-at-rest → post-MVP backlog), 0 Critical/High. Performance: forward-looking only (FK index on `time_slots.medicationId` + DB warm-up when the list ships). Tests: GAPS FOUND → **all RESOLVED post-verify**.
- **Post-verify fixes (2026-06-17)**: all 4 Warnings closed — W2 zero-dose validation (`field:'dose'` + l10n + modal), T008 W1 mapper `StateError`, Gap 1 Tablet/Syrup e2e (recording-repo capture) + PackStock partial-input, Gap 2 times/duration SnackBar tests. Code-reviewed APPROVE; **flutter test 393/393**; analyze clean. (Accepted/deferred: encryption-at-rest, FK index, minor Info gaps.)
- **Next**: `/summarize` → `/finalize`.
