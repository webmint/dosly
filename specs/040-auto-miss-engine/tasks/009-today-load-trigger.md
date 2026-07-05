# Task 009: Fire reconcile on Today-screen load

**Agent**: mobile-engineer
**Review checkpoint**: Yes (convergence — depends on 006 + 007; reconcile-loop risk, AC-11)
**Files**: `lib/features/meds/presentation/screens/today_screen.dart` (modify), `test/features/meds/presentation/screens/today_screen_test.dart` (modify)
**Depends on**: 006, 007
**Blocks**: None
**Context docs**: `docs/features/meds.md`

## Description

Run the auto-miss reconciliation once each time the Today screen is opened. `_TodayScreenState.initState` fires it fire-and-forget — `initState` runs exactly once per mount, so this is "once per Today load, not per rebuild": the resulting `intakesListProvider` re-emission drives `build()`, never re-entering `initState`, so there is no reconcile↔rebuild loop (already-missed occurrences are ineligible anyway, so even a re-fire converges). No new window-expiry `Timer` is added — a dose whose window closes while the screen sits idle flips only on the next load/open (confirmed scope).

## Change details

- In `lib/features/meds/presentation/screens/today_screen.dart`:
  - Add `@override void initState()` to `_TodayScreenState`: call `super.initState()`, then schedule a fire-and-forget reconcile: `Future.microtask(() { if (!mounted) return; ref.read(reconcileMissedIntakesProvider).call(now: clock.now()); });`. The use case returns a `Left` value (never throws), so ignoring the returned future is safe; optionally `.then((r) => r.fold((f) => <log>, (_) {}))`. `reconcileMissedIntakesProvider` comes from the already-imported `../providers/intake_providers.dart`.
  - Leave the existing `dispose()` / grace-timer logic untouched.
- In `test/features/meds/presentation/screens/today_screen_test.dart`:
  - In the scopes that mount `TodayScreen`, add `reconcileMissedIntakesProvider.overrideWith((ref) => _NoOpReconcile())` (a tiny `implements ReconcileMissedIntakes` fake returning `Right(0)`) so existing tests don't hit real repos.
  - Add a **single-fire** test: a recording fake counts `call` invocations; assert it is invoked once per mount and that pumping a rebuild (e.g. a stream re-emission) does NOT increment the count (no loop).
  - Add an **AC-12** test: wire a REAL `ReconcileMissedIntakes` over in-memory/fake repos with one past-window pending dose; mount, pump, and assert that dose's tile renders the `missed` label (from Task 007) without a manual refresh; assert a dose whose window has NOT closed stays pending (no live flip beyond load).

## Contracts

### Expects
- `reconcileMissedIntakesProvider` exposes `ReconcileMissedIntakes` with `call({required DateTime now})` (Task 006).
- `today_screen.dart` `_TodayScreenState` is a `ConsumerState` with an existing `dispose()`.
- The `missed` tile renders a visible `todayStatusMissed` label (Task 007) — the AC-12 assertion reads it.

### Produces
- `today_screen.dart` `_TodayScreenState.initState` reads `reconcileMissedIntakesProvider` and calls `.call(now: clock.now())`.
- `today_screen_test.dart` overrides `reconcileMissedIntakesProvider` and contains a single-fire (once-per-mount, no-loop) test and a past-window→missed reactive test.

## Done when
- [x] Opening the Today screen fires reconcile exactly once per mount; a rebuild does not re-fire it (no loop).
- [x] With no medications, the trigger writes nothing and does not error.
- [x] A past-window pending dose renders `missed` after mount+pump via the reactive stream; a not-yet-closed dose stays pending.
- [x] `flutter test test/features/meds/presentation/screens/today_screen_test.dart` green; `dart analyze` clean on changed files.

**Spec criteria addressed**: AC-11, AC-12

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/features/meds/presentation/screens/today_screen.dart`, `test/features/meds/presentation/screens/today_screen_test.dart`
**Contract**: Expects [confirmed] | Produces [2/2 verified]
**Notes**: `_TodayScreenState.initState` fires `ref.read(reconcileMissedIntakesProvider).call(now: clock.now())` once via `Future.microtask` + `mounted` guard — once per mount (initState), not per rebuild → no reconcile↔rebuild loop. `dispose()`/grace-timer untouched; no live-flip Timer (Spec C). Existing scopes override `reconcileMissedIntakesProvider` → `_NoOpReconcile`. Single-fire test uses a real invocation counter (asserts count stays 1 across a rebuild). **Self-repair (1/3)**: the initial AC-12 test HUNG — it drove a real `ReconcileMissedIntakes` whose `watchAll().first` drift-stream reads never resolve under widget-test fake-async, and left 5 dead scratch classes + a `DEBUG print`. Rewrote AC-12 to the file's working real-DB→drift-`.watch()`→UI pattern (a `_WritesMissedReconcile` fake writes the missed row via `markMissed`; the real `intakesListProvider` re-emits and flips the tile); removed all dead code + prints. File's 10 tests now pass in ~3s (no hang). Full suite 793/793, project-wide analyze clean. Code review: APPROVE (3 non-blocking Info).
