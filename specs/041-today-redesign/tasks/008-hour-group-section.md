# Task 008: Create the `TodayGroupSection` collapsible group widget

**Agent**: mobile-engineer
**Review checkpoint**: No
**Files**: `lib/features/meds/presentation/widgets/today_group_section.dart` (new), `test/features/meds/presentation/widgets/today_group_section_test.dart` (new)
**Depends on**: 005, 006, 001
**Blocks**: 009
**Context docs**: None

## Description

Create the collapsible per-hour group section: a header (hour, state badge, dose-count sub-label, rotating chevron) over a body of `TodayDoseTile`s plus a Mark-all tonal button. Collapse state is ephemeral local `StatefulWidget` state seeded from `initiallyExpanded`. The Mark-all button appears only when the group has an actionable pending dose. (Widget name is `TodayGroupSection` to avoid colliding with the view-model class `TodayHourGroup`.)

## Change details

- In `lib/features/meds/presentation/widgets/today_group_section.dart` (new):
  - Export `TodayGroupSection` — a `StatefulWidget` taking the view-model `TodayHourGroup group`, `bool initiallyExpanded`, `DateTime now`, and per-dose callbacks `onTaken/onSkip/onUndo` (by `TodayDose`) plus `onMarkAll` (`VoidCallback`).
  - Header (`.slot-head`): hour rendered `HH:00` via `MaterialLocalizations.formatTimeOfDay(TimeOfDay(hour: group.hour, minute: 0), alwaysUse24HourFormat: true)`; a **state badge** switching on `group.state` — `now` → `todayGroupBadgeNow` (primary) + a left-border accent on the section; `future` → `todayGroupBadgeFuture` (neutral); `past` → a ✓ icon + `todayGroupTakenCount(group.takenCount, group.total)` (neutral). A `todayGroupDoseCount(group.total)` sub-label. A chevron rotating on collapse. Tapping the header toggles `_expanded`.
  - Body (`.slot-body`, hidden when collapsed): a `TodayDoseTile` per `group.doses` (keyed `todayTile-<medId>-<slotId>`, passing `now` + callbacks), then a Mark-all `FilledButton.tonal` (keyed `todayMarkAll`, label `todayMarkAllInGroup`, check icon) shown ONLY when `group.hasActionablePending`.
  - Use `surfaceContainerHighest`/`surfaceContainerHigh`/container roles — no `surfaceVariant`.
- In the test (new): badge text per state (now/future/past-count); collapse toggle hides/shows the body; Mark-all present only when `hasActionablePending`; left-border accent only for `now`.

## Contracts

### Expects
- `TodayHourGroup` (fields `hour`, `doses`, `state`, `takenCount`, `total`, `hasActionablePending`) and `TodayGroupState` exist (task 005).
- `TodayDoseTile` takes `dose` + `now` + `onTaken/onSkip/onUndo` and is keyed `todayTile-<medId>-<slotId>` (task 006).
- l10n keys `todayGroupBadgeNow/Future`, `todayGroupTakenCount`, `todayGroupDoseCount`, `todayMarkAllInGroup` exist (task 001).

### Produces
- `today_group_section.dart` exports `TodayGroupSection` rendering the header badge (via `TodayGroupState`), a collapsible body of `TodayDoseTile`s, and a Mark-all button keyed `todayMarkAll` gated on `group.hasActionablePending`.

## Done when
- [x] Badge matches `group.state` (Now / Future / "✓ N/M"); only `now` shows the left-border accent.
- [x] Header tap toggles collapse; `initiallyExpanded` seeds the first build.
- [x] Mark-all button appears only when `hasActionablePending`; emits `onMarkAll`. Test BOTH branches explicitly (group with an actionable-pending dose ⇒ button shown; group with only taken/skipped/past-window doses ⇒ button hidden) — this is the coverage for `TodayHourGroup.hasActionablePending`, flagged untested in task 005's review.
- [x] No `surfaceVariant`.
- [x] `flutter test test/features/meds/presentation/widgets/today_group_section_test.dart` is green.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-2, AC-3, AC-10, AC-13

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-06
**Files changed**: `today_group_section.dart` (new), `today_group_section_test.dart` (new)
**Contract**: Expects [3/3 verified] | Produces [1/1 verified — `TodayGroupSection`; badge via `TodayGroupState`; collapsible tiles; `todayMarkAll` gated on `hasActionablePending`]
**Notes**: StatefulWidget, ephemeral `_expanded` from `initiallyExpanded`. Header: `HH:00` + `_GroupBadge` (exhaustive switch: now→primary pill, future→neutral, past→check+`todayGroupTakenCount`) + `todayGroupDoseCount` sub-label + `AnimatedRotation` chevron. Left-border `BorderSide(primary,3)` only when `now`. Body tiles keyed `todayTile-<med>-<slot>`; `FilledButton.tonalIcon` (`todayMarkAll`) only when `hasActionablePending`. 13/13 tests (both mark-all branches — closes task-005 W3). analyze clean.
**Code review**: APPROVE (inline — additive widget, exhaustive switch, thorough tests).
