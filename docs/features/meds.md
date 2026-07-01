# Meds

## Overview

The **meds feature** owns the Meds tab — destination index 1 in `AppBottomNav`. The screen has a localized `AppBar`, a `FloatingActionButton` that opens a full-screen modal, and a reactive medication list (added in feature 034). The add-medication modal was built iteratively (features 026–031) — it collects a name, medication form, form-dependent fields (dose, quantity, stock), intake-time chips, and an intake-type segmented control with course-parameters card — and wired to real drift persistence in feature 032.

The feature now spans all three Clean-Architecture layers under `lib/features/meds/`: `presentation/` (screens, widgets, providers), `domain/` (entities, value objects, repository contract, use case), and `data/` (mapper, local data source, repository implementation). See [`medication-persistence.md`](medication-persistence.md) for the full persistence walkthrough.

As of feature 037, medication CRUD is complete: Create (`AddMedication`), Read (`watchAll`), Update (`EditMedication`), and Delete (`DeleteMedication`).

## MedsScreen

`MedsScreen` (in `lib/features/meds/presentation/screens/meds_screen.dart`) is a `ConsumerStatefulWidget` (upgraded from a placeholder `StatelessWidget` in feature 034) that renders a `Scaffold` with:

- An `AppBar` with an **animated slide-in search bar** mounted in `AppBar.flexibleSpace`. Tapping the trailing search `IconButton` triggers an `AnimationController`-driven `SlideTransition` (220 ms, ease-out) that slides the bar in from the trailing edge while the title fades out via `AnimatedOpacity`. The bar contains a leading search icon, an autofocused `TextField` (hint `medsListSearchHint`), and a trailing × `IconButton` — all inside a `Material` widget colored `ColorScheme.surfaceContainer`. Focus is requested on animation-complete (not synchronously), so the keyboard appears once the bar is settled. Closing (× or animation reverse) clears the query and restores the title. A 1-px `Divider` via `PreferredSize` pins to the bottom of the `AppBar`.
- A filter-chip row with two stadium `FilterChip`s ("All" / "Active").
- A reactive body — see the [Medication List Screen](#medication-list-screen-feature-034) section for the full layout.
- A `FloatingActionButton` (Material 3 FAB, `LucideIcons.plus`) with tooltip `context.l10n.medsAddFabTooltip` ("Add medication" in English). Tapping it calls `_openAddMedicationModal(context)`.

All UI state (search open flag, query string, active filter) is ephemeral `State` — no Riverpod providers are created for it.

## Add / Edit Medication Modal (iterations 6 + 7)

`AddMedicationModal` (in `lib/features/meds/presentation/widgets/add_medication_modal.dart`) is a `ConsumerStatefulWidget` (upgraded from `StatefulWidget` in feature 032) that owns seven `TextEditingController`s (name, dose, stock-remaining, stock-total, stock-warn, course-duration, course-pause) — all disposed in `dispose()`.

### Add/Edit dual mode (`initial` parameter)

`AddMedicationModal` accepts an optional `Medication? initial` parameter (added in feature 036). This single field drives both modes:

- **Add mode** (`initial == null`, default): all fields start empty; AppBar title is `medsAddTitle` ("Add medication"); Save routes to `addMedicationProvider`; success SnackBar uses `medsAddSaveSuccess` ("Medication saved").
- **Edit mode** (`initial != null`): all fields are pre-filled from the supplied `Medication` in `initState`; AppBar title is `medsEditTitle` ("Edit medication"); Save routes to `editMedicationProvider`; success SnackBar uses `medsEditSaveSuccess` ("Medication updated"). The Save button label remains `medsAddSaveButton` ("Save") in both modes.

The `const` constructor is preserved: `const AddMedicationModal()` for add mode, `AddMedicationModal(initial: medication)` for edit mode.

**Pre-fill in `initState`** (edit mode only):
- `_nameController.text` is set to `initial.name`.
- The matching `_MedFormOption` is looked up by `o.key == initial.form.name`; `_selectedForm` is set directly (the picker does not fire `onFormSelected` for this programmatic seed).
- Dose fields: quantity stepper for tablet/capsule; dose amount + unit index for liquid forms. Unit index defaults to 0 if the stored unit is not found in the form's `doseUnitValues`.
- Stock fields: populated when the form has stock and `initial.stock != null`.
- Intake times: slots are converted to `TimeOfDay` values, sorted ascending, and loaded into `_intakeTimes`.
- Intake type and course fields: `ContinuousType` → `_IntakeType.continuous`; `CourseType` → `_IntakeType.course` with duration, pause, and start-date pre-filled. Start date round-trip: the UTC calendar date is reconstructed as a local `DateTime(y, m, d)` so the save path can re-wrap it to UTC without timezone shift.

It is a full-screen modal with:

- A `Scaffold + AppBar` carrying the localized title `context.l10n.medsAddTitle` ("Add medication").
- A leading `IconButton` (back arrow, `LucideIcons.arrowLeft`) that calls `Navigator.of(context).pop()`.
- A `SingleChildScrollView` body whose content is structured as an outer un-padded `Column`, with each of the three form groups wrapped in `Padding(horizontal: 16)` and two full-bleed section dividers as direct siblings between them:

  | Group | Contents |
  |---|---|
  | **"What medicine"** | Name `TextField`, medication-form picker, form-dependent fields (dose, quantity, stock) |
  | **"When"** | Section title (`medsAddTimeTitle`, muted), intake-time chips |
  | **"Type"** | Section title (`medsAddIntakeTypeTitle`, muted), intake-type segmented control, optional course-parameters card |

  Below the last group: a full-width `FilledButton.icon` (`LucideIcons.save` + `context.l10n.medsAddSaveButton`). The button is disabled while a save is in flight (`_isSaving`); otherwise it invokes `_save()`, which delegates to the `AddMedication` use case via `ref.read(addMedicationProvider)`. Followed by a 24px bottom spacer.

### Section dividers

Two `_sectionDivider(ColorScheme)` widgets separate the three groups. Each renders a 1px `Divider` colored `colorScheme.outlineVariant`, with ~4px space above and ~8px space below, spanning the **full scroll viewport width** (no horizontal inset — dividers are direct children of the outer un-padded `Column`, outside any content `Padding`).

### Section-title labels

The "Intake time" and "Intake type" labels use `colorScheme.onSurfaceVariant` (muted) with ~4px space above and 12px space below. `_StockCard` and `_CourseCard` headers intentionally remain at full-emphasis `colorScheme.onSurface` — they are card headers, not section titles.

### Delete (feature 037)

Completes medication CRUD (Create/Read/Update/**Delete**). In **edit mode only** (`widget.initial != null`), the AppBar renders a trailing error-tinted trash `IconButton` (`LucideIcons.trash2`, tooltip `medsDeleteButtonTooltip`); no delete action exists in add mode.

Tapping it opens a Material `AlertDialog` (`_confirmDelete`, via `showDialog<bool>`):
- Title `medsDeleteDialogTitle` ("Delete medication?"), body `medsDeleteDialogBody` naming the medication (e.g. `Delete "Aspirin"? This can't be undone.`).
- **Cancel** (`medsDeleteDialogCancel`) pops the dialog with `false`; **Delete** (`medsDeleteDialogConfirm`, error-colored label) pops with `true`. Dismissing the dialog (barrier tap / back) also resolves to `false`.
- Only a `true` result proceeds — Cancel/dismiss is a no-op with no state mutation.

On confirm, `_onDelete` invokes `DeleteMedication` via `ref.read(deleteMedicationProvider).call(original.id)`, mirroring `_onSave`'s capture-before-`await` idiom (`ScaffoldMessenger` / `Navigator` / l10n captured before the dialog's `await`) plus a `_isDeleting` in-flight guard that disables the trash button during the call:

- **`Right`** — success SnackBar `medsDeleteSuccess` ("Medication deleted"), then the modal pops. The reactive medications list has already dropped the row.
- **`Left`** — error SnackBar `medsDeleteError` ("Couldn't delete medication. Please try again."), the modal stays open so the user can retry.

See [`medication-persistence.md`](medication-persistence.md#delete-flow-end-to-end) for the full use-case → repository → data-source path and the cascade-delete details.

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
| 7 | `cream` | Cream / Ointment | `LucideIcons.bandage` |
| 8 | `sachet` | Sachet | `LucideIcons.package` |

> Note: `LucideIcons.pills` (plural) does not exist in `lucide_icons_flutter` 3.1.12 — `LucideIcons.tablets` is used for the Tablet form.

### `initialFormKey` — edit-mode pre-selection (feature 036)

`_MedicationFormPicker` accepts an optional `String? initialFormKey` parameter. When non-null, `initState` looks up the matching `_MedFormOption` by `o.key == initialFormKey` and seeds `_selectedIndex` to that option's index. This causes the collapsed display to show the medication's form (icon, name, sub-description) immediately on first build, without requiring the user to open the grid. The picker does **not** fire `onFormSelected` for this programmatic seed — the parent (`_AddMedicationModalState`) sets `_selectedForm` directly in its own `initState`. When `initialFormKey` is `null` (add mode) the picker starts with no selection, identical to its original behavior.

### Scope

- **No Riverpod**: the picker is a plain `StatefulWidget`. No `ConsumerStatefulWidget`, no provider.
- **Selection hoisted via callback (spec 028)**: `_MedicationFormPicker` accepts a `ValueChanged<_MedFormOption> onFormSelected` callback. The picker keeps its own `_selectedIndex` / `_isOpen` state; `_AddMedicationModalState` receives the selected option and uses it to conditionally render form-dependent fields. `onFormSelected` is NOT fired for a programmatic `initialFormKey` seed.
- Selected form and all conditional field values are local state — discarded when the modal closes.

## Form-Dependent Fields (iteration 3 — visual only)

When the user selects a medication form, `_AddMedicationModalState` renders additional input fields between the picker and the Save button. All values are local state; nothing is persisted; Save remains a no-op.

### Field matrix

| Form | Dose field + unit dropdown | Quantity stepper | Pack-stock card |
|------|:-:|:-:|:-:|
| Tablet | — | step 0.5, min 0.5, unit "tab" | yes |
| Capsule | — | step 1, min 1, unit "cap" | yes |
| Syrup | ml | — | — |
| Drops | drops / ml | — | — |
| Injection | ml / mg / IU | — | — |
| Inhaler | — | — | — |
| Cream | — | — | — |
| Sachet | — | — | — |

Before any form is selected, **none** of the conditional widgets appear in the widget tree (not just hidden — the `if` guard evaluates to false).

### Dose field (`_DoseField`)

Shown for injection, syrup, and drops. A `Row` containing:
- A `TextField` (3/5 width, decimal keyboard, label `medsAddDoseLabel`) for the dose amount.
- A `DropdownButtonFormField<int>` (2/5 width, label `medsAddDoseUnitLabel`) for the unit. Injection offers ml / mg / IU; syrup offers ml only; drops offers drops / ml.

### Quantity stepper (`_QuantityStepper`)

Shown for tablet and capsule. Rendered inside an `InputDecorator` (label `medsAddQuantityLabel`) for visual consistency with the outlined fields above it. A `Row` with:
- A decrement `IconButton` (`LucideIcons.minus`) — value is clamped at `quantityMin` (0.5 for tablet, 1 for capsule).
- A centred `Text` showing the formatted value — no trailing `.0` for whole numbers (`1.0 → "1"`, `1.5 → "1.5"`).
- A muted unit label (`colorScheme.onSurfaceVariant`).
- An increment `IconButton` (`LucideIcons.plus`).

### Pack-stock card (`_StockCard`)

Shown for tablet and capsule. A rounded `Container` (`colorScheme.surfaceContainerLow` background, `colorScheme.outlineVariant` border, 16 dp radius) containing:
- A header row: `LucideIcons.packageOpen` + title `medsAddStockTitle`.
- A subtitle note `medsAddStockNote`.
- A side-by-side row: "Remaining in pack" (`medsAddStockRemainingLabel`) and "Total in pack" (`medsAddStockTotalLabel`) — both numeric `TextField`s.
- A "Warn when remaining reaches" `TextField` (`medsAddStockWarnLabel`) with a `LucideIcons.triangleAlert` suffix icon.

### Reset on form change

Switching to a different form clears all conditional field controllers and resets the stepper to the new form's `quantityMin`. This happens inside `setState` in `_AddMedicationModalState._onFormSelected`. Controllers are permanent `State` fields — they are cleared (`.clear()`), not recreated — to avoid use-after-dispose risks.

## Intake-Time Chips (iteration 4 — visual only)

The intake-time section sits between the form-dependent fields and the Save button. It lets users build a list of daily intake times as chips. Like all previous form iterations, nothing is persisted — the list is local widget state only and Save remains a no-op.

### State and ordering

`_AddMedicationModalState` holds a `List<TimeOfDay> _intakeTimes`. After any add or edit, the list is sorted ascending (by hour, then minute) so chips always render in chronological order. Duplicates (identified by the minutes-key `hour * 60 + minute`) are rejected: the list is left unchanged and a localized `SnackBar` informs the user. Editing a chip to its own current value is a silent no-op (no SnackBar).

### `_TimeChips` widget

A private `_TimeChips` widget renders the section inside an `InputDecorator` frame (label `medsAddTimeTitle`) for visual consistency with `_QuantityStepper`. Its content is a `Wrap` containing:

- One **`InputChip`** per `TimeOfDay` in the list:
  - Leading `LucideIcons.clock` icon.
  - Label: the time formatted as `HH:MM` in 24-hour format regardless of device locale, via `MaterialLocalizations.formatTimeOfDay(t, alwaysUse24HourFormat: true)`.
  - `onPressed`: opens `showTimePicker()` pre-filled with the chip's current time. Confirming replaces that chip's time; cancelling is a no-op.
  - `onDeleted` (the built-in × affordance): removes the chip without opening the picker. `InputChip.onDeleted` provides a natively separate tap target, avoiding overlapping-gesture bugs.
- One trailing **`ActionChip`** (solid outline, primary color, leading `LucideIcons.plus`, label `medsAddTimeAddChip`) that opens `showTimePicker()` with a fixed default of `08:00` and appends the chosen time on confirm.

### 24-hour format enforcement

The picker dialog is wrapped in `MediaQuery(data: ..., alwaysUse24HourFormat: true)` so the clock face and input field always use 24-hour mode regardless of the device locale. Chip labels use `MaterialLocalizations.formatTimeOfDay(t, alwaysUse24HourFormat: true)` for the same reason.

### Async-safety

`showTimePicker` is awaited. Both add and edit handlers check `if (!context.mounted) return;` before calling `setState` or `ScaffoldMessenger`, satisfying `use_build_context_synchronously`.

### Scope and intentional no-ops

- `_intakeTimes` is **not read by Save** and is **not persisted**. It is discarded when the modal closes.
- No `domain/` or `data/` files are touched. The `TimeSlot` / `Schedule` domain entities, drift table, and Riverpod wiring are deferred to the data-save iteration.

## Intake-Type Control (iteration 5 — visual only)

The intake-type section sits between the intake-time chips and the Save button. It lets users choose whether a medication is taken continuously or as a bounded course. Like all previous form iterations, nothing is persisted — all state is local widget state only and Save remains a no-op.

### Toggle

A `SegmentedButton<_IntakeType>` renders two segments:

| Segment | Value | Icon |
|---|---|---|
| Continuous | `_IntakeType.continuous` | `LucideIcons.infinity` |
| Course | `_IntakeType.course` | `LucideIcons.repeat` |

The default selection on modal open is **Continuous**. Switching to Course immediately reveals the `_CourseCard` below; switching back collapses it. The card is absent from the widget tree (not merely hidden) when Continuous is selected.

```dart
SegmentedButton<_IntakeType>(
  key: const ValueKey('medsAddIntakeTypeSegmented'),
  segments: <ButtonSegment<_IntakeType>>[
    ButtonSegment<_IntakeType>(
      value: _IntakeType.continuous,
      label: Text(context.l10n.medsAddIntakeTypeContinuous),
      icon: const Icon(LucideIcons.infinity),
    ),
    ButtonSegment<_IntakeType>(
      value: _IntakeType.course,
      label: Text(context.l10n.medsAddIntakeTypeCourse),
      icon: const Icon(LucideIcons.repeat),
    ),
  ],
  selected: <_IntakeType>{_intakeType},
  onSelectionChanged: (Set<_IntakeType> selection) {
    if (selection.isEmpty) return;
    setState(() => _intakeType = selection.first);
  },
),
```

### Course-parameters card (`_CourseCard`)

Shown only when Course is selected. A rounded `Container` (`colorScheme.surfaceContainerLow` background, `colorScheme.outlineVariant` border, 16 dp radius) containing:

- A header row: `LucideIcons.repeat` (`colorScheme.tertiary`) + title `medsAddCourseParamsTitle`.
- A side-by-side row: **Duration (days)** (`medsAddCourseDurationLabel`) and **Pause (days)** (`medsAddCoursePauseLabel`) — both numeric `TextField`s. Pre-filled with `"7"` and `"0"` respectively.
- A **Start-date** tap target (`medsAddCourseStartLabel`) styled as an `InputDecorator` with a `LucideIcons.calendarDays` suffix icon. Tapping opens `showDatePicker`; the chosen date is normalised to midnight via `DateUtils.dateOnly`. Defaults to today via `DateUtils.dateOnly(clock.now())` — using the `clock` package so widget tests can override the clock without affecting real time.
- A **live info chip** (`colorScheme.tertiaryContainer` background) showing the inclusive course date range.

### Info chip and date-range computation

The info chip recomputes whenever the duration field changes or the start date is updated. The computation in `_courseInfoLabel`:

- If `_durationController` contains a valid integer ≥ 1: renders `medsAddCourseRangeLabel(range, count)` where `range` is `"<start> — <end>"` and `end = start + (duration − 1)` days (inclusive). Both dates are formatted via `MaterialLocalizations.formatMediumDate` — no `intl`/`DateFormat` dependency.
- Otherwise: falls back to `medsAddCourseStartOnly(date)` showing only the start date.

This is the project's first **ICU-plural + placeholder** ARB message. `medsAddCourseRangeLabel` uses a mixed `{range}` String placeholder and a `{count}` plural selector. Ukrainian uses four plural categories: `one/few/many/other`.

### Scope and intentional no-ops

- `_intakeType`, `_durationController`, `_pauseController`, and `_startDate` are **not read by Save** and are **not persisted**. They are discarded when the modal closes.
- No `domain/` or `data/` files are touched. The `Schedule` / `Course` domain entities and drift table are deferred to the data-save iteration.
- The `clock` package is now a **direct dependency** (promoted from transitive). Default start date = `DateUtils.dateOnly(clock.now())`; tests override via `withClock(Clock.fixed(...), ...)`.

## Opening the modal

`MedsScreen` has two private helpers that push the modal — one for add, one for edit:

```dart
void _openAddMedicationModal(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const AddMedicationModal(),
    ),
  );
}

// Added in feature 036 — mirrors the add helper but passes initial.
void _openEditMedicationModal(BuildContext context, Medication medication) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AddMedicationModal(initial: medication),
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
| `medsEditTitle` | Edit medication | Medikament bearbeiten | Редагувати ліки | `036-meds-edit` |
| `medsEditSaveSuccess` | Medication updated | Medikament aktualisiert | Ліки оновлено | `036-meds-edit` |

`medsAddFabTooltip` and `medsAddTitle` are intentionally distinct so they can diverge if UX copy evolves (e.g. a shorter tooltip). `medsAddNameLabel` and `medsAddSaveButton` are the first form-field keys; additional field keys will be added as the form grows.

`medsEditTitle` and `medsEditSaveSuccess` are the two keys added for the edit flow (feature 036). The Save button label is shared: `medsAddSaveButton` ("Save") is used in both add and edit mode. Both new keys exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb` with `@`-description metadata in `app_en.arb`.

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

### Form-dependent fields (added in `028-form-dependent-fields`)

Five label keys for the conditional input controls:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `medsAddDoseLabel` | Dose amount | Dosismenge | Доза |
| `medsAddDoseUnitLabel` | Unit | Einheit | Одиниця |
| `medsAddQuantityLabel` | Quantity per intake | Menge pro Einnahme | Кількість на прийом |
| `medsAddStockTitle` | Pack stock | Packungsvorrat | Запас упаковки |
| `medsAddStockNote` | Track remaining pills to get low-stock alerts | Verbleibende Tabletten verfolgen, um Warnungen bei niedrigem Bestand zu erhalten | Відстежуйте залишок таблеток для сповіщень про низький запас |
| `medsAddStockRemainingLabel` | Remaining | Verbleibend | Залишок |
| `medsAddStockTotalLabel` | Total in pack | Gesamt in Packung | Всього в упаковці |
| `medsAddStockWarnLabel` | Warn when remaining reaches | Warnen, wenn verbleibend erreicht | Попередити, коли залишок досягне |

Six unit abbreviation keys (resolved at runtime via `context.l10n`):

| Key | English | German | Ukrainian | Used by |
|---|---|---|---|---|
| `medsAddUnitTablet` | tab | Tab. | таб. | tablet stepper |
| `medsAddUnitCapsule` | cap | Kaps. | кап. | capsule stepper |
| `medsAddUnitMl` | ml | ml | мл | syrup / drops / injection |
| `medsAddUnitMg` | mg | mg | мг | injection |
| `medsAddUnitUnits` | IU | IE | МО | injection (International Units) |
| `medsAddUnitDrops` | drops | Tropfen | краплі | drops |

All 14 keys exist in `app_en.arb` (with `@`-description metadata), `app_de.arb`, and `app_uk.arb`.

### Intake-time chips (added in `029-intake-time-chips`)

Four keys for the time-chips section:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `medsAddTimeTitle` | Intake time | Einnahmezeit | Час прийому |
| `medsAddTimeAddChip` | + time | + Zeit | + час |
| `medsAddTimeRemoveTooltip` | Remove | Entfernen | Видалити |
| `medsAddTimeDuplicate` | That time is already added | Diese Zeit ist bereits hinzugefügt | Цей час вже додано |

All 4 keys exist in `app_en.arb` (with `@`-description metadata), `app_de.arb`, and `app_uk.arb`.

### Intake-type control (added in `030-intake-type-control`)

Nine keys for the segmented toggle and the course-parameters card:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `medsAddIntakeTypeTitle` | Intake type | Einnahmeart | Тип прийому |
| `medsAddIntakeTypeContinuous` | Continuous | Dauerhaft | Постійний |
| `medsAddIntakeTypeCourse` | Course | Kur | Курс |
| `medsAddCourseParamsTitle` | Course parameters | Kurparameter | Параметри курсу |
| `medsAddCourseDurationLabel` | Duration (days) | Dauer (Tage) | Тривалість (дні) |
| `medsAddCoursePauseLabel` | Pause (days) | Pause (Tage) | Пауза (дні) |
| `medsAddCourseStartLabel` | Start date | Startdatum | Дата початку |
| `medsAddCourseRangeLabel` | `Course: {range} ({count} day(s))` | `Kur: {range} ({count} Tag(e))` | `Курс: {range} ({count} день/дні/днів)` |
| `medsAddCourseStartOnly` | `Course starts {date}` | `Kur beginnt {date}` | `Курс починається {date}` |

`medsAddCourseRangeLabel` is the project's **first ICU-plural + placeholder message** — it mixes a `{range}` String placeholder with a `{count}` plural selector. Ukrainian uses four plural categories (`one/few/many/other`); English and German use `=1/other`. All 9 keys exist in `app_en.arb` (with `@`-description metadata), `app_de.arb`, and `app_uk.arb`.

### Medication list screen (added in `034-meds-list`)

Chrome, filter, and section keys:

| Key | English | Notes |
|---|---|---|
| `medsListTitle` | My medications | AppBar title (not shared with bottom-nav label) |
| `medsListSearchHint` | Search medications… | Placeholder in inline search field |
| `medsListSearchTooltip` | Search | Tooltip on the search icon button |
| `medsListFilterAll` | All | Filter chip — all medications |
| `medsListFilterActive` | Active | Filter chip — hides completed courses |
| `medsListSectionContinuous` | Continuous | Section header for continuous medications |
| `medsListSectionCourse` | Courses | Section header for course medications |
| `medsListSectionEmpty` | Nothing found | Shown inside a section when filter/search yields no items |
| `medsListEmptyTitle` | No medications yet | Empty-state title when the DB has no rows |
| `medsListEmptyBody` | Tap + to add your first medication | Empty-state body |

Chip and subtitle keys:

| Key | English | Notes |
|---|---|---|
| `medsListStatusActive` | Active | Status chip for active medications |
| `medsListStatusCompleted` | Completed | Status chip for completed (finished) courses |
| `medsListTypeContinuous` | continuous | Type chip for continuous medications |
| `medsListTypeCoursePaused` | Paused | Type chip during a cyclic course's pause gap |
| `medsListTypeCourseDay` | `Day {current}/{total}` | Type chip during an active course window |
| `medsListStock` | `{remaining} of {total} pcs` | Stock segment in the tile subtitle |

Dose-unit abbreviation keys (used in tile subtitle via `doseUnitAbbrev()`):

| Key | English | Used by |
|---|---|---|
| `doseUnitTablet` | tab | tablet stepper |
| `doseUnitCapsule` | cap | capsule stepper |
| `doseUnitMl` | ml | syrup / drops / injection |
| `doseUnitMg` | mg | injection |
| `doseUnitDrops` | drops | drops |
| `doseUnitUnits` | IU | injection (International Units) |
| `doseUnitPuff` | puff | inhaler |
| `doseUnitApplication` | dose | cream |
| `doseUnitSachet` | sachet | sachet |

All keys exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb` with `@`-description metadata.

## Routing

`MedsScreen` is mounted at `/meds` as branch index 1 of the `StatefulShellRoute.indexedStack` in `lib/core/routing/app_router.dart`. Navigate to it with:

```dart
context.go('/meds');
```

The modal is not a named route — it is pushed imperatively via `Navigator` (see above).

## Medication List Screen (feature 034)

The `SizedBox.shrink()` placeholder body is replaced by a fully reactive medication list. `MedsScreen` is now a `ConsumerStatefulWidget` that watches `medicationsListProvider`, applies local ephemeral state (search, filter), builds a pure view model, and renders two grouped sections.

### Reactive read flow

```
drift left-outer-join query (medications ⨝ time_slots)
  → MedicationLocalDataSource.watchAllMedications()   [Stream<List<...>>]
  → MedicationRepositoryImpl.watchAll()               [Stream<Either<Failure, List<Medication>>>]
  → MedicationRepository.watchAll()                   [domain contract]
  → medicationsListProvider (@riverpod Stream)        [maps Left→throw, Right→value]
  → medicationsListProvider as AsyncValue<List<Medication>>
  → MedsScreen (ref.watch)
```

`medicationsListProvider` is a `@riverpod`-annotated function that returns `Stream<List<Medication>>`. It maps each `Either` emission: `Right` becomes a plain data value, `Left(failure)` is re-thrown so Riverpod surfaces it as `AsyncValue.error`. Because it is a stream provider, the `AsyncValue` updates live on every add or delete — no manual refresh is required.

### Activity derivation and course progress

Active/Completed status and course cycle-day counters are **derived at read time** — they are never stored in the drift schema.

`resolveMedicationActivity(medication, now)` (in `domain/value_objects/medication_activity.dart`) computes `MedicationActivityStatus`:
- `ContinuousType` medications are always **Active**.
- `CourseType` medications with `pauseDays > 0` (cyclic) are always **Active**.
- Non-cyclic `CourseType` medications become **Completed** once `daysSinceStart > durationDays - 1`.

`CourseProgress.resolve(course: ..., now: now)` (in `domain/value_objects/course_progress.dart`) produces the cycle-day counter displayed as "Day X/Y" or "Paused" on the type chip:
- Non-cyclic courses: `currentDay = daysSinceStart + 1`, clamped to `totalDays`.
- Cyclic courses: position within the repeating `durationDays + pauseDays` window. During the pause gap, `phase = CoursePhase.paused` and `currentDay` pins to `totalDays`.

**DST-safe day math**: both derivations reduce `DateTime` values to UTC-midnight by extracting local year/month/day and reconstructing with `DateTime.utc(year, month, day)`. This means `difference(...).inDays` counts whole calendar days without a spring-forward shift truncating a 23-hour day to the wrong count. `startDate` values from the form are stored the same way (see [medication-persistence.md](medication-persistence.md)).

### View model

`buildMedsListView(meds:, now:, filter:, query:)` (in `presentation/view_models/meds_list_view_model.dart`) is a pure, synchronous function that shapes the raw list. Pipeline:

1. Map each `Medication` to a `MedListItem` — attaches derived `activity` and (for courses) `progress`.
2. Record `totalCount` before any filtering (distinguishes "empty DB" from "no matches").
3. Apply `query` via **fuzzy name matching**: when the trimmed query is non-empty, score each item with `fuzzyNameScore` (from `lib/core/utils/fuzzy_name_match.dart`) and keep those scoring at or above `medsSearchIncludeThreshold` (`0.6`). Substring and prefix matches always score ≥ 0.9 so they clear the threshold without needing special-case code. When the query is blank, all items are kept.
4. Apply `filter`: `MedsFilter.all` passes everything; `MedsFilter.active` drops `completed` courses.
5. Group by `MedicationType` (continuous / course). While a query is active, sort each group by **descending match score** (ties broken by name ascending, case-insensitive). With no active query, sort by name ascending (case-insensitive only).

Returns `MedsListView` with `continuous`, `course`, and `totalCount`. `MedsScreen` passes `clock.now()` as `now`, keeping the function unit-testable without pumping widgets.

### Fuzzy name matcher (`lib/core/utils/fuzzy_name_match.dart`)

A generic, dependency-free utility (pure Dart, no Flutter imports) used by `buildMedsListView`. Two public symbols:

- `levenshtein(a, b) → int` — classic Levenshtein edit distance, O(m × n) time and O(min length) space, operating on Unicode code points (so Cyrillic and Latin BMP characters each count as one unit).
- `fuzzyNameScore(query, name) → double` — normalized similarity in `[0.0, 1.0]`. Both arguments are lowercased (Unicode-aware `toLowerCase()`) and the query is trimmed before comparison. Returns one of four disjoint score bands:

  | Band | Score | Condition |
  |------|-------|-----------|
  | Exact | `1.0` | `query == name` after normalization |
  | Prefix | `~0.95` | name starts with the query (non-exact) |
  | Contains | `~0.9` | name contains the query elsewhere |
  | Fuzzy-only | `[0.0, 0.85]` | no substring; `1 - levenshtein / maxLength`, clamped below `0.9` |

  The band ordering guarantees that any case-insensitive substring match always outranks a fuzzy-only match. An empty or whitespace-only query returns `0.0`.

Because the matcher is feature-agnostic it lives in `core/utils/` and is reusable by future searchable lists (e.g. medication history).

### Screen layout

`MedsScreen` renders:

1. **AppBar** — animated slide-in search bar (see [MedsScreen](#medsscreen) above). When search is closed, the localized `medsListTitle` text is shown. A 1-px `Divider` pins to the bottom of the app bar.
2. **Filter-chip row** — two stadium `FilterChip`s ("All" / "Active") with `showCheckmark: false`. Selected chip: solid `primary` background, `onPrimary` label weight 500. Unselected: `secondaryContainer` background.
3. **Body** — `medicationsListProvider.when(...)`:
   - loading → `CircularProgressIndicator`
   - error → muted centered error text
   - data with `totalCount == 0` → centered `_EmptyState` card (`medsListEmptyTitle` + `medsListEmptyBody`, both `onSurfaceVariant`). This takes precedence and shows even while a query is active.
   - data with `totalCount > 0` → `ListView` with two `MedicationSection` children (continuous then course), 88 px bottom padding to clear the FAB. Both sections are always rendered; per-section empty placeholders appear only when `queryActive` is `true`.
4. **FAB** (`key: ValueKey('medsAddFab')`) — unchanged from before; opens `AddMedicationModal`.

### Tile anatomy and tap-to-edit (feature 036)

`MedicationTile` renders one `MedListItem` as a custom `Row` tile. It accepts an optional `VoidCallback? onTap` callback (added in feature 036). When `onTap` is non-null the entire tile body is wrapped in an `InkWell` that provides ripple feedback; when `onTap` is `null` the tile renders as a non-interactive row (default for callers that do not supply a callback). Completed-course tiles (`activity == MedicationActivityStatus.completed`) are rendered at **0.65 opacity** via an `Opacity` wrapper that wraps the entire tile.

**Tap wiring**: `MedicationSection` received a `void Function(Medication)? onTapItem` parameter; for each tile it passes `onTap: () => onTapItem(items[i].medication)` when the callback is non-null, otherwise `onTap: null`. `MedsScreen` supplies `onTapItem: (med) => _openEditMedicationModal(context, med)` to both the continuous and course sections, so tapping any tile opens the edit modal pre-filled with that medication.

| Slot | Content |
|------|---------|
| Leading | 48×48 rounded-square (radius 12) icon badge. For **active** medications: `primaryContainer`/`onPrimaryContainer` (continuous) or `tertiaryContainer`/`onTertiaryContainer` (course). For **completed** medications: neutral `surfaceContainerHighest`/`onSurfaceVariant` regardless of type. Icon from `medicationFormIcon(form)`. |
| Body | Name (`bodyLarge` weight 400, single line ellipsized). Subtitle (`bodySmall`, `onSurfaceVariant`): `dose · times · stock`, joined with ` · `. Stock segment is always bold (`w600`) and turns `error` color when `remaining ≤ warnAt`. Below: `Wrap` of chips in type-first order for courses (see below). |
| Trailing | `LucideIcons.chevronRight`, 20 dp, `onSurfaceVariant`. |

**Chip order** depends on medication type:
- **Course** tiles: type chip first (`Day X/Y` or `Paused`), then status chip.
- **Continuous** tiles: status chip first, then type chip.

Status chip colors: Active → `primaryContainer`/`onPrimaryContainer`; Completed → `surfaceContainerHighest`/`onSurfaceVariant`. Type chip for courses: active window (`Day X/Y`) → `tertiaryContainer`/`onTertiaryContainer`; paused → `surfaceContainerHigh`/`onSurfaceVariant`. All chips are non-interactive stadium pill shapes (`borderRadius: 100`).

### Debug seeder

`devSeedMedications(DateTime now)` (in `lib/core/database/dev_seed.dart`) builds 12 representative `Medication` aggregates covering all 8 `MedicationForm` values, both `MedicationType` variants including cyclic-active, cyclic-paused, and completed states, and with/without dose, stock, and low-stock cases.

`devSeedProvider` (`@Riverpod(keepAlive: true)`) reads this list and inserts each entry through `MedicationRepository.add` (the real write path, not direct drift calls). It is guarded by two conditions, both of which must be true:
- `kDebugMode == true` (no-op in release builds)
- the `medications` table is currently empty (non-destructive: never overwrites existing data)

Failed inserts are silently discarded so a seeding error never crashes startup. The provider is triggered once in `app_bootstrap.dart` via `ref.read(devSeedProvider.future)`.

**Integration-test override**: the boot harness (`integration_test/support/app_harness.dart`) overrides `devSeedProvider` with a no-op (`devSeedProvider.overrideWith((ref) async {})`). Integration tests run in `kDebugMode` and without this override the seeder would populate the fresh empty database, breaking golden-flow assertions that expect an exact row count after a single UI-driven medication add. The seeder is debug-only scaffolding, not behavior under test, so disabling it does not mask any production wiring bug.

### Deferred items

- **Tile-tap navigation** — tapping a `MedicationTile` now opens the edit modal (feature 036). A read-only detail screen is still deferred.
- **Archive state** — medications cannot yet be archived; the Completed status is derived from a non-cyclic course's end date, not from an explicit archive flag.

## Evolution

The add-medication form is being built iteratively:

- **Feature 026 (done)** — name `TextField` + Save button (visual only; Save is a no-op).
- **Feature 027 (done)** — medication-form picker (visual only; selected form is local state, not wired to Save).
- **Feature 028 (done)** — form-dependent fields: quantity stepper + pack-stock card for tablet/capsule; dose field + unit dropdown for injection/syrup/drops; picker selection hoisted to modal via callback. Still visual only — Save remains a no-op; no persistence.
- **Feature 029 (done)** — intake-time chips: `_TimeChips` widget with `InputChip` per time (tap to edit, × to remove) plus a trailing `ActionChip` to add; auto-sorted ascending, duplicates rejected with SnackBar; 24-hour forced via `MediaQuery` + `MaterialLocalizations`. Still visual only — `_intakeTimes` is local state, not read by Save, not persisted.
- **Feature 030 (done)** — intake-type control: `SegmentedButton<_IntakeType>` (Continuous / Course); selecting Course reveals `_CourseCard` with Duration, Pause, and Start-date fields plus a live date-range info chip. Date defaults to today via `clock.now()` (test-overridable). First ICU-plural ARB message (`medsAddCourseRangeLabel`). Still visual only — all course fields are local state, not read by Save, not persisted.
- **Feature 031 (done)** — section dividers and spacing alignment: the modal body is restructured from a single outer `Padding(16)` to an outer un-padded `Column` with per-group horizontal insets, enabling two full-bleed 1px `outlineVariant` dividers between the three form groups. Section-title labels ("Intake time", "Intake type") are muted to `onSurfaceVariant`. Minor spacing corrections: 24px bottom spacer after Save, stock card header→note gap 8px, form-option chip padding 12/10, picker grid-card padding `fromLTRB(12,12,12,14)`. No new l10n keys; no behavior change; Save remains a no-op.
- **Feature 032 (done)** — real Save behaviour wired. `AddMedicationModal` converted to a `ConsumerStatefulWidget`. Pure-Dart domain layer added (`Medication`, `MedicationForm`, `TimeSlot`, `Schedule`, `MedicationType`, `Dosage`, `PackStock`, value-object IDs). Local drift database created (`Medications` + `TimeSlots` tables, `schemaVersion=1`). `AddMedication` use case validates and delegates. Save invokes the use case, pops on success, shows a localized error SnackBar on failure, disables the button during the in-flight call. See [`medication-persistence.md`](medication-persistence.md).
- **Feature 034 (done)** — medication list screen. `MedsScreen` upgraded from a `StatelessWidget` placeholder to a `ConsumerStatefulWidget`. Reactive `watchAll` query added to the data source and repository. `medicationsListProvider` stream provider wires the live list to the UI. Pure `buildMedsListView` view-model function. `MedicationTile`, `MedicationSection` widgets. Active/Completed and course cycle-day derivations added to domain. Debug seeder (`devSeedMedications` + `devSeedProvider`). See the [Medication List Screen](#medication-list-screen-feature-034) section above.
- **Feature 035 (done)** — meds-list search and empty-state fidelity. Animated slide-in search bar replaces the title-swap approach. Fuzzy name matching (`fuzzyNameScore` in `lib/core/utils/fuzzy_name_match.dart`) replaces the plain substring filter — typo-tolerant with score-ranked results within each section while a query is active. Per-section "nothing found" placeholder gated on `queryActive && items.isEmpty`. Completed-course tiles de-emphasised: 0.65 opacity, neutral `surfaceContainerHighest` badge, grey `surfaceContainerHighest` status chip. Course chip order fixed: type chip before status chip. Integration-test harness updated to override `devSeedProvider` with a no-op to protect golden-flow assertions from debug-seeded rows.
- **Feature 036 (done)** — tap-to-edit. `AddMedicationModal` gained a `Medication? initial` parameter enabling add/edit dual mode. `_MedicationFormPicker` gained `initialFormKey` to pre-select the form in edit mode. `MedicationTile` wrapped in `InkWell(onTap:)`; `MedicationSection` threads `onTapItem`; `MedsScreen` supplies `_openEditMedicationModal`. Domain: new `EditMedication` use case (slot-ID reconciliation, same 4 validation rules). Data: `MedicationRepository.update` + `MedicationLocalDataSource.upsertMedication` (`insertOnConflictUpdate` to avoid cascade-delete of time slots). Provider: `editMedicationProvider`. New l10n keys: `medsEditTitle`, `medsEditSaveSuccess`. See [`medication-persistence.md`](medication-persistence.md) and [`../../specs/036-meds-edit/spec.md`](../../specs/036-meds-edit/spec.md).
- **Feature 037 (done)** — delete medication, completing CRUD. Edit-mode-only error-tinted trash `IconButton` in the AppBar opens a Material `AlertDialog` confirmation (`showDialog<bool>`). Domain: new `DeleteMedication` use case (pure pass-through, no validation needed). Data: `MedicationRepository.delete` + `MedicationLocalDataSource.deleteMedication` (single drift `DELETE`; time slots removed by the existing `onDelete: cascade` FK). Provider: `deleteMedicationProvider`. Deleting an absent id is an idempotent success. New l10n keys: `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody`, `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError`. See [`medication-persistence.md`](medication-persistence.md#delete-flow-end-to-end) and [`../../specs/037-meds-delete/spec.md`](../../specs/037-meds-delete/spec.md).
- **Pending** — schedule, reminder, and other form fields as future specs are defined.
- **Pending** — archive state (explicit flag, not derived from course end date).

No changes to the `AppBar` structure, the `/meds` route path, or the modal-opening pattern are expected.

## Related

- [`medication-persistence.md`](medication-persistence.md) — domain model, drift schema, Save flow, and architecture decisions for feature 032
- [`../../specs/011-meds-add-fab/spec.md`](../../specs/011-meds-add-fab/spec.md) — the spec that introduced the FAB and modal scaffolding
- [`../../specs/026-add-med-name-input/spec.md`](../../specs/026-add-med-name-input/spec.md) — the spec that added the name field and Save button (iteration 1)
- [`../../specs/027-med-form-picker/spec.md`](../../specs/027-med-form-picker/spec.md) — the spec that added the medication-form picker (iteration 2)
- [`../../specs/028-form-dependent-fields/spec.md`](../../specs/028-form-dependent-fields/spec.md) — the spec that added form-dependent input fields (iteration 3)
- [`../../specs/029-intake-time-chips/spec.md`](../../specs/029-intake-time-chips/spec.md) — the spec that added the intake-time chips section (iteration 4)
- [`../../specs/030-intake-type-control/spec.md`](../../specs/030-intake-type-control/spec.md) — the spec that added the intake-type segmented control and course-parameters card (iteration 5)
- [`../../specs/031-add-med-dividers/spec.md`](../../specs/031-add-med-dividers/spec.md) — the spec that added full-bleed section dividers and aligned spacing/styling to the HTML design template (iteration 6)
- [`../../specs/032-med-persistence/spec.md`](../../specs/032-med-persistence/spec.md) — the spec that wired real Save persistence (iteration 7)
- [`../../specs/034-meds-list/spec.md`](../../specs/034-meds-list/spec.md) — the spec that built the reactive medication list screen (feature 034)
- [`../../specs/035-meds-list-search/spec.md`](../../specs/035-meds-list-search/spec.md) — the spec that added fuzzy search, animated search bar, empty-state gating, and completed-tile de-emphasis (feature 035)
- [`../../specs/036-meds-edit/spec.md`](../../specs/036-meds-edit/spec.md) — the spec that added tap-to-edit, the modal dual mode, slot reconciliation, and the update persistence path (feature 036)
- [`../../specs/037-meds-delete/spec.md`](../../specs/037-meds-delete/spec.md) — the spec that added the delete flow, completing medication CRUD (feature 037)
- [`home.md`](home.md) — `AppBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology, routing conventions, the `rootNavigator` context, the local database section, and the reactive read pattern
- [`i18n.md`](i18n.md) — how ARB keys are added and translated
- [`icons.md`](icons.md) — icon conventions (Lucide vs. Material) and the `medicationFormIcon` shared resolver
