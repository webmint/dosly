# Spec: Add-Medication Form Picker (visual-only, iteration 2)

**Date**: 2026-06-13
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

This is **iteration 2** of building the Add-medication form, again scoped to **visuals + local interaction only**. It adds a **medication-form picker** to `AddMedicationModal`, below the existing name field and above the Save button. The picker reproduces the HTML design's two-part control (`dosly_m3_template.html`): a tappable **display row** (`.form-picker-display`) that expands/collapses a **grid card** (`.form-picker-grid-card`) of **8 medication forms** in a 2-column grid. Selecting a form highlights it and updates the display row (icon + name + sub-description), all driven by **local widget state**. No data is captured, validated, or persisted — the selected form is **not** read by Save, and the Save button stays the documented no-op from spec 026. No `domain/` or `data/` code is added.

## 2. Current State

**The modal** (`lib/features/meds/presentation/widgets/add_medication_modal.dart`) is — after spec 026 — a plain `StatefulWidget` named `AddMedicationModal` whose `State` owns a single `TextEditingController` (`_nameController`, disposed in `dispose()`). Its `build` returns a `Scaffold` with an unchanged `AppBar` (back-arrow `IconButton` leading → `Navigator.pop`, `MaterialLocalizations.backButtonTooltip`, `Text(context.l10n.medsAddTitle)` title). The `body` is a `SingleChildScrollView` → `Padding(EdgeInsets.all(16))` → `Column(crossAxisAlignment: stretch)` containing:
- a name `TextField` bound to `_nameController` (`InputDecoration(labelText: context.l10n.medsAddNameLabel)`, styling from the global theme), then
- a `SizedBox(height: 16)`, then
- a full-width `FilledButton.icon(onPressed: () {}, icon: Icon(LucideIcons.save), label: Text(context.l10n.medsAddSaveButton))` whose `onPressed` is an **intentional documented no-op** (spec 026).

The picker is a **new child inserted into this `Column`, between the name field and the Save button** (matching the design order: name field at `dosly_m3_template.html:2001`, form picker at `:2008`). No conversion of the widget type is needed (it is already a `StatefulWidget`).

**The HTML design** (the contract for the visuals):
- **Display row** — `.form-picker-display` (CSS `dosly_m3_template.html:783–818`, markup `:2011–2021`): a 56px-tall row, `shape-xs` (4px) radius, 1px `outline` border (hover → `on-surface`), with:
  - a floating label (`.fpd-label`, "Форма препарату") sitting on the surface at the top-left,
  - an icon chip (`.fpd-icon-wrap`): 32×32, `shape-sm` radius, `secondary-container` background, a 20px icon in `on-secondary-container`,
  - a text block (`.fpd-text`): a name line (`.fpd-name`, 16px `on-surface`) and a sub line (`.fpd-sub`, 11px `on-surface-variant`),
  - a trailing chevron (`.fpd-caret`) that rotates 180° when open (`.form-picker-display.open`).
- **Grid card** — `.form-picker-grid-card` (CSS `:820–869`, markup `:2024–2077`): a `primary-container`-background card with rounded bottom corners (`shape-lg`), animating open via a `max-height .28s` transition (`.visible`). It contains:
  - a title (`.fpg-title`, "Типові форми", uppercase, bold 12px, `primary`),
  - a 2-column grid (`.fpg-grid`, gap 7px) of **8** options (`.fpg-opt`), each a chip with a 22px icon + a label (`.fpg-lbl`, 13px). The selected option (`.fpg-opt.sel`) flips to `primary` background + `primary` border with `on-primary` icon + label.
- **Interaction** (JS `togglePicker` `:2722`, `selectForm` `:2741`): tapping the display row toggles `open`/`visible` (expand/collapse). Tapping a grid option (a) clears `.sel` from all and marks the tapped one, (b) copies that option's name/sub/icon into the display row, and (c) **collapses** the card (removes `open`/`visible`). The eight forms and their data (`data-form-key`, `data-name`, `data-sub`) are listed in §3.6.

