# Research: Conditional Quantity & Stock Controls on the Add-Medication Form

**Date**: 2026-06-14
**Topic**: "Almost each type of medication has quantity control and stock control. I need to implement that. Design in the root HTML file."
**Verdict**: Feasible — clean fit, with one prerequisite refactor and a scope decision (visual-only vs. real persistence).
**Chosen direction**: Option A — visual-only conditional fields (iteration 3), Save stays a no-op.

## Summary

The design (`dosly_m3_template.html`) drives **form-dependent input fields**: the medication form you pick (tablet, capsule, injection…) decides which of three controls appear — a **dose field** (liquids), a **quantity-per-intake stepper** (tablet/capsule), and a **stock card** (tablet/capsule). This is a natural iteration 3 of the add-med form after 026 (name) and 027 (form picker). It fits the existing widget cleanly. The one architectural prerequisite: the selected form currently lives as **private state inside `_MedicationFormPicker`** — it must be hoisted to the parent modal so the conditional fields can react to it. Decision taken: keep this **visual-only** (consistent with 026/027, Save stays a no-op); persistence is deferred to a later data-save spec.

## Discrepancy to note

The original phrasing — *"almost each type has quantity + stock"* — doesn't match the design's actual matrix. Per the HTML's `FORM_FIELDS` config (line 2730), **only tablet and capsule** get quantity + stock. The real mapping:

| Form | Dose field | Qty stepper | Stock card | Dose units |
|------|:--:|:--:|:--:|------|
| **tablet** | — | yes (step 0.5, min 0.5, "табл") | yes | — |
| **capsule** | — | yes (step 1, min 1, "капс") | yes | — |
| **injection** | yes | — | — | мл, мг, од |
| **syrup** | yes | — | — | мл |
| **drops** | yes | — | — | краплі, мл |
| **inhaler** | — | — | — | — |
| **cream** | — | — | — | — |
| **sachet** | — | — | — | — |

So it is really *three* mutually-influenced controls, of which qty+stock is the tablet/capsule pair. Recommendation: implement the whole conditional block together (dose included) since they share one mechanism — otherwise liquids get no dose input at all.

## What the design specifies (extracted from HTML)

**Quantity stepper** (`#qty-row`, CSS line 622, JS line 2864):
- Outlined 56px row: `[−]  value  unit  [+]` with a floating "Кількість на прийом" label.
- `QTY_CONFIG`: tablet → step 0.5 / min 0.5 / "табл"; capsule → step 1 / min 1 / "капс".
- Value is a `double`; display drops the decimal when whole (`1`, not `1.0`).
- Constitution §5.1 already names this idiom: *"In Flutter: Row with IconButton(−) + Text + IconButton(+), value stored as double."*

**Stock card** (`#stock-row`, CSS line 1213, HTML line 2127):
- Card with header "Залишок у пачці" + note *"auto-decreases after each intake."*
- Three inputs: **Залишок** (remaining), **Всього в пачці** (total in pack), **Попередити коли лишиться** (low-stock warning threshold, with a warning trailing icon).
- The list/detail screens render `.med-stock` and turn it red (`--md-error`) when stock is low (CSS line 511) — so stock has a **consumption + display** side beyond the form (out of scope for the visual-only form iteration).

**Dose field** (`#dose-row`, HTML line 2088): text input + a unit dropdown populated per-form.

## Codebase findings

| Area | File | Relevance |
|------|------|-----------|
| Add-med form (target) | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Where everything lands. Has name field + form picker + no-op Save. |
| Form picker | `_MedicationFormPicker` (same file) | **Selection is private `_selectedIndex` state.** Must be hoisted to drive conditional fields. The `key` strings (`'tablet'`…) already match the planned domain enum. |
| l10n | `lib/l10n/*.arb` (en/de/uk…) | `medsAddForm*` keys exist. New keys needed for qty/stock/dose labels + units. |
| Failures | `lib/core/error/failures.dart` | `ValidationFailure` ready for when validation is wired. |

