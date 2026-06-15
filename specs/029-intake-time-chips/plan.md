# Plan: Add-Medication Intake-Time Chips (visual-only, iteration 4)

**Date**: 2026-06-14
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Add a presentation-only "Intake time" section to `AddMedicationModal` (`lib/features/meds/presentation/widgets/add_medication_modal.dart`). A new private `_TimeChips` widget renders one `InputChip` per `TimeOfDay` (tap body → `showTimePicker()` to edit, `onDeleted` × → remove) plus a trailing dashed "+ time" `ActionChip` (tap → `showTimePicker()` to append). The selected times are held as a `List<TimeOfDay>` in `_AddMedicationModalState`, kept sorted ascending, de-duplicated with a `SnackBar` rejection. Picker dialog and chip labels are forced to 24-hour. No `domain/`/`data/` code, no persistence — Save stays a no-op.

## Technical Context

**Architecture**: `presentation/` layer only (one widget file) + `lib/l10n/` arb files + the mirrored widget test. No domain/data layers touched.
**Error Handling**: No `Either<Failure, T>` involved — there is no fallible repository/use-case call. The only nullable boundary is `showTimePicker()`'s `Future<TimeOfDay?>`, handled with an explicit early `return` on `null` (no `!`).
**State Management**: Local `StatefulWidget` state in `_AddMedicationModalState` (mirrors specs 026–028). No Riverpod provider — this is ephemeral UI state, never read by Save.

## Constitution Compliance

