# Spec: Add-Medication Modal — Section Dividers & Title/Spacing Alignment

**Date**: 2026-06-16
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

The Add-medication modal reproduces every content element of the HTML design template
(`dosly_m3_template.html`, `#s-add`), but omits the two **full-bleed horizontal dividers** that the
template uses to group the form into three visual blocks, and its section-title labels drift from the
template's styling. This spec brings the modal's structural separation and vertical rhythm into line
with the template: add the two dividers (true edge-to-edge), align the two section-title labels to the
muted `.fs-title` style, and correct a small set of spacing values. It is a **visual-only** change —
no behavior, persistence, or content is added or removed.

This work is grounded in `research/2026-06-16-add-med-modal-fidelity.md`.

## 2. Current State

**Existing codebase.** The entire Add-medication flow lives in one file:
`lib/features/meds/presentation/widgets/add_medication_modal.dart` (visual-only iterations,
specs 026–030; Save is an intentional no-op).

The modal body (lines 1262–1398) is:

```
SingleChildScrollView
└─ Padding(EdgeInsets.all(16))          ← single outer inset on ALL sides (line 1264)
   └─ Column(crossAxisAlignment: stretch)
      1. TextField (name)                                              line 1268
      2. SizedBox(height: 16)                                         line 1277
      3. _MedicationFormPicker                                        line 1281
      4. if hasDose:     SizedBox(16) + _DoseField                    lines 1291–1303
      5. if hasQuantity: SizedBox(16) + _QuantityStepper             lines 1306–1315
      6. if hasStock:    SizedBox(16) + _StockCard                    lines 1318–1325
      7. SizedBox(16) + Time title (titleSmall) + SizedBox(8) + _TimeChips   lines 1328–1339
      8. SizedBox(16) + Intake-type title (titleSmall) + SizedBox(8) + SegmentedButton  lines 1342–1367
      9. if course:      SizedBox(16) + _CourseCard                   lines 1370–1383
      10. SizedBox(16) + Save FilledButton.icon                       lines 1385–1393
```

Relevant current facts:
- **No dividers anywhere.** Sections are separated only by uniform `const SizedBox(height: 16)`.
- **Single outer horizontal inset.** `Padding(EdgeInsets.all(16))` insets *everything* (content and
  any future divider) 16px on both sides — so a divider added inside the `Column` cannot reach the
  screen edges.
- **Section titles** ("Час прийому" / Time, line 1329; "Тип прийому" / Intake-type, line 1343) use
  `Theme.of(context).textTheme.titleSmall` with **default color** (`onSurface`, full emphasis) and a
  `SizedBox(height: 8)` gap below.
- **Card headers** `_StockCard` (`titleSmall`, line 638) and `_CourseCard` (`titleSmall`, line 830)
  are distinct from section titles — they correspond to the template's `.sc-head` / `.cc-head`
  (full-emphasis `onSurface`), **not** `.fs-title`.
- **Stock card** head→note gap is `SizedBox(height: 4)` (line 641).
- **Form-option chip** padding is `EdgeInsets.symmetric(horizontal: 10, vertical: 8)` (line 414).
- **Form picker grid card** padding is `EdgeInsets.fromLTRB(12, 10, 12, 12)` (line 378).
- **Below the Save button**: nothing except the outer `Padding` bottom (16px).
- Section titles already use l10n keys `medsAddTimeTitle` and `medsAddIntakeTypeTitle` — no new
  strings are required.

**Template reference** (`dosly_m3_template.html`):
- `.s-div` (CSS line 1211): `height: 1px; background: var(--md-outline-variant); margin: 4px 0 8px;`
  → **full-bleed** (no horizontal inset), 4px above / 8px below. Used at HTML lines 2152 and 2186.
- `.divider` (CSS line 774): `margin: 0 16px;` → **inset 16px**. Used on the History screen only —
  **must not** be the style used here.
- `.fs-title` (CSS line 870): `font: 500 14px/20px; color: var(--md-on-surface-variant);
  letter-spacing: .1px; padding-top: 4px; margin-bottom: 12px;`
- `.sp` (CSS line 1416): `height: 24px;` (bottom spacer after Save).
- `.sc-note` (CSS line 1228): nets ~8px below `.sc-head`.
- `.fpg-opt` (CSS line 847): `padding: 10px 12px;` (vertical 10, horizontal 12).
- `.form-picker-grid-card.visible` (CSS line 831): `padding: 12px 12px 14px;`.

## 3. Desired Behavior

1. **Two full-bleed section dividers** are rendered in the modal body:
   - **Divider A** between the form-dependent fields group (dose/quantity/stock) and the Time section
     (replaces the current `SizedBox(16)` boundary at line 1328).
   - **Divider B** between the Time section and the Intake-type section (replaces the boundary at
     line 1342).
   - Each divider spans the **full width of the scroll viewport** (edge-to-edge, no 16px horizontal
     inset), matching `.s-div`.
   - Each divider is **1px** thick, colored `colorScheme.outlineVariant`, with **~4px space above**
     and **~8px space below**.
   - Dividers are always present regardless of which medication form is selected or whether the
     course card is expanded.

2. **Full-bleed padding model.** Restructure the body so dividers reach the screen edges while
   text/content **retains its 16px horizontal inset**. (The single outer `EdgeInsets.all(16)` is
   replaced by a model where horizontal inset is applied to content sections, not to the dividers.)