### Critical gaps (current architecture vs. constitution)
- **No medication domain/data layer exists.** `lib/features/meds/` has only `presentation/`. No `Medication` entity, no `Dosage` value object, no repository.
- **No `drift` database.** Despite the constitution mandating drift, `pubspec.yaml` has no `drift` dependency and `lib/core/` has no `database/`. Persistence so far is SharedPreferences (settings only).
- **Save is a no-op by design.** Both 026 and 027 explicitly defer persistence to a future *"data-save iteration"* (per the modal's own dartdoc).

## Constitution constraints

| Rule | Impact |
|------|--------|
| §3.1 No `!`, no `dynamic`, exhaustive `switch` | Form→fields mapping must be an exhaustive `switch` over the form enum, no `default:`. |
| §3.1 Typed value objects; freezed entities | Real persistence ⇒ `Quantity`/`StockInfo` value objects + `freezed` model (deferred). |
| §5.1 `Dosage` unit enum | Design units (мл/мг/од/краплі) must reconcile with the constitution's `DoseUnit` when persistence lands. |
| §6.1 Minimal changes | Hoisting form selection touches the picker — scope it as a deliberate refactor, not incidental. |
| Save-as-no-op precedent (026/027) | A visual-only iteration 3 is fully consistent with project history. |

## Approaches

### Option A — Visual-only conditional fields (iteration 3) — CHOSEN
Hoist the selected form to the modal; render dose/qty/stock conditionally via a `switch` on the form; stepper & inputs hold local state; Save stays a no-op.
- **Pros**: Matches 026/027 exactly. Small, reviewable. No new deps. Unblocks the full UI.
- **Cons**: No data saved yet (but neither is name/form today — consistent).
- **Complexity**: Low–Medium. ~1 widget file + l10n keys + the picker hoist.

### Option B — Visual + domain value objects (no persistence)
Option A, plus introduce pure-Dart `Quantity` / `StockInfo` value objects with validation, exercised by the form but not persisted.
- **Pros**: Starts the domain layer correctly; testable business rules.
- **Cons**: Half-built layer with no repository can rot; YAGNI risk before persistence exists.
- **Complexity**: Medium.

### Option C — Full persistence (form → drift → list/detail consumption)
Add `drift`, build the `Medication` domain+data layer, real Save, and the auto-decrement-on-intake + low-stock display.
- **Pros**: Delivers the complete feature including the consumption/display side.
- **Cons**: Large. Pulls in the entire unbuilt data foundation. Crosses into intake/adherence. Far beyond "a form field."
- **Complexity**: High.

**Selected**: Option A — the precedent-consistent next step; isolates the persistence question (Option C) into its own future spec, exactly as 026/027 intended.

## Complexity assessment

| Dimension | Rating | Notes |
|-----------|:--:|------|
| Codebase changes | Low–Med | One widget file + l10n; the form-selection hoist is the only structural change. |
| New dependencies | None | Option A uses existing Flutter widgets only. |
| Risk | Low | Mainly: exhaustive form→field `switch` and the stepper `double` formatting. |

## Recommendation / next step

Proceed with the visual-only iteration (Option A):

```
/specify "Add-medication form iteration 3: form-dependent input fields.
Hoist the selected medication form out of _MedicationFormPicker to the modal.
Based on the form, conditionally render: a dose field + unit dropdown (injection/syrup/drops),
a quantity-per-intake stepper (tablet: step 0.5/min 0.5; capsule: step 1/min 1),
and a stock card (remaining, total-in-pack, low-stock warning threshold) for tablet/capsule only.
Visual-only — Save remains a no-op, matching specs 026/027. Persistence deferred to a later data-save spec."
```

`/specify` will likely ask: (a) include the dose field now or qty+stock only, (b) whether to localize the Ukrainian-only unit strings across all locales, and (c) confirm Save stays a no-op.
