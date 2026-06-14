# Research: Add Medication-Form Picker to Add-Medication Modal (visual-only, iteration 2)

**Date**: 2026-06-13
**Topic**: Add a "medication form/type" picker (`.form-picker-display` + `.form-picker-grid-card` from the HTML template) to the add-medication form — UI only, same scope discipline as the last spec (026)
**Verdict**: Feasible

## Summary

This is a clean **iteration 2** of the add-medication form, directly following spec 026's visual-only pattern. The HTML design (`dosly_m3_template.html:783–869` styles, `:2011–2074+` markup) defines a two-part "form picker": a **56px outlined display row** (floating label, icon chip, selected-form name + sub-text, rotating caret) that toggles an **expanding grid card** of 8 medication-form options in a 2-column grid, with the selected option highlighted in `primary`. It maps cleanly onto Flutter's existing patterns — a tappable `Material`/`InkWell` row + an `AnimatedSize` grid of selectable chips, all driven by **local widget state** in the already-`StatefulWidget` modal. **No domain, data, or persistence** is touched (consistent with 026 and "just UI"). The only sizeable effort is **localization** of the 8 form labels (+ picker chrome strings) across the 3 ARB files. Verdict: feasible, low risk, recommended to proceed to `/specify`.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| The modal (target) | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Already a `StatefulWidget` (spec 026) with a scrollable padded `Column` body — the picker is a **new child inserted above/below the name field**. No structural conversion needed this time. |
| Name field + Save (reference) | same file, lines 64–81 | Establishes the exact pattern to follow: theme-driven decoration, `context.l10n` strings, Lucide icons, no call-site colors. |
| L10n (3-locale) | `lib/l10n/app_{en,de,uk}.arb`, `l10n_extensions.dart` | `medsAdd*` keys already exist; new form keys slot in identically. `@`-metadata only in `app_en.arb`; consume via `context.l10n`; regen with `flutter gen-l10n`. |
| Theme | `lib/core/theme/app_theme.dart` | `secondary-container` (icon chip), `primary-container` (grid card bg), `primary`/`on-primary` (selected option), `outline`/`on-surface-variant` — all design tokens already exist as M3 `colorScheme` roles. Zero call-site colors needed. |
| Icons | `lucide_icons_flutter: ^3.1.12` | Already the project icon set; the 8 form glyphs are Lucide SVGs (see mapping below). |
| HTML design source | `dosly_m3_template.html:783–876` (CSS), `2007–2074+` (markup) | The full picker spec: 8 forms, 2-col grid, selected-state, expand/collapse. |

### Patterns Available
- **Local UI state in the existing `StatefulWidget`** — the selected form (an `int` index or a small presentation enum) and the open/closed state are plain `setState` fields. No controller to dispose (unlike the name field), no Riverpod.
- **`AnimatedSize` / `AnimatedCrossFade`** — reproduces the HTML's `max-height .28s` expand/collapse of the grid card with built-in Flutter widgets.
- **`InkWell` + `AnimatedRotation`** — the tappable display row + the caret that rotates 180° when open.
- **Theme-driven selectable chips** — each `.fpg-opt` is a `Material`/`InkWell` whose background flips to `colorScheme.primary` and content to `onPrimary` when selected (mirrors `.fpg-opt.sel`).

### Gaps
- **No `MedicationForm` enum exists in `lib/`** — it appears only in MEMORY's "Domain Cheat Sheet" as the *planned* domain enum (`tablet, capsule, injection, syrup, drops, inhaler, cream, sachet`). For a UI-only iteration, the 8 options should be a **presentation-level list/record** inside the widget (key + l10n label + icon [+ optional sub-label]), **not** a domain entity — that lands in the future data-save iteration. (Open question below.)
- **8 new form-label strings (× 3 locales)** don't exist yet — this is the bulk of the work.

### Lucide icon mapping (from the HTML SVG paths)
| Form (UK / EN) | `data-form-key` | Likely Lucide name | Confidence |
|---|---|---|---|
| Таблетка / Tablet | `tablet` | `LucideIcons.pills` | High |
| Капсули / Capsule | `capsule` | `LucideIcons.pill` | High |
| Сироп / Syrup | `syrup` | `LucideIcons.milk` | High |
| Краплі / Drops | `drops` | `LucideIcons.droplets` | High |
| Ін'єкція / Injection | `injection` | `LucideIcons.syringe` | High |
| Інгалятор / Inhaler | `inhaler` | `LucideIcons.wind` | High |
| Крем / Мазь / Cream | `cream` | _needs name confirm_ (`container`?) | Low |
| Саше / Sachet | `sachet` | `LucideIcons.package` | Med |

