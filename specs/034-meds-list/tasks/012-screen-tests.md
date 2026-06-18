# Task 012: Screen widget tests (incl. reactive add)

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/screens/meds_screen_test.dart` (new)
**Depends on**: 011
**Blocks**: None
**Context docs**: `specs/034-meds-list/spec.md` (acceptance criteria)
**Review checkpoint**: No

**Description**:
Widget-test the rebuilt screen with overridden providers (override `medicationsListProvider` / `medicationRepositoryProvider` via in-memory or fake), wrapped in `ProviderScope` + localization delegates, and `withClock(Clock.fixed(...))` for deterministic course-day output. Cover the behaviors the ACs promise. Mind the documented widget-test gotchas in MEMORY (off-stage menu items; `MaterialLocalizations` date formats).

**Change details**:
- Cases:
  - sections render: continuous meds under the Continuous header, course meds under the Course header, sorted by name (AC-7).
  - tile content: a low-stock med shows its stock segment in `colorScheme.error`; a course tile shows `День X/Y`; a continuous tile shows the continuous type chip (AC-8/9).
  - filter: selecting `Active` hides a completed course; `All` shows it again (AC-10).
  - search: typing a substring filters across sections; clearing restores (AC-11).
  - empty states: zero meds → top-level empty state; a filter/search with no matches in one section → that section's inline placeholder (AC-12).
  - chevron present but not tappable (no navigation on tile tap) (AC-13).
  - loading + error branches render via overridden provider states (AC-14).
  - **reactive add (AC-19)**: with a real in-memory DB override, persist a medication through the repository and `pump` → the new med appears without any manual refresh.

**Done when**:
- [x] All listed cases present and asserting localized output / colors / visibility.
- [x] `flutter test test/features/meds/presentation/screens/meds_screen_test.dart` green.
- [x] `dart analyze` clean.

**Spec criteria addressed**: AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-14, AC-19

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: meds_screen_test.dart (rewrote pre-existing placeholder test → 33 tests), app_router_test.dart (repair: in-memory DB override)
**Contract**: Expects 2/2 verified | Produces 1/1 verified
**Notes**: 33 screen tests cover AC-7/8/9/10/11/12/13/14/19; `_FakeMedicationRepository` override for state tests; real in-memory DB (`closeStreamsSynchronously:true`) for reactive-add. **Full-suite verification caught a Task-011 integration regression**: `app_router_test.dart` pumps the shell incl. `MedsScreen`, which now needs `appDatabaseProvider` — repaired by overriding it in-memory there (+ `closeStreamsSynchronously` to avoid a pending-timer assertion). Full suite **481/481 green**; project analyze clean. Logged to MEMORY (shell/router tests must override new screen provider deps).

## Contracts

### Expects
- Task 011 `Produces` (the rebuilt `MedsScreen` consuming `medicationsListProvider` + `buildMedsListView`).
- `appDatabaseProvider` / `medicationRepositoryProvider` are overridable (existing in-memory `AppDatabase` test pattern).

### Produces
- `meds_screen_test.dart` overrides the list/repository providers, wraps in `withClock(Clock.fixed(`, and asserts section/filter/search/empty/loading/error behaviors plus a reactive add.
