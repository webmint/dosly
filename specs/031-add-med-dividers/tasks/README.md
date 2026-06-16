# Tasks: Add-Medication Modal — Section Dividers & Title/Spacing Alignment

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-16
**Total tasks**: 2

## Dependency Graph

```
001 (source: dividers + restructure + titles + spacing) ──→ 002 (tests)
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Full-bleed dividers, group restructure, section-title restyle & spacing | mobile-engineer | None | Complete |
| 002 | Widget tests for dividers & section-title color | qa-engineer | 001 | Complete |

## Additions to Spec

None. All edits are confined to the two files in the spec's Affected Areas
(`add_medication_modal.dart` + its test). The form-option chip and grid-card padding changes live in
`_MedicationFormPicker`, already covered by the spec's Affected Areas.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Medium | Body restructure (outer padding → 3 padded groups + 2 full-bleed dividers) could shift the form-picker `InputDecorator` label alignment. Mitigated: content width unchanged (still 16px inset both sides); full `flutter test` + visual sanity. |
| 002 | Low | Additive tests only; existing semantic finders (`byType`/`text`/`byKey`) are unaffected by the restructure. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 001 | High-visual-risk restructure + first/only presentation change | Dividers are full-bleed (edge-to-edge) while content keeps 16px inset; section titles muted (`onSurfaceVariant`) with 4px-above/12px-below; card headers unchanged; Save still no-op; no l10n/behavior change. |

## Verification Summary

**Verified**: 2026-06-16 · **Verdict: APPROVED** · Spec status → Complete.
- Acceptance criteria: **12/12 PASS** (code-reading mode — `AC_VERIFICATION: off`).
- Code quality: `dart analyze` clean · `flutter test` 327/327 · build SKIP (heavy APK deferred;
  compilation validated by widget tests + analyze) · no scope creep · no leftover artifacts.
- Review: Security 0 Crit/0 High/0 Med/2 Info · Performance 0 High/0 Med/2 Low · Tests GAPS FOUND
  (non-blocking — AC-1 only baseline-tested; AC-6/AC-12 cheap-but-uncovered; AC-2/5/7/8/9/10 visual-only).
- Post-review gap-fill: AC-1 (form/course-expanded states), AC-3 (second divider), AC-6 (both card
  headers) closed via +5 tests (suite 327 → 332, all green). AC-12 locale guard + AC-2/5/7/8/9/10
  pixel spacing intentionally left to visual review.
- Cleanup: removed stale tracked `.claude/wip.md`.

## Contract Chain Integrity

- **001 Produces → 002 Expects**: `_sectionDivider`×2 / divider style / title color produced by 001 are
  consumed by 002's assertions. ✅
- **001 Produces → spec ACs**: the three spacing constants (stock gap, chip padding, grid padding) and
  the bottom spacer map directly to AC-8/AC-9/AC-10/AC-7. ✅
- **002 Produces → spec AC**: maps to AC-11. ✅
- No orphaned Produces; no unsatisfied Expects (001's Expects are current codebase state). ✅