3. **Section-title alignment** (Time + Intake-type labels only):
   - Color → `colorScheme.onSurfaceVariant` (muted), confirmed target.
   - Gap **below** each title → **12px** (was 8px).
   - **~4px space above** each title (matching `.fs-title` `padding-top: 4px`).
   - `_StockCard` and `_CourseCard` headers are **unchanged** (remain `onSurface`).

4. **Bottom spacer.** Add **~24px** of space below the Save button (matching `.sp`).

5. **Stock card header→note gap** → **8px** (was 4px).

6. **Form-option chip padding** → `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`.

7. **Form picker grid card padding** → `EdgeInsets.fromLTRB(12, 12, 12, 14)`.

No content is added or removed; no logic, state, persistence, or Save behavior changes.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Add-medication modal body | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (`_AddMedicationModalState.build`, ~1262–1398) | Restructure padding for full-bleed; insert 2 dividers; restyle 2 section titles; add bottom spacer |
| Stock card widget | same file (`_StockCard.build`, ~641) | Head→note gap 4px → 8px |
| Form-option chip | same file (`_MedicationFormPicker._buildChip`, ~414) | Chip padding 10/8 → 12/10 |
| Form picker grid card | same file (`_MedicationFormPicker._buildGrid`, ~378) | Grid card padding → fromLTRB(12,12,12,14) |
| Widget tests | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Add assertions for divider count/style; existing tests must still pass |

## 5. Acceptance Criteria

- [x] **AC-1**: The modal body renders exactly **two** section dividers — one between the
  form-dependent fields and the Time section, one between the Time section and the Intake-type
  section — and both are present regardless of selected form or course-card expansion. (Testable:
  `find.byType(Divider)` returns 2 in a widget test.)
- [x] **AC-2**: Each divider is **full-bleed** — its width equals the scroll viewport width with **no
  16px horizontal inset** — while text content (name field, titles, cards) keeps its 16px horizontal
  inset. (Verifiable by reading the build tree and/or a layout/golden assertion.)
- [x] **AC-3**: Each divider is **1px** thick and colored `colorScheme.outlineVariant`, with ~4px
  space above and ~8px space below (per `.s-div`).
- [x] **AC-4**: The Time and Intake-type section-title labels render with color
  `colorScheme.onSurfaceVariant`.
- [x] **AC-5**: The gap directly below each section title is **12px**, and there is **~4px** space
  above each section title.
- [x] **AC-6**: `_StockCard` and `_CourseCard` headers are **unchanged** — they still render at
  `onSurface` emphasis (no muted color applied to card headers).
- [x] **AC-7**: There is **~24px** of space below the Save button (bottom breathing room).
- [x] **AC-8**: The `_StockCard` header→note vertical gap is **8px**.
- [x] **AC-9**: Each form-option chip uses padding `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`.
- [x] **AC-10**: The form-picker grid card uses padding `EdgeInsets.fromLTRB(12, 12, 12, 14)`.
- [x] **AC-11**: No behavior or content regression — Save remains a no-op; all existing widget tests
  pass unchanged; all existing `ValueKey('medsAdd*')` selectors remain valid; `dart analyze` is clean.
- [x] **AC-12**: No new l10n keys are introduced; section titles continue to use `medsAddTimeTitle`
  and `medsAddIntakeTypeTitle`.

## 6. Out of Scope

- NOT included: any change to Save behavior, persistence, state, or the visual-only nature of the form.
- NOT included: the History screen or any use of the inset `.divider` style elsewhere.
- NOT included: changing the default intake type (stays **Continuous**; the template's Course-selected
  state is demo-only).
- NOT included: new localization strings or any `.arb` edits.
- NOT included: form-picker behavior, time-chip logic, course date/info-chip logic, dropdowns, or
  any non-spacing styling of inputs.
- NOT included: theme/`ColorScheme` token changes in `core/theme/` — only existing tokens are consumed.
- NOT included: adding a divider before the Save button (template has none there).

## 7. Technical Constraints

- Must follow Clean Architecture §2.1 — change is confined to `presentation/widgets/`; pure widget
  composition, no new dependencies.
- Must use `ColorScheme` tokens (`outlineVariant`, `onSurfaceVariant`) — **no hardcoded colors**.
- Must obey strict lint mode — no `!` null-assertion, no `dynamic`, no `print`/`debugPrint`.
- Must be **behavior-preserving** for existing widget tests (refactoring of layout only).
- The full-bleed divider must match `.s-div`, **not** the inset `.divider`; if `Divider` is used, set
  `height`, `thickness`, and `color` explicitly (M3 defaults differ).
- All new/changed public widgets retain dartdoc; no bare TODOs.

## 8. Open Questions

- Exact full-bleed mechanism (per-section horizontal `Padding` vs. a layout wrapper that lets dividers
  escape the inset) is a `/plan` decision — the spec fixes only the visual outcome (AC-2).
- Whether to extract a small private `_SectionDivider` helper (DRY across the two dividers) is a
  `/plan`/implementation choice; not required by an AC.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Moving the outer 16px horizontal padding disturbs the form-picker floating label / `InputDecorator` alignment | Medium | Medium | Prefer per-section horizontal `Padding(16)` over removing inset; run full `flutter test` + visual check of the picker |
| `Divider` M3 defaults (indent/thickness/color) don't match `.s-div` | Low | Low | Set `height`/`thickness`/`color` explicitly; assert in widget test (AC-3) |
| Existing widget tests rely on exact `SizedBox`/offset structure | Low | Medium | Tests use `ValueKey('medsAdd*')` and type finders, not pixel offsets (AC-11); adjust only assertions that count widgets |
| Scope creep into other spacing nits | Low | Low | Out-of-scope list is explicit; ACs enumerate the exact spacing values |
