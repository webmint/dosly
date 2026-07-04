# Research: Full-Fidelity Today Screen — hourly grouping, checkbox model, mark-ahead, auto-miss

**Date**: 2026-07-03
**Topic**: Rework the shipped Today screen to match `dosly_m3_template.html` SCREEN 1 — group doses **by hour** (not exact slot time), with the checkbox interaction model, mark-ahead, and auto-miss **all in scope** (explicitly not deferred).
**Verdict**: **Feasible — but it's 3 ordered specs, not one**, and two HTML behaviors are overridden by the constitution.

## Summary

The Today screen (spec 038, shipped) is a flat, time-sorted `ListView` of `TodayDoseTile`s with per-tile **Take / Skip / Undo** buttons. The HTML design (`dosly_m3_template.html`, lines 1627–1832) is a materially different layout: a **countdown card** ("next intake in Xh Ym"), doses **grouped into collapsible time groups** with a state badge (past ✓ / now / future), a **checkbox** interaction model instead of buttons, per-tile **status chips** (continuous / "Day 3/7") and inline **stock warnings**, plus a **"Mark all"** action per group.

The user requested the **full** design incl. the checkbox model, mark-ahead, and auto-miss — none deferred. Those three aren't screen polish: each pulls in a subsystem that does not exist yet, and the constitution (§5.2, which is law) already dictates how two of them must behave. The honest scoping is a dependency chain: **Settings knobs → auto-miss engine → redesigned screen**. Doing it as one spec would violate the "atomic spec" rule and the interface-blast-radius lesson in MEMORY.

The user's note *"grouped within hour"* is the key deviation from the template — the HTML groups by exact minute (08:00, 14:00, 20:00), but doses should be bucketed by **hour** (everything 08:00–08:59 → one "08:00" group).

## Two constitution overrides (the HTML dev-notes are wrong here)

