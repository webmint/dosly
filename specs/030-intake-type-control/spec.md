# Spec: Add-Medication Intake-Type Control (visual-only, iteration 5)

**Date**: 2026-06-15
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

This is **iteration 5** of building the Add-medication form, again scoped to **visuals + local interaction only** (no persistence, Save stays a no-op). It adds an **"Intake type" section** to `AddMedicationModal` containing a two-option `SegmentedButton` — **Continuous** (Постійний) vs **Course** (Курс) — positioned **after the intake-time chips and before the Save button**. Selecting **Course** reveals a **course-parameters card** (Duration in days, Pause in days, a Start date field opened via `showDatePicker`, and a **live-computed date-range info chip**). All values live in **local widget state** in `_AddMedicationModalState` — nothing is read by Save, validated against domain rules, or persisted. No `domain/` or `data/` code is added.

Research: `research/2026-06-15-intake-type-control.md` (verdict Feasible, recommends this visual-only Option A approach).

## 2. Current State

**The modal** (`lib/features/meds/presentation/widgets/add_medication_modal.dart`, 1118 lines) is — after specs 026 + 027 + 028 + 029 — a `StatefulWidget` named `AddMedicationModal`. Its `State` (`_AddMedicationModalState`) owns five `TextEditingController`s (all disposed in `dispose()`, lines 847–855), form-dependent local state (`_selectedForm`, `_quantity`, `_selectedDoseUnitIndex`), and intake-time state (`final List<TimeOfDay> _intakeTimes`). `build` (lines 1011–1117) returns a `Scaffold` with an `AppBar` (back-arrow → `Navigator.pop`; `Text(context.l10n.medsAddTitle)` title) and a `body` of `SingleChildScrollView` → `Padding(EdgeInsets.all(16))` → `Column(crossAxisAlignment: stretch)` containing, in order:
1. a name `TextField` bound to `_nameController`,
2. `SizedBox(height: 16)`,
3. `_MedicationFormPicker(onFormSelected: _onFormSelected)` (spec 027),
4. conditional form-dependent blocks — `_DoseField`, `_QuantityStepper`, `_StockCard` — each gated on `_selectedForm` capability flags with `if (selectedForm?.hasX ?? false) ...[ ... ]` (spec 028, lines 1052–1087),
5. `SizedBox(height: 16)` + intake-time section: `Text(medsAddTimeTitle, titleSmall)` + `_TimeChips(...)` (spec 029, lines 1089–1101),
6. `SizedBox(height: 16)` + a full-width `FilledButton.icon(onPressed: () {}, icon: Icon(LucideIcons.save), label: Text(medsAddSaveButton))` — an **intentional documented no-op** (lines 1103–1111).

**Established patterns in this file** (to be mirrored by the new section):
- Sub-controls are **private widgets in the same library** (`_MedicationFormPicker`, `_DoseField`, `_QuantityStepper`, `_StockCard`, `_TimeChips`), driven by local parent state and `onX` callbacks.
- **Conditional sections** appear/disappear via `if (...) ...[ widget ]` spreads so absent widgets are truly out of the tree (spec 028 form-dependent fields).
- The outlined floating-label frame is obtained by wrapping content in `InputDecorator(isEmpty: false, decoration: InputDecoration(labelText: …))` (see `_QuantityStepper`, lines 536–538).
- A titled container card is the `_StockCard` shape: `Container(decoration: BoxDecoration(color: surfaceContainerLow, border: Border.all(outlineVariant), borderRadius: 16), padding: 16)` with an icon+title header row (lines 603–620).
- `showTimePicker` is wrapped, awaited, then `mounted`-guarded before mutating state (`_addTime`/`_editTime`, lines 924–959). `showDatePicker` follows the same idiom.
- All strings come from `context.l10n` (`AppLocalizations`); icons come from `LucideIcons.*`; colors/typography come from `Theme.of(context)` (no hardcoded values).

**SegmentedButton precedent**: `lib/features/settings/presentation/widgets/theme_selector.dart:75–103` already uses `SegmentedButton<AppThemeMode>` with `ButtonSegment`s (`value`/`label`/`icon`), `selected: <T>{...}`, and an `onSelectionChanged` callback that **guards `selection.isEmpty` before `.first`**. Mirror this exactly.

**Date formatting**: the file currently formats times via `MaterialLocalizations.of(context).formatTimeOfDay(...)` (spec 029) — no `intl`/`DateFormat` is used anywhere in `lib/`. Dates in this spec use the analogous `MaterialLocalizations.of(context).formatMediumDate(DateTime)` (locale-aware, no new dependency).

