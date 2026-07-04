# Tasks: Intake-Behavior Settings

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-07-03
**Total tasks**: 11
**Feature status**: ✅ Complete & Verified (2026-07-04) — 11/11 tasks Complete; `/review` (security PASS, perf clean, tests GAPS FOUND → closed by `/fix`); `/verify` APPROVED — all 17 ACs PASS; full suite 764/764 green, `dart analyze` clean. Ready for `/summarize` → `/finalize`.

## Dependency Graph

```
001 (value objects)
 ├─→ 002 (prefs keys + data source) ─┐
 ├─→ 003 (entity + constitution) ────┼─→ 004 (repo contract+impl+fakes) ──→ 005 (use cases) ─┐
 └───────────────────────────────────┘        [checkpoint]                                   │
                                                                                             │
 003 ───────────────────────────────────────────────────────────────────────→ 006 (provider)┤
 005 ────────────────────────────────────────────────────────────────────────→ 006 ─────────┘
                                                                                     │
 007 (l10n)  ────────────────────────────────────────────────┐                       │
 006 + 007 ──────────────────────────────────────────────────┴─→ 008 (Intake UI) ────┘
                                                                    [checkpoint]

Tests (run once their impl deps are met):
 001,005 ─→ 009 (domain tests)
 002,004 ─→ 010 (data tests)
 006,008 ─→ 011 (presentation tests) [checkpoint — final verification]
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Value objects (IntakeWindow, GracePeriod) | architect | None | Complete |
| 002 | Prefs keys + data-source read/write | architect | 001 | Complete |
| 003 | AppSettings +3 fields + constitution §5.1 | architect | 001 | Complete |
| 004 | Repo contract + impl + patch 8 fakes | architect | 001, 002, 003 | Complete |
| 005 | Use cases (Set×3) | architect | 004 | Complete |
| 006 | Use-case providers + notifier mutators | mobile-engineer | 005, 003 | Complete |
| 007 | l10n keys (en/de/uk) | mobile-engineer | None | Complete |
| 008 | Intake controls widget + screen wiring | mobile-engineer | 006, 007 | Complete |
| 009 | Domain tests (VOs + use cases) | qa-engineer | 001, 005 | Complete |
| 010 | Data tests (data source + repo) | qa-engineer | 002, 004 | Complete |
| 011 | Presentation tests (notifier + controls) | qa-engineer | 006, 008 | Complete |

## Additions to Spec

- **`constitution.md` §5.1 amendment** (bundled into Task 003) — add `allowMarkAhead` and note the `IntakeWindow`/`GracePeriod` VO representation. Surfaced during `/plan`'s §5.1 compliance check; not in the spec's original Affected Areas.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 004 | High | Adds 3 methods to `SettingsRepository` → breaks 8 hand-written fakes; project-wide `dart analyze` stays red until all are patched (MEMORY F037). Contract + impl + fakes deliberately bundled to keep the tree compiling. Touches 10 files (interface-ripple exception to the 1–3 file rule). |
| 001 | Low | New pure VOs; freezed-const wrinkle designed out via hand-rolled class. |
| 003 | Low | `@Default` with VO fields depends on 001's const `defaultValue`; freezed regen. Also edits the sensitive `constitution.md`. |
| 006 | Low | Riverpod codegen — keep `name: 'settingsNotifierProvider'`; regen `.g.dart`. |
| 008 | Med | First UI; stepper bounds + persistence-failure behavior are the fiddly bits. |
| 002, 005, 007, 009, 010, 011 | Low | Mechanical mirrors of established patterns / straightforward tests. |

## Review Checkpoints

| Before/After Task | Reason | What to Review |
|-------------------|--------|----------------|
| 004 | Convergence (001+002+003) + high-risk interface blast radius | All 8 fakes patched; `load()` populates new fields; `saveX` Either paths correct; **project-wide** `dart analyze` clean, suite compiles. |
| 008 | Layer crossing (first presentation) + convergence (006+007) | Stepper step/bounds correct; switch wired; values read from provider; failure SnackBar path intact; no `data/` import from the widget. |
| 011 | Final convergence + verification | Full suite green, project-wide analyze clean, all ACs exercised. |

## Contract Chain Integrity

No orphans, no unsatisfied expects:
- **001 Produces** (VOs) → consumed by 002, 003, 004, 005, 008, 009.
- **002 Produces** (data source get/set + keys) → consumed by 004 (`load`/`saveX` bodies), 010.
- **003 Produces** (entity fields) → consumed by 004 (`load`), 006 (`copyWith`), 011.
- **004 Produces** (repo contract/impl + fakes) → consumed by 005, 010, 011; satisfies AC-9/AC-10/AC-17.
- **005 Produces** (use cases) → consumed by 006, 009.
- **006 Produces** (providers + mutators) → consumed by 008, 011.
- **007 Produces** (l10n keys) → consumed by 008.
- **008 Produces** (UI) → consumed by 011; satisfies AC-13/14/15.
- Test tasks (009/010/011) map directly to spec ACs (terminal nodes).

## AC Coverage Map

| AC | Task(s) |
|----|---------|
| AC-1 | 003 (impl), 011 (test) |
| AC-2, AC-3, AC-4 | 001 (impl), 009 (test) |
| AC-5 | 002 |
| AC-6, AC-7, AC-8 | 002 (impl), 010 (test) |
| AC-9, AC-10 | 004 (impl), 010 (test) |
| AC-11 | 005 (impl), 009 (test) |
| AC-12 | 006 (impl), 011 (test) |
| AC-13, AC-14, AC-15 | 008 (impl), 011 (test) |
| AC-16 | 007 |
| AC-17 | 004 (impl), 011 (final verify) |
