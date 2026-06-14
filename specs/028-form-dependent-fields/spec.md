# Spec: Add-Medication Form-Dependent Fields (visual-only, iteration 3)

**Date**: 2026-06-14
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

This is **iteration 3** of building the Add-medication form, again scoped to **visuals + local interaction only** (no persistence, Save stays a no-op). It adds **form-dependent input fields** below the existing medication-form picker in `AddMedicationModal`: depending on which of the 8 forms is selected, the form conditionally renders a **dose field + unit dropdown** (injection / syrup / drops), a **quantity-per-intake stepper** (tablet / capsule), and a **pack-stock card** (tablet / capsule only). Driving these fields requires **hoisting the selected form out of the private `_MedicationFormPicker` state** so the parent modal can react to it. All new controls hold **local widget state**; nothing is read by Save, validated, or persisted. No `domain/` or `data/` code is added.

## 2. Current State

**The modal** (`lib/features/meds/presentation/widgets/add_medication_modal.dart`) is — after specs 026 + 027 — a plain `StatefulWidget` named `AddMedicationModal`. Its `State` (`_AddMedicationModalState`) owns one `TextEditingController` (`_nameController`, disposed in `dispose()`). `build` returns a `Scaffold` with an unchanged `AppBar` (back-arrow `IconButton` → `Navigator.pop`; `Text(context.l10n.medsAddTitle)` title) and a `body` of `SingleChildScrollView` → `Padding(EdgeInsets.all(16))` → `Column(crossAxisAlignment: stretch)` containing, in order:
1. a name `TextField` bound to `_nameController` (`InputDecoration(labelText: context.l10n.medsAddNameLabel)`),
2. `SizedBox(height: 16)`,
3. `const _MedicationFormPicker()` (spec 027),
4. `SizedBox(height: 16)`,
5. a full-width `FilledButton.icon(onPressed: () {}, icon: Icon(LucideIcons.save), label: Text(context.l10n.medsAddSaveButton))` — an **intentional documented no-op**.

**`_MedicationFormPicker`** (private widget in the same library) is a `StatefulWidget` whose `_MedicationFormPickerState` holds the selection in **private local state**: `int? _selectedIndex` (`null` = nothing selected) and `bool _isOpen`. Selection is made by `setState` inside `_buildChip`'s `onTap`. **The selected form is not exposed to the parent in any way** — there is no callback and no shared state. The 8 options live in a presentation-only `final List<_MedFormOption> _medFormOptions` (fields: `String key`, `IconData icon`, `String Function(AppLocalizations) name`, `String Function(AppLocalizations) sub`), ordered: `tablet, capsule, syrup, drops, injection, inhaler, cream, sachet`. **Note**: the `key` strings already match the planned domain-enum names, for forward compatibility.

> This `key`-string ordering inside `_medFormOptions` (`tablet, capsule, syrup, drops, injection, …`) differs from the §3.6 display order documented in spec 027's table; the live grid order is the one in `_medFormOptions`. The conditional-field logic in this spec keys off the **stable `key` string**, not the index, so it is order-independent.

**The HTML design** (the visual contract — `dosly_m3_template.html`) defines three conditional field blocks shown between the form picker and the Save button, gated by the selected form:

- **`FORM_FIELDS` matrix** (`:2730–2739`) — which blocks each form shows:

  | form `key` | dose field | qty stepper | stock card | dose-unit list |
  |---|:--:|:--:|:--:|---|
  | `tablet` | — | yes | yes | — |
  | `capsule` | — | yes | yes | — |
  | `injection` | yes | — | — | ml, mg, units |
  | `syrup` | yes | — | — | ml |
  | `drops` | yes | — | — | drops, ml |
  | `inhaler` | — | — | — | — |
  | `cream` | — | — | — | — |
  | `sachet` | — | — | — | — |