> Same gotcha as spec 026's `LucideIcons.save`: verify each name compiles at execution time; `Icons.*` Material fallback is the sanctioned escape (MEMORY).

## Constitution Constraints

| Rule | Impact on This Idea |
|------|-------------------|
| §2.1/§4.2 presentation-only iteration | No `domain/` or `data/` code — the picker is local widget state. Forms list stays in `presentation/`. |
| No `!` null assertion (§4.2.1) | Strings via `context.l10n`; selection state is a non-null `int`/enum. |
| Theme-driven, no call-site colors (MEMORY F005) | All colors are `colorScheme` roles already defined in `app_theme.dart`. |
| Dartdoc on public widgets; document intentional no-ops | The new picker sub-widget(s) need `///`; if the selection still doesn't feed Save, keep the no-op comment referencing this spec. |
| `dart analyze` zero issues; no lint suppression | Standard gate; PostToolUse hook enforces. |
| Dispose hygiene | No new `TextEditingController` here — selection state needs no disposal. (`AnimationController` only if you hand-roll animation instead of `AnimatedSize`.) |

## Approaches

### Option A: Faithful custom picker (display row + animated expanding grid) — **Recommended**
- **Description**: Build the `.form-picker-display` row (icon chip, floating label, selected name + sub, rotating caret) as a tappable row that toggles an `AnimatedSize` grid card of 8 selectable option chips, with local `setState` for `selectedIndex` + `isOpen`.
- **Pros**: Pixel-faithful to the design; consistent with "same as last spec" intent; reuses only built-in Flutter widgets + existing theme tokens; no new deps.
- **Cons**: Most code of the three (~150–220 lines + l10n); custom selected-chip styling.
- **Complexity**: Medium.

### Option B: Standard M3 control (grid of `ChoiceChip`s, or `DropdownMenu`)
- **Description**: Replace the bespoke display-row+grid with a labelled `Wrap` of `ChoiceChip`s or a single `DropdownMenu<form>`.
- **Pros**: Least code; fully theme-native; trivial selection state.
- **Cons**: Abandons the design's distinctive expanding-grid + icon-chip-per-form look; diverges visibly from the HTML.
- **Complexity**: Low.

### Option C: Static display row only (no grid, no selection)
- **Description**: Render just the collapsed display row as decoration.
- **Pros**: Trivial.
- **Cons**: Pointless — the design's core interaction (choosing a form) is missing; not what "add the form picker" means.
- **Complexity**: Low.

**Recommended approach**: **Option A** — it honors the HTML design and the visual-only discipline of spec 026, keeps everything in `presentation/` with local state, and adds no dependencies. Option B is the fallback if you decide design fidelity isn't worth the extra code this iteration.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Medium** | One widget file (new picker sub-widget + wiring), 3 ARB files, generated bindings (regen), modal test. More than 026 due to the 8-option grid + collapse behavior. |
| New dependencies | **None** | Flutter built-ins + existing `lucide_icons_flutter` + existing theme. `pubspec.yaml` untouched. |
| Risk | **Low** | Local state only; no persistence; theme-driven colors; the one real watch-item is the 8 Lucide icon names (verify-at-compile, Material fallback). |

## Open Questions (to resolve in `/specify`)

1. **Sub-text per form?** The HTML shows a `.fpd-sub` / `data-sub` description (e.g. "Пресована форма"). Including it **doubles** the l10n keys (8 more). Include for fidelity, or omit to halve translation work?
2. **Forms data shape** — confirm a **presentation-only** list/record of 8 options (no domain `MedicationForm` enum yet), consistent with 026 touching only `presentation/`. Agree?
3. **Initial state** — picker starts **collapsed with no selection** ("Choose a form" placeholder), or pre-expanded / pre-selected to a default like Tablet (the HTML renders it open)?
4. **Save still no-op?** Confirm the selected form is **not** persisted or fed to Save this iteration (Save remains the documented no-op from 026).
5. **Animate the expand/collapse** (`AnimatedSize`, matching the `.28s` transition) or render static open/closed? (Minor.)

## Recommendation

**Proceed.** This is a well-scoped visual iteration that fits the architecture and the established 026 pattern with zero new dependencies and low risk.

```
Next steps:
- To proceed: /specify "Add the medication-form picker (display row + expanding 8-option grid from the HTML .form-picker-display/.form-picker-grid-card) to the add-medication modal — visual-only iteration 2, local selection state, no persistence, Save stays no-op"
- To narrow first: /research "medication-form picker — include per-form sub-text labels or not?"
- To shelve: no action needed
```