> The `selectForm` handler also toggles dose/quantity/stock field visibility via a `FORM_FIELDS` map — **out of scope** (those fields do not exist in the app yet; they are later iterations). See §6.

**Localization** (`lib/l10n/app_{en,de,uk}.arb` + `l10n_extensions.dart`): the established `flutter gen-l10n` 3-locale pattern. Keys exist in all three ARB files; `@`-description metadata lives only in `app_en.arb`; strings are read via `context.l10n` (the single sanctioned `AppLocalizations.of(context)!` site, `l10n_extensions.dart`). Existing meds keys: `medsAddFabTooltip`, `medsAddTitle`, `medsAddNameLabel`, `medsAddSaveButton`. Generated bindings (`app_localizations*.dart`) must not be hand-edited.

**Theme** (`lib/core/theme/app_theme.dart`): the global Material 3 theme drives all chrome. Every color the design uses is an M3 `colorScheme` role already present: `outline` (display border), `on-surface` / `on-surface-variant` (text), `secondary-container` / `on-secondary-container` (icon chip), `primary-container` (grid card background), `primary` / `on-primary` (selected option), `primary` (grid title). No call-site color values are needed.

**Icons** (`lucide_icons_flutter: ^3.1.12`): the project icon set. `LucideIcons.plus`, `LucideIcons.arrowLeft`, and `LucideIcons.save` are already in use. The 8 form glyphs are Lucide SVGs (mapping in §3.7). _MEMORY note: as with `LucideIcons.save` in spec 026, some names may not be in the verified-name list — confirm each compiles; a Material `Icons.*` fallback is sanctioned (§7)._

**No domain/data exists for meds.** `drift`/`sqlite` are not in `pubspec.yaml`; there is no `Medication` entity, `MedicationForm` enum, repository, data source, use case, or provider. MEMORY's "Domain Cheat Sheet" lists a *planned* `MedicationForm` enum (`tablet, capsule, injection, syrup, drops, inhaler, cream, sachet`) but it does **not** exist in `lib/`. This iteration adds **nothing** to `domain/` or `data/`.

**Existing test** (`test/features/meds/presentation/widgets/add_medication_modal_test.dart`) asserts (from spec 026): a `TextField` with the localized `medsAddNameLabel`; a `FilledButton` with the localized `medsAddSaveButton` and `LucideIcons.save`; a Save tap that completes without throwing and does not pop; plus locale-switching, back-arrow, and title-typography tests. Adding the picker is **additive** — the picker uses no `TextField` and no `FilledButton`, so the "exactly one `TextField` / one `FilledButton`" assertions stay valid. These tests must continue to pass unchanged; new picker assertions are added in the same task.

## 3. Desired Behavior

### 3.1 Placement
The picker is inserted into the existing body `Column` **between** the name `TextField` and the Save `FilledButton`, separated by appropriate spacing, within the existing `SingleChildScrollView` (so it never causes overflow when the keyboard is up or the grid is expanded).

### 3.2 Display row (collapsed control)
- A tappable row matching `.form-picker-display`: ~56px tall, `shape-xs`-radius outlined container (border from `colorScheme.outline`), with:
  - a floating label reading `context.l10n.medsAddFormLabel` ("Medication form"),
  - a leading icon chip (`secondary-container` background, rounded, icon in `on-secondary-container`),
  - a name line and a sub line,
  - a trailing chevron that indicates open/closed state (e.g. rotates when the grid is open).
- **Before any selection** (initial state): the name line shows the placeholder `context.l10n.medsAddFormPlaceholder` ("Choose a form"), the sub line is empty, and the icon chip shows a neutral placeholder icon. The grid is **collapsed** (not shown).

### 3.3 Expand / collapse
- Tapping the display row toggles the grid card open/closed.
- The chevron reflects the state (rotated when open).
- The expand/collapse **animates** to match the design's transition (e.g. `AnimatedSize`, ~250–300 ms). _(Animation is desired but soft — see §8.)_