- **Dose field** (`#dose-row`, markup `:2088–2102`): a horizontal row with a `Доза` text input (`flex 1.3`) and an `Одиниця` unit dropdown (`flex 1`, a chevron trailing icon). The dropdown's options are the form's `dose-unit list` above; for single-unit forms (syrup) it has one option.
- **Quantity stepper** (`#qty-row`, CSS `:622–667`, markup `:2111–2123`, JS `QTY_CONFIG` `:2864–2885`): a 56px outlined row (`shape-xs` radius, `outline` border) laid out as `[floating label]  [−]  value  unit  [+]`. The floating label reads `Кількість на прийом`. Per-form config: `tablet → {step 0.5, min 0.5, unit "табл"}`, `capsule → {step 1, min 1, unit "капс"}`. Value is a **double**, clamped to `min` on the low end (no max), displayed **without** a trailing `.0` when whole (`1`, not `1.0`; `1.5` stays `1.5`). On form change, `updateQtyInput` **resets** the value to the new form's `min`.
- **Stock card** (`#stock-row`, CSS `.stock-card` `:1213–1233`, markup `:2127–2150`): a card with `surface-low` background, `outline-variant` 1px border, `shape-lg` radius, containing: a header (box icon + `Залишок у пачці`), a note (`Для капсул, таблеток та подібних форм. Автоматично зменшується після кожного прийому.`), a row of two text inputs (`Залишок` / `Всього в пачці`), and a full-width text input (`Попередити коли лишиться`) with a trailing warning-triangle icon. In the design these carry demo prefills (18 / 30 / 5) — for a fresh add form they start **empty**.

> The HTML also wires a list/detail `.med-stock` display that turns red on low stock (`:506–511`). That is the **consumption/display** side — **out of scope** (no persistence exists). See §6.

**Localization** (`lib/l10n/app_{en,de,uk}.arb` + `l10n.yaml` + `l10n_extensions.dart`): the established `flutter gen-l10n` 3-locale pattern. Strings are read via `context.l10n` (the single sanctioned `AppLocalizations.of(context)!` site). `@`-description metadata lives only in `app_en.arb`. The 19 `medsAddForm*` keys from spec 027 already exist in all three ARBs. Generated bindings (`app_localizations*.dart`) must not be hand-edited.

**Theme** (`lib/core/theme/app_theme.dart`): every color the design uses maps to an existing M3 `colorScheme` role: `outline` (stepper border, dose-field border via global `inputDecorationTheme`), `surfaceContainerLow`/`surfaceContainerLowest` (stock card background), `outlineVariant` (stock card border), `onSurface` / `onSurfaceVariant` (text, units, labels), `error` (warning icon accent, optional), `secondary` (stock header icon, per design `.sc-head svg`). No call-site color literals are needed (global `inputDecorationTheme` is already outlined/transparent — spec 025-era change).

**Icons** (`lucide_icons_flutter: ^3.1.12`): `LucideIcons.plus`, `LucideIcons.minus`, `LucideIcons.arrowLeft`, `LucideIcons.save`, `LucideIcons.chevronDown` are in use. New glyphs needed: a stock/package header icon and a warning-triangle icon — names verified at execution (Material `Icons.*` fallback sanctioned, per spec 026/027 gotcha).

**No domain/data exists for meds.** `drift`/`sqlite` are not in `pubspec.yaml`; there is no `Medication` entity, `MedicationForm` enum, `Dosage` value object, repository, data source, use case, or provider. This iteration adds **nothing** to `domain/` or `data/`.

**Existing tests** (`test/features/meds/presentation/widgets/add_medication_modal_test.dart`): assert AppBar title/back-arrow/typography (spec 011), the single name `TextField` via `tester.widget<TextField>(find.byType(TextField))` and the single Save `FilledButton` (spec 026), locale switching, and the form picker's collapse/expand/select behavior (spec 027). **Critical**: the spec-026 structure tests run with **no form selected**, so on initial render only the name `TextField` and the Save `FilledButton` exist — the new conditional fields (which appear only after a form is chosen) must **not** be present in the no-selection state, keeping `find.byType(TextField)` == 1 and the single-`FilledButton` assertions valid. The spec-027 picker tests select Syrup (c) and Injection (d) — those forms now also render a dose field; since those tests assert by visible **text** (not `TextField`/`FilledButton` counts), they remain valid, but new dose-field assertions must use scoped finders.

