# Task 015: Today screen assembly + empty state

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/screens/today_screen.dart` (new), `lib/features/meds/presentation/widgets/today_empty_state.dart` (new), `lib/core/routing/app_router.dart` (branch 0 → TodayScreen), DELETE `lib/features/home/presentation/screens/home_screen.dart` (+ test), `test/core/routing/app_router_test.dart` (hermetic `_HomeStub`), `test/features/meds/presentation/screens/today_screen_test.dart` (new) _(relocated from `home/` per §2.1 — see notes)_
**Depends on**: 011, 012, 013, 014
**Blocks**: 016
**Context docs**: docs/features/home.md, docs/features/meds.md
**Review checkpoint**: Yes

**Description**:
Convert `HomeScreen` from a placeholder `StatelessWidget` into the reactive Today checklist (`ConsumerStatefulWidget`, like `MedsScreen`). Watch the medications + intakes streams, compute `buildTodayView(now: clock.now())`, render the time-sorted list of `TodayDoseTile`s (or the empty state), wire the three actions to their providers, and run a periodic grace-refresh ticker. This is the integration convergence point.

**Change details**:
- `home_screen.dart` → `ConsumerStatefulWidget`:
  - AppBar: keep the settings-gear action + bottom divider; set the title to `context.l10n.todayTitle`. Add a date header (localized via `MaterialLocalizations`, e.g. `formatFullDate(clock.now())`).
  - Body: combine `ref.watch(medicationsListProvider)` and `ref.watch(intakesListProvider)` — render `CircularProgressIndicator` while either is loading, muted error text on either error, else `buildTodayView(meds, intakes, clock.now())`. If the view has no doses → `TodayEmptyState`; else a `ListView` of `TodayDoseTile`.
  - Actions: `onTaken` → `ref.read(markIntakeTakenProvider).call(medicationId, slotId, scheduledAt, now: clock.now())`; `onSkip` → `skipIntakeProvider`; `onUndo` → `undoIntakeProvider.call(id, confirmedAt, now: clock.now())`. Capture `ScaffoldMessenger`/l10n before any `await` (established async-safety idiom). On `Left`, show a localized error SnackBar; success needs no SnackBar (list updates reactively).
  - Grace ticker: `Timer.periodic(const Duration(seconds: 30), ...)` calling `setState` (started in `initState`, cancelled in `dispose`) so `undoable` re-evaluates as the window elapses.
- `today_empty_state.dart`: centered card with `context.l10n.todayEmptyTitle` + `todayEmptyBody` (`onSurfaceVariant`), mirroring the meds `_EmptyState`.
- Widget tests: list renders time-sorted tiles (AC-8); tapping Take/Skip marks the dose and the tile reflects it (AC-9); empty state when no doses (AC-11); loading/error branches (AC-11); Undo within grace returns to pending, and undo is absent/no-op after grace (AC-12, AC-13) using `withClock`.

**Contracts**:

### Expects
- `intakesListProvider`, `markIntakeTakenProvider`, `skipIntakeProvider`, `undoIntakeProvider` (Task 012); `buildTodayView`/`TodayDose`/`TodayView` (Task 013); `TodayDoseTile` (Task 014); `medicationsListProvider` (existing); Today l10n keys (Task 011).

### Produces
- `home_screen.dart` declares `class HomeScreen extends ConsumerStatefulWidget` whose state watches `medicationsListProvider` and `intakesListProvider` and calls `buildTodayView`.
- `home_screen.dart` wires `onTaken`/`onSkip`/`onUndo` to the respective providers and starts/cancels a `Timer.periodic` grace ticker.
- `today_empty_state.dart` exports `class TodayEmptyState` using `todayEmptyTitle`/`todayEmptyBody`.

**Done when**:
- [ ] Reactive time-sorted checklist renders; mark/skip/undo work end-to-end and survive rebuild (widget-tested).
- [ ] Empty / loading / error states render correctly.
- [ ] Grace ticker started in `initState`, cancelled in `dispose`; undo gated by grace.
- [ ] Settings navigation from the AppBar still works.
- [ ] `dart analyze` + `flutter test test/features/home/` pass.

**Spec criteria addressed**: AC-8, AC-9, AC-10, AC-11, AC-12, AC-13

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: NEW `today_screen.dart`, `today_empty_state.dart`, `today_screen_test.dart`; EDIT `today_view_model.dart` (+test) added `TodayDose.intakeId`, `app_router.dart` (branch 0 → TodayScreen), `app_router_test.dart` (`_HomeStub`), 3 ARBs + regen (`todayActionError`); collateral `app_bootstrap_test.dart`/`widget_test.dart` (in-memory DB overrides); DELETED `home_screen.dart` (+test).
**Contract**: Produces [4/4] — `TodayScreen` (watches both providers, wires mark/skip/undo, non-periodic grace timer cancelled in dispose), `app_router` branch 0 → TodayScreen (no HomeScreen import in lib), `TodayEmptyState` + `TodayDose.intakeId`, HomeScreen retired + hermetic app_router_test.
**Notes**: **ARCHITECTURE (per §2.1 from Task 014 review):** Today screen built in `features/meds/` and routed via `core/routing` (composition root) rather than editing `home_screen.dart` — avoids the cross-feature violation. `HomeScreen` retired; `app_router_test` uses a private `_HomeStub` (stays hermetic, no timer/DB on branch 0). **Grace refresh:** single rescheduling one-shot `Timer` (never `Timer.periodic`) → keeps `pumpAndSettle` usable; cancelled in dispose + before reschedule; scheduled only when a dose is undoable. **View-model gap fixed:** `TodayDose.intakeId` added (undo needs it). **Code review: APPROVE WITH WARNINGS** — async-safety + timer lifecycle + AC-13 confirmed correct; one warning fixed (write failures now show `todayActionError`, not the misleading `todayLoadError`). Two collateral test regressions from retiring HomeScreen were caught + fixed. `dart analyze` clean; today_view_model 11/11, today_screen 7/7, app_router 7/7; full suite 659/659 (pre-fix run).
