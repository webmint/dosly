# Task 007: Create the `TodayCountdownCard` widget

**Agent**: mobile-engineer
**Review checkpoint**: No
**Files**: `lib/features/meds/presentation/widgets/today_countdown_card.dart` (new), `test/features/meds/presentation/widgets/today_countdown_card_test.dart` (new)
**Depends on**: 005, 001
**Blocks**: 009
**Context docs**: None

## Description

Create the dumb primary-container "next intake" card. Given the countdown target's scheduled instant (or `null`) and `now`, it renders "Next intake" + "in Xh Ym · HH:mm", or the "All done for today" message when there is no upcoming dose. No provider access — inputs only.

## Change details

- In `lib/features/meds/presentation/widgets/today_countdown_card.dart` (new):
  - Export `TodayCountdownCard({DateTime? nextScheduledAt, required DateTime now})` (or take the `TodayDose? nextIntake`; prefer the raw `DateTime?` to keep it dumb).
  - When `nextScheduledAt == null` → render `l10n.todayAllDone`.
  - Else compute `remaining = nextScheduledAt.difference(now)` (clamped ≥ 0); split into hours/minutes; render `l10n.todayNextIntakeIn(h, m)` (or `todayNextIntakeInMinutes(m)` when `h == 0`) + " · " + the local `HH:mm` via `MaterialLocalizations.formatTimeOfDay(TimeOfDay.fromDateTime(nextScheduledAt.toLocal()), alwaysUse24HourFormat: true)`, plus the `todayNextIntakeLabel`.
  - Style: `cs.primaryContainer` card, `onPrimaryContainer` text, a leading clock icon; keyed `todayCountdownCard`.
- In the test (new): countdown value for a 2h15m-ahead target; minutes-only for a sub-hour target; all-done message when `nextScheduledAt == null`.

## Contracts

### Expects
- l10n keys `todayNextIntakeLabel`, `todayNextIntakeIn`, `todayNextIntakeInMinutes`, `todayAllDone` exist (task 001).
- `TodayView.nextIntake` (`TodayDose?`) exists (task 005) so the screen can pass its `scheduledAt`.

### Produces
- `today_countdown_card.dart` exports `TodayCountdownCard` taking `nextScheduledAt` (`DateTime?`) and `now` (`DateTime`), rendering the countdown or `todayAllDone`; keyed `todayCountdownCard`.

## Done when
- [x] Renders "in Xh Ym · HH:mm" for a future target and "All done for today" for `null`.
- [x] Uses `primaryContainer`/`onPrimaryContainer` (no `surfaceVariant`).
- [x] `flutter test test/features/meds/presentation/widgets/today_countdown_card_test.dart` is green.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-4, AC-13

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-06
**Files changed**: `today_countdown_card.dart` (new), `today_countdown_card_test.dart` (new)
**Contract**: Expects [2/2 verified] | Produces [1/1 verified — `TodayCountdownCard(nextScheduledAt, now)`, keyed `todayCountdownCard`]
**Notes**: `primaryContainer` card, `LucideIcons.clock`; `null` → `todayAllDone`; else private `_Countdown` computes `remaining` (clamped ≥0), `h`/`m`, `todayNextIntakeIn(h,m)` or `todayNextIntakeInMinutes(m)` + " · HH:mm" (24h). Dumb, no provider. 3/3 tests green; analyze clean.
**Code review**: APPROVE (inline — additive dumb widget, tested).
