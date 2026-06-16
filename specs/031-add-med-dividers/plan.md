# Plan: Add-Medication Modal — Section Dividers & Title/Spacing Alignment

**Date**: 2026-06-16
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

A presentation-only restructure of `add_medication_modal.dart`'s build tree. The single outer
`Padding(EdgeInsets.all(16))` is replaced by a **three-group layout** (matching the template's three
`.form-sec` blocks): each group carries its own horizontal inset, and two **full-bleed `Divider`s**
sit between the groups as direct stretch-children of the outer `Column`. The two section-title labels
are restyled to the muted `.fs-title` token, and four spacing values are corrected. No domain/data
layers, no new dependencies, no behavior change.

## Technical Context

**Architecture**: Presentation only (`lib/features/meds/presentation/widgets/`). No domain/data touch.
**Error Handling**: N/A — no fallible operations introduced (pure layout).
**State Management**: Unchanged — all existing local `State` (controllers, `_selectedForm`,
`_intakeTimes`, `_intakeType`, `_startDate`) is preserved verbatim.

## Constitution Compliance

- **§2.1 Layer boundaries** — compliant: change confined to `presentation/widgets/`; no new imports, no
  `data/`/`domain/` access.
- **§ Strict lint** (no `!`, no `dynamic`) — compliant: layout uses tokens + const widgets only.
- **No hardcoded colors** — compliant: dividers/titles consume `colorScheme.outlineVariant` /
  `colorScheme.onSurfaceVariant`.
- **Document new code** — the new private `_sectionDivider` helper gets dartdoc; the library-level
  header comment is updated to describe the three-group layout.
- **No print/debugPrint, no bare TODOs** — compliant.
- **Minimal changes** — compliant: edits localized to one file's `build` + three widgets; tests add
  assertions only.

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain | none | — |
| Data | none | — |
| Presentation | Restructure modal body into 3 groups + 2 dividers; restyle section titles; fix 4 spacing values; add `_sectionDivider` helper + dartdoc | `lib/features/meds/presentation/widgets/add_medication_modal.dart` |
| Test | Add assertions: 2 `Divider`s present + style; section-title color = `onSurfaceVariant`; existing tests unchanged | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` |

### Target body structure

```
SingleChildScrollView
└─ Column(crossAxisAlignment: stretch)
   ├─ Padding(fromLTRB(16,16,16,8))            // GROUP A — "what medicine"
   │  └─ Column(stretch): name field
   │                      SizedBox(16) + form picker
   │                      if hasDose:     SizedBox(16) + _DoseField
   │                      if hasQuantity: SizedBox(16) + _QuantityStepper
   │                      if hasStock:    SizedBox(16) + _StockCard
   ├─ _sectionDivider()                         // DIVIDER A — full-bleed
   ├─ Padding(fromLTRB(16,0,16,8))             // GROUP B — "when"
   │  └─ Column(stretch): SizedBox(4) + title(onSurfaceVariant)
   │                      SizedBox(12) + _TimeChips
   ├─ _sectionDivider()                         // DIVIDER B — full-bleed
   └─ Padding(fromLTRB(16,0,16,0))             // GROUP C — "type" + save
      └─ Column(stretch): SizedBox(4) + title(onSurfaceVariant)
                          SizedBox(12) + SegmentedButton
                          if course: SizedBox(16) + _CourseCard
                          SizedBox(16) + Save FilledButton.icon
                          SizedBox(24)          // bottom spacer (.sp)
```

`_sectionDivider` helper:
```dart
/// Full-bleed section divider matching the template's `.s-div`
/// (1px outlineVariant hairline, 4px above / 8px below, edge-to-edge).
Widget _sectionDivider(ColorScheme colorScheme) => Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
    );
