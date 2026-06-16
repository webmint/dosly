# Meds

## Overview

The **meds feature** owns the Meds tab — destination index 1 in `AppBottomNav`. The screen has a localized `AppBar`, a `FloatingActionButton` that opens a full-screen modal, and an intentionally empty body (medication list is pending a future spec). The add-medication modal is being built iteratively (features 026–030): it currently has a name field, a medication-form picker, form-dependent fields (dose, quantity, stock), an intake-time chips section, and an intake-type segmented control with a course-parameters card — all visual only. Persistence, domain layer, and Save wiring are still pending.

Everything in this feature lives under `lib/features/meds/presentation/`. There is no `domain/` or `data/` layer yet.

## MedsScreen

`MedsScreen` (in `lib/features/meds/presentation/screens/meds_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `bottomNavMeds` string (`context.l10n.bottomNavMeds`), shared with the bottom navigation bar destination label.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the medication-list feature is implemented.
- A `FloatingActionButton` (Material 3 FAB, `LucideIcons.plus`) with tooltip `context.l10n.medsAddFabTooltip` ("Add medication" in English). Tapping it calls `_openAddMedicationModal(context)`.

## Add-Medication Modal (iteration 5 — visual only)

`AddMedicationModal` (in `lib/features/meds/presentation/widgets/add_medication_modal.dart`) is a `StatefulWidget` that owns seven `TextEditingController`s (name, dose, stock-remaining, stock-total, stock-warn, course-duration, course-pause) — all disposed in `dispose()`. It is a full-screen modal with:

- A `Scaffold + AppBar` carrying the localized title `context.l10n.medsAddTitle` ("Add medication").
- A leading `IconButton` (back arrow, `LucideIcons.arrowLeft`) that calls `Navigator.of(context).pop()`.
- A `SingleChildScrollView → Padding(16) → Column(crossAxisAlignment: stretch)` body containing:
  - An outlined `TextField` bound to `_nameController` with label `context.l10n.medsAddNameLabel`. The outlined, transparent styling (2px outline, `primary` on focus) comes from the global `inputDecorationTheme` in `lib/core/theme/app_theme.dart` — no call-site border/color overrides.
  - A medication-form picker (added in iteration 2 — see below).
  - Form-dependent fields gated on the selected form's capability flags (added in iteration 3 — see below).
  - An intake-time chips section (added in iteration 4 — see below).
  - An intake-type segmented control and optional course-parameters card (added in iteration 5 — see below).
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
// _TimeChips inserted here (iteration 4)
const SizedBox(height: 16),
FilledButton.icon(
  onPressed: () {},
  icon: const Icon(LucideIcons.save),
  label: Text(context.l10n.medsAddSaveButton),
),
```

The Save button's empty callback is **intentional and documented** (spec 026 through 030, iterations 1–5). It does not validate input, persist data, pop the modal, or give user feedback. Real save behaviour — drift persistence, domain layer, Riverpod provider — will be wired in the data-save iteration. There is still no `domain/` or `data/` layer for this feature.

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
- **Selection hoisted via callback (spec 028)**: `_MedicationFormPicker` accepts a `ValueChanged<_MedFormOption> onFormSelected` callback. The picker keeps its own `_selectedIndex` / `_isOpen` state; `_AddMedicationModalState` receives the selected option and uses it to conditionally render form-dependent fields (see below). The selection is **not** connected to the Save button.
- **No persistence**: the selected form and all conditional field values are local state — discarded when the modal closes.
- **Save remains a no-op** (spec 026–028, unchanged): it still does `onPressed: () {}`.
- **No domain/data layer** for meds: no `Medication` entity, no `MedicationForm` enum in `lib/`, no repository, no data source.

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
- **Feature 028 (done)** — form-dependent fields: quantity stepper + pack-stock card for tablet/capsule; dose field + unit dropdown for injection/syrup/drops; picker selection hoisted to modal via callback. Still visual only — Save remains a no-op; no persistence.
- **Feature 029 (done)** — intake-time chips: `_TimeChips` widget with `InputChip` per time (tap to edit, × to remove) plus a trailing `ActionChip` to add; auto-sorted ascending, duplicates rejected with SnackBar; 24-hour forced via `MediaQuery` + `MaterialLocalizations`. Still visual only — `_intakeTimes` is local state, not read by Save, not persisted.
- **Feature 030 (done)** — intake-type control: `SegmentedButton<_IntakeType>` (Continuous / Course); selecting Course reveals `_CourseCard` with Duration, Pause, and Start-date fields plus a live date-range info chip. Date defaults to today via `clock.now()` (test-overridable). First ICU-plural ARB message (`medsAddCourseRangeLabel`). Still visual only — all course fields are local state, not read by Save, not persisted.
- **Pending** — real Save behaviour: `domain/` entities (`Medication`, `MedicationForm` enum, `TimeSlot`/`Schedule`/`Course`), repository interface, `data/` datasource (drift), concrete repository, Riverpod provider wired to the Save button; all controller values, stepper state, `_intakeTimes`, `_intakeType`, and course parameters will be read at this point.
- **Pending** — schedule, reminder, and other form fields as future specs are defined.
- **Pending** — medication list replacing the `SizedBox.shrink()` body of `MedsScreen`.

No changes to the `AppBar` structure, the `/meds` route path, or the modal-opening pattern are expected.

## Related

- [`../../specs/011-meds-add-fab/spec.md`](../../specs/011-meds-add-fab/spec.md) — the spec that introduced the FAB and modal scaffolding
- [`../../specs/026-add-med-name-input/spec.md`](../../specs/026-add-med-name-input/spec.md) — the spec that added the name field and Save button (iteration 1)
- [`../../specs/027-med-form-picker/spec.md`](../../specs/027-med-form-picker/spec.md) — the spec that added the medication-form picker (iteration 2)
- [`../../specs/028-form-dependent-fields/spec.md`](../../specs/028-form-dependent-fields/spec.md) — the spec that added form-dependent input fields (iteration 3)
- [`../../specs/029-intake-time-chips/spec.md`](../../specs/029-intake-time-chips/spec.md) — the spec that added the intake-time chips section (iteration 4)
- [`../../specs/030-intake-type-control/spec.md`](../../specs/030-intake-type-control/spec.md) — the spec that added the intake-type segmented control and course-parameters card (iteration 5)
- [`home.md`](home.md) — `AppBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology, routing conventions, and the `rootNavigator` context
- [`i18n.md`](i18n.md) — how ARB keys are added and translated
- [`icons.md`](icons.md) — icon conventions (Lucide vs. Material)
