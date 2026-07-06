# Spec: Today Screen Redesign — Hourly Groups, Countdown, Checkbox Model

**Date**: 2026-07-05
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Redesign the Today screen to full Material 3 fidelity against `dosly_m3_template.html` SCREEN 1: replace the flat dose `ListView` with **collapsible per-hour dose groups** (bucketed by `minuteOfDay ~/ 60`), each carrying a **state badge** (past taken-count / now / future) and a **Mark-all-in-group** action; add a **"next intake" countdown card** driven by a one-shot rescheduling `Timer`; restyle dose tiles with **status chips** (continuous / Day N/M) and an **inline low-stock warning**; and adopt the **checkbox interaction model** with a **secondary explicit-skip affordance**, keeping the `skipped` vs `missed` distinction.

This is **Spec C**, the final link of the three-spec Today-redesign chain: Spec A (039 intake-behavior settings) shipped the `intakeWindow` / `gracePeriod` / `allowMarkAhead` knobs; Spec B (040 auto-miss engine) shipped the `missed` state and its reconcile triggers. This spec is the **first UI consumer of all three settings** — per-dose checkbox enable/disable is driven by `intakeWindow` + `allowMarkAhead` + Spec B's `missed` state, and the currently-hardcoded `kIntakeUndoGracePeriod` is rewired to read `gracePeriod` (the rewire both 039 and 040 explicitly deferred to Spec C).

## 2. Current State

### The Today screen (spec 038 + spec 040 — the code this redesigns)
`lib/features/meds/presentation/screens/today_screen.dart` — `TodayScreen`, a `ConsumerStatefulWidget` mounted at `/` and surfaced as the "Today" bottom-nav destination. It:
- Renders a Material 3 `AppBar` (`l10n.todayTitle`, a settings-gear action pushing `/settings`, a 1-px bottom `Divider`) and, below it, a muted full-date header (`MaterialLocalizations.formatFullDate(now)`).
- Watches `medicationsListProvider` + `intakesListProvider` (both `AsyncValue`), and on the settled path shapes them via `buildTodayView(meds:, intakes:, now: clock.now())` into a **flat** `ListView.builder` of `TodayDoseTile`s (ascending schedule-time), or `TodayEmptyState` when nothing is due.
- Owns a single **one-shot grace-refresh `Timer`** (`_graceTimer`, `_scheduleGraceRefresh`) that fires when the soonest undoable dose's grace window elapses to hide the Undo affordance — deliberately **never `Timer.periodic`** ("breaks `pumpAndSettle`"). Cancelled in `dispose` and before each reschedule.
- Fires **auto-miss reconciliation once per mount** via `Future.microtask` in `initState` (`ref.read(reconcileMissedIntakesProvider).call(now: clock.now())`; fire-and-forget, `mounted`-guarded) — spec 040's on-Today-load trigger.

`lib/features/meds/presentation/view_models/today_view_model.dart` — pure, synchronous `buildTodayView({meds, intakes, now}) → TodayView(doses: List<TodayDose>)`. Indexes stored intakes once into a map keyed `(medicationId, slotId, localCalendarDate(scheduledAt))`, then per due dose resolves `status` (`pending` when unmatched), `confirmedAt`, `intakeId`, and `undoable` (grace-window, via `kIntakeUndoGracePeriod`). `TodayDose` carries `{dose, status, confirmedAt, undoable, intakeId}`; `TodayView` carries `{doses}` + `isEmpty`. **No grouping, no per-dose enable/disable, no window/settings awareness, no countdown, no chips today.**

`lib/features/meds/presentation/widgets/today_dose_tile.dart` — dumb `TodayDoseTile`: 48×48 primary-container icon badge → name + "HH:mm · dose" subtitle → a status-dispatched actions area (exhaustive `switch` over `IntakeStatus`, no `default:`): `pending` → OutlinedButton **Skip** + FilledButton **Take** (both always enabled; NO overdue styling — "a past-time pending dose renders identically to an upcoming one"); `taken`/`skipped` → status label + Undo (only when `undoable`); `missed` → error-toned "Missed" label, no actions (spec 040). **No checkbox, no chips, no stock, no grouping.**

`lib/features/meds/presentation/widgets/today_empty_state.dart` — the "nothing due" empty state (unchanged by this spec except to coexist with the countdown card).

