# Spec: Add-Medication Intake-Time Chips (visual-only, iteration 4)

**Date**: 2026-06-14
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

This is **iteration 4** of building the Add-medication form, again scoped to **visuals + local interaction only** (no persistence, Save stays a no-op). It adds an **"Intake time" section** to `AddMedicationModal` that renders one **chip per selected intake time**. Tapping a chip opens the **default Flutter `showTimePicker()`** pre-filled with that chip's time to edit it; an **× on each chip removes it**; and a trailing **dashed "+ time" chip** opens the picker to append a new time. All times live in **local widget state** (`List<TimeOfDay>` in `_AddMedicationModalState`) — nothing is read by Save, validated against domain rules, or persisted. No `domain/` or `data/` code is added.

## 2. Current State

**The modal** (`lib/features/meds/presentation/widgets/add_medication_modal.dart`, 933 lines) is — after specs 026 + 027 + 028 — a `StatefulWidget` named `AddMedicationModal`. Its `State` (`_AddMedicationModalState`) owns five `TextEditingController`s (all disposed in `dispose()`) plus form-dependent local state (`_selectedForm`, `_quantity`, `_selectedDoseUnitIndex`). `build` returns a `Scaffold` with an `AppBar` (back-arrow `IconButton` → `Navigator.pop`; `Text(context.l10n.medsAddTitle)` title) and a `body` of `SingleChildScrollView` → `Padding(EdgeInsets.all(16))` → `Column(crossAxisAlignment: stretch)` containing, in order:
1. a name `TextField` bound to `_nameController`,
2. `SizedBox(height: 16)`,
3. `_MedicationFormPicker(onFormSelected: _onFormSelected)` (spec 027),
4. conditional form-dependent blocks — `_DoseField`, `_QuantityStepper`, `_StockCard` — each gated on `_selectedForm` capability flags (spec 028),
5. `SizedBox(height: 16)`,
6. a full-width `FilledButton.icon(onPressed: () {}, icon: Icon(LucideIcons.save), label: Text(context.l10n.medsAddSaveButton))` — an **intentional documented no-op**.

**Established patterns in this file** (to be mirrored by the new section):
- Sub-controls are **private widgets in the same library** (`_MedicationFormPicker`, `_DoseField`, `_QuantityStepper`, `_StockCard`), driven by local parent state and `onX` callbacks.
- The outlined floating-label frame is obtained by wrapping content in `InputDecorator(isEmpty: false, decoration: InputDecoration(labelText: …))` (see `_QuantityStepper`, lines 542–546).
- All strings come from `context.l10n` (`AppLocalizations`); icons come from `LucideIcons.*`; colors/typography come from `Theme.of(context)` (no hardcoded values).

**No time-related code exists yet.** A search across `lib/` for `TimeOfDay`, `showTimePicker`, and `TimeSlot` returns nothing — this is the app's first use of the Material time picker. There is no existing chip/picker utility to reuse.

**The HTML design** (the visual contract — `dosly_m3_template.html`, lines **2154–2184**) defines the section between the "Час прийому" (Intake time) title and the type segment:
- A `.time-chips` flex-wrap container (CSS lines 945–964).
- Each selected time is a `.t-chip.close-mi` chip: pill-shaped (`shape-full` radius), `surface-high` background, a **leading clock icon**, the time as **24-hour `HH:MM`** text (seed values `08:00`, `14:00`, `20:00`), and a **trailing × icon** that deletes the chip.
- A trailing `.t-chip.add` chip: **transparent with a dashed outline**, primary color, leading `+`, label "Час" (Time) → opens the picker.
- The design's own dev comment (lines 2155–2163) prescribes the Flutter implementation: *"Кнопка '+ Час' відкриває TimePicker → У Flutter: `showTimePicker()` → повертає `TimeOfDay`"*. The static markup wires only delete (`tpDeleteChip`) and add (`tpOpen(null)`); the picker's `tpOpen(chipEl)` function already supports **editing an existing chip** (it parses `HH:MM` out of the tapped chip), confirming tap-to-edit is the intended behavior. The reset state (lines 3009–3011) clears the list to **only the add chip** (no seeded times).

**Localization**: `lib/l10n/app_{en,uk,de}.arb` already hold 74 `medsAdd*` keys; `context.l10n` is wired via `l10n_extensions.dart`. New keys follow the same `medsAdd*` naming convention and must be added to **all three** arb files.