| HTML dev-note says | Constitution §5.2 says (wins) |
|---|---|
| Unmarked dose auto-logs as **`skipped`** when window closes | `pending → **missed**` automatically when `now > scheduledAt + intakeWindowMinutes`. `skipped` is **only** an explicit user action. `missed` (lapsed) and `skipped` (deliberate) are distinct — adherence treats them differently (skipped doesn't count against you; missed does). |
| Grace default **60 min**, window default **60 min** | Grace default **5** (range 0–30); intake window default **120** (range 15–240). Both adjustable in Settings. |

Take the constitution's numbers and semantics; treat the HTML comments as imprecise mockup notes.

## The one product decision still open (checkbox vs. explicit skip)

The HTML tile has **only a checkbox** — no explicit Skip. But the shipped app has a first-class `SkipIntake` use case, and the constitution keeps `skipped` distinct from `missed`. A pure checkbox **silently deletes the ability to deliberately skip a dose** (it would just lapse to `missed`). Recommendation: **checkbox = taken (primary tap), plus a secondary affordance for explicit Skip** (long-press, swipe, or overflow menu). Preserves the `skipped`/`missed` distinction the adherence math depends on, while matching the design's primary visual. Decided in Spec C.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| Today screen (host) | `lib/features/meds/presentation/screens/today_screen.dart` | Flat `ListView.builder` of tiles + grace-refresh `Timer`. Rebuilt in Spec C. |
| Pure view model | `.../view_models/today_view_model.dart` | `buildTodayView({meds, intakes, now}) → TodayView(doses)`. Hour-grouping + countdown layer added here. Pure, unit-tested, clock-injected. |
| Dose tile | `.../widgets/today_dose_tile.dart` | Badge + name + "HH:mm · dose" + Take/Skip/Undo. Restyled to checkbox + chips + stock warning. `IntakeStatus.missed` currently renders `SizedBox.shrink()` (reserved) — needs a real visual. |
| Dose expansion | `.../domain/value_objects/due_dose.dart` | `expandDueDoses` already sorts ascending by `minuteOfDay` — grouping is a fold over this ordered list. |
| Course progress | `.../value_objects/course_progress.dart`, `medication_activity.dart` | Already computes "Day N / M" — feeds the `День 3/7` chip directly. |
| Stock model | `Medication.stock` (`PackStock` remaining/total/warnAt) | Feeds the inline "5 з 60 шт" error-colored warning. |
| Meds-list grouping precedent | `.../view_models/meds_list_view_model.dart` | Established pattern for a view model emitting grouped lists — mirror for hour groups. |
| Settings feature | `lib/features/settings/**` | Currently theme + language only, persisted via `SharedPreferencesWithCache`. The pattern to mirror for the new numeric/bool knobs. |
| Intake use cases | `.../domain/usecases/{mark_intake_taken,skip_intake,undo_intake}.dart` | Existing state transitions. Auto-miss adds a `ReconcileMissedIntakes` sibling. |

### Gaps
- **No hour-grouping layer** — `TodayView` is a flat `List<TodayDose>`; needs a grouped wrapper.
- **No countdown computation** — "next upcoming pending dose" + duration-to-now not derived anywhere.
- **No group/dose window-state model** — past / now / future / disabled state isn't computed.
- **Settings knobs absent** — `intakeWindowMinutes`, `gracePeriodMinutes`, `allowMarkAhead` not in Settings (only theme + language).
- **No auto-miss engine** — spec 038 explicitly deferred `missed`/auto-transition.

## Constitution & Domain Constraints

| Rule | Impact |
|------|--------|
| §5.2 state machine | `pending → missed` auto when `now > scheduledAt + intakeWindowMinutes` (background job + on next app open). `taken → pending` only within `gracePeriodMinutes`. After grace, taken/missed editable only via a separate audit-logged "Manual Correction" flow. |
| §5.1 Settings | `gracePeriodMinutes` (5), `intakeWindowMinutes` (120), `notificationLeadMinutes` (0), quiet hours. `allowMarkAhead` is **not** listed — adding it is an additive §5.1 amendment. |
| §2.1 domain purity | Hour-grouping + countdown derivation must be **pure Dart** in the view model — no Flutter `TimeOfDay`/widgets. Group by `minuteOfDay ~/ 60`. |
| Clock injection (MEMORY) | Countdown / now-past-future state derive from passed-in `now` (`clock.now()`), never `DateTime.now()`. |
| UTC store / local display | `scheduledAt` is UTC; hour bucket computed from the **local** wall-clock `minuteOfDay` (already local on `TimeSlot`). |
| One-shot Timer only (tile dartdoc) | Live countdown must use a rescheduling one-shot `Timer`, or it breaks `pumpAndSettle` in widget tests. |
| Interface-change blast radius (MEMORY) | `TodayView` flat→grouped shape change ripples into 038's widget tests — enumerate implementers first. |
| Deprecated `surfaceVariant` (MEMORY) | HTML `--md-surface-variant` badges → Flutter `surfaceContainerHighest`, not `surfaceVariant` (lint-as-error). |

## The build, decomposed (all in scope — nothing deferred)

### Spec A — Intake-behavior Settings *(foundation)*
Extend the Settings feature (theme + language only, `SharedPreferencesWithCache`) with three knobs:
- `intakeWindowMinutes` (int, default 120, range 15–240)
- `gracePeriodMinutes` (int, default 5, range 0–30)
- `allowMarkAhead` (bool, default false) — **new knob, additive §5.1 amendment.** Governs whether a dose is tappable *before* its window opens.

*Grounded in existing code*: mirror the theme/language pattern — add keys to `core/providers/settings_prefs_keys.dart` allowList, `getInt`/`setInt` + `getBool`/`setBool` in `settings_local_data_source.dart`, three fields on the freezed `AppSettings`, one use case each, Settings-screen controls (slider/stepper + switch). Introduce the `IntakeWindow` value object the constitution anticipates (§ line 45). **No drift migration** — these are prefs, not PHI.

### Spec B — Auto-miss reconciliation + `missed` rendering *(depends on A)*
- New `ReconcileMissedIntakes` use case: for every pending due dose where `now > scheduledAt + intakeWindowMinutes`, write a `missed` `Intake` row (lazy-materialization means pending doses have no row today, so auto-miss must **create** them).
- Trigger points: **on app open** (`AppBootstrap`) and **on Today-view load** — the "on next app open" trigger the constitution names.
- Give `IntakeStatus.missed` a real tile visual (today it renders `SizedBox.shrink()`).
- **Scope honesty**: true OS-level background execution *while the app is closed* (WorkManager / BGTaskScheduler) is a **separate notifications-infra spec** — the constitution lists "background job" *and* "on next app open" as two triggers; B delivers the app-open one, which covers the practical case.

### Spec C — Today screen redesign *(depends on A + B)*
- **Hour grouping** (user's note): bucket doses by `minuteOfDay ~/ 60`; within-group keep the existing minute/name sort. Group = layout/collapse unit; **per-dose** state still drives each checkbox (a group can hold doses in different states).
- Collapsible groups with header badge (aggregate: "✓ taken/total"; accent "now" when `now`'s hour == group hour), chevron, count.
- **Countdown card** — "next intake in Xh Ym · HH:mm" from the soonest upcoming pending dose; live one-shot `Timer` tick.
- **Checkbox interaction** with per-dose enable/disable from A's window/grace/mark-ahead: before window → disabled unless `allowMarkAhead`; in window → enabled; taken within grace → uncheckable (undo); taken after grace → locked; pending after window → shown `missed` (from B).
- Per-tile **chips** (continuous / "Day N/M" via `course_progress.dart`), inline **low-stock warning** (`PackStock`), and **mark-all-in-group**.

## Complexity Assessment

| Dimension | Rating | Notes |
|---|---|---|
| Total scope | **High** | 3 specs. A: ~8–10 files; B: ~5–7 files + trigger wiring; C: screen rebuild + view-model rewrite + 2–3 widgets. |
| New dependencies | None | Settings=SharedPreferences; grouping/countdown=built-in `Timer`/`ExpansionTile`. No OS background scheduler unless added. |
| Risk | Medium | `TodayView` flat→grouped shape change ripples into 038's widget tests (enumerate implementers first). Auto-miss writing rows interacts with future adherence — get `missed` vs `skipped` right now. |

## Recommendation

**Proceed as an ordered chain — start with Spec A.** Both the auto-miss engine and the screen's disable logic read the window/grace/mark-ahead settings; doing C first would hardcode magic numbers you'd rip out immediately.

Decisions to confirm (recommended option first):
1. **Auto-miss target**: `missed` per constitution (not `skipped` per HTML) — ✅ follow constitution.
2. **Skip affordance**: checkbox + secondary Skip gesture (keep explicit skip) vs. pure checkbox (drop it).
3. **Background auto-miss**: app-open reconciliation now, OS background scheduler as a later spec — vs. build the OS scheduler now.
4. **Group "current" rule**: by clock hour vs. by any dose's active window.
5. **Mark-ahead default**: `false` (off) — matches "not actionable before window opens."

**Kick off the chain:**
```
/specify "Add intake-behavior settings to the Settings feature: intakeWindowMinutes (default 120, range 15–240), gracePeriodMinutes (default 5, range 0–30), and a new allowMarkAhead toggle (default false). Persist via SharedPreferences mirroring the theme/language pattern; add an IntakeWindow value object, use cases, and Settings-screen controls. Foundation for the Today-screen redesign and auto-miss engine."
```

Then Spec B (auto-miss), then Spec C (Today redesign).

---

## Chain status & ready-to-run commands

- **Spec A — Intake-behavior settings**: ✅ **DONE** — shipped as `specs/039-intake-settings/` (11/11 tasks complete, 756 tests green). Foundation only; nothing consumes the settings yet.
- **Spec B — Auto-miss reconciliation**: ⬜ not started (no spec dir yet). Depends on A.
- **Spec C — Today hourly-grouping redesign**: ⬜ not started (no spec dir yet). Depends on A + B.

B and C are NOT yet specs — they exist only as the plan above. To turn each into a runnable spec, invoke `/specify` with the prompt below, then follow the normal chain: `/specify → /plan → /breakdown → /execute-task all → /review → /verify → /summarize → /finalize`.

### Run Spec B next (auto-miss engine)
```
/specify "Add an auto-miss engine for intakes. New ReconcileMissedIntakes use case: for every pending due dose whose intake window has closed (now > scheduledAt + intakeWindowMinutes, reading the intakeWindow setting shipped in spec 039), write a missed Intake row (lazy model — pending doses have no row, so auto-miss must create them). Trigger it on app open (AppBootstrap) and on Today-view load. Give IntakeStatus.missed a real tile rendering on the Today screen (it currently renders SizedBox.shrink). Follow the constitution §5.2 state machine (pending → missed, NOT skipped). Out of scope: OS-level background execution while the app is closed (separate notifications-infra spec), and the Today hourly-grouping redesign (spec C)."
```

### Run Spec C after B (Today screen redesign)
```
/specify "Redesign the Today screen to match dosly_m3_template.html SCREEN 1. Group today's doses into collapsible hour groups — bucket by minuteOfDay ~/ 60 (per-hour, NOT per exact slot time) — each with a state badge (past taken-count / now / future) and a Mark-all-in-group action. Add a 'next intake' countdown card driven by a one-shot Timer (never Timer.periodic — breaks pumpAndSettle). Restyle dose tiles with status chips (continuous / Day N/M via course_progress.dart) and an inline low-stock warning (PackStock). Adopt the checkbox interaction model with a secondary explicit-skip affordance (keep the skipped vs missed distinction). Drive per-dose checkbox enable/disable from spec 039's intakeWindow/gracePeriod/allowMarkAhead settings and spec B's missed state. Use surfaceContainerHighest, not the deprecated surfaceVariant. Depends on specs 039 and B."
```

Both prompts already bake in the 5 decisions above and the constitution overrides (missed-not-skipped; 120/5 defaults; VO-driven bounds). Tweak before running if a decision changed.