### The pure derivations this reuses (spec 038 + 040 — unchanged)
- `domain/value_objects/due_dose.dart` — `expandDueDoses({meds, now}) → List<DueDose>`: today's due doses on the **local calendar day** of `now`, sorted ascending by `minuteOfDay` (ties by name, then slot id). Each `DueDose` = `{medication, slot, effectiveDose, scheduledAt (UTC)}`. Due-today logic reuses `localCalendarDate` + `CourseProgress.resolve` + `resolveMedicationActivity` (excludes future starts, completed courses, cyclic pause-gap days). **This is the group source — `slot.minuteOfDay ~/ 60` is the hour bucket.**
- `domain/value_objects/course_progress.dart` — `CourseProgress.resolve({course, now}) → {currentDay, totalDays, phase}` (DST-safe local-calendar day math). **The source of the "Day N/M" chip.**
- `domain/value_objects/local_calendar_date.dart` — DST-safe local-day reduction reused across all of the above.

### The settings this consumes (spec 039 — shipped, this is the first UI consumer)
`lib/features/settings/`:
- `AppSettings` (freezed) carries `intakeWindow: IntakeWindow` (default 120), `gracePeriod: GracePeriod` (default 5), `allowMarkAhead: bool` (default false), plus theme/language fields.
- `IntakeWindow` (`domain/value_objects/intake_window.dart`) — self-clamping VO, `minutes` in [15, 240], `const IntakeWindow.defaultValue` = 120. `GracePeriod` (`grace_period.dart`) — self-clamping VO, `minutes` in [0, 30], `defaultValue` = 5. Both pure Dart, value-equality.
- `settingsNotifierProvider` (`presentation/providers/settings_provider.dart`, `@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')`) holds `AppSettings` **synchronously** (seeded from `repo.load().fold(default, id)` against the resolved `SharedPreferencesWithCache`). Reads are `ref.watch(settingsNotifierProvider).intakeWindow` etc.

### The auto-miss engine + settings DI seam (spec 040 — shipped)
`lib/features/meds/presentation/providers/intake_providers.dart` — the meds **composition seam** (the one presentation file permitted to import `data/` and, per spec 040, `settings/presentation/providers/settings_provider.dart` for DI). It exposes `intakeRepositoryProvider`, `markIntakeTakenProvider`, `skipIntakeProvider`, `undoIntakeProvider`, the reactive `intakesListProvider`, and `reconcileMissedIntakesProvider` (whose use case reads `intakeWindow` internally via `settingsRepositoryProvider`). **Screens/widgets stay settings-free today** — this spec must decide how the Today screen reaches the three settings (see §7 / §8).

### The grace constant to be rewired (spec 039/040 explicitly deferred this to Spec C)
`lib/features/meds/domain/value_objects/intake_grace.dart` — `const kIntakeUndoGracePeriod = Duration(minutes: 5)`, consumed by `today_view_model.dart` (`_isUndoable`) and `undo_intake.dart`. Its dartdoc already notes: "it will become Settings-configurable (§5.2 range 0–30) in a future feature, at which point this constant becomes the default rather than the hard-coded value." **This spec is that feature.**

### The tile-styling patterns to reuse (spec 034/036 — the meds list)
`lib/features/meds/presentation/widgets/medication_tile.dart` + `medication_display.dart` already implement, for the meds LIST, exactly the visual vocabulary this redesign needs on Today:
- **Type/status chips** — a `_Pill` (stadium, radius 100, `labelSmall` w500) with color specs: continuous → `surfaceContainerHigh`/`onSurfaceVariant`; course activeWindow "Day N/M" (`l10n.medsListTypeCourseDay`) → `tertiaryContainer`/`onTertiaryContainer`; course paused → neutral. Already correctly uses `surfaceContainerHighest`/`surfaceContainerHigh` (NOT deprecated `surfaceVariant`).
- **Inline low-stock** — `formatStock(stock, l10n)` (`l10n.medsListStock(remaining, total)`) rendered bold, `cs.error` when `isLowStock(stock)` (`remaining <= warnAt`), via a `Text.rich` span. `isLowStock`/`formatStock` are reusable pure helpers in `medication_display.dart`.

### Constitution contract (already authored — this spec implements the UI half)
- **§5.2 intake window**: default 120, range 15–240; an intake is `pending` from `scheduledAt − notificationLeadMinutes` (lead = 0, not built) until `scheduledAt + intakeWindowMinutes`; after that it is `missed`.
- **§5.2 grace period**: default 5, range 0–30; a `taken` dose can be undone within grace.
- **§5.2 `allowMarkAhead`** (039 additive amendment): governs whether a dose is actionable before its window opens.
- **§5.2 missed vs skipped**: `missed` (window lapsed) and `skipped` (explicit opt-out) are **distinct** and must stay distinguishable in the UI.
- **§4.2.1**: check `mounted` after `await` before using `BuildContext`; exhaustive `switch` (no `default:`) over `IntakeStatus`; `const` constructors; inject `Clock`.

