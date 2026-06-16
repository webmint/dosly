# Tasks: Add-Medication Intake-Type Control (visual-only, iteration 5)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-15
**Total tasks**: 3

## Dependency Graph

```
001 (l10n keys) ──→ 002 (widget + clock dep) ──→ 003 (widget tests)
```

Linear chain — each task gates the next. Task 002 is a review checkpoint (first presentation-layer task; carries the gen-l10n-plural, `withClock`, and `clock`-promotion risks).

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add intake-type & course l10n keys (en/uk/de) | mobile-engineer | None | Complete |
| 002 | Build the intake-type section in the modal (+ promote `clock`) | mobile-engineer | 001 | Complete |
| 003 | Widget tests for the intake-type section | qa-engineer | 002 | Complete |

## Additions to Spec

- **`pubspec.yaml`** — not in the spec's Affected-Areas table, but the spec (§2/§7) and plan call for promoting `clock` from a transitive to a direct dependency. Folded into Task 002 (its consumer) per the bundling rule rather than a standalone task.
- The `clock` promotion is the only infra change; everything else is presentation + l10n, matching the spec.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Med | First ICU-plural + first placeholder `@`-metadata in the project; Ukrainian `one/few/many/other` categories must be correct. Mitigated by exact metadata in the task + a uk-plural test in Task 003. |
| 002 | Med | First `clock` usage + `showDatePicker` + live-computed chip; gen-l10n method signature must match. Mitigated by the `theme_selector` SegmentedButton pattern, `_StockCard` shape, and `_addTime` await/`mounted` idiom to copy. |
| 003 | Low | Additive tests over a stable harness; only nuance is `withClock` zone wrapping and the date-picker dialog interaction. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 002 | Layer-boundary crossing (l10n → presentation) + highest-risk integration | Verify the gen-l10n plural method signature (`medsAddCourseRangeLabel(String, int)`) generated cleanly; `clock` promoted without version downgrades; `_CourseCard` matches `_StockCard` style; SegmentedButton mirrors `theme_selector` incl. the `selection.isEmpty` guard; Save still a no-op; no domain/data touched. |

## Contract Chain Integrity

- **001 Produces → 002 Expects**: the 9 `AppLocalizations` getters/methods are consumed by the widget. ✓
- **002 Produces → 003 Expects**: `SegmentedButton`, course-card gate, and the `ValueKey`s are consumed by the tests; `clock` direct dep enables `withClock` in tests. ✓
- **AC mapping**: 001 → AC-9/10/11 (strings); 002 → AC-1…AC-13; 003 → AC-3…AC-11 (uk)/AC-14.
- **Orphans**: none. Every Produces item is consumed downstream or maps directly to an AC. Every Expects item is either existing codebase state (l10n template, `_TimeChips`, `theme_selector`, transitive `clock`) or an upstream Produces.

## AC Coverage

All 14 ACs are covered: AC-1/2/12/13 by Task 002; AC-3…AC-10 by Tasks 002 (impl) + 003 (test); AC-9/10/11 strings by Task 001; AC-11 (uk plural) by Tasks 001 (impl) + 003 (test); AC-14 by the per-task `dart analyze`/`flutter test` gates + Task 003.

## Verification Summary (`/verify` 2026-06-15)

**Verdict: APPROVED.** All 14 ACs PASS (code-reading mode + `flutter test`). Code quality: `dart analyze` clean, 324/324 tests, no scope creep, no leftover artifacts, cross-task consistency PASS. Review: Security PASS (0 Critical/High/Medium, 5 Info); Performance clean (1 Low, deferred); Test coverage GAPS FOUND (non-blocking).

Non-blocking warnings (optional hardening, not AC failures):
- Test gaps: zero/negative duration boundary (Medium), German-locale plural (Medium — de strings exist, untested), controller-dispose assertion (Medium), AC-1/2/6-header/13 (Low).
- `clock` was hand-added to `pubspec.yaml` (should be `flutter pub add` — logged to MEMORY).
- `showDatePicker` window derives from `_startDate` rather than `clock.now()` (spec-accepted).

Spec status set to **Complete**. Ready for `/summarize` → `/finalize`.