- §2.1 Layer boundaries — **compliant**: all code lives in `presentation/widgets/`; no `domain/`/`data/` imports added.
- §3.1 No `!` null-assertion — **compliant**: `showTimePicker()`'s `TimeOfDay?` is pattern-/null-checked (`if (picked == null) return;`).
- §3.1 No `dynamic`, no unchecked `as` — **compliant**: only `TimeOfDay`, `int`, `List<TimeOfDay>`.
- §4.2.1 `mounted` after `await` / `use_build_context_synchronously` — **requires attention** (addressed): after the awaited `showTimePicker`, guard `if (!context.mounted) return;` before `ScaffoldMessenger`/`setState` that touches `context`.
- §3.3 Naming / §3.5 no magic values — **compliant**: a named `const _defaultPickerTime = TimeOfDay(hour: 8, minute: 0)` instead of an inline literal.
- §4.1.1 `const` constructors, named params, declared return types — **compliant**.
- §6.4 dartdoc on new public/private types — **compliant**: `_TimeChips` and its helpers get `///` comments matching the file's existing density.
- §3.4 Testing (screens with logic → widget test) — **compliant**: extend `add_medication_modal_test.dart`.
- §i18n convention (specs 026–028) — **compliant**: all strings via `context.l10n`, keys added to `app_en/uk/de.arb`, `flutter gen-l10n` re-run, generated files committed.
- MEMORY.md lucide-name lesson — **addressed**: confirm `LucideIcons.clock`/`plus`/`x` via `dart analyze` (oracle); `InputChip.onDeleted` provides the × so a `deleteIcon` may use `LucideIcons.x`.
- MEMORY.md `inputDecorationTheme` is outlined/transparent — **noted**: the section title is a plain label `Text`, not an `InputDecorator`, so it is unaffected; chips set their own shape/colors from the theme.

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain | none | — |
| Data | none | — |
| Presentation | `_TimeChips` widget; `List<TimeOfDay> _intakeTimes` + add/edit/remove/sort/dedupe handlers in `_AddMedicationModalState`; section inserted into `build` | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (modify) |
| l10n | new `medsAddTime*` keys (×3 locales) + regenerated delegates | `lib/l10n/app_en.arb`, `app_uk.arb`, `app_de.arb` (modify); `lib/l10n/app_localizations*.dart` (regenerate) |
| Test | widget tests for the new section | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Selected-time chip widget | Material **`InputChip`** with `avatar`=clock icon, `label`=`HH:MM`, `onPressed`=edit, `onDeleted`=remove (`deleteIcon`=×) | `onPressed`+`onDeleted` give the two **separate tap targets** AC-7 requires natively; M3-themed for free (pairs with the "Flutter built-ins deliver M3 theming" memory) | Hand-rolled `InkWell`+`IconButton` (more code, manual hit-target isolation, easy to get the overlapping-gesture bug); `GestureDetector` (banned for primary tap targets by §4.3.1) |
| Add chip | Material **`ActionChip`** with dashed-look styling: `side: BorderSide` + `LucideIcons.plus` avatar, `onPressed`=add | Tappable, themed, distinct from `InputChip`; closest to the HTML `.t-chip.add` (dashed outline, primary) | A second `InputChip` (carries a delete affordance it shouldn't); `OutlinedButton` (wrong shape/affordance) |
| Time picker | **`showTimePicker(context:, initialTime:, builder:)`** | Spec-mandated default Material picker; built into Flutter (no dep) | `CupertinoPicker`/custom wheel (explicitly out of scope) |
| 24-hour enforcement | Wrap picker child in `MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!)` via the `builder:`; format labels with `MaterialLocalizations.of(context).formatTimeOfDay(t, alwaysUse24HourFormat: true)` | Honors AC-10 regardless of device 12/24h locale; one consistent format for picker + chips | `TimeOfDay.format(context)` alone (follows device setting, can render AM/PM); manual `sprintf`-style padding (reinvents `MaterialLocalizations`) |
| Sort + dedupe | Pure helper on a working copy: compare by `hour*60+minute`; reject when the minutes-key already exists (excluding the chip being edited); sort ascending before `setState` | Centralizes AC-8/AC-9 in one testable place; keeps `build` declarative | Sorting in `build` (recomputes every frame); `SplayTreeSet` (obscures the dedupe-with-feedback branch) |
| Duplicate feedback | `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.medsAddTimeDuplicate)))` after `mounted` guard | AC-9; matches Material feedback idiom; `Scaffold` already present | Inline error text (no anchor in a chip row); silent reject (spec chose "with feedback") |
| Add-chip default `initialTime` | Named `const _defaultPickerTime = TimeOfDay(hour: 8, minute: 0)` | Matches HTML seed `08:00`; deterministic (testable) — avoids `TimeOfDay.now()` which §3.4 forbids reading real time in tests | `TimeOfDay.now()` (non-deterministic, untestable, clashes with the no-real-time-in-tests rule) |
| Duplicate-message string | Static localized string, **no ICU placeholder** | No existing arb key uses placeholders; keeps `gen-l10n` simple | Placeholder `{time}` (adds first-in-project ICU placeholder for marginal benefit) |
| Section position | After the conditional form-dependent blocks, before the `SizedBox(height:16)` + Save button | Matches HTML order (time section precedes type/Save); independent of `_selectedForm` so it doesn't disturb spec-028 gating (AC-14) | Above the form picker (diverges from design) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | Add `_TimeChips` private `StatelessWidget` (renders `Wrap` of `InputChip`s + trailing `ActionChip`); add `List<TimeOfDay> _intakeTimes` field + `_addTime`/`_editTime`/`_removeTime`/`_pickTime` handlers + `const _defaultPickerTime` + a `_formatTime` helper to `_AddMedicationModalState`; insert the section (title `Text` + `_TimeChips`) into `build` between the form-dependent blocks and Save. No new top-level imports beyond `flutter/material.dart` (already present). |
| `lib/l10n/app_en.arb` | Modify | Add `medsAddTimeTitle` ("Intake time"), `medsAddTimeAddChip` ("Time"), `medsAddTimeRemoveTooltip` ("Remove time"), `medsAddTimeDuplicate` ("This time is already added") + `@`-metadata. |
| `lib/l10n/app_uk.arb` | Modify | Same keys — `Час прийому`, `Час`, `Видалити час`, `Цей час уже додано`. |
| `lib/l10n/app_de.arb` | Modify | Same keys — German values. |
| `lib/l10n/app_localizations.dart` + `app_localizations_{en,uk,de}.dart` | Regenerate | `flutter gen-l10n` output (committed per project convention). |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Add a `group('AddMedicationModal intake time', …)`: initial empty state (only add chip), add→chip appears, tap chip→picker opens prefilled, edit replaces, × removes (and does not open picker), ascending sort, duplicate rejected + SnackBar, 24-hour label. Reuse the existing `_harness(locale:)`. |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| docs/ | None | `docs/` directory does not exist in this project (no `/onboard` run); documentation is the inline dartdoc on the new widget/handlers per §6.4. |

No external documentation changes — internal presentation-only implementation.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `InputChip.onPressed` + `onDeleted` overlap so × also edits | Low | Med | `onDeleted` is a built-in separate hit target; widget test taps the delete icon and asserts the picker did NOT open (AC-7). |
| 24-hour not honored on a 12h-locale device/test | Med | Low | `alwaysUse24HourFormat: true` in both the `builder` `MediaQuery` and `formatTimeOfDay`; assert `08:00` label under a 12h-defaulting locale (AC-10). |
| `use_build_context_synchronously` lint after awaited picker | Med | Low | `if (!context.mounted) return;` before SnackBar/setState; `dart analyze` is the gate (AC-13). |
| Guessed `LucideIcons` name (`clock`/`x`/`plus`) absent | Med | Low | `dart analyze` oracle; fall back to verified names; record confirmed names in MEMORY.md. |
| `ActionChip` dashed-outline look can't fully match CSS `border:dashed` | Med | Low | Material `BorderSide` has no dash style; approximate with a solid `outline`/`primary` border (design-acceptable; design-auditor can refine later). Functional behavior unaffected. |
| New section perturbs spec-026/027/028 tests | Low | Med | Section is additive and form-independent; run full `flutter test` (AC-14). |
| AC-9 edit-to-own-value mis-flagged as duplicate | Low | Low | Dedupe check excludes the index being edited; a unit-style widget test covers "edit chip to its own time = silent no-op". |

## Dependencies

None. `showTimePicker`, `TimeOfDay`, `InputChip`, `ActionChip`, `MaterialLocalizations`, and `MediaQuery` are all in `package:flutter/material.dart` (already imported). No `flutter pub add`. Tooling: `flutter gen-l10n` (already part of the build).

## AC Coverage Map (Phase 2.5 cross-reference)

| AC | Covered by |
|----|-----------|
| AC-1 section present, positioned, titled | File Impact (build insertion) + `medsAddTimeTitle` |
| AC-2 empty initial state | `_intakeTimes = []`; `_TimeChips` renders only the add chip |
| AC-3 add → 24h chip | `_addTime` → `_pickTime` → append + `_formatTime` |
| AC-4 cancel = no-op, no `!` | `_pickTime` `if (picked == null) return;` |
| AC-5 chip = clock + HH:MM + × | `InputChip` avatar/label/`onDeleted` |
| AC-6 tap edits, prefilled | `InputChip.onPressed` → `_editTime(initialTime: t)` |
| AC-7 × removes, no picker | `InputChip.onDeleted` separate target; test asserts |
| AC-8 ascending order | sort helper before `setState`; add chip last |
| AC-9 dup rejected + SnackBar; self-edit no-op | dedupe helper (excl. edit index) + SnackBar |
| AC-10 24h everywhere | `alwaysUse24HourFormat` in builder + formatter |
| AC-11 strings localized ×3 | arb edits + `gen-l10n` |
| AC-12 no-op Save, no domain/data, not persisted | local state only; build untouched re: Save |
| AC-13 analyze clean, no `!`, mounted | null guard + `context.mounted` + `dart analyze` |
| AC-14 existing tests pass | additive section; full `flutter test` |

## Supporting Documents

- [Spec](spec.md)
- [Research](../../research/2026-06-14-intake-time-chips.md) — feasibility study (Option A chosen)
- No `research.md` (no new-tech signals), `data-model.md` (no persisted entities — local `TimeOfDay` only), or `contracts.md` (no API) generated — none apply.