## 3. Desired Behavior

### 3.1 Hoist the selected form out of the picker
`_MedicationFormPicker`'s current selection (`_selectedIndex`) must become **observable by `_AddMedicationModalState`** so the parent can render conditional fields for the chosen form. The hoist must **preserve the picker's existing externally-observable behavior** (tap display row / chevron → expand; tap option → select + collapse + display-row updates; single selection at a time; placeholder before any selection) so the spec-027 tests keep passing. *(The exact mechanism — callback vs. lifting state fully to the parent — is a `/plan` decision; this spec requires only that the parent knows the currently-selected form `key`, or `null` when none.)*

### 3.2 Conditional block placement
The conditional fields render in the body `Column` **between the `_MedicationFormPicker` and the Save `FilledButton`**, inside the existing `SingleChildScrollView` (so the growing form scrolls rather than overflows). When present, blocks appear in the design order: **dose field**, then **quantity stepper**, then **stock card** (only one of {dose} or {qty+stock} is ever shown for a given form). Appropriate spacing separates blocks from the picker and the Save button.

### 3.3 No selection → no conditional fields
When **no form is selected** (initial state), **none** of the dose field, quantity stepper, or stock card are present in the widget tree. (This keeps the spec-026 single-`TextField` / single-`FilledButton` assertions valid.)

### 3.4 Field visibility per form
On selecting a form, the conditional block matches the §2 `FORM_FIELDS` matrix exactly:
- `tablet`, `capsule` → quantity stepper **and** stock card (no dose field).
- `injection`, `syrup`, `drops` → dose field + unit dropdown (no stepper, no stock card).
- `inhaler`, `cream`, `sachet` → **no** conditional fields.

The form→fields resolution is an **exhaustive mapping over the 8 form keys** (no `default:` fallthrough that hides a real case — constitution §3.1).

### 3.5 Dose field (injection / syrup / drops)
- A row with a **dose text input** (decimal-capable numeric keyboard) labeled `context.l10n.medsAddDoseLabel`, starting **empty**, and a **unit dropdown** labeled `context.l10n.medsAddDoseUnitLabel`.
- The dropdown's options are the selected form's localized unit list (§3.9): injection → [ml, mg, units]; syrup → [ml]; drops → [drops, ml]. The **first** unit is selected by default.
- Styling comes from the global `inputDecorationTheme` (outlined). The dropdown is a Material dropdown form field (HOW for `/plan`).
- Values are **local state only**, not read by Save.

### 3.6 Quantity stepper (tablet / capsule)
- An outlined row matching `.qty-stepper`: a floating label `context.l10n.medsAddQuantityLabel`, a **minus** `IconButton` (`LucideIcons.minus`), the current **value** (centered), the **unit** text, and a **plus** `IconButton` (`LucideIcons.plus`).
- Per-form config: `tablet → step 0.5, min 0.5, unit = context.l10n.medsAddUnitTablet`; `capsule → step 1, min 1, unit = context.l10n.medsAddUnitCapsule`.
- Initial value = the form's `min`. Minus is clamped at `min` (never goes below); there is no upper bound. Value is stored as a **double** and displayed without a trailing `.0` when whole (`1`, `1.5`, `2` …).
- Tap targets ≥ 48dp (constitution §4.3.1 — use `IconButton`/`InkWell` with explicit constraints).
- Value is **local state only**, not read by Save.