### Relevant MEMORY.md lessons
- **`Timer.periodic` breaks `pumpAndSettle`** (feature 038/040): the countdown/live-refresh timer MUST be a self-rescheduling **one-shot** `Timer`, cancelled in `dispose` and before each reschedule.
- **Interface-change blast radius** (features 037/039/040): changing `buildTodayView`'s signature or `UndoIntake`'s API breaks every caller and hand-written test fake; run **project-wide** `dart analyze`, not just changed-file.
- **Un-batched N writes → N stream re-emits → N rebuilds** (040 deferred follow-up): Mark-all-in-group looping `markTaken` N times is acceptable for MVP but is a known perf trade-off; note it, don't silently ship a hidden cap.
- **Clock injection; UTC storage, local display** throughout.

## 3. Desired Behavior

### 3.1 Per-hour dose grouping
Doses due today are **bucketed by hour** = `slot.minuteOfDay ~/ 60` (0–23) — per-hour, **NOT** per exact slot time, so 14:00 and 14:30 doses share the hour-14 group. Grouping happens in the **pure view model** (mirrors `buildTodayView`'s existing purity, for unit-testability without pumping widgets):

- Each group holds: the **hour** (0–23), its **ordered doses** (preserving `expandDueDoses`' ascending order), a derived **state** (§3.2), and the **taken-count / total** for its badge.
- Groups are ordered ascending by hour. A group exists only when it has ≥1 due dose.
- Each group is rendered as a collapsible section (`.slot-group`) with a header (`.slot-head`) and a body (`.slot-body`); tapping the header toggles collapse with a rotating chevron (`.slot-chevron`).
- **Default expansion (ephemeral, not persisted)**: on load, the **current** group(s) (state = now) are **expanded**; past and future groups are **collapsed**. If no current group exists, the soonest **future** group is expanded. The user may toggle any group; collapse state is local UI only and resets on the next screen load.

### 3.2 Group state badge (past / now / future)
Each group's state is derived from the **aggregate window state** of its doses as of `now` (windows are per-dose, driven by `intakeWindow`; `windowClose = scheduledAt + intakeWindow.minutes`, `notificationLeadMinutes` = 0):

- **future** — every dose in the group is strictly before its window open (`now < scheduledAt` for all). Badge: localized **"Future"**, neutral (`surfaceContainerHighest` / `onSurfaceVariant`). Left border accent absent.
- **now** (current) — at least one dose's window is open (`scheduledAt ≤ now ≤ windowClose`), i.e. neither all-future nor all-past. Badge: localized **"Now"**, primary (`primary` / `onPrimary`). The group gets the **left-border accent** (`.slot-group.current`) and a distinct header background.
- **past** — every dose's window has closed (`now > windowClose` for all). Badge: a **taken-count** "✓ N/M" where N = doses in the group with `status == taken`, M = group size; neutral styling.

The header also shows a muted count sub-label (`.slot-sub`, e.g. "3 doses" localized/pluralized) and the hour rendered via `MaterialLocalizations.formatTimeOfDay` at `HH:00` (each dose's exact `HH:mm` remains in its own tile subtitle).

### 3.3 Mark-all-in-group action
Each group body ends (`.mark-all-row`) with a **tonal button** ("Mark all", check icon) that marks **every actionable pending dose in that group as `taken`** (via `markIntakeTakenProvider`, one call per dose; see MEMORY perf note). It:
- Is shown ONLY when the group has ≥1 **actionable pending** dose (a pending dose whose checkbox is currently enabled per §3.5). Hidden otherwise (all-done, all-locked, or all-future-with-mark-ahead-off groups show no button).
- Never touches already-`taken`/`skipped`/`missed` doses, and never touches a pending dose whose checkbox is disabled (future with mark-ahead off, or past-window).
- Marks **`taken`**, never `skipped` (the checkmark semantics).
- A per-dose failure surfaces the existing localized error `SnackBar` (`l10n.todayActionError`); successful marks flow back reactively via `intakesListProvider`.

### 3.4 "Next intake" countdown card
A card (`.cd-card`, primary-container) at the top of the scroll body, below the date header, above the first group:

- **Target** = the **soonest strictly-future pending dose** across all groups (smallest `scheduledAt` with `now < scheduledAt` and `status == pending`). Renders a localized label ("Next intake") + a value "in Xh Ym · HH:mm" (relative duration + the dose's local `HH:mm`). Sub-hour targets render "in Ym"; the exact plural/format shape is an l10n detail for `/plan`.
- **All-done state** — when **no** strictly-future pending dose remains (everything today is taken/skipped/missed, or only currently-open/past doses linger), the same card shows a localized **"All done for today"** message instead of disappearing. The card is always present whenever ≥1 dose is due today; it is absent only in the whole-day empty state (`TodayEmptyState`).

### 3.5 Checkbox interaction model + per-dose enable/disable
Each dose tile adopts the **M3 checkbox** model (`.m3-cb` / `.cb-box`), replacing the Take/Skip/Undo button cluster:

- **Checkbox meaning** = "taken". `pending` → unchecked; `taken` → checked; `skipped`/`missed` → unchecked but visually distinct (§3.6).
- **Check (unchecked → checked)** on a pending dose = mark `taken` (`markIntakeTakenProvider`).
- **Uncheck (checked → unchecked)** on a `taken` dose = **undo** back to pending (`undoIntakeProvider`), allowed **only while `undoable`** (within `gracePeriod`, §3.7). After grace, the checked box is **locked** (disabled, stays checked).
- **Secondary explicit-skip affordance** = a **trailing skip icon button** beside the checkbox (a small icon, e.g. skip-forward), shown for a pending dose while its checkbox is enabled. One tap = record `skipped` (`skipIntakeProvider`), keeping `skipped` distinct from `missed`. Hidden once the dose is taken/skipped/missed or its checkbox is disabled. Tap target ≥ 48 dp (constitution §4.3.1); carries an accessibility tooltip.

**Per-dose checkbox enabled/disabled** is derived (in the pure view model, given `intakeWindow`, `allowMarkAhead`, `gracePeriod`, and `now`):

| Dose state | Condition | Checkbox | Skip icon |
|---|---|---|---|
| pending, **future** (`now < scheduledAt`), mark-ahead **off** | window not open, no early marking | disabled, unchecked (tile dimmed, `.future-slot`) | hidden |
| pending, **future**, mark-ahead **on** | early marking allowed | enabled, unchecked | shown |
| pending, **open** (`scheduledAt ≤ now ≤ windowClose`) | actionable | enabled, unchecked | shown |
| pending, **past window** (`now > windowClose`) | lapsed (about to reconcile to missed) | disabled, unchecked | hidden |
| **taken**, within grace (`undoable`) | undoable | enabled, **checked** | hidden |
| **taken**, past grace | locked | disabled, **checked** (`.done`, line-through name) | hidden |
| **skipped** | explicit opt-out (undoable within grace) | disabled/neutral, unchecked; undo within grace (§3.7) | hidden |
| **missed** | lapsed (spec 040) | disabled, unchecked, error-toned "Missed" (§3.6) | hidden |

Marking a future dose ahead (mark-ahead on) records `confirmedAt = now` while `scheduledAt` stays the slot's scheduled instant (existing `MarkIntakeTaken` behavior — no change needed).

### 3.6 Restyled dose tile (chips, stock, distinct states)
`TodayDoseTile` is restyled to the template `.med-tile`:

- **Leading badge** — 48×48 rounded-square icon (existing `medicationFormIcon`), primary-container tint.
- **Body** — medication name (line-through + muted when `taken`/locked, `.done`), "HH:mm · dose" subtitle, then **status chips** and an optional inline low-stock segment:
  - **Status chip** (reusing the meds-list `_Pill` vocabulary, extracted to a shared widget if `/plan` prefers): **continuous** → neutral "continuous" chip; **course** → teal **"Day N/M"** chip derived via `CourseProgress.resolve(course:, now:)` (the same source the meds list uses). Course paused shouldn't appear on Today (paused ⇒ not due), but the derivation is defensive.
  - **Inline low-stock warning** — shown ONLY when `isLowStock(medication.stock)` is true: the localized stock string (`formatStock`) rendered bold, `cs.error` (matching the template's red "5 з 60 шт"). Non-low or stock-less doses show no stock segment on Today.
- **Trailing** — the checkbox (+ skip icon per §3.5).
- **All new/changed surfaces use `surfaceContainerHighest`/`surfaceContainerHigh`/`primaryContainer` — never the deprecated `surfaceVariant`.**

### 3.7 Grace-period rewire (`kIntakeUndoGracePeriod` → `gracePeriod` setting)
The undo grace window becomes user-configurable, reading `AppSettings.gracePeriod` instead of the hardcoded 5-min constant:

- `today_view_model.dart`'s `undoable` derivation uses the passed `gracePeriod.minutes` (not `kIntakeUndoGracePeriod`).
- `undo_intake.dart` (`UndoIntake`) reads the grace window from `gracePeriod` — supplied by the caller/provider (mirroring how `ReconcileMissedIntakes` receives `intakeWindow`), keeping the use case unit-testable with a fixed period. Its `Either` contract and grace-boundary rule (inclusive) are preserved.
- `kIntakeUndoGracePeriod` is retained **only** as the shared **default** (or replaced by `GracePeriod.defaultValue`); no code path keeps the hardcoded value as the live grace window. The one-shot refresh timer reschedules against the configured grace period.

### 3.8 Live re-derive timer (one-shot, rescheduling)
The existing grace-refresh `Timer` is generalized into a single **one-shot, self-rescheduling** timer that fires at the **next relevant boundary** = the minimum future instant among: the next dose's `scheduledAt` (window open), any open dose's `windowClose`, and any `taken` dose's grace-expiry. On fire it `setState`s to **re-derive the whole view** — countdown advances, group badges recolor past↔now↔future, checkboxes/skip enable/disable, Undo disappears — **with no database writes** (missed rows remain the job of the load/app-open reconcile triggers from spec 040; no reconcile fires from this timer). It remains **never `Timer.periodic`**, is cancelled in `dispose` and before each reschedule, and schedules nothing when there is no future boundary.

### 3.9 Localization
New ARB keys in `app_en.arb` (+ `@`-descriptions) with parity in `app_de.arb` and `app_uk.arb`: next-intake label + countdown value (hours/minutes/time placeholders) + all-done message; group badges (Now / Future / "✓ {taken}/{total}") + group dose-count sub-label (pluralized) + hour header; Mark-all button; skip-icon accessibility tooltip. Reuse existing keys where possible (`todayStatusTaken/Skipped/Missed`, `medsListTypeContinuous`, `medsListTypeCourseDay`, `medsListStock`, `todaySkip`); `/plan` decides reuse-vs-new per key. `AppLocalizations` regenerates cleanly.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| View model — grouping/state/enable/countdown | `lib/features/meds/presentation/view_models/today_view_model.dart` | **Modify**: `buildTodayView` gains `intakeWindow`/`gracePeriod`/`allowMarkAhead` params; returns hour-bucketed groups (`TodayHourGroup` w/ state + taken-count), per-dose `enabled`/window-state, and the countdown target; `undoable` reads `gracePeriod`. **Signature change — blast radius below.** |
| Screen — layout/timer/actions | `lib/features/meds/presentation/screens/today_screen.dart` | **Modify**: render countdown card + collapsible groups (collapse state, default expansion) instead of a flat list; generalize the one-shot timer to re-derive at the next boundary; wire check/uncheck→take/undo, skip icon→skip, mark-all→N×take; read the three settings (seam per §7/§8). |
| Widget — dose tile | `lib/features/meds/presentation/widgets/today_dose_tile.dart` | **Modify**: checkbox + trailing skip icon (replacing Take/Skip/Undo buttons), status chips, inline low-stock, `.done`/locked/future/missed visual states; keep exhaustive `IntakeStatus` switch. |
| Widget — group section (new) | `lib/features/meds/presentation/widgets/today_hour_group.dart` (name TBD) | **Create**: collapsible group header (time, state badge, count sub-label, chevron) + body (tiles + mark-all row). |
| Widget — countdown card (new) | `lib/features/meds/presentation/widgets/today_countdown_card.dart` (name TBD) | **Create**: primary-container card rendering the countdown value or all-done message. |
| Widget — shared status chip (maybe) | `lib/features/meds/presentation/widgets/…` | **Create/extract (optional)**: a shared continuous/Day-N/M chip if `/plan` factors it out of `medication_tile.dart`'s `_Pill`/`_TypeChip`. |
| Domain — undo use case | `lib/features/meds/domain/usecases/undo_intake.dart` | **Modify**: read grace window from a supplied `gracePeriod` (VO/Duration) rather than `kIntakeUndoGracePeriod`; preserve `Either` + inclusive-boundary contract. |
| Domain — grace constant | `lib/features/meds/domain/value_objects/intake_grace.dart` | **Modify**: demote to default-only (or remove in favor of `GracePeriod.defaultValue`); no live path keeps the hardcoded window. |
| Providers — settings seam + undo wiring | `lib/features/meds/presentation/providers/intake_providers.dart` | **Modify**: supply `gracePeriod` to `undoIntakeProvider`; expose the three settings to the Today screen (projection provider vs direct `settingsNotifierProvider` watch — §8 OQ). |
| Localization | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `AppLocalizations`) | **Modify**: add countdown/all-done/group-badge/count/mark-all/skip-tooltip keys in all three locales. |
| Test fakes / callers (blast radius) | `test/features/meds/presentation/view_models/today_view_model_test.dart`, `.../screens/today_screen_test.dart`, `.../usecases/undo_intake_test.dart`, any `implements`-based fakes touching `UndoIntake`/`buildTodayView` | **Modify**: update `buildTodayView` call sites for the new params; update `UndoIntake` tests for the grace param; project-wide `dart analyze` + full suite green. |
| New tests | `test/features/meds/presentation/view_models/…`, `.../widgets/today_dose_tile_test.dart`, `.../widgets/today_hour_group_test.dart`, `.../widgets/today_countdown_card_test.dart`, `.../screens/today_screen_test.dart` | **Create**: hour-bucketing, group-state boundaries, per-dose enable matrix (future/open/past × mark-ahead), countdown target + all-done, checkbox take/undo/skip, mark-all filtering, one-shot timer reschedule (no `Timer.periodic`, `pumpAndSettle`-safe), chip/stock rendering, de/uk parity. |

## 5. Acceptance Criteria

**Grouping & group state**
- [x] **AC-1**: Today's due doses are bucketed into groups by `slot.minuteOfDay ~/ 60` (per hour), so two doses at 14:00 and 14:30 share one hour-14 group; groups render in ascending hour order; each dose's exact `HH:mm` still appears in its own tile subtitle. Grouping is computed in the pure view model (unit-tested without pumping widgets).
- [x] **AC-2**: A group's state is **future** iff every dose has `now < scheduledAt`; **past** iff every dose has `now > scheduledAt + intakeWindow.minutes`; otherwise **now**. The badge shows localized "Future" / a "✓ N/M" taken-count (N = taken doses, M = group size) / localized "Now" respectively, and only the **now** group carries the left-border accent.
- [x] **AC-3**: Each group is collapsible (header tap toggles; chevron rotates). On load the **now** group is expanded and past/future groups are collapsed; with no now group, the soonest future group is expanded. Collapse state is local/ephemeral (not persisted) and does not survive a reload.

**Countdown card**
- [x] **AC-4**: The countdown card targets the soonest strictly-future pending dose (`now < scheduledAt`, `status == pending`) and shows "Next intake" + "in Xh Ym · HH:mm" for it. When no strictly-future pending dose remains, the same card shows the localized "All done for today" message rather than disappearing. The card is present whenever ≥1 dose is due today and absent only in the whole-day empty state.
- [x] **AC-5**: The card's countdown value and the target dose update **live** when the one-shot timer fires at the next boundary (e.g. once the current "next" dose's time passes, the card advances to the following dose or the all-done state) — without a manual refresh and without any DB write.

**Checkbox model & per-dose enable/disable**
- [x] **AC-6**: Checking a pending dose's checkbox marks it `taken` (via `markIntakeTakenProvider`); unchecking a `taken` dose within its grace window undoes it to pending (via `undoIntakeProvider`); after grace the checked box is disabled (locked, stays checked). The name renders line-through/muted when taken.
- [x] **AC-7**: A trailing skip icon button (≥48 dp, with tooltip) appears beside the checkbox only for a pending dose whose checkbox is enabled; tapping it records `skipped` (via `skipIntakeProvider`), and `skipped` stays visually distinct from `missed`. It is hidden once the dose is taken/skipped/missed or the checkbox is disabled.
- [x] **AC-8**: Per-dose checkbox enable/disable matches §3.5: pending-future is disabled (dimmed) when `allowMarkAhead` is off and enabled when on; pending-open is enabled; pending-past-window is disabled; taken-within-grace is enabled (checked); taken-past-grace, skipped, and missed are disabled. Toggling `allowMarkAhead` in Settings updates the enablement reactively.
- [x] **AC-9**: Window boundaries are computed in UTC with `windowClose = scheduledAt + intakeWindow.minutes`, `notificationLeadMinutes` = 0; the open interval is inclusive of both ends (`scheduledAt ≤ now ≤ windowClose`); a dose exactly at `windowClose` is still "open" (consistent with spec 040's strict `>` for missed-eligibility, so there is no gap or overlap between "open" and "missed").

**Mark-all-in-group**
- [x] **AC-10**: The Mark-all button appears only when a group has ≥1 actionable pending dose; tapping it marks every actionable pending dose in that group `taken` and leaves taken/skipped/missed and disabled-pending doses untouched. A per-dose failure surfaces the localized error SnackBar; successful marks appear reactively.

**Chips, stock, styling**
- [x] **AC-11**: Each dose tile shows a status chip — "continuous" (neutral) for continuous meds, "Day N/M" (teal, from `CourseProgress.resolve`) for course meds — matching the meds-list chip vocabulary.
- [x] **AC-12**: A dose whose medication `isLowStock` (`stock.remaining <= stock.warnAt`) shows an inline bold `cs.error` stock string (`formatStock`); non-low / stock-less doses show no stock segment on the Today tile.
- [x] **AC-13**: No new or changed Today widget uses the deprecated `surfaceVariant`; group/badge/tile surfaces use `surfaceContainerHighest` / `surfaceContainerHigh` / container roles.

**Grace rewire & timer**
- [x] **AC-14**: The undo grace window reads `AppSettings.gracePeriod` (range 0–30) end-to-end: `today_view_model.dart`'s `undoable` and `UndoIntake` both use the configured period; no live path uses the hardcoded `kIntakeUndoGracePeriod` as the grace window (it survives only as a default). Changing grace in Settings changes how long Undo stays available.
- [x] **AC-15**: The Today screen uses exactly one **one-shot** rescheduling `Timer` (never `Timer.periodic`), cancelled in `dispose` and before each reschedule; widget tests reach a settled state with `pumpAndSettle` (no hang). The timer performs no DB writes and never triggers reconciliation.

**Quality & blast radius**
- [x] **AC-16**: `buildTodayView`'s new signature and `UndoIntake`'s grace parameter are propagated to every caller and hand-written test fake; **project-wide** `dart analyze` is clean and the full `flutter test` suite is green. New/changed ARB keys exist in en/de/uk and `AppLocalizations` regenerates cleanly. New public APIs carry dartdoc; every fallible op returns `Either<Failure, T>`; the `IntakeStatus` switch stays exhaustive (no `default:`).

## 6. Out of Scope

- **NOT included**: The auto-miss engine itself (spec 040 — shipped); this spec only **restyles** the missed tile within the new layout and adds no new reconcile trigger (the timer re-derives, it never writes/reconciles).
- **NOT included**: OS-level background execution / notifications / reminders / `notificationLeadMinutes` / quiet hours (lead stays 0).
- **NOT included**: The "Manual Correction" audit-logged edit flow — `missed` and post-grace `taken` doses stay **locked** (no correction affordance).
- **NOT included**: Decrementing `PackStock` on intake, editing stock, or a refill flow — low-stock is **display-only** here.
- **NOT included**: Adherence / History computation or any History-screen change.
- **NOT included**: Multi-day / past-day views — Today remains the single local calendar day (`expandDueDoses`).
- **NOT included**: A batched "mark many" repository/use-case op — Mark-all loops the existing `markTaken` (N writes) for MVP.
- **NOT included**: Persisting group collapse state across sessions; per-group settings; drag/reorder.
- **NOT included**: Any drift schema/migration change (`schemaVersion` stays 2); any change to `expandDueDoses` / `CourseProgress` / `localCalendarDate` math.
- **NOT included**: New locales beyond en/de/uk; the add/edit-medication and meds-list screens (SCREEN 2/3 of the template).
- **NOT included**: Consuming `quietHoursStart/End` or other unshipped §5.1 settings.

## 7. Technical Constraints

- **Clean Architecture (§2.1)**: the grouping/state/enable/countdown derivations live in the **pure** `today_view_model.dart` (no Flutter/drift/data imports); widgets stay dumb; the screen reaches use cases only via `@riverpod` providers. Reading settings' `IntakeWindow`/`GracePeriod` VOs from the meds layer is a permitted domain→domain import (spec 039 OQ-1).
- **Settings-consumption seam**: the Today screen must obtain `intakeWindow`/`gracePeriod`/`allowMarkAhead`. Prefer a meds-side projection provider (or a direct reactive `ref.watch(settingsNotifierProvider)` in the screen) so Settings changes reflect live (AC-8/AC-14). Keep pure derivations settings-value-driven (pass VOs in), not provider-aware. Exact seam is an `/plan` decision (§8 OQ-1) — do NOT let widgets import settings `data/`.
- **One-shot timer only (§ MEMORY)**: never `Timer.periodic`; self-reschedule to the next boundary; cancel in `dispose` and before reschedule; keep `pumpAndSettle` safe (AC-15).
- **Clock injection / UTC**: all time math via injected `clock.now()`; store UTC, display local; window/grace comparisons in UTC (AC-9).
- **`missed` boundary alignment (spec 040)**: "open" must be inclusive at `windowClose` so it dovetails with 040's strict `now > windowClose` missed-eligibility — no gap, no double-count.
- **Reuse, don't reinvent (§3.7 constitution)**: reuse `expandDueDoses`, `CourseProgress.resolve`, `localCalendarDate`, `formatDose`/`formatStock`/`isLowStock`, and the meds-list chip/`_Pill` vocabulary; extract shared widgets rather than duplicating.
- **M3 tokens**: `surfaceContainerHighest`/`surfaceContainerHigh` (NOT deprecated `surfaceVariant`); container/on-container role pairs for badges and chips (AC-13).
- **Interface-change blast radius (§ MEMORY)**: `buildTodayView` + `UndoIntake` signature changes ripple to callers and hand-written fakes — enumerate and run **project-wide** `dart analyze` + full suite (AC-16).
- **Localization**: all user-facing strings via `context.l10n.*`; en/de/uk parity; pluralize dose-count and countdown units through ARB (AC-16).
- **Async-safety (§4.2.1)**: `mounted` checks after every `await` before touching `BuildContext`/`ScaffoldMessenger`; `ref.read` in callbacks, `ref.watch` in `build`.
- **Codegen**: run `dart run build_runner build --delete-conflicting-outputs` after any `@riverpod`/freezed change; commit generated files.

## 8. Open Questions

- **OQ-1 (settings seam)**: expose the three settings to the Today screen via a new meds-side projection provider (keeps the screen "settings-free" like spec 040's seam) vs a direct `ref.watch(settingsNotifierProvider)` in `TodayScreen` (simpler, still a provider read, not a widget import). Lean toward the direct watch for reactivity + simplicity; `/plan` decides.
- **OQ-2 (view-model shape)**: return a `TodayView` with `groups: List<TodayHourGroup>` + `nextIntake` + `isEmpty`, or keep `doses` flat and derive groups/countdown in a second pure pass. Prefer explicit groups in the view model for testability.
- **OQ-3 (`UndoIntake` grace param type)**: pass `GracePeriod` (settings VO, cross-feature import) vs a plain `Duration` (keeps the meds use case settings-agnostic). Lean `Duration` at the use-case boundary, resolved from `GracePeriod` at the provider seam.
- **OQ-4 (shared chip extraction)**: extract the continuous/Day-N/M chip into a shared widget consumed by both `medication_tile.dart` and the Today tile, vs duplicate the small `_Pill`. Prefer extraction (DRY once there are 2 consumers).
- **OQ-5 (skip icon glyph + placement)**: exact Lucide glyph for skip (e.g. `skipForward` / `x` / `chevronsRight`) and whether it sits left-of or right-of the checkbox. Cosmetic; `/plan` + design-auditor.
- **OQ-6 (group hour header format)**: render the bucket as `HH:00` vs an hour range `HH:00–HH:59` vs a localized hour label. Lean `HH:00` via `MaterialLocalizations`.
- **OQ-7 (countdown unit formatting)**: exact plural/format for "in Xh Ym" across en/de/uk (single ARB placeholder string vs composed parts). `/plan` + l10n.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `buildTodayView`/`UndoIntake` signature change breaks callers + hand-written fakes and slips past changed-file analyze | High | Med | Enumerate all callers/fakes (§4); run **project-wide** `dart analyze` + full suite (AC-16). |
| One-shot re-derive timer regresses to a `Timer.periodic` or a reschedule loop → `pumpAndSettle` hangs | Med | High | Single self-rescheduling one-shot, no DB writes, cancel on dispose/reschedule; assert `pumpAndSettle`-safe in a widget test (AC-15). |
| "Open" vs "missed" boundary off-by-one (gap or overlap with spec 040's strict `>`) | Med | Med | Inclusive `windowClose` for "open"; unit-test at/just-past the boundary; cross-check with 040's AC-2 (AC-9). |
| Un-batched Mark-all → N stream re-emits → N rebuilds jank on large groups | Low | Low | Accept for MVP (known 040 follow-up); note the trade-off; a batch op is out of scope. |
| Cross-feature settings coupling makes the Today view model provider-aware / impure | Med | Med | Keep pure derivations value-driven (pass VOs); confine the provider read to the screen/seam (§7, OQ-1/OQ-3). |
| Checkbox undo semantics confuse users (uncheck = undo only within grace, else locked) | Low | Med | Clear locked/disabled affordance + line-through; grace now user-visible/configurable (AC-6/AC-14); design-auditor pass. |
| Reusing `medsList*` l10n keys on Today couples two screens' copy | Low | Low | `/plan` decides reuse vs new per key; default to new Today-namespaced keys where copy may diverge. |