**Clock**: the constitution mandates `clock.now()` over `DateTime.now()` for testability (overridable via `withClock` in tests). `package:clock` is currently only a **transitive** dependency (present in `pubspec.lock`, not in `pubspec.yaml`) and is used nowhere in `lib/`/`test/` yet — so this feature **promotes it to a direct dependency** (see `/plan`). `clock` is permitted in presentation (the forbidden-import list applies to `domain/`).

**Localization**: `lib/l10n/app_{en,uk,de}.arb` already hold ~78 `medsAdd*` keys; `context.l10n` is wired via `l10n_extensions.dart`; gen-l10n regenerates `app_localizations*.dart`. New keys follow the `medsAdd*` convention and must be added to **all three** arb files. This iteration introduces the file's first **ICU plural** message (day count).

**The HTML design** (the visual contract — `dosly_m3_template.html`):
- "Тип прийому" section (lines **2188–2230**): a `.fs-title` heading, a `.seg-btn` segmented control with two `.seg-opt`s — **Постійний** (`selectType('perm')`) and **Курс** (`selectType('course')`); the selected option carries `.sel` (secondary-container colours). CSS at lines **923–943**.
- `.course-card` (lines **2200–2228**, CSS **966–1010**): header "Параметри курсу" (tertiary-stroked icon), a `.f-row` with **Тривалість (дні)** (Duration, default `7`) + **Пауза (дні)** (Pause, default `0`), a readonly **Дата початку** (Start date) field with a trailing calendar icon and a dev comment prescribing Flutter's `showDatePicker`, and an `.info-chip` (tertiary-container) reading **"Курс: 26 бер — 1 квіт 2026 (7 днів)"**.
- JS `selectType()` (lines 2897–2903): selecting `course` shows the card, `perm` hides it. The info chip is computed from start + duration in the demo data; pause does **not** feed the chip.

## 3. Desired Behavior

Insert a new **"Intake type" section** into `AddMedicationModal`'s body, **after** the intake-time `_TimeChips` section and **before** the Save button (with the usual `SizedBox(height: 16)` spacing, consistent with sibling sections — no `Divider`).

### 3.1 Intake-type segmented control (always visible)
- A section title `Text(context.l10n.medsAddIntakeTypeTitle, style: titleSmall)`, then `SizedBox(height: 8)`.
- A full-width `SegmentedButton<_IntakeType>` with exactly two `ButtonSegment`s:
  - `_IntakeType.continuous` → label `medsAddIntakeTypeContinuous`, an "ongoing" icon (suggested `LucideIcons.infinity`).
  - `_IntakeType.course` → label `medsAddIntakeTypeCourse`, a "repeating course" icon (suggested `LucideIcons.repeat`).
- `selected: <_IntakeType>{_intakeType}`; `onSelectionChanged` sets `_intakeType` inside `setState`, guarding `selection.isEmpty` before `.first` (mirror `theme_selector.dart`).
- **On open, `_intakeType == _IntakeType.continuous`** → the course card is absent from the tree.

### 3.2 Course-parameters card (visible only when Course is selected)
Rendered via `if (_intakeType == _IntakeType.course) ...[ const SizedBox(height: 16), _CourseCard(...) ]` (plain conditional spread, mirroring spec 028). The card is a titled container matching the `_StockCard` shape and contains, top to bottom:
1. Header row: tertiary-coloured icon (suggested `LucideIcons.repeat`) + `Text(medsAddCourseParamsTitle, titleSmall)`.
2. A `Row` of two numeric `TextField`s:
   - **Duration**: `labelText: medsAddCourseDurationLabel`, `keyboardType: number`, controller `_durationController` (default text `"7"`).
   - **Pause**: `labelText: medsAddCoursePauseLabel`, `keyboardType: number`, controller `_pauseController` (default text `"0"`).
3. A **Start date** field: a tappable `InputDecorator(isEmpty: false, decoration: InputDecoration(labelText: medsAddCourseStartLabel, suffixIcon: calendar))` whose child shows `MaterialLocalizations.of(context).formatMediumDate(_startDate)`. Tapping opens `showDatePicker` (initialDate `_startDate`; a wide `firstDate`/`lastDate` window around `clock.now()`); on confirm, `setState(_startDate = picked)`; on cancel, unchanged. The method is `mounted`-guarded after the `await`.
4. An **info chip**: a tertiary-container rounded `Container` with a leading info icon and a **live-computed** label.

