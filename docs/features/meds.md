# Meds

## Overview

The **meds feature** owns the Meds tab — destination index 1 in `AppBottomNav`. The screen has a localized `AppBar`, a `FloatingActionButton` that opens a full-screen modal, and an intentionally empty body (medication list is pending a future spec). The add-medication modal is being built iteratively — feature 026 added the first form controls (name field + Save button); persistence, validation, and the rest of the form are still pending.

Everything in this feature lives under `lib/features/meds/presentation/`. There is no `domain/` or `data/` layer yet.

## MedsScreen

`MedsScreen` (in `lib/features/meds/presentation/screens/meds_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `bottomNavMeds` string (`context.l10n.bottomNavMeds`), shared with the bottom navigation bar destination label.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the medication-list feature is implemented.
- A `FloatingActionButton` (Material 3 FAB, `LucideIcons.plus`) with tooltip `context.l10n.medsAddFabTooltip` ("Add medication" in English). Tapping it calls `_openAddMedicationModal(context)`.

## Add-Medication Modal (iteration 1 — visual only)

`AddMedicationModal` (in `lib/features/meds/presentation/widgets/add_medication_modal.dart`) is a `StatefulWidget` that owns a `TextEditingController` for the medication-name field and disposes it in `dispose()`. It is a full-screen modal with:

- A `Scaffold + AppBar` carrying the localized title `context.l10n.medsAddTitle` ("Add medication").
- A leading `IconButton` (back arrow, `LucideIcons.arrowLeft`) that calls `Navigator.of(context).pop()`.
- A `SingleChildScrollView → Padding(16) → Column(crossAxisAlignment: stretch)` body containing:
  - An outlined `TextField` bound to `_nameController` with label `context.l10n.medsAddNameLabel`. The outlined, transparent styling (2px outline, `primary` on focus) comes from the global `inputDecorationTheme` in `lib/core/theme/app_theme.dart` — no call-site border/color overrides.
  - A medication-form picker (added in iteration 2 — see below).
  - A full-width `FilledButton.icon` (`LucideIcons.save` + `context.l10n.medsAddSaveButton`) with `onPressed: () {}` — a **deliberate no-op**.

```dart
TextField(
  controller: _nameController,
  // Outline/label styling inherited from the global inputDecorationTheme.
  decoration: InputDecoration(
    labelText: context.l10n.medsAddNameLabel,
  ),
),
const SizedBox(height: 16),
// _MedicationFormPicker inserted here (iteration 2)
const SizedBox(height: 16),
FilledButton.icon(
  onPressed: () {},
  icon: const Icon(LucideIcons.save),
  label: Text(context.l10n.medsAddSaveButton),
),
```

The Save button's empty callback is **intentional and documented** (spec 026, iteration 1). It does not validate input, persist data, pop the modal, or give user feedback. Real save behaviour — drift persistence, domain layer, Riverpod provider — will be wired in the data-save iteration. There is still no `domain/` or `data/` layer for this feature.

## Medication-Form Picker (iteration 2 — visual only)

The form picker is a **private `_MedicationFormPicker` `StatefulWidget`** defined inside `add_medication_modal.dart`. It renders a two-part control matching the HTML design template: a tappable **display row** that expands/collapses a **grid of 8 medication forms**. All state is local (`setState`); the selected form is intentionally not consumed — the Save button stays a no-op until the data-save iteration.

### Display row

The display row is built from an `InputDecorator` using `InputDecoration(labelText: context.l10n.medsAddFormLabel)`, which reuses the global `inputDecorationTheme` (outlined border, floating label) for visual consistency with the name field above it. Its inner `Row` contains:

- A leading **icon chip** — a rounded `Container` with `colorScheme.secondaryContainer` background, holding the selected form's icon (20 dp, `colorScheme.onSecondaryContainer`). Before any selection the chip shows a neutral placeholder icon (`LucideIcons.shapes`).
- An `Expanded` text column — a name line (`bodyLarge`, `colorScheme.onSurface`) showing either the selected form's localized name or the placeholder `context.l10n.medsAddFormPlaceholder` ("Choose a form"), and a sub line (`bodySmall`, `colorScheme.onSurfaceVariant`) showing the selected form's localized sub-description (empty before selection).
- A trailing chevron wrapped in `AnimatedRotation` (0 → 0.5 turns) that reflects open/closed state.

Tapping the display row toggles `_isOpen` via `setState`, expanding or collapsing the grid below.

### Grid card

The grid is wrapped in `AnimatedSize` (~250 ms). When collapsed its child is `SizedBox.shrink()`, so the 8 options and the grid title are **absent from the widget tree** — not merely hidden. When expanded, the child is a `Container` with `colorScheme.primaryContainer` background and rounded bottom corners, containing:

- A title reading `context.l10n.medsAddFormGridTitle` ("Common forms"), uppercase, `colorScheme.primary`, `labelMedium` bold.
- The 8 form options laid out as a 2-column grid (a `Column` of four `Row`s with `Expanded` pairs — avoids `GridView.count` and its `childAspectRatio` friction inside the outer `SingleChildScrollView`).

Each option chip shows a Lucide icon + the localized form name. The **selected** option uses `colorScheme.primary` background, `colorScheme.primary` border, and `colorScheme.onPrimary` for icon and label; unselected options use a transparent background with a surface-colored border.

Tapping an option: (1) sets `_selectedIndex` to that option's index, (2) updates the display row icon/name/sub, and (3) sets `_isOpen = false`, collapsing the grid.

### The 8 forms

Forms are defined as a top-level `final List<_MedFormOption>` (a private presentation-only value type). Each entry holds a stable `key` that matches the *planned* domain enum name, an `IconData`, and closure-based localized `name`/`sub` (resolved at build time via `context.l10n`). No `MedicationForm` enum or domain entity exists yet.

| # | key | English name | Icon |
|---|-----|-------------|------|
| 1 | `tablet` | Tablet | `LucideIcons.tablets` |
| 2 | `capsule` | Capsule | `LucideIcons.pill` |
| 3 | `syrup` | Syrup | `LucideIcons.milk` |
| 4 | `drops` | Drops | `LucideIcons.droplets` |
| 5 | `injection` | Injection | `LucideIcons.syringe` |
| 6 | `inhaler` | Inhaler | `LucideIcons.wind` |
| 7 | `cream` | Cream / Ointment | `LucideIcons.container` |
| 8 | `sachet` | Sachet | `LucideIcons.package` |

> Note: `LucideIcons.pills` (plural) does not exist in `lucide_icons_flutter` 3.1.12 — `LucideIcons.tablets` is used for the Tablet form.

### Scope and intentional no-ops

- **No Riverpod**: the picker is a plain `StatefulWidget`. No `ConsumerStatefulWidget`, no provider.
- **No persistence**: the selected form is held only in `_MedicationFormPicker`'s local state and discarded when the modal closes.
- **No callback to the parent**: `_AddMedicationModalState` does not read the selected form. The connection to the Save button will be wired in the data-save iteration.
- **Save remains a no-op** (spec 026, unchanged): it still does `onPressed: () {}`.
- **No domain/data layer** for meds: no `Medication` entity, no `MedicationForm` enum in `lib/`, no repository, no data source.

## Opening the modal

`MedsScreen` uses a private helper to push the modal:

```dart
void _openAddMedicationModal(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const AddMedicationModal(),
    ),
  );
}
```

`rootNavigator: true` is required here because `MedsScreen` lives inside `AppShell`'s `StatefulShellRoute`. Without it, `Navigator.push` would use the branch navigator, and the modal would not cover the bottom nav bar. `fullscreenDialog: true` gives the route the platform-standard full-screen modal presentation (slide-up on iOS, fade on Android) without needing a named `go_router` route — appropriate for transient, non-deep-linkable UI.

This pattern (`rootNavigator: true` + `MaterialPageRoute(fullscreenDialog: true)`) is the **project-standard** way to present a full-screen modal over the AppShell. Future features that need a full-screen form should follow the same approach.

## Localization keys

### Chrome and navigation

| Key | English | German | Ukrainian | Added in |
|---|---|---|---|---|
| `medsAddFabTooltip` | Add medication | Medikament hinzufügen | Додати ліки | `011-meds-add-fab` |
| `medsAddTitle` | Add medication | Medikament hinzufügen | Додати ліки | `011-meds-add-fab` |
| `medsAddNameLabel` | Medication name | Medikamentenname | Назва ліків | `026-add-med-name-input` |
| `medsAddSaveButton` | Save | Speichern | Зберегти | `026-add-med-name-input` |

`medsAddFabTooltip` and `medsAddTitle` are intentionally distinct so they can diverge if UX copy evolves (e.g. a shorter tooltip). `medsAddNameLabel` and `medsAddSaveButton` are the first form-field keys; additional field keys will be added as the form grows.

### Form picker (added in `027-med-form-picker`)

Three chrome keys for the picker control itself:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `medsAddFormLabel` | Medication form | Medikamentenform | Форма препарату |
| `medsAddFormPlaceholder` | Choose a form | Form wählen | Оберіть форму |
| `medsAddFormGridTitle` | Common forms | Typische Formen | Типові форми |

Sixteen keys for the 8 form options (name + sub each):

| Key | English | German | Ukrainian |
|---|---|---|---|
| `medsAddFormTablet` | Tablet | Tablette | Таблетка |
| `medsAddFormTabletSub` | Compressed form | Gepresste Form | Пресована форма |
| `medsAddFormCapsule` | Capsule | Kapsel | Капсули |
| `medsAddFormCapsuleSub` | Hard gelatin shell | Harte Gelatinehülle | Тверда желатинова оболонка |
| `medsAddFormSyrup` | Syrup | Sirup | Сироп |
| `medsAddFormSyrupSub` | Liquid dosage form | Flüssige Darreichungsform | Рідка лікарська форма |
| `medsAddFormDrops` | Drops | Tropfen | Краплі |
| `medsAddFormDropsSub` | Liquid drop form | Flüssige Tropfenform | Рідка крапельна форма |
| `medsAddFormInjection` | Injection | Injektion | Ін'єкція |
| `medsAddFormInjectionSub` | Intramuscular / IV | Intramuskulär / i.v. | Внутрішньом'язова/в/в |
| `medsAddFormInhaler` | Inhaler | Inhalator | Інгалятор |
| `medsAddFormInhalerSub` | Aerosol form | Aerosolform | Аерозольна форма |
| `medsAddFormCream` | Cream / Ointment | Creme / Salbe | Крем / Мазь |
| `medsAddFormCreamSub` | Topical form | Äußerliche Form | Зовнішня форма |
| `medsAddFormSachet` | Sachet | Sachet | Саше |
| `medsAddFormSachetSub` | Soluble powder | Lösliches Pulver | Розчинний порошок |

All 19 keys exist in `app_en.arb` (with `@`-description metadata), `app_de.arb`, and `app_uk.arb`. Consumed exclusively via `context.l10n` (no direct `AppLocalizations.of(context)!` call sites).

## Routing

`MedsScreen` is mounted at `/meds` as branch index 1 of the `StatefulShellRoute.indexedStack` in `lib/core/routing/app_router.dart`. Navigate to it with:

```dart
context.go('/meds');
```

The modal is not a named route — it is pushed imperatively via `Navigator` (see above).

## Evolution

The add-medication form is being built iteratively:

- **Feature 026 (done)** — name `TextField` + Save button (visual only; Save is a no-op).
- **Feature 027 (done)** — medication-form picker (visual only; selected form is local state, not wired to Save).
- **Pending** — real Save behaviour: `domain/` entities (`Medication`, `MedicationForm` enum), repository interface, `data/` datasource (drift), concrete repository, Riverpod provider wired to the Save button; the picker's selection callback will be connected at this point.
- **Pending** — additional form fields (dose, unit, schedule, etc.) as future specs are defined; the HTML design's `FORM_FIELDS` field-visibility logic (different fields shown per form) is also deferred.
- **Pending** — medication list replacing the `SizedBox.shrink()` body of `MedsScreen`.

No changes to the `AppBar` structure, the `/meds` route path, or the modal-opening pattern are expected.

## Related

- [`../../specs/011-meds-add-fab/spec.md`](../../specs/011-meds-add-fab/spec.md) — the spec that introduced the FAB and modal scaffolding
- [`../../specs/026-add-med-name-input/spec.md`](../../specs/026-add-med-name-input/spec.md) — the spec that added the name field and Save button (iteration 1)
- [`../../specs/027-med-form-picker/spec.md`](../../specs/027-med-form-picker/spec.md) — the spec that added the medication-form picker (iteration 2)
- [`home.md`](home.md) — `AppBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology, routing conventions, and the `rootNavigator` context
- [`i18n.md`](i18n.md) — how ARB keys are added and translated
- [`icons.md`](icons.md) — icon conventions (Lucide vs. Material)
