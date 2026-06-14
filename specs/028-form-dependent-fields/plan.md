# Plan: Add-Medication Form-Dependent Fields (visual-only, iteration 3)

**Date**: 2026-06-14
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Hoist the selected form out of `_MedicationFormPicker` via a callback (picker keeps its own selection display; parent caches the selected `_MedFormOption`), then render three form-gated presentation widgets — `_DoseField`, `_QuantityStepper`, `_StockCard` — between the picker and the Save button, driven by per-form config attached to each `_MedFormOption`. All state is local `setState`; controllers live for the `State`'s lifetime and are cleared (not recreated) on form change. 14 localized keys are added across the 3 ARBs. No `domain/`, `data/`, persistence, or new dependencies.

## Technical Context

**Architecture**: `presentation/` only — one feature widget library (`add_medication_modal.dart`) plus l10n. No domain/data layers touched (consistent with specs 026/027).
**Error Handling**: N/A — no fallible operations; no `Either`/`Failure`, no repository. Visual-only, values discarded.
**State Management**: plain `StatefulWidget` + `setState` (no Riverpod / `ConsumerStatefulWidget`, per spec §6). Selection hoisted via a `ValueChanged` callback.

## Constitution Compliance

| Rule | Status | Notes |
|------|--------|-------|
| §2.1 layer boundaries | Compliant | Only `presentation/` + `l10n/` change; nothing added to `domain/`/`data/`. |
| §3.1 no `!`, no `dynamic` | Compliant | Selected form read via `_selectedForm?.x ?? false`; no null-assertions. |
| §3.1 exhaustive over forms (no `default:` that hides a case) | Compliant | Field visibility is **data-driven** — each of the 8 `_MedFormOption`s explicitly declares `hasDose/hasQuantity/hasStock` + units; there is no `switch`/`default` on a `String` key that could silently swallow a form. |
| §3.1 dispose controllers; `late` discipline | Compliant | All `TextEditingController`s are `final` State fields, disposed in `dispose()`. No `AnimationController` added (no animation in these fields). |
| §3.3 naming (`_UpperCamel` widgets, `lowerCamel` members) | Compliant | New private widgets `_DoseField`, `_QuantityStepper`, `_StockCard`; private fields `_doseController`, `_quantity`, etc. |
| §4.1.1 const constructors | Compliant | New widgets use `const` constructors; `_medFormOptions` stays non-const (holds closures — unchanged). |
| §4.3.1 tap targets ≥ 48dp | Compliant | Stepper −/+ are `IconButton`s (48dp default). |
| §4.2.1 no `print`/`debugPrint`; theme from `colorScheme` | Compliant | No logging; colors via `Theme.of(context).colorScheme` + global `inputDecorationTheme`. |
| §3.4 testing (presentation widget tests) | Compliant | New widget tests added; existing tests preserved (§ AC-13). |
| §6.1 minimal changes | Compliant | Callback hoist (not a full state-lift) keeps the picker diff minimal and 027 tests intact. |