### 3.3 Live-computed info chip
- Parse `int.tryParse(_durationController.text.trim())` → `n`.
- **If `n != null && n >= 1`**: compute `end = _startDate.add(Duration(days: n - 1))` (a 7-day course starting Mar 26 ends Apr 1 inclusive, matching the HTML). Render `medsAddCourseRangeLabel` with placeholders `{range}` = `"${formatMediumDate(_startDate)} — ${formatMediumDate(end)}"` and `{count}` = `n` (ICU plural for the day count). The chip recomputes whenever the start date or duration changes (the duration field triggers a rebuild on edit, e.g. via `onChanged: (_) => setState(() {})`).
- **If `n` is null or `< 1`** (empty/invalid duration): render the fallback `medsAddCourseStartLabel`-style chip `medsAddCourseStartOnly` with `{date}` = `formatMediumDate(_startDate)` (no crash, no computed range).
- **Pause** is captured in local state only and does **not** affect the chip or any computation this iteration.

### 3.4 State & lifecycle additions to `_AddMedicationModalState`
- `_IntakeType _intakeType = _IntakeType.continuous;`
- `final TextEditingController _durationController = TextEditingController(text: '7');`
- `final TextEditingController _pauseController = TextEditingController(text: '0');`
- `DateTime _startDate = clock.now();` (date component used for display/computation).
- Add `_durationController.dispose()` and `_pauseController.dispose()` to `dispose()`.
- Add a private `enum _IntakeType { continuous, course }` in the same library.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Add-medication modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Add `enum _IntakeType`, a `_CourseCard` private widget, the inline `SegmentedButton` section, new state fields + controllers (disposed), `_pickStartDate()` method, info-chip computation, and `build` wiring after `_TimeChips` |
| Localization (source) | `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb`, `lib/l10n/app_de.arb` | Add new `medsAdd*` keys incl. one ICU-plural message; all three locales |
| Localization (generated) | `lib/l10n/app_localizations*.dart` | Regenerated by gen-l10n (`flutter gen-l10n` / build) — not hand-edited |
| Tests | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Add widget tests for AC-3 … AC-10 (mirrors spec 029's test additions) |

### New l10n keys (English canonical; uk + de added during execution)
| Key | English value | Notes |
|-----|---------------|-------|
| `medsAddIntakeTypeTitle` | `Intake type` | Section title |
| `medsAddIntakeTypeContinuous` | `Continuous` | Segment label (Постійний) |
| `medsAddIntakeTypeCourse` | `Course` | Segment label (Курс) |
| `medsAddCourseParamsTitle` | `Course parameters` | Card header (Параметри курсу) |
| `medsAddCourseDurationLabel` | `Duration (days)` | Numeric field |
| `medsAddCoursePauseLabel` | `Pause (days)` | Numeric field |
| `medsAddCourseStartLabel` | `Start date` | Date field label |
| `medsAddCourseRangeLabel` | `Course: {range} ({count, plural, =1{1 day} other{{count} days}})` | Info chip; placeholders `{range}` (String), `{count}` (num, plural) |
| `medsAddCourseStartOnly` | `Course starts {date}` | Info-chip fallback when duration is empty/invalid; `{date}` (String) |

## 5. Acceptance Criteria

- [x] **AC-1**: An "Intake type" section (titled via `medsAddIntakeTypeTitle`) renders in the modal body **after** the intake-time chips and **before** the Save button.
- [x] **AC-2**: The section shows a `SegmentedButton` with exactly two segments labelled `medsAddIntakeTypeContinuous` and `medsAddIntakeTypeCourse`.
- [x] **AC-3**: On first open, the **Continuous** segment is selected and the course-parameters card is **not present** in the widget tree.
- [x] **AC-4**: Tapping the **Course** segment selects it and makes the course-parameters card appear.
- [x] **AC-5**: Tapping **Continuous** again removes the course-parameters card from the tree.
- [x] **AC-6**: When visible, the card shows a header (`medsAddCourseParamsTitle`), a Duration field defaulting to `7`, a Pause field defaulting to `0`, a Start date field, and an info chip.
- [x] **AC-7**: The Start date field displays **today's date** (from `clock.now()`, formatted via `formatMediumDate`) when the card first appears; tests override the clock with `withClock` and assert the formatted date.
- [x] **AC-8**: Tapping the Start date field opens `showDatePicker`; confirming a date updates the displayed date and the info chip, while cancelling leaves both unchanged.
- [x] **AC-9**: With a valid duration `n ≥ 1`, the info chip renders `medsAddCourseRangeLabel` where the range end is `start + (n − 1)` days and the day count is correctly pluralized; editing the Duration field updates the chip live.
- [x] **AC-10**: When the Duration field is empty or not a positive integer, the info chip falls back to `medsAddCourseStartOnly` (showing only the start date) without throwing.
- [x] **AC-11**: All new user-facing strings are added to `app_en.arb`, `app_uk.arb`, and `app_de.arb` (including the ICU-plural message with correct Ukrainian plural categories); no hardcoded strings in the widget.
- [x] **AC-12**: `_durationController` and `_pauseController` are disposed in `dispose()`.
- [x] **AC-13**: Save remains a no-op; no `domain/` or `data/` files are added or modified; nothing is persisted; `_intakeType`, controllers, and `_startDate` are local state only.
- [x] **AC-14**: `dart analyze` passes clean; the existing test suite still passes; new widget tests cover AC-3 … AC-10.

## 6. Out of Scope

- NOT included: wiring Save / any persistence (drift), reading these values anywhere.
- NOT included: a domain `IntakeType` entity/value object, course-schedule use cases, or drift schema/migrations.
- NOT included: **Pause** affecting the computed range, scheduling, or any logic (visual capture only).
- NOT included: validation UX for Duration/Pause (no inline errors, no min/max caps, no input formatters beyond `keyboardType: number`) — only the info-chip fallback of AC-10.
- NOT included: reminder/notification scheduling derived from course dates.
- NOT included: the edit-medication flow (this is the add modal only).
- NOT included: pixel-exact replication of the HTML's compact dual-month range (`26 бер — 1 квіт`) — `formatMediumDate` is used on both endpoints; the HTML `.s-div` divider is not reproduced.
- NOT included: time-zone / DST exactness of the course end date (visual approximation via `add(Duration(days:))`).
- NOT included: animating the card reveal (plain conditional render, matching spec 028).

## 7. Technical Constraints

- Must follow the **visual-only iteration** convention of specs 026–029: private widgets in the same library, parent-owned local state + `onX` callbacks, Save stays a no-op, no `domain/`/`data/` code.
- Must mirror `theme_selector.dart`'s `SegmentedButton` usage, including the `selection.isEmpty` guard before `.first`.
- Must use `clock.now()` (`package:clock`), **not** `DateTime.now()`, for the default start date (testable via `withClock`).
- Must format dates with `MaterialLocalizations.of(context).formatMediumDate(...)` — **no** new `intl`/`DateFormat` usage.
- Must pluralize the day count via an **ICU plural** message in the arb files (gen-l10n), not manual string logic; Ukrainian requires `one`/`few`/`many`/`other` categories.
- Strict-mode lint (constitution §7.4): use the `_IntakeType` enum (no magic strings), no `!` null-assertions, parse with `int.tryParse`, null-safe throughout.
- Icons via `LucideIcons.*`; colours/typography via `Theme.of(context)` (info chip uses `tertiaryContainer`/`onTertiaryContainer`); no hardcoded colours.
- New keys live in all three arb files; generated localizations are produced by gen-l10n, never hand-edited.

## 8. Open Questions

- Exact Lucide icons for the two segments and the card header — suggested `LucideIcons.infinity` (Continuous), `LucideIcons.repeat` (Course / header). Final choice deferred to `/plan` / implementation.
- `showDatePicker` `firstDate`/`lastDate` window — assumed a wide, sensible range around `clock.now()` (e.g. −1 year … +5 years); finalized in `/plan`.
- Whether the Duration field should clamp/sanitize input beyond the AC-10 fallback — assumed **no** for this visual-only iteration.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Ukrainian ICU plural categories (`one/few/many/other`) authored incorrectly | Med | Med | Follow gen-l10n plural syntax; provide all four uk categories; verify with `flutter gen-l10n` + a uk plural test (1/2/5 days) |
| Combining a `{range}` String placeholder with a `{count}` plural in one message | Low | Med | gen-l10n supports mixed placeholders; `/plan` verifies the generated signature; fallback is to split into two composed keys |
| `formatMediumDate` output diverging from the HTML's compact style | Low | Low | Accepted — locale-correct medium format is explicitly chosen over pixel parity (Out of Scope) |
| Non-deterministic default date breaking widget tests | Low | Med | Use `clock.now()` and `withClock(Clock.fixed(...))` in tests (AC-7) |
| Duration `onChanged: setState` causing focus/rebuild jank | Low | Low | Minimal rebuild (info chip only); acceptable for a single text field |