**Research**: `research/2026-06-14-intake-time-chips.md` (this feature's feasibility study) — verdict Feasible, recommends this visual-only Option A approach.

## 3. Desired Behavior

Insert a new **"Intake time" section** into `AddMedicationModal`'s body, positioned **after the medication-form picker and its conditional form-dependent fields, and before the Save button**. The section consists of a section frame containing a wrapping run of chips.

### 3.1 Initial state
- When the modal first opens, the time list is **empty**. The section shows **only** the dashed "+ time" add chip (matching the HTML reset state). No time chips are present.

### 3.2 Selected-time chip
- One chip per `TimeOfDay` in the local list, displaying the time as **24-hour `HH:MM`** (e.g. `08:00`, `14:00`, `20:00`) regardless of the device's 12/24-hour locale setting.
- The chip carries a **leading clock icon** and a **trailing × (remove) affordance**.
- **Tapping the chip body** opens the default `showTimePicker()` pre-filled (`initialTime`) with that chip's current time. Confirming the picker **replaces** that chip's time with the chosen value. Cancelling leaves the chip unchanged.
- **Tapping the × affordance** removes that chip from the list. The × must be a **separate tap target** — tapping × must NOT also open the time picker.

### 3.3 Add chip
- A trailing **dashed-outline "+ time" chip** (primary-colored, leading `+`) sits after the time chips.
- **Tapping it** opens the default `showTimePicker()` (with a sensible default `initialTime`). Confirming **appends** the chosen time to the list. Cancelling adds nothing.

### 3.4 Ordering
- After any add or edit, the chip list is **auto-sorted ascending** by time-of-day (hour, then minute), so chips always read in chronological order. The add chip always renders last.

### 3.5 Duplicate handling
- If the user picks (via add or edit) a time that **already exists** in the list, the duplicate is **rejected** — the list is left unchanged — and a brief **`SnackBar`** informs the user that the time is already added (localized message).
- For **edit**: choosing a time equal to another existing chip is a duplicate and rejected (the edited chip keeps its original value). Choosing the chip's own current value is a no-op (no SnackBar needed).

### 3.6 Picker & display format
- Use Flutter's built-in **`showTimePicker()`** (Material) — no custom wheel/CupertinoPicker.
- Force **24-hour display** in both the picker dialog and the chip labels, independent of device locale, to match the design.

### 3.7 Persistence
- **None.** The `List<TimeOfDay>` is local state in `_AddMedicationModalState`. Save remains an intentional, documented no-op. No values are validated against domain `Schedule`/`TimeSlot` rules or written to drift.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Add-medication modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Add a private `_TimeChips` (or equivalently named) widget; add `List<TimeOfDay> _intakeTimes` local state + add/edit/remove handlers in `_AddMedicationModalState`; insert the section into `build` between the form-dependent fields and the Save button. |
| Localization (EN) | `lib/l10n/app_en.arb` | Add new `medsAdd*` time keys (section title, add-chip label, remove tooltip/semantics, duplicate-time message). |
| Localization (UK) | `lib/l10n/app_uk.arb` | Same keys, Ukrainian values (title "Час прийому", add chip "Час"). |
| Localization (DE) | `lib/l10n/app_de.arb` | Same keys, German values. |
| Generated l10n | `lib/l10n/app_localizations*.dart` | Regenerated via `flutter gen-l10n` (committed). |
| Tests | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Add/extend widget tests for add/edit/remove/sort/duplicate behavior (per constitution §3.4 — screens with logic). |

## 5. Acceptance Criteria

- [x] **AC-1**: An "Intake time" section appears in `AddMedicationModal`, positioned after the form-dependent fields and before the Save button, with a localized section title.
- [x] **AC-2**: On first open, the section shows **only** the dashed "+ time" add chip and **no** time chips.
- [x] **AC-3**: Tapping the add chip opens Flutter's default `showTimePicker()`; confirming a time appends a new chip displaying that time as 24-hour `HH:MM`.
- [x] **AC-4**: Cancelling the picker (returns `null`) adds/changes nothing and produces no error (no `!` null-assertion; null handled explicitly).
- [x] **AC-5**: Each time chip shows a leading clock icon, the 24-hour `HH:MM` time, and a trailing × remove affordance.
- [x] **AC-6**: Tapping a chip's body opens `showTimePicker()` pre-filled (`initialTime`) with that chip's current time; confirming a new value **replaces** that chip's time.
- [x] **AC-7**: Tapping a chip's × removes that chip and does **not** open the time picker (separate tap targets).
- [x] **AC-8**: After any add or edit, chips are rendered in **ascending** time order; the add chip is always last.
- [x] **AC-9**: Picking a time (via add or edit) that already exists leaves the list unchanged and shows a localized `SnackBar`; editing a chip to its own current value is a silent no-op.
- [x] **AC-10**: The picker dialog and chip labels use **24-hour** format regardless of device locale.
- [x] **AC-11**: All new user-visible strings are sourced from `context.l10n` and present in `app_en.arb`, `app_uk.arb`, and `app_de.arb`; `flutter gen-l10n` succeeds.
- [x] **AC-12**: Save remains a no-op; no `domain/` or `data/` files are added or modified; `_intakeTimes` is not persisted.
- [x] **AC-13**: `dart analyze` passes with no new warnings; the file uses no `!` null-assertion and checks `context.mounted` after the awaited `showTimePicker`/before using `ScaffoldMessenger`.
- [x] **AC-14**: Existing spec-026/027/028 widget tests continue to pass (the new section does not break the "no conditional field when no form selected" assertions, etc.).

## 6. Out of Scope

- NOT included: persisting intake times (no drift table, no migration, no DTO/mapper).
- NOT included: the `TimeSlot` / `Schedule` domain entities, value objects, or use cases (constitution §5.1) — deferred to the data-save iteration.
- NOT included: wiring Save to read or validate `_intakeTimes`.
- NOT included: per-slot dosage override (the `TimeSlot.dosage` field).
- NOT included: a custom wheel / `CupertinoPicker` time selector — the default Material `showTimePicker()` is mandated.
- NOT included: validation rules (min/max number of times, required-at-least-one, etc.).
- NOT included: scheduling notifications for these times.
- NOT included: changes to the medication-form picker, dose, quantity, or stock fields beyond inserting the new section around them.
- NOT included: editing times of an existing/saved medication (there is no edit-existing-medication flow yet).

## 7. Technical Constraints

- Must follow Clean Architecture layer boundaries (§2.1): **all changes are in `presentation/widgets/`** (plus l10n + tests). No `domain/`/`data/` edits.
- Must use the default Flutter Material **`showTimePicker()`** (returns `Future<TimeOfDay?>`).
- Must **not** use the `!` null-assertion operator (§3.1) — handle the picker's nullable return with an explicit `if (picked == null) return;`.
- Must check **`context.mounted`** after the awaited `showTimePicker` before using `context` again (e.g. for `ScaffoldMessenger`), per §4.2.1 / `use_build_context_synchronously`.
- Must source all strings from `context.l10n` and add keys to all three arb files (§i18n convention; mirrors specs 026–028).
- Must use `LucideIcons.*` for icons (clock, plus, ×) and verify exact names with `dart analyze` (per MEMORY.md lucide-name lessons — e.g. `pills`→`tablets`).
- Must take colors, radii, and typography from `Theme.of(context)` (no hardcoded colors); pill chips use the full/`StadiumBorder` shape to match `.t-chip`.
- Must keep Save a documented no-op and keep the visual-only iteration contract (mirrors spec 028's framing).
- Should prefer Material chip primitives already available (`InputChip` with `onPressed` + `onDeleted`, or `ActionChip`) before hand-rolling tap targets (§3.7 search-before-build) — `InputChip.onDeleted` natively provides the separate × tap target required by AC-7.
- New public/private types and methods get dartdoc `///` comments per §6.4 and the file's existing documentation density.

## 8. Open Questions

- **Add-chip default `initialTime`**: when adding the first time, what should the picker default to? Proposed: a fixed sensible default (e.g. `08:00`) to match the HTML seed; alternatively `TimeOfDay.now()`. (Minor — resolve in `/plan`; default to `08:00` to align with the design.)
- **Chip widget choice**: `InputChip` (native `onDeleted` ×) vs a hand-rolled `InkWell`+`IconButton`. `InputChip` is preferred for the separate-tap-target requirement but its default visuals may need tuning to match `.t-chip`. (Resolve in `/plan`.)

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| × tap also triggers chip-edit (overlapping gesture targets) | Med | Med | Use `InputChip.onDeleted` (separate built-in hit target) or isolate the × in its own `InkWell`/`IconButton`; cover with a widget test (AC-7). |
| 24-hour format not honored on a 12-hour-locale device | Med | Low | Wrap the picker in a `MediaQuery` with `alwaysUse24HourFormat: true` and format chip labels via `MaterialLocalizations.formatTimeOfDay(t, alwaysUse24HourFormat: true)`; assert in a test (AC-10). |
| `use_build_context_synchronously` lint after awaited picker | Med | Low | `if (!context.mounted) return;` before SnackBar/setState that touches context; §4.2.1. |
| Guessed `LucideIcons` name doesn't exist | Med | Low | Verify with `dart analyze` (oracle); record confirmed names in MEMORY.md. |
| New section breaks existing 026/027/028 widget-test assertions | Low | Med | Run the full `flutter test` suite; the section is additive and independent of form-dependent gating (AC-14). |
| Scope creep toward real persistence / domain model | Low | Med | "Out of Scope" explicitly excludes domain/data/persistence; Save stays a no-op (AC-12). |
