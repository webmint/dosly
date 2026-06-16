## Feature Summary: 031 — Add-Medication Modal Section Dividers & Title/Spacing Alignment

### What was built
The Add-medication modal now matches the HTML design template's structure: the form is split into
three clear visual groups ("what medicine" → "when" → "type") separated by two full-bleed hairline
dividers, with muted section-title labels and corrected spacing throughout. A purely visual polish
pass — no behavior, data, or persistence changed; Save remains a no-op pending the data-save iteration.

### Changes
- Task 001: Full-bleed dividers, group restructure, section-title restyle & spacing — replaced the
  single outer 16px padding with three padded group columns separated by two edge-to-edge `Divider`s
  (new `_sectionDivider` helper); muted the two section titles to `onSurfaceVariant`; added a 24px
  bottom spacer; corrected stock-card, chip, and grid-card spacing constants.
- Task 002: Widget tests for dividers & section-title color — added 3 tests (2 dividers present,
  divider `thickness`/`outlineVariant`, titles `onSurfaceVariant`); existing suite unchanged.

### Files changed
- `lib/features/meds/presentation/widgets/` — 1 file modified (add_medication_modal.dart)
- `test/features/meds/presentation/widgets/` — 1 file modified (+3 tests)
- `specs/031-add-med-dividers/` + `research/` — feature artifacts (spec, plan, tasks, review, research)

[Source/test: 2 files changed. Full branch diff: 11 files, 1021 insertions, 151 deletions
(includes spec/plan/task/research artifacts).]

### Key decisions
- Full-bleed mechanism: outer un-padded `Column` with per-group horizontal `Padding` and dividers as
  direct children (`indent`/`endIndent` default 0) — keeps content's 16px inset while dividers reach
  the edges; chosen over negative-margin hacks or per-child padding wrappers.
- Divider style via a `_sectionDivider(ColorScheme)` helper (`Padding(top:4,bottom:8) → Divider(1px,
  outlineVariant)`) to match the template's `.s-div` exactly and stay DRY across both call sites.
- Section titles muted to `onSurfaceVariant`; card headers (`_StockCard`/`_CourseCard`) deliberately
  left at `onSurface` (they map to the template's `.sc-head`/`.cc-head`, not `.fs-title`).

### Acceptance criteria
- [x] AC-1: Exactly two section dividers, present regardless of selected form / course state
- [x] AC-2: Dividers full-bleed (edge-to-edge); text content keeps its 16px inset
- [x] AC-3: Each divider 1px, `outlineVariant`, ~4px above / ~8px below
- [x] AC-4: Section titles render `onSurfaceVariant`
- [x] AC-5: 12px below + ~4px above each section title
- [x] AC-6: `_StockCard`/`_CourseCard` headers unchanged (`onSurface`)
- [x] AC-7: ~24px space below the Save button
- [x] AC-8: Stock card header→note gap = 8px
- [x] AC-9: Form-option chip padding = 12/10
- [x] AC-10: Form-picker grid card padding = `fromLTRB(12,12,12,14)`
- [x] AC-11: No behavior/content regression — `flutter test` 332/332, `dart analyze` clean
- [x] AC-12: No new l10n keys; titles reuse `medsAddTimeTitle` / `medsAddIntakeTypeTitle`
