# Research: Add-Medication "Intake Time" Chips + Default Time Picker

**Date**: 2026-06-14
**Topic**: In the add-medication form, add a time-selection control — chips for already-selected times, where tapping a chip opens the time picker (use Flutter's default `showTimePicker()`), plus an "add time" chip.
**Verdict**: Feasible — clean fit, low complexity, natural next visual-only iteration (iteration 4)

## Summary

This maps almost 1:1 onto the existing pattern. The HTML design already contains this exact control (the "Час прийому" / *Intake time* section) and its own dev comment **explicitly prescribes `showTimePicker()` → `TimeOfDay`** — the same "default one" you're asking for. The work is a self-contained, presentation-only addition to `add_medication_modal.dart`: a `_TimeChips` widget backed by a `List<TimeOfDay>` in local state, identical in spirit to the `_MedicationFormPicker` / `_DoseField` / `_QuantityStepper` blocks shipped in specs 026–028. No `domain/` or `data/` code, no persistence (Save stays a no-op), no new dependencies. The one behavior that goes *beyond* the static HTML is **tap-a-chip-to-edit** — but the HTML's `tpOpen(chipEl)` JS was already written to support editing an existing chip, so the design intent is clear.

## Codebase Findings

### Existing Related Code
| Area | File | Relevance |
|------|------|-----------|
| The form modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (933 lines) | The single file to extend. Already a `StatefulWidget` whose `_AddMedicationModalState` owns controllers + local form state and disposes them. |
| Pattern to copy | `_MedicationFormPicker`, `_DoseField`, `_QuantityStepper`, `_StockCard` (same file) | Private, presentation-only sub-widgets driven by local state and `onX` callbacks. `_TimeChips` follows the same shape. |
| Outlined-field look | `_QuantityStepper` wraps its row in `InputDecorator(isEmpty:false, decoration: InputDecoration(labelText: …))` | The time section can reuse this exact trick to get the floating-label outlined frame around the chips. |
| Localization | `lib/l10n/app_{en,uk,de}.arb` + `context.l10n` | 74 `medsAdd*` keys already exist. New keys follow the same convention. |
| Design contract | `dosly_m3_template.html` lines **2154–2184** (markup), **536–619** (picker JS), **945–964** (`.t-chip` CSS) | Defines the chips: clock-icon + `HH:MM` + `×` delete, plus a trailing dashed "+ Час" add chip. |

### Design Contract Details (from the HTML)
- **Selected-time chip** (`.t-chip.close-mi`): pill-shaped (`shape-full`), `surface-high` background, leading clock icon, `HH:MM` text (24-hour: `08:00`, `14:00`, `20:00`), trailing `×` that deletes the chip.
- **Add chip** (`.t-chip.add`): transparent with a **dashed outline**, primary color, leading `+`, label "Час" → opens the picker (`tpOpen(null)`).
- **Dev comment (lines 2155–2163)** literally says: *"Кнопка '+ Час' відкриває TimePicker → У Flutter: `showTimePicker()` → повертає `TimeOfDay`"* — i.e. the design already nominates the default Material picker. It also mentions a custom wheel as an *alternative*, which the instruction ("use default one") declines.

### Gaps / Net-new behavior
- **Tap-to-edit a chip**: the *static* HTML wires only the `×` (delete) and the add chip; existing time chips have no tap-to-edit handler. This request adds that. It's trivial and the design's `tpOpen` already anticipates it (it parses `HH:MM` out of the tapped chip).
- **No time code exists anywhere yet** — a `grep` for `TimeOfDay` / `showTimePicker` / `TimeSlot` across `lib/` returns nothing. This is greenfield for the app, so there's nothing to reuse or conflict with (and nothing to break).

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §3.1 No `!` null-assertion | `showTimePicker()` returns `TimeOfDay?` (null on cancel). Handle with `if (picked == null) return;` — never `!`. |
| §4.2.1 `mounted` after `await` / `use_build_context_synchronously` | `showTimePicker` is async; after awaiting you must `if (!context.mounted) return;` before using `context` again. |
| §2.1 layer boundaries | All changes live in `presentation/widgets/`. Stays consistent with the visual-only iterations 026–028 — **no `domain/`/`data/` edits**. |
| §3.7 search before building | Done — no existing picker/chip utility exists; `showTimePicker` is a Flutter built-in, so nothing to add. |
| §5.1 (`TimeSlot`, `Schedule`) | The eventual domain model already defines `TimeSlot{ id, time(HH:mm), dosage? }`. This iteration intentionally does **not** build it yet (Save is still a no-op) — local `List<TimeOfDay>` only, mirroring how 027/028 deferred persistence. |
| §3.5 / lint | Lucide icon names (`clock`, `plus`, `x`) must be verified via `dart analyze` — memory has repeatedly caught guessed Lucide names (e.g. `pills`→`tablets`). |

## Approaches

### Option A: Visual-only iteration 4 — `_TimeChips` widget + local `List<TimeOfDay>` (Recommended)
- **Description**: Add a `_TimeChips` private widget and a `List<TimeOfDay> _intakeTimes` field to `_AddMedicationModalState`. Render a `Wrap` of chips (each a tappable chip that opens `showTimePicker(initialTime: that time)` to edit, with a separate `×` tap target to remove) followed by a dashed "add" chip that opens `showTimePicker()` to append. Keep the list sorted ascending. Pure local state; Save stays a no-op.
- **Pros**: Exactly mirrors the established 026–028 pattern; one source file + 3 arb files; no new deps; uses the *default* picker as requested; trivially forward-compatible with the future `TimeSlot`/`Schedule` wiring.
- **Cons**: Not persisted yet (by design); two distinct tap targets within one chip (edit vs delete) needs care so the `×` doesn't also trigger edit.
- **Complexity**: **Low**

### Option B: Wire the full domain now (`TimeSlot` + `Schedule` + persistence)
- **Description**: Introduce the `TimeSlot` entity / `Schedule` and persist intake times immediately.
- **Pros**: One less iteration later.
- **Cons**: Breaks the deliberate visual-first cadence; premature while Save is a no-op and name/form/dose aren't persisted either; pulls in drift schema + migration + use cases — far larger than a 1-file change; contradicts §6.1 minimal-changes.
- **Complexity**: **High**

**Recommended approach**: **Option A** — it's the smallest change that satisfies the request, matches the codebase's proven iteration rhythm, and uses the default `showTimePicker()` specified.

## Implementation Notes (for the eventual spec)
- **Edit vs. delete tap targets**: make the chip body an `InkWell`/`ActionChip` that opens the editor; render the `×` as a *separate* `InkWell`/`IconButton` (or `InputChip.onDeleted`) so tapping it removes the slot without also opening the picker. `InputChip` with `onPressed` + `onDeleted` is the most idiomatic Material fit for "tap to edit, × to delete."
- **24-hour display**: the design shows 24-hour times. `showTimePicker` and `TimeOfDay.format(context)` follow `MediaQuery.alwaysUse24HourFormat`. To match the design regardless of device setting, format chips via `MaterialLocalizations.of(context).formatTimeOfDay(t, alwaysUse24HourFormat: true)` and optionally wrap the picker in a `MediaQuery` override. **Decision point for the spec.**
- **Sorting / de-duplication**: HTML seed data is ascending and unique (`08:00, 14:00, 20:00`). Decide whether to auto-sort and reject duplicates after add/edit. **Decision point.**
- **New l10n keys** (all 3 arb files + regenerate): e.g. `medsAddTimeTitle` ("Intake time"), `medsAddTimeAddChip` ("Time"), and a delete semantics/tooltip label `medsAddTimeRemoveTooltip`.
- **Icons**: clock (leading), plus (add), x (delete) — confirm exact `LucideIcons.*` names with `dart analyze`.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low** | 1 Dart file (`add_medication_modal.dart`) + 3 `.arb` files + l10n regen. |
| New dependencies | **None** | `showTimePicker` is built into Flutter Material. |
| Risk | **Low** | Presentation-only, no persistence, no schema; main pitfalls are the `mounted`-after-await rule and the edit-vs-delete tap separation. |

## Recommendation

**Proceed.** This is a well-scoped visual-only iteration that fits the existing pattern cleanly.

Suggested next step:

```
/specify "Add-medication form: intake-time chips (visual-only, iteration 4). Add a 'Intake time' section to AddMedicationModal showing a chip per selected time; tapping a chip opens the default Flutter showTimePicker() pre-filled to edit that time, an × on each chip removes it, and a dashed '+ time' chip appends a new time. Hold times as a local List<TimeOfDay> in _AddMedicationModalState (no persistence, Save stays a no-op). Match dosly_m3_template.html lines 2154-2184; 24-hour display; add l10n keys to en/uk/de."
```

Before that, two small decisions the spec will pin down: **(1)** force 24-hour display to match the design, and **(2)** auto-sort + reject duplicate times.