### 3.7 Stock card (tablet / capsule only)
- A card (`surfaceContainerLow`/`Lowest` background, `outlineVariant` border, `shape-lg` radius) containing:
  - a **header**: a stock/package icon + `context.l10n.medsAddStockTitle`,
  - a **note**: `context.l10n.medsAddStockNote`,
  - a **row** of two numeric text inputs: `context.l10n.medsAddStockRemainingLabel` and `context.l10n.medsAddStockTotalLabel`,
  - a full-width numeric text input `context.l10n.medsAddStockWarnLabel` with a trailing warning-triangle icon.
- All three inputs start **empty** (the HTML's 18/30/5 are demo prefills, not used for a fresh add form), use a numeric keyboard, and derive styling from the global `inputDecorationTheme`.
- Values are **local state only**, not read by Save.

### 3.8 Reset on form change
When the selected form **changes** (including any switch among forms), the conditional block resets:
- the quantity stepper resets to the **new** form's `min` (tablet → 0.5, capsule → 1),
- the dose field text and the stock inputs are **cleared**,
- the dose unit dropdown resets to the new form's first unit.
No conditional-field value persists across a form change. (Controllers for fields that disappear must be disposed correctly — see §7.)

### 3.9 New localization keys (14)
All 14 keys added to **all three** ARB files; `@`-description metadata for all 14 in `app_en.arb` only. EN/DE are translations the user may adjust (§8); UK values are taken verbatim from the HTML where present.

**Field labels & chrome (8):**

| key | EN | DE | UK |
|---|---|---|---|
| `medsAddDoseLabel` | Dose | Dosis | Доза |
| `medsAddDoseUnitLabel` | Unit | Einheit | Одиниця |
| `medsAddQuantityLabel` | Quantity per intake | Menge pro Einnahme | Кількість на прийом |
| `medsAddStockTitle` | Pack stock | Packungsbestand | Залишок у пачці |
| `medsAddStockNote` | For capsules, tablets and similar forms. Decreases automatically after each intake. | Für Kapseln, Tabletten und ähnliche Formen. Verringert sich automatisch nach jeder Einnahme. | Для капсул, таблеток та подібних форм. Автоматично зменшується після кожного прийому. |
| `medsAddStockRemainingLabel` | Remaining | Verbleibend | Залишок |
| `medsAddStockTotalLabel` | Total in pack | Gesamt in Packung | Всього в пачці |
| `medsAddStockWarnLabel` | Warn when remaining reaches | Warnen, wenn Restbestand erreicht | Попередити коли лишиться |

**Unit abbreviations (6):**

| key | EN | DE | UK |
|---|---|---|---|
| `medsAddUnitMl` | ml | ml | мл |
| `medsAddUnitMg` | mg | mg | мг |
| `medsAddUnitUnits` | units | IE | од |
| `medsAddUnitDrops` | drops | Tropfen | краплі |
| `medsAddUnitTablet` | tab | Tabl. | табл |
| `medsAddUnitCapsule` | cap | Kaps. | капс |

**Total new keys: 14**, each in all three ARBs; `@`-metadata for all 14 in `app_en.arb` only.

### 3.10 Theme & localization correctness
- All conditional-field colors/shape come from the global M3 theme — **no** hardcoded color literals at the call site (text-field styling already flows from the global outlined `inputDecorationTheme`).
- All visible strings reach through `context.l10n`; no `AppLocalizations.of(context)!` and no `!` null assertion at call sites.
- The fields render correct colors in both light and dark themes and update their strings when the app language changes.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Meds presentation — modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Hoist the picker's selected-form out to `_AddMedicationModalState` (callback or lifted state — `/plan`). Add the conditional block (dose field + unit dropdown, quantity stepper, stock card) between the picker and Save, gated by the selected form per §3.4. Add local state (selected form key, qty double, dose text + unit, stock text fields) and the per-form config (steps/mins/units, dose-unit lists). Implement reset-on-change (§3.8) with correct controller disposal. Extend dartdoc. AppBar, name field, and Save no-op unchanged. |
| L10n — English template | `lib/l10n/app_en.arb` | Add the 14 keys (§3.9) with an `@`-description block for each. |
| L10n — German | `lib/l10n/app_de.arb` | Add the 14 keys with the DE values from §3.9 (no `@` blocks). |
| L10n — Ukrainian | `lib/l10n/app_uk.arb` | Add the 14 keys with the UK values from §3.9 (no `@` blocks). |
| L10n — generated bindings | `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerated by `flutter gen-l10n` (do not hand-edit). |
| Meds tests — modal | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Add conditional-field assertions (§5 AC-9…AC-13). Keep all existing spec-011/026/027 tests passing unchanged. |

**No changes** to `meds_screen.dart`, routing, theme, `pubspec.yaml`, or any `domain/` or `data/` code.

## 5. Acceptance Criteria

- [x] **AC-1** (hoist): The selected medication form is observable by `_AddMedicationModalState` (the picker no longer keeps the selection exclusively private). The picker's externally-observable behavior from spec 027 is preserved: tapping the display row/chevron expands the grid; tapping an option selects it (single selection), updates the display row, and collapses the grid; the placeholder shows before any selection.
- [x] **AC-2** (no selection): With **no** form selected (initial modal render), none of the dose field, quantity stepper, or stock card are present in the widget tree. Exactly one `TextField` (the name field) and exactly one `FilledButton` (Save) exist — the spec-026 structure assertions remain valid.
- [x] **AC-3** (placement): When shown, the conditional fields render inside the existing `SingleChildScrollView` → `Column`, **below** the `_MedicationFormPicker` and **above** the Save `FilledButton`, in the order dose → quantity → stock.
- [x] **AC-4** (tablet/capsule): Selecting **Tablet** or **Capsule** shows the quantity stepper **and** the stock card, and **no** dose field. The stepper's unit is the localized tablet/capsule unit; its initial value is `0.5` for tablet and `1` for capsule; minus is clamped at that min; values display without a trailing `.0` when whole; tablet steps by `0.5` and capsule by `1`.
- [x] **AC-5** (dose forms): Selecting **Injection**, **Syrup**, or **Drops** shows the dose field + unit dropdown, and **no** quantity stepper or stock card. The dropdown lists the form's localized units (injection → ml/mg/units; syrup → ml; drops → drops/ml) with the first selected by default.
- [x] **AC-6** (no-extra forms): Selecting **Inhaler**, **Cream/Ointment**, or **Sachet** shows **none** of the conditional fields (only the picker + name + Save remain).
- [x] **AC-7** (reset on change): Switching the selected form resets the conditional block — the quantity stepper resets to the new form's min, the dose field text and stock inputs clear, and the dose-unit dropdown resets to the new form's first unit. No conditional value carries over across a form switch.
- [x] **AC-8** (visual-only / local state): All conditional-field values (qty double, dose text + unit, stock fields) are held in **local widget state**; none are read, validated, or persisted, and none are passed to Save. The Save button's `onPressed` remains the documented no-op from spec 026. No Riverpod/`ConsumerStatefulWidget` is introduced. No `domain/` or `data/` code is added; `pubspec.yaml` is unchanged.
- [x] **AC-9** (l10n keys): All **14** new keys (§3.9) exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb` with the EN/DE/UK values from §3.9. `app_en.arb` includes an `@`-description block for each of the 14; `app_de.arb` and `app_uk.arb` contain values only.
- [x] **AC-10** (l10n correctness): Every conditional-field string in widget code is reached via `context.l10n` — no `AppLocalizations.of(context)!`, no `!` null assertion at the call site. All colors/shape derive from the global M3 theme (no hardcoded color literals at the call site).
- [x] **AC-11** (analyze): `dart analyze` passes on all changed/created files with zero warnings or errors (strict-mode lint config preserved; no lint-suppression comments). Any `TextEditingController`/`AnimationController` introduced is disposed.
- [x] **AC-12** (tests added): `add_medication_modal_test.dart` adds tests asserting: (a) before selection, none of the dose/qty/stock fields are present (and `find.byType(TextField)` finds exactly one — the name field); (b) selecting Tablet shows the quantity stepper (localized `medsAddQuantityLabel` + unit) and the stock card (localized remaining/total/warn labels) and no dose field; (c) selecting Capsule shows initial qty `1` and stepping changes it by `1`; selecting Tablet shows initial `0.5` and stepping by `0.5`; minus clamps at the min; (d) selecting Syrup shows the dose field + a unit dropdown containing the localized ml unit, and no stepper/stock card; (e) selecting Inhaler shows none of the conditional fields; (f) switching from Tablet to Syrup removes the stepper/stock and shows the dose field (reset behavior). New dose/stock TextField assertions use **scoped** finders (not a global `find.byType(TextField)` count once fields are visible).
- [x] **AC-13** (existing tests green): All existing spec-011/026/027 tests in `add_medication_modal_test.dart` remain and pass unchanged (AppBar title/back-arrow/typography; single name `TextField`; single Save `FilledButton` + `LucideIcons.save`; Save tap harmless + does not pop; locale switching; picker collapse/expand/select including selecting Syrup and Injection).
- [x] **AC-14** (suite): `flutter test` passes for the full project.
- [x] **AC-15** (build): `flutter build apk --debug` succeeds.
- [x] **AC-16** _(manual, gated by /verify reading code only)_: Running the app and opening the modal: selecting Tablet/Capsule reveals the stepper (with working +/− and correct min/step) and the stock card; selecting Injection/Syrup/Drops reveals the dose field with the correct unit dropdown; selecting Inhaler/Cream/Sachet reveals no extra fields; switching forms resets the fields; toggling Settings → Appearance Light/Dark recolors all new fields with no glitch; switching Settings → Language updates all new labels and unit strings on the next render.

## 6. Out of Scope

- **NOT included**: any persistence — no `drift` dependency, table, migration, repository, data source, or write. All entered values are discarded.
- **NOT included**: any `domain/` or `data/` code for meds — no `Medication` entity, `MedicationForm`/`DoseUnit` enum, `Dosage`/`Quantity`/`StockInfo` value object, use case, abstract repository, or provider. This iteration touches only `presentation/` (+ l10n + test).
- **NOT included**: any Riverpod provider or `ConsumerStatefulWidget` — the modal stays a plain `StatefulWidget` with local `setState`.
- **NOT included**: the list/detail `.med-stock` display, low-stock red highlighting, or auto-decrement-after-intake behavior (that is the consumption/display side and needs persistence).
- **NOT included**: validation tied to the fields (e.g. requiring a dose, rejecting `total < remaining`, requiring numeric input), error/helper text, or disable-until-valid gating of Save.
- **NOT included**: the rest of the HTML "Screen 3" below these fields — time chips, intake type (Permanent/Course) and course parameters. Later iterations.
- **NOT included**: changing the Save button behavior (still a no-op), the AppBar, title, back-arrow, push mechanics, the Meds-screen FAB, the name field, the form picker's own visuals, or the theme.
- **NOT included**: an edit/prefill flow (pre-filling dose/qty/stock for an existing medication) or any add-vs-edit distinction.

## 7. Technical Constraints

- **Constitution compliance**:
  - No Flutter imports added to `domain/` (not relevant — no domain code is touched).
  - No `!` null assertion in widget code; reach strings via `context.l10n`.
  - Exhaustive form→fields resolution (constitution §3.1) — no `default:` clause that silently swallows a form case.
  - All new/changed public widgets retain accurate dartdoc `///` comments.
  - `dart analyze` must pass with zero issues; lint-suppression comments are forbidden (MEMORY, Feature 010).
  - SOLID/DRY/KISS — render the dose-unit options and the per-form config from data (a map/table keyed by form), not hand-duplicated per form.
  - Any `TextEditingController` for the dose/stock inputs must be created and **disposed** correctly, including when a field is removed on form change (constitution §3.1 `cancel_subscriptions`/`close_sinks` discipline; lifecycle correctness).
  - Tap targets ≥ 48dp for the stepper buttons (constitution §4.3.1).
- **Theme**: use the global Material 3 theme; no explicit color literals/shape/elevation at the call site (MEMORY, Feature 005). The global `inputDecorationTheme` is already outlined/transparent (the bbb3 "outlined inputs" change) — reuse it for the dose/stock text fields and the dropdown.
- **Icons**: use `lucide_icons_flutter`; the stepper uses `LucideIcons.minus`/`LucideIcons.plus`. The stock header and warning-triangle glyphs are verified at execution; a Material `Icons.*` fallback is sanctioned only where a Lucide name does not compile (same gotcha as spec 026/027). Do not add an icon package.
- **Localization**: 14 keys in all three locales, `@`-metadata only in `app_en.arb`, consumed via `context.l10n`; regenerate with `flutter gen-l10n` (never hand-edit `app_localizations*.dart`).
- **No new dependencies**: `pubspec.yaml` is not modified.
- **Test framework**: `flutter_test` (+ `mocktail` if needed) per project convention; no new test deps. _MEMORY (Bug 020): when conditional fields are off-stage/absent before selection, drive the state change (select a form) with a `pump()`/`pumpAndSettle()` before asserting; locate fields with scoped finders and `skipOffstage` as appropriate; keep assertions self-validating._

## 8. Open Questions

- **EN/DE wording** (minor): UK values come from the HTML design; EN and DE are standard translations. The user is the translator and may adjust any EN/DE value (e.g. `medsAddUnitUnits` "units"/"IE", `medsAddStockWarnLabel`) in a follow-up without changing the spec's structure.
- **Stock/warning Lucide icon names** (minor): the stock header (package/box) and warning-triangle names are not in MEMORY's verified-name list. Resolve at execution; AC permits a Material `Icons.*` fallback if a name does not compile. No spec change needed.
- **Single-unit dropdown UX** (minor): for syrup (only `ml`) the unit control is a dropdown with one option. Whether to render it disabled or as a plain read-only field is an execution detail; AC-5 only requires the correct localized unit to be shown and selected.
- **Decimal entry locale** (minor): the dose/stock numeric inputs use a numeric keyboard; whether to accept `,` vs `.` as a decimal separator is not validated this iteration (visual-only, values discarded).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Hoisting the picker selection breaks the spec-027 picker tests (they tap the chevron and option text) | Med | Med | Preserve the picker's externally-observable contract (AC-1); run the full modal test group; if lifting state up, keep the same widget structure/icons the tests target. |
| Adding dose/stock `TextField`s breaks the spec-026 `tester.widget<TextField>(find.byType(TextField))` single-match assertion | Med | Med | Conditional fields are absent until a form is selected (AC-2); the spec-026 test never selects a form, so only the name field exists at assert time. |
| `TextEditingController`s for fields removed on form change are leaked or read after dispose | Med | Med | Manage controllers per §3.8/§7 — create on demand, dispose on removal and in `dispose()`; verified by `dart analyze` + widget tests that switch forms. |
| Stock/warning Lucide icon names don't exist under the guessed names | Med | Low | Material `Icons.*` fallback (per spec 026/027); verified at execution via `dart analyze`/build. |
| The form→fields mapping drifts from the HTML `FORM_FIELDS` matrix | Low | Med | §2/§3.4 pin the matrix verbatim; AC-4/5/6 test all 8 forms' field visibility. |
| Growing form overflows on small screens when fields expand | Low | Low | Body is already a `SingleChildScrollView`; new fields scroll into view rather than overflow. |
| Future iterations copy the unconsumed field state but forget it's not wired to Save | Med | Low | Inline dartdoc marks the fields as visual-only iteration 3 and that Save stays a no-op until the data-save iteration. |
