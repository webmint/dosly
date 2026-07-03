# Task 014: Today dose tile widget

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/today_dose_tile.dart`, `test/features/meds/presentation/widgets/today_dose_tile_test.dart` _(relocated from `features/home/` during code review — see notes)_
**Depends on**: 011, 013
**Blocks**: 015
**Context docs**: docs/features/meds.md
**Review checkpoint**: Yes

**Description**:
Stateless presentation widget that renders one `TodayDose` row and exposes callbacks for the three actions. First presentation-layer UI task (layer-boundary checkpoint). No provider access — the screen (Task 015) wires callbacks. Reuses `medicationFormIcon` and the 24-hour time formatting idiom.

**Change details**:
- `TodayDoseTile` (`StatelessWidget`) taking `TodayDose dose`, `VoidCallback onTaken`, `VoidCallback onSkip`, `VoidCallback onUndo`.
  - Leading: `medicationFormIcon(dose.dose.medication.form)` badge.
  - Body: medication name; time via `MaterialLocalizations.formatTimeOfDay(TimeOfDay(hour: .., minute: ..), alwaysUse24HourFormat: true)` derived from `dose.dose.slot.minuteOfDay`; effective dose amount when present.
  - Trailing/actions by status:
    - `pending` → Take (`context.l10n.todayMarkTaken`) + Skip (`todaySkip`) affordances (both enabled regardless of clock — early marking).
    - `taken`/`skipped` → status label (`todayStatusTaken`/`todayStatusSkipped`); show Undo (`todayUndo`) affordance ONLY when `dose.undoable` is true.
  - No overdue styling — a past-time pending dose renders identically to an upcoming one.
  - Strings via `context.l10n.*`.
- Widget tests: pending shows Take+Skip and taps fire callbacks; taken/skipped shows status; Undo shown iff `undoable`; tapping Undo fires `onUndo`.

**Contracts**:

### Expects
- `TodayDose` exported from `today_view_model.dart` (Task 013); Today l10n keys exist (Task 011); `medicationFormIcon` exists.

### Produces
- `today_dose_tile.dart` exports `class TodayDoseTile` with named params `dose`, `onTaken`, `onSkip`, `onUndo`.
- Undo affordance is rendered only when `dose.undoable == true`.

**Done when**:
- [ ] Renders name/time(24h)/dose; pending vs taken/skipped affordances correct; Undo gated on `undoable`.
- [ ] Callbacks fire on tap (widget-tested).
- [ ] Strings via `context.l10n`; `dart analyze` + widget test pass.

**Spec criteria addressed**: AC-8, AC-10, AC-12, AC-13

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `lib/features/meds/presentation/widgets/today_dose_tile.dart`, `test/features/meds/presentation/widgets/today_dose_tile_test.dart`
**Contract**: Expects [ok] | Produces [2/2] — `TodayDoseTile(dose,onTaken,onSkip,onUndo)`; Undo gated on `dose.undoable`. 10 widget tests pass; full suite 653 green.
**Notes**: **ARCHITECTURE CORRECTION (code review, §2.1).** First review = REQUEST CHANGES (Critical): a `features/home/` widget importing `features/meds/presentation/` violates §2.1. Root cause: the plan placed the Today UI in `home`, but intake is a `meds` concern (view model/providers/shared widgets all live in `meds`). Fix: relocated the tile+test into `features/meds/presentation/widgets/` (imports now same-feature). Also: removed inaccurate "plan-approved" dartdoc, made l10n imports relative (match `add_medication_modal`), added a 24h time-subtitle test. Second review = APPROVE WITH WARNINGS (Critical resolved). **Consequence for Task 015**: the Today SCREEN must be built in `features/meds/presentation/screens/` and wired via the router (core/routing), NOT by editing `home_screen.dart` — else the violation returns. `dart format`/`dart analyze` clean.