### 3.4 Grid card (expanded)
- A card with `primary-container` background and rounded bottom corners, containing:
  - a title reading `context.l10n.medsAddFormGridTitle` ("Common forms"),
  - a **2-column grid** of the **8** form options listed in §3.6, in that order.
- Each option chip shows its Lucide icon + its localized name. The **selected** option is visually distinct: `primary` background, `on-primary` icon + label.

### 3.5 Selection behavior
- Tapping an option:
  1. marks it as the single selected form (any prior selection is cleared — exactly one selected at a time),
  2. updates the display row's icon, name, and sub to that form, and
  3. collapses the grid card.
- Selection is held in **local widget state** (plain `StatefulWidget` `setState`). No Riverpod, no `ConsumerStatefulWidget`.
- The selected form is **not** read, validated, persisted, or passed to the Save button or anywhere else. **Save remains the documented no-op from spec 026.**

### 3.6 The 8 forms (order, key, strings)
Order matches the HTML grid (`:2028–2073`). Each form has a stable `key` (matching the *planned* domain enum names, for forward-compatibility), a localized **name** key, and a localized **sub** key. UK values are taken verbatim from the HTML; EN/DE are standard translations (user may adjust — §8).

| # | key | name key | EN name | DE name | UK name | sub key | EN sub | DE sub | UK sub |
|---|-----|----------|---------|---------|---------|---------|--------|--------|--------|
| 1 | `tablet` | `medsAddFormTablet` | Tablet | Tablette | Таблетка | `medsAddFormTabletSub` | Compressed form | Gepresste Form | Пресована форма |
| 2 | `capsule` | `medsAddFormCapsule` | Capsule | Kapsel | Капсули | `medsAddFormCapsuleSub` | Hard gelatin shell | Harte Gelatinehülle | Тверда желатинова оболонка |
| 3 | `syrup` | `medsAddFormSyrup` | Syrup | Sirup | Сироп | `medsAddFormSyrupSub` | Liquid dosage form | Flüssige Darreichungsform | Рідка лікарська форма |
| 4 | `drops` | `medsAddFormDrops` | Drops | Tropfen | Краплі | `medsAddFormDropsSub` | Liquid drop form | Flüssige Tropfenform | Рідка крапельна форма |
| 5 | `injection` | `medsAddFormInjection` | Injection | Injektion | Ін'єкція | `medsAddFormInjectionSub` | Intramuscular / IV | Intramuskulär / i.v. | Внутрішньом'язова/в/в |
| 6 | `inhaler` | `medsAddFormInhaler` | Inhaler | Inhalator | Інгалятор | `medsAddFormInhalerSub` | Aerosol form | Aerosolform | Аерозольна форма |
| 7 | `cream` | `medsAddFormCream` | Cream / Ointment | Creme / Salbe | Крем / Мазь | `medsAddFormCreamSub` | Topical form | Äußerliche Form | Зовнішня форма |
| 8 | `sachet` | `medsAddFormSachet` | Sachet | Sachet | Саше | `medsAddFormSachetSub` | Soluble powder | Lösliches Pulver | Розчинний порошок |

Plus three **chrome** keys:

| chrome key | EN | DE | UK |
|------------|----|----|----|
| `medsAddFormLabel` | Medication form | Medikamentenform | Форма препарату |
| `medsAddFormPlaceholder` | Choose a form | Form wählen | Оберіть форму |
| `medsAddFormGridTitle` | Common forms | Typische Formen | Типові форми |

**Total new keys: 19** (3 chrome + 8 names + 8 subs), each in all three ARB files; `@`-description metadata for all 19 in `app_en.arb` only.

### 3.7 Icon mapping (Lucide)
The option icon should match the design glyph. Mapping (verify each compiles at execution; Material fallback per §7):

| key | Lucide name | confidence |
|-----|-------------|-----------|
| `tablet` | `LucideIcons.pills` | High |
| `capsule` | `LucideIcons.pill` | High |
| `syrup` | `LucideIcons.milk` | High |
| `drops` | `LucideIcons.droplets` | High |
| `injection` | `LucideIcons.syringe` | High |
| `inhaler` | `LucideIcons.wind` | High |
| `cream` | _verify_ (e.g. `LucideIcons.container`) | Low |
| `sachet` | `LucideIcons.package` | Med |