```
Because the divider is a direct child of the outer (un-padded) `Column` with default zero
`indent`/`endIndent`, it spans the full scroll-viewport width → full-bleed. Content keeps its 16px
inset via each group's `Padding`.

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Full-bleed mechanism | Three groups each with `Padding(horizontal:16)`; dividers are un-padded `Column` children | Idiomatic Flutter; maps 1:1 to template's 3 `.form-sec` blocks; content width unchanged (no input-decorator regression) | **OverflowBox/negative-margin escape** (non-idiomatic, fragile); **per-child `_hPad()` on all ~10 children** (verbose, scatters inset) |
| Divider widget | `Divider(height:1, thickness:1, color: outlineVariant)` wrapped in `Padding(top:4,bottom:8)`, via `_sectionDivider` helper | Matches `.s-div` exactly; DRY across both; `find.byType(Divider)` testable | **Bare `Divider()`** (M3 defaults: wrong color, centered ~16px height); **`Container(height:1)`** (not a `Divider` → weaker semantics/testability) |
| Section-title style | `titleSmall.copyWith(color: onSurfaceVariant)`; `SizedBox(4)` above, `SizedBox(12)` below | Matches `.fs-title` (muted, pt:4, mb:12); minimal diff | New custom `TextStyle` (over-engineered); leaving onSurface (rejected by spec AC-4) |
| Card headers | Left unchanged (`_StockCard`/`_CourseCard` stay `titleSmall`/`onSurface`) | They map to `.sc-head`/`.cc-head` (full emphasis), not `.fs-title` | Applying muted color to all headers (would diverge from template) |
| Bottom spacer | `SizedBox(height:24)` after Save inside Group C | Matches `.sp`; survives the removed outer bottom padding | Group C `padding bottom:24` (works, but explicit SizedBox reads clearer next to Save) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | (a) `build` ~1262–1398: replace outer `EdgeInsets.all(16)` with 3 `Padding`-wrapped group `Column`s + 2 `_sectionDivider()` calls; (b) add `_sectionDivider` helper + dartdoc; (c) section titles (Time ~1329, Intake-type ~1343): `copyWith(color: onSurfaceVariant)`, 4px above, gap 8→12; (d) add `SizedBox(24)` after Save; (e) `_StockCard` head→note `SizedBox(4)`→`SizedBox(8)` (~641); (f) `_buildChip` padding `h10,v8`→`h12,v10` (~414); (g) `_buildGrid` card padding `fromLTRB(12,10,12,12)`→`(12,12,12,14)` (~378); (h) update library header dartdoc to describe 3-group layout |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Add a structure test: `find.byType(Divider)` → 2, each `thickness==1`/`color==outlineVariant`; add title-color test (`onSurfaceVariant`). Existing tests remain unchanged |

Note (discovered during planning): `_buildGrid` card padding (item g) and `_buildChip` padding (item f)
are inside `_MedicationFormPicker`, which the spec's Affected Areas already lists. No files outside the
spec's Affected Areas are touched.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/meds.md` | Update (at `/finalize`, via tech-writer) | Reflect the add-med modal's three-group layout + section dividers and the muted section-title styling, if it documents the modal's visual structure |

`docs/architecture.md` — no change (no architectural pattern change). API docs — N/A (local-only app).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Moving outer padding into groups shifts form-picker `InputDecorator` floating-label alignment | Low | Medium | Content width is unchanged (still 16px inset both sides); run full `flutter test` + visual sanity on the picker |
| Existing widget tests depend on tree shape | Low | Medium | Audited: finders are semantic (`byType`/`text`/`byKey('medsAdd*')`), not pixel/`SizedBox` offsets — restructure is transparent to them (AC-11) |
| Divider M3 defaults diverge from `.s-div` | Low | Low | Explicit `height`/`thickness`/`color` in helper; asserted in new test (AC-3) |
| `find.byType(TextField)` singleton assertion (test line 130) breaks if a TextField is added | Low | Low | No TextField added; name field stays the only one when no form selected |

## Dependencies

None. No packages to install, no config, no env vars. Uses existing Flutter Material (`Divider`) and
the app's `ColorScheme` tokens.

## Plan ↔ Spec Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (two dividers, always present) | 2× `_sectionDivider()` as `Column` children, outside conditionals; new `find.byType(Divider)==2` test |
| AC-2 (full-bleed vs 16px content inset) | Dividers un-padded in `Column`; groups wrapped in `Padding(horizontal:16)` |
| AC-3 (1px, outlineVariant, 4/8) | `_sectionDivider` helper params; new style assertion |
| AC-4 (title color onSurfaceVariant) | `titleSmall.copyWith(color: onSurfaceVariant)` on both section titles; new color test |
| AC-5 (12px below, 4px above title) | `SizedBox(4)` above + `SizedBox(12)` below each title |
| AC-6 (card headers unchanged) | `_StockCard`/`_CourseCard` headers untouched (design decision row) |
| AC-7 (~24px below Save) | `SizedBox(24)` after Save in Group C |
| AC-8 (stock head→note 8px) | `SizedBox(4)`→`SizedBox(8)` in `_StockCard` |
| AC-9 (chip padding 12/10) | `_buildChip` padding update |
| AC-10 (grid card padding 12/12/12/14) | `_buildGrid` padding update |
| AC-11 (no regression, tests pass, analyze clean) | Semantic-finder audit; behavior/state untouched; run `flutter test` + `dart analyze` |
| AC-12 (no new l10n) | Titles reuse `medsAddTimeTitle`/`medsAddIntakeTypeTitle`; no `.arb` edits |

All 12 ACs have a concrete implementation path.

## Supporting Documents

- Research (pre-spec): `research/2026-06-16-add-med-modal-fidelity.md`
- No `research.md` (no signals), `data-model.md` (no entities), or `contracts.md` (no API) — not applicable.
