# Research: Add-Medication Modal — Template Fidelity (spacing & dividers)

**Date**: 2026-06-16
**Topic**: Compare the finished Add-Medication modal against the full HTML template; find differences in spacing, horizontal dividers, etc.
**Verdict**: Feasible — small, localized visual-polish gap in a single file (`add_medication_modal.dart`). No architecture impact.
**Decision captured**: Dividers should be **true full-bleed** (edge-to-edge), matching `.s-div`. This requires moving the 16px horizontal padding from the outer wrapper into each section.

## Summary

The Flutter modal (`lib/features/meds/presentation/widgets/add_medication_modal.dart`) faithfully
reproduces every *content* element of the template's "ADD / EDIT MEDICATION" screen
(`dosly_m3_template.html`, `#s-add`, lines 1986–2239): name field, form picker, dose/qty/stock,
time chips, intake-type segmented control, course card, save button — all present and in the right
order.

The gap is **structural separation and vertical rhythm**, not content. The template groups the form
into three visual blocks using two **full-bleed horizontal dividers** (`.s-div`). The Flutter build
has **zero dividers** — every section is separated by a uniform `SizedBox(height: 16)`. Section-title
styling and a few spacing values also drift from the design tokens. All differences live in one file;
this is a polish pass, not a feature.

## The headline finding: two missing section dividers

The template separates the form into 3 groups with full-bleed hairline dividers:

```
┌ Group A ──────────────────────────────┐
│ Name → Form picker → Dose/Qty/Stock   │
└───────────────────────────────────────┘
══════════ s-div (full-bleed) ══════════   ← MISSING in Flutter
┌ Group B ──────────────────────────────┐
│ Час прийому (Time chips)              │
└───────────────────────────────────────┘
══════════ s-div (full-bleed) ══════════   ← MISSING in Flutter
┌ Group C ──────────────────────────────┐
│ Тип прийому (segmented + course card) │
└───────────────────────────────────────┘
   (no divider before Save)
   Save button
```

- **Divider 1** — HTML line 2152, between the form-dependent fields and the Time section.
- **Divider 2** — HTML line 2186, between the Time section and the Intake-type section.
- **Style** (`.s-div`, CSS line 1211): `height: 1px; background: var(--md-outline-variant); margin: 4px 0 8px;`
  → edge-to-edge (no 16px inset), 4px above / 8px below.

In Flutter these two boundaries are just `const SizedBox(height: 16)` (lines 1328 and 1342). No
visual separation at all.

> ⚠️ The template uses two different divider styles; pick the right one. `.divider` (CSS line 774,
> used on the History screen) is **inset 16px** (`margin: 0 16px`). `.s-div` (the Add screen) is
> **full-bleed**. Don't reuse the inset one here.

## The full-bleed approach (padding model) — chosen direction

The Flutter body wraps the whole column in a single `Padding(EdgeInsets.all(16))` (line 1264), so
everything — including any divider dropped in — is inset 16px on both sides. A plain `Divider()` here
would NOT match the design's edge-to-edge look.

The template achieves full-bleed by giving the scroll container no horizontal padding and letting each
`.form-sec` supply its own `padding: 8px 16px` (CSS line 780), while `.s-div` (a direct child, no
padding) spans the full width.

**Chosen fix**: replace the outer `Padding(EdgeInsets.all(16))` with vertical-only outer padding (or
none) and apply `EdgeInsets.symmetric(horizontal: 16)` per content section, leaving the two dividers
to span edge-to-edge. Match `.s-div` with `Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant)`
and the 4px-above / 8px-below margins (e.g. wrap or use `SizedBox`/`Padding`).

## Other spacing / styling differences

| # | Element | Template (HTML/CSS) | Flutter | Severity |
|---|---------|---------------------|---------|----------|
| 1 | Section dividers | 2× full-bleed `.s-div` | none (`SizedBox(16)`) | High |
| 2 | Section title color | `.fs-title` → `--md-on-surface-variant` (muted) — CSS 870 | `titleSmall`, default `onSurface` (full emphasis) — lines 1330, 1344 | Medium |
| 3 | Title → content gap | `.fs-title` `margin-bottom: 12px` (+`padding-top: 4px`) | `SizedBox(height: 8)` — lines 1333, 1347 | Low |
| 4 | Bottom breathing room | Save `form-sec` + `.sp` 24px ≈ 32px below button (CSS 1416) | only outer `Padding` bottom = 16px; last `SizedBox(16)` is above the button | Low |
| 5 | Stock card head → note | net ~8px (`.sc-head` mb 12 + `.sc-note` mt −4) | `SizedBox(height: 4)` — line 641 | Low |
| 6 | Form-option chip padding | `.fpg-opt` `padding: 10px 12px` (CSS 847) | `symmetric(horizontal: 10, vertical: 8)` — line 414 | Low |
| 7 | Grid card padding | `12px 12px 14px` (CSS 831) | `fromLTRB(12, 10, 12, 12)` — line 378 | Low |
| 8 | Default intake type | template demo shows Course pre-selected | defaults to Continuous — line 1015 | Info (sensible default; likely intentional) |

Notes:
- Items 2–3 are the most visible after the dividers: the design's section labels ("Час прийому",
  "Тип прийому") are a muted, smaller-feeling caption; Flutter renders them at full `onSurface`
  emphasis with a tighter gap.
- The course info-chip's `margin-top: -4px` (CSS 987) nets to ~12px below the date field — Flutter's
  `SizedBox(height: 12)` already matches, so no change needed there. ✅
- Form-picker grid gap (7px), grid title gap (10px), and chevron rotation already match. ✅

## Constitution & architecture check

| Rule | Impact |
|------|--------|
| §2.1 layer boundaries | None — change is confined to one `presentation/widgets/` file. |
| Visual-only iterations (specs 026–030) | Consistent — dividers were never in scope; each spec built one widget, the connective tissue was deferred. |
| DRY / KISS | A small `_SectionDivider` helper (or shared full-bleed divider) avoids repeating the edge-to-edge trick twice. |

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | One file; add 2 dividers, adjust title color/gap, restructure padding for full-bleed. |
| New dependencies | None | Pure widget composition. |
| Risk | Low | Visual-only; existing widget-test key selectors (`medsAdd*`) are unaffected. Verify with `flutter test`. |

## Recommendation

Proceed — focused visual-fidelity fix. Two reasonable paths:

- `/fix "Add-medication modal: add the two full-bleed section dividers and align section-title color/spacing to the HTML template"`
  — best fit: single file, localized, behavior-preserving. Lead with the dividers (#1) + title styling
  (#2–3); fold in the minor spacing nits (#4–7) for a clean sweep.
- `/specify` — only if you'd rather track this as a formal visual-polish iteration (e.g. "spec 031 —
  add-med layout/dividers") with acceptance criteria, consistent with how 026–030 were run.

Implementation note (decided): use **true full-bleed** dividers — move the 16px horizontal padding from
the outer wrapper into each section so the dividers span edge-to-edge, exactly matching `.s-div`.