The collapsed display-row placeholder icon (before selection) is a neutral Lucide glyph (e.g. `LucideIcons.pill` or `LucideIcons.shapes`) — choose one that compiles.

### 3.8 Forms data shape (presentation-only)
The 8 forms are defined as an **ordered, presentation-only** structure (a `const` list of a small private value type, or equivalent) in the **presentation layer** (within the modal's library/widget file), each entry holding: the stable `key`, the `IconData`, and a way to resolve the localized name + sub via `AppLocalizations` at build time. **No `MedicationForm` enum or any entity is added to `domain/` or `data/`.**

### 3.9 Theme & localization correctness
- All picker colors/shape come from the global M3 theme (`colorScheme` roles per §2 "Theme") — **no** hardcoded color values, fills, or text styles at the call site beyond what the design's typography requires via theme text styles.
- All visible strings reach through `context.l10n`; no `AppLocalizations.of(context)!` and no `!` at call sites.
- The picker renders correct colors in both light and dark themes, and updates its strings when the app language changes.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Meds presentation — modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Insert the form picker into the body `Column` between the name field and Save button. Add local state for the selected-form index/key and the open/closed flag. Define the presentation-only 8-form list. Add/extend dartdoc. May extract a private `_MedicationFormPicker` widget within the same library (HOW is for `/plan`). AppBar, name field, and Save no-op unchanged. |
| L10n — English template | `lib/l10n/app_en.arb` | Add the 19 keys (§3.6) with `@`-description metadata for each. |
| L10n — German | `lib/l10n/app_de.arb` | Add the 19 keys with the DE values from §3.6 (no `@` blocks). |
| L10n — Ukrainian | `lib/l10n/app_uk.arb` | Add the 19 keys with the UK values from §3.6 (no `@` blocks). |
| L10n — generated bindings | `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerated by `flutter gen-l10n` (do not hand-edit). |
| Meds tests — modal | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Add picker assertions (collapsed initial state with placeholder + label; expand reveals title + 8 options; selecting an option updates the display row + collapses + shows selected state). Keep all existing spec-026 + locale tests passing unchanged. |

**No changes** to `meds_screen.dart`, the routing shell, the theme, `pubspec.yaml`, or any `domain/` or `data/` code.

## 5. Acceptance Criteria

- [x] **AC-1**: A medication-form picker is rendered in the modal body, inside the existing `SingleChildScrollView` → `Column`, positioned **below** the name `TextField` and **above** the Save `FilledButton`.
- [x] **AC-2**: The picker exposes a tappable **display row** showing a floating label equal to the localized `medsAddFormLabel`, a leading icon chip, a primary name line, a sub line, and a trailing chevron indicator.
- [x] **AC-3**: On first open (no selection), the display row's name line shows the localized `medsAddFormPlaceholder`, the sub line is empty, and the grid is **collapsed** (the 8 options and the grid title are not present in the tree / not shown).
- [x] **AC-4**: Tapping the display row **expands** the grid, revealing a title equal to the localized `medsAddFormGridTitle` and exactly **8** form options in a 2-column layout, in the order: Tablet, Capsule, Syrup, Drops, Injection, Inhaler, Cream/Ointment, Sachet (per §3.6). Tapping the display row again collapses it. The chevron reflects open/closed state.
- [x] **AC-5**: Each option displays its localized name (§3.6) and a Lucide icon per the §3.7 mapping (Material `Icons.*` fallback allowed only where a Lucide name does not compile — §7).
- [x] **AC-6**: Tapping an option (a) selects it as the single selected form (exactly one selected at a time), (b) updates the display row's name to that form's localized name and its sub to that form's localized sub and its icon to that form's icon, and (c) **collapses** the grid.
- [x] **AC-7**: The selected form and open/closed state are held in **local widget state** (plain `StatefulWidget` `setState`); no Riverpod / `ConsumerStatefulWidget` is introduced. The selected form is **not** read, validated, persisted, or passed to Save or any other sink. The Save button's `onPressed` remains the documented no-op from spec 026 (unchanged behavior).
- [x] **AC-8**: The 8 forms are defined as an ordered, **presentation-only** structure (stable key + `IconData` + localized name + localized sub) within the presentation layer. **No** `MedicationForm` enum/entity, repository, data source, use case, or provider is added to `domain/` or `data/`; `pubspec.yaml` is unchanged.
- [x] **AC-9**: All **19** new ARB keys (§3.6: `medsAddFormLabel`, `medsAddFormPlaceholder`, `medsAddFormGridTitle`, the 8 `medsAddForm<Name>`, and the 8 `medsAddForm<Name>Sub`) exist in all three ARB files (`app_en.arb`, `app_de.arb`, `app_uk.arb`) with the EN/DE/UK values from §3.6.
- [x] **AC-10**: `app_en.arb` includes an `@`-description block for each of the 19 keys; `app_de.arb` and `app_uk.arb` contain values only (no `@` blocks).
- [x] **AC-11**: All picker strings in widget code are reached via `context.l10n` — no `AppLocalizations.of(context)!` and no `!` null assertion at the call site. All picker colors/shape derive from the global M3 theme `colorScheme` (no hardcoded color literals at the call site).
- [x] **AC-12**: `dart analyze` passes on all changed/created files with zero warnings or errors (strict-mode lint config preserved; no lint-suppression comments).
- [x] **AC-13**: `add_medication_modal_test.dart` adds tests asserting: (a) before selection, the display row shows the localized placeholder + label and the grid title/options are absent; (b) tapping the display row reveals the localized grid title and the 8 localized option names; (c) tapping a specific option (e.g. Syrup) updates the display row to that form's localized name + sub and the grid collapses (title/options no longer shown); (d) exactly one option is selected at a time. The existing spec-026 assertions (name field with `medsAddNameLabel`; Save `FilledButton` with `medsAddSaveButton` + `LucideIcons.save`; Save tap harmless + does not pop) and the locale-switching / back-arrow / title-typography tests remain and pass unchanged.
- [x] **AC-14**: `flutter test` passes for the full project.
- [x] **AC-15**: `flutter build apk --debug` succeeds.
- [x] **AC-16** _(manual, gated by /verify reading code only)_: Running the app, opening the modal, expanding the picker, and selecting forms shows the selected highlight (primary) and the display row updating; toggling Settings → Appearance between Light and Dark recolors the picker (display border, icon chip, grid card, selected option) with no glitch; switching Settings → Language updates the label, placeholder, grid title, and all 8 option names/subs to the corresponding localized strings on the next open of the modal.

## 6. Out of Scope

- **NOT included**: any persistence — no `drift` dependency, table, migration, repository, data source, or write. The selected form is discarded.
- **NOT included**: any `domain/` or `data/` code for meds — no `Medication` entity, no `MedicationForm` enum/value object, no use case, abstract repository, or provider. This iteration touches only `presentation/` (+ l10n + test).
- **NOT included**: any Riverpod provider or `ConsumerStatefulWidget` — the modal stays a plain `StatefulWidget` with local `setState`.
- **NOT included**: the `FORM_FIELDS` form→field-visibility logic from the HTML (`selectForm` showing/hiding dose / quantity / stock fields and populating unit options based on the chosen form). Those fields do not exist in the app yet.
- **NOT included**: the rest of the HTML "Screen 3" form below the picker — dose + unit, quantity stepper, stock card, time chips, intake type (Permanent/Course) and course parameters. Later iterations.
- **NOT included**: validation tied to the form (e.g. requiring a form to be chosen before Save), error/helper text, or disable-until-valid gating of Save.
- **NOT included**: changing the Save button behavior (still a no-op), the AppBar, title, back-arrow, push mechanics, the Meds-screen FAB, the name field, or the theme.
- **NOT included**: an edit/prefill flow (pre-selecting the form for an existing medication) or any add-vs-edit distinction.
- **NOT included**: keyboard handling, autofocus, or input formatters for the picker (it is not a text input).

## 7. Technical Constraints

- **Constitution compliance**:
  - No Flutter imports added to `domain/` (not relevant — no domain code is touched).
  - No `!` null assertion in widget code; reach strings via `context.l10n`.
  - All new/changed public widgets retain accurate dartdoc `///` comments.
  - `dart analyze` must pass with zero issues; lint-suppression comments are forbidden (MEMORY, Feature 010).
  - SOLID/DRY/KISS — render the 8 options by iterating the presentation-only list, not by hand-duplicating 8 chip widgets.
  - If an `AnimationController` is introduced for the expand/collapse, it must be disposed; prefer `AnimatedSize` / implicit animations to avoid manual controller lifecycle.
- **Theme**: use the global Material 3 theme; no explicit color literals/shape/elevation at the call site (MEMORY, Feature 005: "Flutter built-in widgets deliver M3 theming for free"). Colors come from `colorScheme` roles named in §2/§3.9.
- **Icons**: use `lucide_icons_flutter` per §3.7; a Material `Icons.*` fallback is sanctioned only where a Lucide name does not compile (same gotcha as spec 026's `LucideIcons.save`). Do not add an icon package.
- **Localization**: 19 keys in all three locales, `@`-metadata only in `app_en.arb`, consumed via `context.l10n`; regenerate with `flutter gen-l10n` (never hand-edit `app_localizations*.dart`).
- **No new dependencies**: `pubspec.yaml` is not modified.
- **Test framework**: `flutter_test` (+ `mocktail` if needed) per project convention; no new test deps. _MEMORY (Bug 020): if grid options are off-stage when collapsed, drive expansion with a `pump()` after the tap and locate options with `skipOffstage` set appropriately; make assertions self-validating._

## 8. Open Questions

- **DE/EN wording** (minor): UK name/sub values come directly from the HTML design; EN and DE are standard translations. The user is the translator and may adjust any EN/DE value in a follow-up without changing the spec's structure.
- **`cream` and `sachet` Lucide icon names** (minor): not in MEMORY's verified-name list. Resolve at execution time; AC-5 sanctions a Material `Icons.*` fallback if a name does not compile. No spec change needed.
- **Expand/collapse animation** (minor): specced as desired (`AnimatedSize`, ~250–300 ms) to match the design's `.28s` transition. If the animation materially complicates the widget test, rendering without animation (instant show/hide) is an acceptable fallback — the selection/expand contract (AC-3/4/6) does not depend on animation.
- **Placeholder display-row icon** (minor): the design shows a generic glyph before selection; the exact Lucide name is an execution detail (any compiling neutral glyph is fine).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `cream`/`sachet` Lucide names don't exist under the guessed names | Med | Low | AC-5 fallback to `Icons.*`; verified at execution via `dart analyze`/build. |
| Widget test can't find grid options because they're off-stage/not built when collapsed | Med | Low | Expand first (tap display row), `pump()`, then locate; set `skipOffstage` appropriately; make assertions self-validating (MEMORY Bug 020). |
| 19 keys × 3 locales is a sizeable translation surface; a missed key fails `flutter gen-l10n` / leaves an untranslated-message warning | Med | Low | Add all keys to all three ARBs in one task; the EN template plus `flutter gen-l10n` output surfaces any missing locale. |
| Expanding the grid grows the modal beyond the viewport on small screens | Low | Low | Body is already a `SingleChildScrollView`; the grid scrolls into view rather than overflowing. |
| Future iterations copy the selected-form state but forget it's not wired to Save | Med | Low | Inline dartdoc marks the picker as visual-only iteration 2 and that Save stays a no-op until the data-save iteration. |
| A reviewer reads the unused selected-form state as a dead-code/bug | Low | Low | Document inline that the selection is intentionally local/unconsumed this iteration (per this spec), consistent with the 026 no-op Save. |