**No violations.** The only judgment call is "exhaustive switch over enums" (§3.1) — not applicable here because the form is identified by a presentation `key` string, not a domain enum (no enum exists — out of scope). Exhaustiveness is achieved by attaching explicit field config to every option, so every form is configured by construction.

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain | — (none) | — |
| Data | — (none) | — |
| Presentation | Hoist callback; per-form field config on `_MedFormOption`; 3 new private field widgets; conditional rendering + reset logic; controllers | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (modify) |
| L10n | 14 new keys × 3 locales (+ `@`-meta in en) | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (modify) → `app_localizations*.dart` (regenerate) |
| Test | Conditional-field widget tests | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| **Hoist mechanism** | Picker keeps internal `_selectedIndex`/`_isOpen`; add `final ValueChanged<_MedFormOption> onFormSelected;`; call it in the chip `onTap`. Parent caches `_MedFormOption? _selectedForm`. | Smallest diff; preserves the picker's externally-observable behaviour verbatim → spec-027 tests pass unchanged (AC-1/13). Idiomatic uncontrolled-child-notifies-parent. | **Full state-lift** (parent owns index, picker becomes controlled) — larger refactor, higher risk to 027 tests. **Riverpod** — explicitly out of scope. |
| **Field-visibility data model** | Attach `bool hasDose/hasQuantity/hasStock`, `List<String Function(AppLocalizations)> doseUnits`, `double quantityStep/quantityMin`, `String Function(AppLocalizations)? quantityUnit` to each `_MedFormOption` (defaults: false/empty/1/1/null). | Single source of truth per form; mirrors the HTML `FORM_FIELDS`+`QTY_CONFIG`; DRY/KISS; no `switch` over strings. | **Separate parallel maps** keyed by string (`FORM_FIELDS`, `QTY_CONFIG`) — two structures keyed by the same form (DRY smell), risk of drift. |
| **Conditional value state** | Parent holds `double _quantity`, `int _selectedDoseUnitIndex`, and 4 `final TextEditingController`s (dose, stockRemaining, stockTotal, stockWarn). Widgets are inserted into the body `Column` only when `_selectedForm?.hasX`. | Plain `setState`; values are local & discarded (spec §3.8/AC-8). | Holding values in the child widgets — would need lift-up to survive rebuilds; more complex. |
| **Controller lifecycle** | Create all controllers once as `final` State fields; dispose all in `dispose()`; on form change `.clear()` them (never recreate). | Eliminates "used-after-dispose"/leak risk entirely even though fields show/hide; KISS. | Per-show create + per-hide dispose — fragile lifecycle, the spec's main risk. |
| **Reset on form change** | In the `onFormSelected` callback, if `newForm.key != _selectedForm?.key`: clear the 3 stock controllers + dose controller, set `_selectedDoseUnitIndex = 0`, set `_quantity = newForm.hasQuantity ? newForm.quantityMin : 0`. | Matches HTML `updateQtyInput`; satisfies AC-7. | Preserve values — rejected by user during /specify. |
| **Quantity stepper chrome** | Build with `InputDecorator(isEmpty: false, decoration: InputDecoration(labelText: …), child: Row[IconButton(−), Expanded(Text(value)), Text(unit), IconButton(+)])`. | Reuses the **exact** outlined+floating-label pattern already in the picker's display row → free M3 theming, visual consistency. | Hand-rolled `Container` + `Border` + `Positioned` label — duplicates what `InputDecorator` gives for free. |
| **Dose unit control** | `DropdownButtonFormField<int>` (value = index into `doseUnits`, items render `unitResolver(l10n)`), default `0`; decoration from global theme. | Index value is stable while the displayed label is localized; single-item lists (syrup→ml) render fine. | `DropdownButtonFormField<String>` over resolved labels — value changes with locale; brittle. |
| **Qty value formatting** | `String _formatQuantity(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();` | `1`/`1.5`/`2`, matches HTML (`% 1 === 0 ? v : toFixed(1)`); Dart `0.5.toString()=='0.5'`. | `toStringAsFixed(1)` always — shows `1.0`, wrong per design. |
| **Widget decomposition** | Extract `_DoseField`, `_QuantityStepper`, `_StockCard` as private `const` `StatelessWidget`s in the same library. | Keeps the modal `build` short (§3.5 ~40-line guideline); follows the `_MedicationFormPicker` precedent; SRP. | Inline `_buildX` methods — longer build, harder to read. |
| **Test targeting** | Add `ValueKey`s: stepper value (`medsAddQtyValue`), −/+ buttons, and the dose/stock fields. Tests locate by key/icon/text (private widget types aren't importable from the test library). | Stable, unambiguous finders; minus/plus icons are currently unused in the modal so are also viable targets. | Rely on `find.byType(private)` — impossible across libraries; `find.text` on numbers — ambiguous. |

### Per-form configuration (the contract, encoded on `_MedFormOption`)

| key | hasDose | hasQuantity | hasStock | doseUnits | qty step / min / unit |
|-----|:--:|:--:|:--:|------|------|
| `tablet` | false | true | true | — | 0.5 / 0.5 / `medsAddUnitTablet` |
| `capsule` | false | true | true | — | 1 / 1 / `medsAddUnitCapsule` |
| `injection` | true | false | false | `medsAddUnitMl`, `medsAddUnitMg`, `medsAddUnitUnits` | — |
| `syrup` | true | false | false | `medsAddUnitMl` | — |
| `drops` | true | false | false | `medsAddUnitDrops`, `medsAddUnitMl` | — |
| `inhaler` | false | false | false | — | — |
| `cream` | false | false | false | — | — |
| `sachet` | false | false | false | — | — |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | Add field config to `_MedFormOption`; add `onFormSelected` callback to `_MedicationFormPicker` (called in chip `onTap`); add parent state (`_selectedForm`, `_quantity`, `_selectedDoseUnitIndex`, 4 controllers + dispose); add `_DoseField`/`_QuantityStepper`/`_StockCard` widgets; insert them conditionally between picker and Save; add `_resetConditionalFields` + `_formatQuantity`; extend dartdoc (mark visual-only iteration 3, Save still no-op). |
| `lib/l10n/app_en.arb` | Modify | Add 14 keys (§3.9) each with an `@`-description block. |
| `lib/l10n/app_de.arb` | Modify | Add 14 keys (DE values), no `@` blocks. |
| `lib/l10n/app_uk.arb` | Modify | Add 14 keys (UK values), no `@` blocks. |
| `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerate | `flutter gen-l10n` output — do not hand-edit. |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Add conditional-field group (AC-12); keep all existing tests (AC-13). |

**Discovered during planning** (beyond the spec's Affected Areas): none — file set matches the spec.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/meds.md` | Update (at `/finalize` via tech-writer) | Document the form-dependent fields on the add-medication modal (dose/qty/stock matrix, visual-only, Save still no-op). |

No `docs/architecture.md` change — no new pattern (callback-up + presentation config already used in the codebase). No `docs/api/` change — no API.

## AC Coverage (Phase 2.5 cross-reference)

| AC | Covered by |
|----|-----------|
| AC-1 hoist + preserve picker behaviour | `onFormSelected` callback decision; picker keeps internal state |
| AC-2 no fields before selection | Conditional insert gated on `_selectedForm?.hasX`; controllers don't create widgets |
| AC-3 placement/order | Insert dose→qty→stock between picker and Save in the `Column` |
| AC-4 tablet/capsule qty+stock, min/step/format | `_QuantityStepper` + `_StockCard`; per-form config; `_formatQuantity` |
| AC-5 dose forms + unit lists | `_DoseField` + `DropdownButtonFormField<int>` from `doseUnits` |
| AC-6 inhaler/cream/sachet → none | config all-false → no widgets inserted |
| AC-7 reset on change | `_resetConditionalFields` in callback |
| AC-8 local state / no persistence / Save no-op | parent `setState` only; Save `onPressed: () {}` unchanged |
| AC-9/10 l10n keys + `@`-meta | ARB edits; `flutter gen-l10n` |
| AC-11 analyze + disposal | controllers disposed; strict lints; no suppressions |
| AC-12 new tests | new test group with keyed finders |
| AC-13 existing tests green | callback hoist preserves picker contract; fields absent pre-selection |
| AC-14/15 suite + build | `flutter test` / `flutter build apk --debug` in verification |
| AC-16 manual | covered by /verify reading code |

All 16 ACs have an implementation path.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Callback hoist subtly changes picker tree and breaks 027 tests | Low | Med | Picker keeps `_selectedIndex`/`_isOpen` and widget structure; only adds a callback invocation. Run full modal group. |
| Post-selection `find.byType(TextField)` ambiguity in tests | Med | Low | Use `ValueKey`/icon/scoped finders (decision above); bare `find.byType(TextField)` only in the pre-selection AC-2 test. |
| Stock-header / warning-triangle Lucide names don't compile | Med | Low | Material `Icons.*` fallback (spec 026/027 gotcha); resolved at execution via analyze/build. `LucideIcons.minus`/`plus` confirmed available family; verify exact names. |
| `gen-l10n` untranslated-message warning if a locale misses a key | Med | Low | Add all 14 keys to all 3 ARBs in the l10n task; en template + `gen-l10n` surfaces gaps. |
| Single-item dose dropdown (syrup) looks odd | Low | Low | Acceptable per spec §8; renders the one localized unit selected. |

## Dependencies

None. No packages to add (`pubspec.yaml` unchanged), no services, no env vars. Build step: `flutter gen-l10n` (already part of the build) regenerates localization bindings; `dart run build_runner` is **not** required (no `@riverpod`/`freezed`/drift changes).

## Supporting Documents

- Research: not needed (no external-dependency or architectural signals; existing stack only).
- Data Model: not needed (no domain/data entities; per-form config documented above).
- Contracts: not needed (no API).
