# Tasks: Meds Screen Add-FAB and Placeholder Modal

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-04-29
**Total tasks**: 3

## Dependency Graph

```
001 (l10n keys) ─┬─→ 002 (sheet widget + test) ──→ 003 (screen FAB + screen test)
                 └────────────────────────────────→ 003
```

Tasks 001 and 002 must complete before Task 003. Task 002 also depends
on Task 001 (its widget reads `context.l10n.medsAddTitle`).

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add l10n keys for FAB tooltip and modal title | mobile-engineer | None | Complete |
| 002 | Create AddMedicationSheet widget and its widget test | mobile-engineer | 001 | Complete |
| 003 | Wire FAB on MedsScreen, open AddMedicationSheet, extend screen test | mobile-engineer | 001, 002 | Complete |

## Completion Summary

**Verified**: 2026-04-30 (see [verify.md](../verify.md))

- All 3 tasks: Complete
- All 14 automated ACs (AC-1..AC-14): PASS
- AC-15, AC-16: MANUAL (deferred to on-device check; code paths verified clean)
- Post-implementation refactor (2026-04-30): bottom-sheet → full-screen modal
  (`MaterialPageRoute(fullscreenDialog: true)` + `rootNavigator: true`). Spec/plan
  AC-3..AC-6 text revised in-place to reflect shipped behavior.

**Final test count**: 184/184 PASS · `dart analyze` clean · `flutter build apk --debug` SUCCESS

## Additions to Spec

None. The breakdown stays inside the file footprint declared in
`spec.md` §4 (Affected Areas) and `plan.md` §"File Impact".

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Pure ARB additions following the established pattern from features 006 / 008 / 009 / 010. `flutter gen-l10n` is deterministic. |
| 002 | Low | New stateless widget with one `Text` child and a co-located test. No state, no navigation, no providers. |
| 003 | Med | Convergence point: depends on Tasks 001 + 002, integrates the FAB into a live `Scaffold`, and is the integration gate for `flutter test` + `flutter build apk --debug`. The existing `meds_screen_test.dart` will need new groups added in the same task that introduces the FAB so the existing AppBar-shape assertions don't break. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 003 | Convergence (depends on 001 + 002) + layer-boundary integration + integration gate for the full feature | Confirm that (a) `AppLocalizations` exposes the two getters in all three locales, (b) `AddMedicationSheet` widget renders only one `Text` and zero interactive controls (Task 002 test green), (c) the screen-test additions cover the FAB tooltip in en/de/uk + tap-opens-sheet behavior, (d) no hard-coded colors slipped into the FAB or sheet code paths, (e) `flutter test` is green and `flutter build apk --debug` succeeds. |

## Contract Consistency Check

| Producer task | Produces | Consumed by |
|---------------|----------|-------------|
| 001 | `AppLocalizations.medsAddTitle` getter (en/de/uk) | 002 (sheet widget) |
| 001 | `AppLocalizations.medsAddFabTooltip` getter (en/de/uk) | 003 (screen FAB tooltip) |
| 002 | `AddMedicationSheet` widget class with `const` constructor | 003 (sheet builder) |

No orphaned Produces and no unsatisfied Expects. All upstream contracts
are consumed downstream and every downstream Expects has either a clear
upstream Produces or maps to existing pre-spec codebase state
(`floatingActionButtonTheme`, `lucide_icons_flutter`,
`l10n_extensions.dart`, ARB infrastructure).

## Acceptance Criteria Coverage

| AC | Covered by |
|----|------------|
| AC-1 (FAB present + Lucide plus + tooltip) | 003 |
| AC-2 (theme-driven colors, no explicit overrides) | 003 (verified by code review during the checkpoint) |
| AC-3 (tap opens `showModalBottomSheet`) | 003 |
| AC-4 (sheet has only one localized string, no buttons/fields) | 002 (widget structure test) |
| AC-5 (titleLarge style) | 002 (typography test) |
| AC-6 (`useSafeArea: true`, no other overrides) | 003 (call site) |
| AC-7 (3 ARB files have the keys) | 001 |
| AC-8 (en ARB has `@` description metadata) | 001 |
| AC-9 (no `!` at call sites) | 002 + 003 (both consume `context.l10n`) |
| AC-10 (`dart analyze` zero issues) | 001 + 002 + 003 (each task gates on `dart analyze`) |
| AC-11 (existing screen test extended) | 003 |
| AC-12 (new sheet widget test) | 002 |
| AC-13 (`flutter test` passes) | 003 (integration gate) |
| AC-14 (`flutter build apk --debug`) | 003 (integration gate) |
| AC-15 (manual theme toggle) | 003 (code path only); manual on-device verification deferred to /verify |
| AC-16 (manual locale toggle) | 003 (code path only); manual on-device verification deferred to /verify |
